-- Complete editable public route content while preserving draft/publication workflow.
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
  'sort_order',greatest(0,coalesce((p_payload->>'sort_order')::integer,v_route.sort_order))
 );
 insert into public.route_drafts(route_id,content) values(p_route_id,v_content) on conflict(route_id) do update set content=excluded.content;
 insert into public.audit_log(admin_id,action,entity_type,entity_id,details) values(auth.uid(),'route_draft_saved','route',p_route_id::text,jsonb_build_object('complete_editor',true));
 return v_content;
end $$;

create or replace function public.publish_route_draft(p_route_id uuid)
returns public.routes language plpgsql security definer set search_path=public as $$
declare v_route public.routes;v_draft public.route_drafts;v_has_draft boolean;v_has_media_changes boolean;v_new_hero public.route_media;v_remove_current_hero boolean;v_before jsonb;v_after jsonb;v_media_before jsonb;v_media_after jsonb;v_result public.routes;
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
 if v_new_hero.id is not null then update public.route_media set status='archived' where route_id=p_route_id and role='hero' and status='published';end if;
 update public.route_media set status='archived' where route_id=p_route_id and status='pending_removal';update public.route_media set status='published' where route_id=p_route_id and status='draft';
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'status',status) order by id),'[]'::jsonb) into v_media_after from public.route_media where route_id=p_route_id;
 v_after:=to_jsonb(v_result)||jsonb_build_object('stops',coalesce((select jsonb_agg(title order by sort_order) from public.route_stops where route_id=p_route_id),'[]'::jsonb));
 if v_before is distinct from v_after or v_media_before is distinct from v_media_after then insert into public.audit_log(admin_id,action,entity_type,entity_id,details) values(auth.uid(),'route_updated','route',p_route_id::text,jsonb_build_object('before',v_before,'after',v_after,'media_before',v_media_before,'media_after',v_media_after,'source','complete_editor'));end if;
 delete from public.route_drafts where route_id=p_route_id;return v_result;
end $$;

create or replace function public.revert_route_revision(p_audit_id bigint)
returns public.routes language plpgsql security definer set search_path=public as $$
declare v_revision public.audit_log;v_target public.routes;v_before jsonb;
begin
 if not public.is_active_admin() then raise exception 'admin_access_required' using errcode='42501';end if;
 select * into v_revision from public.audit_log where id=p_audit_id and action='route_updated' and entity_type='route' for update;if not found then raise exception 'route_revision_not_found' using errcode='P0002';end if;v_before:=v_revision.details->'before';
 update public.routes set title=v_before->>'title',eyebrow=nullif(v_before->>'eyebrow',''),promise=nullif(v_before->>'promise',''),full_description=nullif(v_before->>'full_description',''),status_label=nullif(v_before->>'status_label',''),display_duration=nullif(v_before->>'display_duration',''),display_format=nullif(v_before->>'display_format',''),display_area=nullif(v_before->>'display_area',''),offered_languages=array(select jsonb_array_elements_text(coalesce(v_before->'offered_languages','[]'::jsonb))),audience=array(select jsonb_array_elements_text(coalesce(v_before->'audience','[]'::jsonb))),display_starting_point=nullif(v_before->>'display_starting_point',''),display_ending_point=nullif(v_before->>'display_ending_point',''),includes=array(select jsonb_array_elements_text(coalesce(v_before->'includes','[]'::jsonb))),excludes=array(select jsonb_array_elements_text(coalesce(v_before->'excludes','[]'::jsonb))),accessibility=nullif(v_before->>'accessibility',''),display_price_individual=nullif(v_before->>'display_price_individual',''),display_price_group=nullif(v_before->>'display_price_group',''),featured=coalesce((v_before->>'featured')::boolean,false),sort_order=coalesce((v_before->>'sort_order')::integer,0),primary_image_path=nullif(v_before->>'primary_image_path',''),primary_image_alt=nullif(v_before->>'primary_image_alt',''),status=(v_before->>'status')::public.route_status where id=v_revision.entity_id::uuid returning * into v_target;
 if v_before ? 'stops' then delete from public.route_stops where route_id=v_target.id;insert into public.route_stops(route_id,title,sort_order) select v_target.id,value,ordinality-1 from jsonb_array_elements_text(v_before->'stops') with ordinality;end if;
 if jsonb_typeof(v_revision.details->'media_before')='array' then update public.route_media media set status=previous.status from jsonb_to_recordset(v_revision.details->'media_before') as previous(id uuid,status text) where media.id=previous.id;end if;
 insert into public.audit_log(admin_id,action,entity_type,entity_id,details) values(auth.uid(),'route_revision_reverted','route',v_target.id::text,jsonb_build_object('reverted_audit_id',p_audit_id));return v_target;
end $$;

revoke all on function public.save_route_draft(uuid,jsonb) from public,anon;grant execute on function public.save_route_draft(uuid,jsonb) to authenticated;
revoke all on function public.publish_route_draft(uuid) from public,anon;grant execute on function public.publish_route_draft(uuid) to authenticated;
revoke all on function public.revert_route_revision(bigint) from public,anon;grant execute on function public.revert_route_revision(bigint) to authenticated;
