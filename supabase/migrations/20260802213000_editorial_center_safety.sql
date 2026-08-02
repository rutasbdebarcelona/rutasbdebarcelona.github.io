-- Centro editorial seguro: validaci?n ampliada y reversi?n de portada.
create or replace function public.validate_site_design(p_settings jsonb)
returns void
language plpgsql
immutable
set search_path=public
as $$
declare
  k text;
  section_key text;
begin
  if jsonb_typeof(p_settings) <> 'object' then raise exception 'invalid_settings'; end if;
  if coalesce(p_settings->>'fontPair','') not in ('editorial','classic','modern','brand','lato') then raise exception 'invalid_font_pair'; end if;
  if coalesce(p_settings->>'layout','') not in ('editorial','compact','airy') then raise exception 'invalid_layout'; end if;
  if coalesce(p_settings->>'logo','') not in ('symbol-text','full','symbol') then raise exception 'invalid_logo'; end if;

  foreach k in array array['forest','forest2','cream','paper','ink','clay','gold'] loop
    if coalesce(p_settings->'colors'->>k,'') !~ '^#[0-9A-Fa-f]{6}$' then raise exception 'invalid_color_%', k; end if;
  end loop;

  if jsonb_typeof(p_settings->'content'->'es') <> 'object'
     or jsonb_typeof(p_settings->'content'->'en') <> 'object' then
    raise exception 'invalid_content';
  end if;
  if jsonb_typeof(p_settings->'home') <> 'object'
     or jsonb_typeof(p_settings->'home'->'sectionOrder') <> 'array'
     or jsonb_array_length(p_settings->'home'->'sectionOrder') <> 3 then
    raise exception 'invalid_home_structure';
  end if;

  foreach section_key in array array['routes','method','partner'] loop
    if not (p_settings->'home'->'sectionOrder' ? section_key) then raise exception 'missing_section_%', section_key; end if;
  end loop;

  if length(coalesce(p_settings->'home'->'heroImage'->>'url','')) > 2048
     or length(coalesce(p_settings->'home'->'methodImage'->>'url','')) > 2048 then
    raise exception 'invalid_image_url';
  end if;
  if length(coalesce(p_settings->'home'->'heroImage'->>'altEs','')) > 240
     or length(coalesce(p_settings->'home'->'heroImage'->>'altEn','')) > 240
     or length(coalesce(p_settings->'home'->'methodImage'->>'altEs','')) > 240
     or length(coalesce(p_settings->'home'->'methodImage'->>'altEn','')) > 240 then
    raise exception 'invalid_image_alt';
  end if;
end
$$;

create or replace function public.revert_site_design_revision(p_revision_id bigint)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  target_settings jsonb;
  current_settings jsonb;
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;

  select settings into target_settings
  from public.site_design_revisions
  where id=p_revision_id;
  if target_settings is null then raise exception 'revision_not_found'; end if;
  perform public.validate_site_design(target_settings);

  select published into current_settings
  from public.site_design_settings
  where id=true
  for update;

  insert into public.site_design_revisions(settings,created_by)
  values(current_settings,auth.uid());

  update public.site_design_settings
  set published=target_settings,
      draft=null,
      updated_at=now(),
      published_at=now(),
      updated_by=auth.uid()
  where id=true;

  return target_settings;
end
$$;

revoke all on function public.revert_site_design_revision(bigint) from public,anon;
grant execute on function public.revert_site_design_revision(bigint) to authenticated;
