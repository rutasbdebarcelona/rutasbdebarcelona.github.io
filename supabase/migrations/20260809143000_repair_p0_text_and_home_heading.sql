-- Repair character loss introduced in the P0 catalogue import and refresh the home catalogue heading.
-- ASCII-only migration: accented characters are generated with chr() to avoid terminal encoding loss.

create or replace function public._repair_p0_text(p_value text, p_separator text default null)
returns text language plpgsql immutable as $$
declare v text := p_value;
begin
  if v is null then return null; end if;
  v := replace(v,'Caf?Born','Caf'||chr(232)||'Born');
  v := replace(v,'a?rea','a'||chr(233)||'rea');
  v := replace(v,'Aig?es','Aig'||chr(252)||'es');
  v := replace(v,'aqu?','aqu'||chr(237));
  v := replace(v,'c?mo','c'||chr(243)||'mo');
  v := replace(v,'c?modo','c'||chr(243)||'modo');
  v := replace(v,'Caf?','Caf'||chr(232));
  v := replace(v,'Cerd?','Cerd'||chr(224));
  v := replace(v,'chafl?n','chafl'||chr(225)||'n');
  v := replace(v,'construcci?n','construcci'||chr(243)||'n');
  v := replace(v,'conversaci?n','conversaci'||chr(243)||'n');
  v := replace(v,'coraz?n','coraz'||chr(243)||'n');
  v := replace(v,'cuadr?cula','cuadr'||chr(237)||'cula');
  v := replace(v,'d?August','d'||chr(8217)||'August');
  v := replace(v,'decisi?n','decisi'||chr(243)||'n');
  v := replace(v,'despu?s','despu'||chr(233)||'s');
  v := replace(v,'dimensi?n','dimensi'||chr(243)||'n');
  v := replace(v,'est?n','est'||chr(225)||'n');
  v := replace(v,'fa?ade','fa'||chr(231)||'ade');
  v := replace(v,'G?tic','G'||chr(242)||'tic');
  v := replace(v,'Gr?cia','Gr'||chr(224)||'cia');
  v := replace(v,'Gu?a','Gu'||chr(237)||'a');
  v := replace(v,'hist?rica','hist'||chr(243)||'rica');
  v := replace(v,'hist?rico','hist'||chr(243)||'rico');
  v := replace(v,'identificaci?n','identificaci'||chr(243)||'n');
  v := replace(v,'iluminaci?n','iluminaci'||chr(243)||'n');
  v := replace(v,'im?genes','im'||chr(225)||'genes');
  v := replace(v,'investigaci?n','investigaci'||chr(243)||'n');
  v := replace(v,'jud?a','jud'||chr(237)||'a');
  v := replace(v,'l?gica','l'||chr(243)||'gica');
  v := replace(v,'l?mite','l'||chr(237)||'mite');
  v := replace(v,'m?s','m'||chr(225)||'s');
  v := replace(v,'M?sica','M'||chr(250)||'sica');
  v := replace(v,'operaci?n','operaci'||chr(243)||'n');
  v := replace(v,'p?blica','p'||chr(250)||'blica');
  v := replace(v,'P?blico','P'||chr(250)||'blico');
  v := replace(v,'percepci?n','percepci'||chr(243)||'n');
  v := replace(v,'Pla?a','Pla'||chr(231)||'a');
  v := replace(v,'pol?tica','pol'||chr(237)||'tica');
  v := replace(v,'pol?ticas','pol'||chr(237)||'ticas');
  v := replace(v,'pol?tico','pol'||chr(237)||'tico');
  v := replace(v,'preparaci?n','preparaci'||chr(243)||'n');
  v := replace(v,'Programaci?n','Programaci'||chr(243)||'n');
  v := replace(v,'re?ne','re'||chr(250)||'ne');
  v := replace(v,'recreaci?n','recreaci'||chr(243)||'n');
  v := replace(v,'religi?n','religi'||chr(243)||'n');
  v := replace(v,'renovaci?n','renovaci'||chr(243)||'n');
  v := replace(v,'representaci?n','representaci'||chr(243)||'n');
  v := replace(v,'segregaci?n','segregaci'||chr(243)||'n');
  v := replace(v,'simb?lica','simb'||chr(243)||'lica');
  v := replace(v,'superposici?n','superposici'||chr(243)||'n');
  v := replace(v,'t?cnica','t'||chr(233)||'cnica');
  v := replace(v,'transformaci?n','transformaci'||chr(243)||'n');
  v := replace(v,'vac?a','vac'||chr(237)||'a');
  v := replace(v,'vac?os','vac'||chr(237)||'os');
  v := replace(v,'versi?n','versi'||chr(243)||'n');
  v := replace(v,'Bishop?s','Bishop'||chr(8217)||'s');
  v := replace(v,'Today?s','Today'||chr(8217)||'s');
  v := replace(v,'Barcino?s','Barcino'||chr(8217)||'s');
  v := replace(v,'Quarter?s','Quarter'||chr(8217)||'s');
  v := replace(v,'neighbourhood?s','neighbourhood'||chr(8217)||'s');
  if p_separator is not null then v := replace(v,' ? ',' '||p_separator||' '); end if;
  v := replace(v,'60?75','60'||chr(8211)||'75');
  return v;
end $$;

do $$
declare rid uuid;
begin
  for rid in select id from public.routes where slug in ('barcino','barcino-nocturna','cerda','vista-previa-born') loop
    update public.routes set
      title=public._repair_p0_text(title,chr(183)),
      short_description=public._repair_p0_text(short_description,chr(183)),
      full_description=public._repair_p0_text(full_description,chr(183)),
      accessibility=public._repair_p0_text(accessibility,chr(183)),
      includes=(select coalesce(array_agg(public._repair_p0_text(x,chr(183))),array[]::text[]) from unnest(includes) x),
      excludes=(select coalesce(array_agg(public._repair_p0_text(x,chr(183))),array[]::text[]) from unnest(excludes) x),
      eyebrow=public._repair_p0_text(eyebrow,chr(183)),
      promise=public._repair_p0_text(promise,chr(183)),
      status_label=public._repair_p0_text(status_label,chr(183)),
      display_duration=public._repair_p0_text(display_duration,chr(183)),
      display_format=public._repair_p0_text(display_format,chr(183)),
      display_area=public._repair_p0_text(display_area,chr(183)),
      display_starting_point=public._repair_p0_text(display_starting_point,chr(183)),
      display_ending_point=public._repair_p0_text(display_ending_point,chr(183)),
      audience=(select coalesce(array_agg(public._repair_p0_text(x,chr(183))),array[]::text[]) from unnest(audience) x),
      primary_image_alt=public._repair_p0_text(primary_image_alt,chr(183)),
      updated_at=now()
    where id=rid;

    update public.route_product_profiles set
      short_description=public._repair_p0_text(short_description,chr(183)),
      long_description=public._repair_p0_text(long_description,chr(183)),
      highlights=(select coalesce(array_agg(public._repair_p0_text(x,chr(183))),array[]::text[]) from unnest(highlights) x),
      categories=(select coalesce(array_agg(public._repair_p0_text(x,chr(183))),array[]::text[]) from unnest(categories) x),
      itinerary_summary=public._repair_p0_text(itinerary_summary,chr(8594)),
      meeting_address=public._repair_p0_text(meeting_address,chr(183)),
      meeting_reference=public._repair_p0_text(meeting_reference,chr(183)),
      meeting_instructions=public._repair_p0_text(meeting_instructions,chr(183)),
      meeting_transport=public._repair_p0_text(meeting_transport,chr(183)),
      what_to_bring=(select coalesce(array_agg(public._repair_p0_text(x,chr(183))),array[]::text[]) from unnest(what_to_bring) x),
      cancellation_policy=public._repair_p0_text(cancellation_policy,chr(183)),
      private_notes=public._repair_p0_text(private_notes,chr(183)),
      translations=public._repair_p0_text(translations::text,chr(8594))::jsonb,
      schedule_notes=public._repair_p0_text(schedule_notes,chr(183)),
      updated_at=now()
    where route_id=rid;

    update public.route_stops set
      title=public._repair_p0_text(title,chr(183)),
      short_description=public._repair_p0_text(short_description,chr(183)),
      full_description=public._repair_p0_text(full_description,chr(183)),
      practical_info=public._repair_p0_text(practical_info,chr(183)),
      accessibility=public._repair_p0_text(accessibility,chr(183)),
      image_alt=public._repair_p0_text(image_alt,chr(183)),
      translations=public._repair_p0_text(translations::text,chr(183))::jsonb
    where route_id=rid;
  end loop;
end $$;

update public.site_design_settings
set published=jsonb_set(
      jsonb_set(published,'{content,es,routesTitle}',to_jsonb('Distintas rutas, nuevas maneras de mirar Barcelona.'::text),true),
      '{content,en,routesTitle}',to_jsonb('Different tours, new ways to see Barcelona.'::text),true),
    draft=case when draft is null then null else jsonb_set(
      jsonb_set(draft,'{content,es,routesTitle}',to_jsonb('Distintas rutas, nuevas maneras de mirar Barcelona.'::text),true),
      '{content,en,routesTitle}',to_jsonb('Different tours, new ways to see Barcelona.'::text),true) end,
    updated_at=now()
where id=true;

-- Complete stop summaries for the day tour. The public page only shows them when the full set is complete.
update public.route_stops s
set short_description=case s.sort_order
  when 0 then 'La obra de Gaud'||chr(237)||' se entiende mejor al situarla dentro del Eixample y de la ciudad que la rodea.'
  when 1 then 'La fachada presenta la naturaleza, la vida y el trabajo colectivo como un relato construido en piedra.'
  when 2 then 'El contraste de formas y esculturas convierte la Pasi'||chr(243)||'n en una lectura de tensi'||chr(243)||'n, muerte y transformaci'||chr(243)||'n.'
  when 3 then 'La fachada todav'||chr(237)||'a en desarrollo abre la pregunta por el futuro del templo y su relaci'||chr(243)||'n con Barcelona.'
end,
translations=jsonb_set(
  jsonb_set(coalesce(s.translations,'{}'::jsonb),'{en,title}',to_jsonb(case s.sort_order
    when 0 then 'Gaudi, the Eixample and the city'
    when 1 then 'Nativity Facade'
    when 2 then 'Passion Facade'
    when 3 then 'Glory, the future and the Barcelona to come' end::text),true),
  '{en,short_description}',to_jsonb(case s.sort_order
    when 0 then 'Gaudi''s work becomes clearer when placed within the Eixample and the city around it.'
    when 1 then 'The facade presents nature, life and collective work as a story built in stone.'
    when 2 then 'The contrast of forms and sculpture turns the Passion into a reading of tension, death and transformation.'
    when 3 then 'The facade still under development opens a question about the temple''s future and its relationship with Barcelona.' end::text),true)
where s.route_id=(select id from public.routes where slug='sagrada-familia') and s.sort_order between 0 and 3;

-- Complete the English stop summaries for the night tour.
update public.route_stops s
set translations=jsonb_set(
  jsonb_set(coalesce(s.translations,'{}'::jsonb),'{en,title}',to_jsonb(case s.sort_order
    when 0 then 'Placa de Gaudi'
    when 1 then 'Nativity Facade'
    when 2 then 'Apse area'
    when 3 then 'Passion Facade'
    when 4 then 'Glory Facade' end::text),true),
  '{en,short_description}',to_jsonb(case s.sort_order
    when 0 then 'The complex emerges from the darkness.'
    when 1 then 'Light selects the relief.'
    when 2 then 'Volume, stained glass and a living work.'
    when 3 then 'Scene, shadow and tension.'
    when 4 then 'Barcelona and the temple after dark.' end::text),true)
where s.route_id=(select id from public.routes where slug='sagrada-familia-nocturna') and s.sort_order between 0 and 4;

-- Consistent public presentation; every control remains editable in the route workbench.
update public.route_product_profiles
set page_settings=jsonb_set(
      jsonb_set(coalesce(page_settings,'{}'::jsonb),'{gallery_mode}','"grid"'::jsonb,true),
      '{show_long_description}','true'::jsonb,true),
    updated_at=now();

-- Retain the old tentative Cerda title without cluttering the active editor list or public site.
update public.routes set status='inactive',featured=false,updated_at=now()
where lower(title) like '%agobio%' and slug<>'cerda';

create or replace function public.set_route_archived(p_route_id uuid,p_archived boolean)
returns public.routes language plpgsql security definer set search_path=public as $$
declare v_result public.routes;
begin
  if not public.is_active_admin() then raise exception 'admin_access_required' using errcode='42501'; end if;
  update public.routes
  set status=case when p_archived then 'inactive'::public.route_status else 'draft'::public.route_status end,
      featured=case when p_archived then false else featured end,
      updated_at=now()
  where id=p_route_id returning * into v_result;
  if v_result.id is null then raise exception 'route_not_found' using errcode='P0002'; end if;
  insert into public.audit_log(admin_id,action,entity_type,entity_id,details)
  values(auth.uid(),case when p_archived then 'route_archived' else 'route_restored' end,'route',p_route_id::text,jsonb_build_object('archived',p_archived));
  return v_result;
end $$;
revoke all on function public.set_route_archived(uuid,boolean) from public,anon;
grant execute on function public.set_route_archived(uuid,boolean) to authenticated;

drop function public._repair_p0_text(text,text);