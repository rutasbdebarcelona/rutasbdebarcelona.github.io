-- A new commercial route can be born in the private editor without cloning old content.
create or replace function public.create_route_from_scratch(p_title text)
returns public.routes language plpgsql security definer set search_path=public as $$
declare v_route public.routes; v_slug text; v_base text;
begin
  if not public.is_active_admin() then raise exception 'admin_access_required' using errcode='42501'; end if;
  if char_length(trim(coalesce(p_title,''))) not between 2 and 160 then raise exception 'invalid_route_title' using errcode='22023'; end if;
  v_base:=lower(translate(trim(p_title),'áéíóúüñçàèìòùÁÉÍÓÚÜÑÇÀÈÌÒÙ','aeiouuncaeiouAEIOUUNCAEIOU'));
  v_base:=trim(both '-' from regexp_replace(v_base,'[^a-z0-9]+','-','g'));
  if v_base='' then v_base:='ruta'; end if;
  v_slug:=v_base;
  if exists(select 1 from public.routes where slug=v_slug) then v_slug:=v_base||'-'||substr(encode(extensions.gen_random_bytes(3),'hex'),1,6); end if;
  insert into public.routes(slug,title,short_description,full_description,duration_minutes_min,duration_minutes_max,offered_languages,accessibility,includes,excludes,min_participants,max_participants,status,featured,sort_order,eyebrow,promise,status_label,display_duration,display_format,display_area,audience)
  values(v_slug,trim(p_title),'','',75,75,array['es','en'],'',array[]::text[],array[]::text[],1,15,'draft',false,coalesce((select max(sort_order)+10 from public.routes),10),'','','En preparación','','','',array[]::text[])
  returning * into v_route;
  insert into public.route_translations(route_id,locale,title,status_label,offered_languages) values(v_route.id,'en',trim(p_title),'In preparation',array['es','en']);
  insert into public.route_product_profiles(route_id,max_group_size,translations,page_settings)
  values(v_route.id,15,jsonb_build_object('en','{}'::jsonb),jsonb_build_object('gallery_mode','grid','stops_media_mode','carousel','stops_display_mode','cards','show_highlights',true,'show_meeting_point',true,'show_accessibility',true,'show_long_description',true));
  insert into public.audit_log(admin_id,action,entity_type,entity_id,details) values(auth.uid(),'route_created','route',v_route.id::text,jsonb_build_object('from_scratch',true,'status','draft'));
  return v_route;
end $$;
revoke all on function public.create_route_from_scratch(text) from public,anon;
grant execute on function public.create_route_from_scratch(text) to authenticated;
