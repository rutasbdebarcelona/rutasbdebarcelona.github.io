-- Editable English content for every route.
create table if not exists public.route_translations(
 route_id uuid not null references public.routes(id) on delete cascade,
 locale text not null check(locale in('en','ca')),title text not null,eyebrow text,promise text,full_description text,status_label text,display_duration text,display_format text,display_area text,offered_languages text[] not null default '{}',audience text[] not null default '{}',display_starting_point text,display_ending_point text,stops text[] not null default '{}',includes text[] not null default '{}',excludes text[] not null default '{}',accessibility text,display_price_individual text,display_price_group text,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),primary key(route_id,locale));
alter table public.route_translations enable row level security;
drop policy if exists admin_route_translations on public.route_translations;create policy admin_route_translations on public.route_translations using(public.is_active_admin()) with check(public.is_active_admin());
drop policy if exists public_route_translations on public.route_translations;create policy public_route_translations on public.route_translations for select using(exists(select 1 from public.routes r where r.id=route_id and r.status='published'));

create or replace function public.save_route_draft(p_route_id uuid,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_route public.routes; v_content jsonb;
begin
 if not public.is_active_admin() then raise exception 'admin_access_required' using errcode='42501'; end if;
 if char_length(trim(coalesce(p_payload->>'title',''))) not between 2 and 160 then raise exception 'invalid_route_title' using errcode='22023'; end if;
 if char_length(coalesce(p_payload->>'status_label',''))>80 then raise exception 'invalid_route_status_label' using errcode='22023'; end if;
 select * into v_route from public.routes where id=p_route_id for update;
 if not found then raise exception 'route_not_found' using errcode='P0002'; end if;
 v_content:=jsonb_build_object(
  'title',trim(p_payload->>'title'),'eyebrow',nullif(trim(p_payload->>'eyebrow'),''),'promise',nullif(trim(p_payload->>'promise'),''),
  'full_description',nullif(trim(p_payload->>'full_description'),''),'status_label',coalesce(nullif(trim(p_payload->>'status_label'),''),v_route.status_label),
  'display_duration',nullif(trim(p_payload->>'display_duration'),''),'display_format',nullif(trim(p_payload->>'display_format'),''),
  'display_area',nullif(trim(p_payload->>'display_area'),''),'offered_languages',coalesce(p_payload->'offered_languages','[]'::jsonb),
  'audience',coalesce(p_payload->'audience','[]'::jsonb),'display_starting_point',nullif(trim(p_payload->>'display_starting_point'),''),
  'display_ending_point',nullif(trim(p_payload->>'display_ending_point'),''),'stops',coalesce(p_payload->'stops','[]'::jsonb),
  'includes',coalesce(p_payload->'includes','[]'::jsonb),'excludes',coalesce(p_payload->'excludes','[]'::jsonb),
  'accessibility',nullif(trim(p_payload->>'accessibility'),''),'display_price_individual',nullif(trim(p_payload->>'display_price_individual'),''),
  'display_price_group',nullif(trim(p_payload->>'display_price_group'),''),'featured',coalesce((p_payload->>'featured')::boolean,false),
  'sort_order',greatest(0,coalesce((p_payload->>'sort_order')::integer,v_route.sort_order)),
  'en',coalesce(p_payload->'en','{}'::jsonb)
 );
 insert into public.route_drafts(route_id,content) values(p_route_id,v_content) on conflict(route_id) do update set content=excluded.content;
 insert into public.audit_log(admin_id,action,entity_type,entity_id,details) values(auth.uid(),'route_draft_saved','route',p_route_id::text,jsonb_build_object('complete_editor',true));
 return v_content;
end $$;

create or replace function public.publish_route_draft(p_route_id uuid)
returns public.routes language plpgsql security definer set search_path=public as $$
declare v_route public.routes;v_draft public.route_drafts;v_has_draft boolean;v_has_media_changes boolean;v_new_hero public.route_media;v_remove_current_hero boolean;v_before jsonb;v_after jsonb;v_media_before jsonb;v_media_after jsonb;v_result public.routes;v_en jsonb;
begin
 if not public.is_active_admin() then raise exception 'admin_access_required' using errcode='42501'; end if;
 select * into v_route from public.routes where id=p_route_id for update;if not found then raise exception 'route_not_found' using errcode='P0002';end if;
 select exists(select 1 from public.route_drafts where route_id=p_route_id) into v_has_draft;if v_has_draft then select * into v_draft from public.route_drafts where route_id=p_route_id for update;end if;
 select exists(select 1 from public.route_media where route_id=p_route_id and status in('draft','pending_removal')) into v_has_media_changes;
 if v_route.status<>'draft' and not v_has_draft and not v_has_media_changes then raise exception 'route_draft_required' using errcode='P0002';end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'status',status) order by id),'[]'::jsonb) into v_media_before from public.route_media where route_id=p_route_id;
 select * into v_new_hero from public.route_media where route_id=p_route_id and role='hero' and status='draft' order by created_at desc limit 1;
 select exists(select 1 from public.route_media where route_id=p_route_id and role='hero' and storage_path=v_route.primary_image_path and status='pending_removal') into v_remove_current_hero;
 v_before:=to_jsonb(v_route)||jsonb_build_object('stops',coalesce((select jsonb_agg(title order by sort_order) from public.route_stops where route_id=p_route_id),'[]'::jsonb));
 update public.routes set
  title=case when v_has_draft then coalesce(v_draft.content->>'title',v_route.title) else v_route.title end,
  eyebrow=case when v_has_draft then nullif(v_draft.content->>'eyebrow','') else v_route.eyebrow end,
  promise=case when v_has_draft then nullif(v_draft.content->>'promise','') else v_route.promise end,
  full_description=case when v_has_draft then nullif(v_draft.content->>'full_description','') else v_route.full_description end,
  status_label=case when v_has_draft then coalesce(v_draft.content->>'status_label',v_route.status_label) else v_route.status_label end,
  display_duration=case when v_has_draft then nullif(v_draft.content->>'display_duration','') else v_route.display_duration end,
  display_format=case when v_has_draft then nullif(v_draft.content->>'display_format','') else v_route.display_format end,
  display_area=case when v_has_draft then nullif(v_draft.content->>'display_area','') else v_route.display_area end,
  offered_languages=case when v_has_draft then array(select jsonb_array_elements_text(coalesce(v_draft.content->'offered_languages','[]'::jsonb))) else v_route.offered_languages end,
  audience=case when v_has_draft then array(select jsonb_array_elements_text(coalesce(v_draft.content->'audience','[]'::jsonb))) else v_route.audience end,
  display_starting_point=case when v_has_draft then nullif(v_draft.content->>'display_starting_point','') else v_route.display_starting_point end,
  display_ending_point=case when v_has_draft then nullif(v_draft.content->>'display_ending_point','') else v_route.display_ending_point end,
  includes=case when v_has_draft then array(select jsonb_array_elements_text(coalesce(v_draft.content->'includes','[]'::jsonb))) else v_route.includes end,
  excludes=case when v_has_draft then array(select jsonb_array_elements_text(coalesce(v_draft.content->'excludes','[]'::jsonb))) else v_route.excludes end,
  accessibility=case when v_has_draft then nullif(v_draft.content->>'accessibility','') else v_route.accessibility end,
  display_price_individual=case when v_has_draft then nullif(v_draft.content->>'display_price_individual','') else v_route.display_price_individual end,
  display_price_group=case when v_has_draft then nullif(v_draft.content->>'display_price_group','') else v_route.display_price_group end,
  featured=case when v_has_draft then coalesce((v_draft.content->>'featured')::boolean,v_route.featured) else v_route.featured end,
  sort_order=case when v_has_draft then coalesce((v_draft.content->>'sort_order')::integer,v_route.sort_order) else v_route.sort_order end,
  primary_image_path=case when v_new_hero.id is not null then v_new_hero.storage_path when v_remove_current_hero then null else v_route.primary_image_path end,
  primary_image_alt=case when v_new_hero.id is not null then v_new_hero.alt_text when v_remove_current_hero then null else v_route.primary_image_alt end,status='published'
 where id=p_route_id returning * into v_result;
 if v_has_draft and v_draft.content ? 'stops' then
  delete from public.route_stops where route_id=p_route_id;
  insert into public.route_stops(route_id,title,sort_order) select p_route_id,value,ordinality-1 from jsonb_array_elements_text(v_draft.content->'stops') with ordinality;
 end if;
 if v_has_draft and jsonb_typeof(v_draft.content->'en')='object' then
  v_en:=v_draft.content->'en';
  insert into public.route_translations(route_id,locale,title,eyebrow,promise,full_description,status_label,display_duration,display_format,display_area,offered_languages,audience,display_starting_point,display_ending_point,stops,includes,excludes,accessibility,display_price_individual,display_price_group)
  values(p_route_id,'en',coalesce(nullif(trim(v_en->>'title'),''),v_result.title),nullif(trim(v_en->>'eyebrow'),''),nullif(trim(v_en->>'promise'),''),nullif(trim(v_en->>'full_description'),''),coalesce(nullif(trim(v_en->>'status_label'),''),'In preparation'),nullif(trim(v_en->>'display_duration'),''),nullif(trim(v_en->>'display_format'),''),nullif(trim(v_en->>'display_area'),''),array(select jsonb_array_elements_text(coalesce(v_en->'offered_languages','[]'::jsonb))),array(select jsonb_array_elements_text(coalesce(v_en->'audience','[]'::jsonb))),nullif(trim(v_en->>'display_starting_point'),''),nullif(trim(v_en->>'display_ending_point'),''),array(select jsonb_array_elements_text(coalesce(v_en->'stops','[]'::jsonb))),array(select jsonb_array_elements_text(coalesce(v_en->'includes','[]'::jsonb))),array(select jsonb_array_elements_text(coalesce(v_en->'excludes','[]'::jsonb))),nullif(trim(v_en->>'accessibility'),''),nullif(trim(v_en->>'display_price_individual'),''),nullif(trim(v_en->>'display_price_group'),''))
  on conflict(route_id,locale) do update set title=excluded.title,eyebrow=excluded.eyebrow,promise=excluded.promise,full_description=excluded.full_description,status_label=excluded.status_label,display_duration=excluded.display_duration,display_format=excluded.display_format,display_area=excluded.display_area,offered_languages=excluded.offered_languages,audience=excluded.audience,display_starting_point=excluded.display_starting_point,display_ending_point=excluded.display_ending_point,stops=excluded.stops,includes=excluded.includes,excludes=excluded.excludes,accessibility=excluded.accessibility,display_price_individual=excluded.display_price_individual,display_price_group=excluded.display_price_group,updated_at=now();
 end if;
 if v_new_hero.id is not null then update public.route_media set status='archived' where route_id=p_route_id and role='hero' and status='published';end if;
 update public.route_media set status='archived' where route_id=p_route_id and status='pending_removal';update public.route_media set status='published' where route_id=p_route_id and status='draft';
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'status',status) order by id),'[]'::jsonb) into v_media_after from public.route_media where route_id=p_route_id;
 v_after:=to_jsonb(v_result)||jsonb_build_object('stops',coalesce((select jsonb_agg(title order by sort_order) from public.route_stops where route_id=p_route_id),'[]'::jsonb));
 if v_before is distinct from v_after or v_media_before is distinct from v_media_after then insert into public.audit_log(admin_id,action,entity_type,entity_id,details) values(auth.uid(),'route_updated','route',p_route_id::text,jsonb_build_object('before',v_before,'after',v_after,'media_before',v_media_before,'media_after',v_media_after,'source','complete_editor'));end if;
 delete from public.route_drafts where route_id=p_route_id;return v_result;
end $$;

revoke all on function public.save_route_draft(uuid,jsonb) from public,anon;grant execute on function public.save_route_draft(uuid,jsonb) to authenticated;
revoke all on function public.publish_route_draft(uuid) from public,anon;grant execute on function public.publish_route_draft(uuid) to authenticated;
