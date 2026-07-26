create table if not exists public.site_design_settings (
  id boolean primary key default true check (id),
  published jsonb not null,
  draft jsonb,
  updated_at timestamptz not null default now(),
  published_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

create table if not exists public.site_design_revisions (
  id bigint generated always as identity primary key,
  settings jsonb not null,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);

alter table public.site_design_settings enable row level security;
alter table public.site_design_revisions enable row level security;

insert into public.site_design_settings (id, published)
values (true, '{
  "colors":{"forest":"#16382f","forest2":"#0d2922","cream":"#fbf8f2","paper":"#f4efe6","ink":"#18231f","clay":"#b75f43","gold":"#c59b52"},
  "fontPair":"editorial","layout":"editorial","logo":"symbol-text",
  "content":{
    "es":{"homeKicker":"Rutas culturales en Barcelona","homeTitle":"Barcelona no solo se visita.","homeAccent":"Se aprende a mirar.","homeLead":"Recorridos con contexto, conversación y una mirada propia para entender lo que la ciudad todavía tiene delante de los ojos.","homeNote":"Historias conectadas con el lugar, no discursos repetidos frente a una postal.","contactTitle":"Hablemos de tu visita","contactIntro":"Para cualquier otra pregunta, puedes escribirnos al correo o contactarnos por teléfono."},
    "en":{"homeKicker":"Cultural tours in Barcelona","homeTitle":"Barcelona is not only visited.","homeAccent":"You learn how to see it.","homeLead":"Tours with context, conversation and a distinctive point of view to understand what the city still holds in plain sight.","homeNote":"Stories connected to the place, rather than a repeated speech in front of a postcard.","contactTitle":"Let us talk about your visit","contactIntro":"For any further questions, write to our email address or contact us by phone."}
  }
}'::jsonb)
on conflict (id) do nothing;

create or replace function public.validate_site_design(p_settings jsonb)
returns void language plpgsql immutable set search_path=public as $$
declare k text;
begin
  if jsonb_typeof(p_settings) <> 'object' then raise exception 'invalid_settings'; end if;
  if coalesce(p_settings->>'fontPair','') not in ('editorial','classic','modern') then raise exception 'invalid_font_pair'; end if;
  if coalesce(p_settings->>'layout','') not in ('editorial','compact','airy') then raise exception 'invalid_layout'; end if;
  if coalesce(p_settings->>'logo','') not in ('symbol-text','full','symbol') then raise exception 'invalid_logo'; end if;
  foreach k in array array['forest','forest2','cream','paper','ink','clay','gold'] loop
    if coalesce(p_settings->'colors'->>k,'') !~ '^#[0-9A-Fa-f]{6}$' then raise exception 'invalid_color_%', k; end if;
  end loop;
  if jsonb_typeof(p_settings->'content'->'es') <> 'object' or jsonb_typeof(p_settings->'content'->'en') <> 'object' then raise exception 'invalid_content'; end if;
end $$;

create or replace function public.get_public_site_design()
returns jsonb language sql stable security definer set search_path=public as $$
  select published from public.site_design_settings where id=true;
$$;

create or replace function public.get_admin_site_design()
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare result jsonb;
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;
  select jsonb_build_object('published',published,'draft',draft,'updated_at',updated_at,'published_at',published_at) into result from public.site_design_settings where id=true;
  return result;
end $$;

create or replace function public.save_site_design_draft(p_settings jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;
  perform public.validate_site_design(p_settings);
  update public.site_design_settings set draft=p_settings,updated_at=now(),updated_by=auth.uid() where id=true;
  return p_settings;
end $$;

create or replace function public.publish_site_design()
returns jsonb language plpgsql security definer set search_path=public as $$
declare result jsonb;
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;
  select draft into result from public.site_design_settings where id=true for update;
  if result is null then raise exception 'no_draft'; end if;
  perform public.validate_site_design(result);
  insert into public.site_design_revisions(settings,created_by)
    select published,auth.uid() from public.site_design_settings where id=true;
  update public.site_design_settings set published=result,draft=null,updated_at=now(),published_at=now(),updated_by=auth.uid() where id=true;
  return result;
end $$;

create or replace function public.discard_site_design_draft()
returns jsonb language plpgsql security definer set search_path=public as $$
declare result jsonb;
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;
  update public.site_design_settings set draft=null,updated_at=now(),updated_by=auth.uid() where id=true returning published into result;
  return result;
end $$;

revoke all on public.site_design_settings from public,anon,authenticated;
revoke all on public.site_design_revisions from public,anon,authenticated;
revoke all on function public.validate_site_design(jsonb) from public,anon,authenticated;
revoke all on function public.get_public_site_design() from public,authenticated;
revoke all on function public.get_admin_site_design() from public,anon;
revoke all on function public.save_site_design_draft(jsonb) from public,anon;
revoke all on function public.publish_site_design() from public,anon;
revoke all on function public.discard_site_design_draft() from public,anon;
grant execute on function public.get_public_site_design() to anon,authenticated;
grant execute on function public.get_admin_site_design() to authenticated;
grant execute on function public.save_site_design_draft(jsonb) to authenticated;
grant execute on function public.publish_site_design() to authenticated;
grant execute on function public.discard_site_design_draft() to authenticated;
grant select on public.site_design_revisions to authenticated;
create policy "admin_site_design_revisions" on public.site_design_revisions for select to authenticated using (public.is_active_admin());