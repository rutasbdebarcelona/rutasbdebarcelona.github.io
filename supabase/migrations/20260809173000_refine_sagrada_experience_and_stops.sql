-- Expand the public narrative to roughly 75% of its former length and correct the night itinerary.
update public.route_product_profiles p
set long_description = E'Contempla la Sagrada Família no como un monumento aislado, sino como una obra viva que ha transformado su barrio, atravesado generaciones de arquitectos y escultores y continúa dialogando con Barcelona. Esta ruta exterior diurna recorre el perímetro de la basílica para comprender cómo nació el proyecto antes de Gaudí, cómo el arquitecto lo convirtió gradualmente en una propuesta radical y por qué su construcción sigue exigiendo interpretación, tecnología y decisiones contemporáneas. La luz del día permite detenerse en relieves, materiales, geometrías y relaciones urbanas que suelen pasar inadvertidas.\n\nLa experiencia comienza con una lectura general del templo y su planta. Después, la fachada del Nacimiento muestra cómo naturaleza, vida y continuidad del taller de Gaudí se convierten en claves de observación; durante el desplazamiento, el ábside ayuda a reconocer la base heredada del proyecto y la transformación introducida sobre ella, sin constituir una parada independiente.\n\nEn la fachada de la Pasión aparece un lenguaje austero y dramático, organizado alrededor de los últimos días de Jesús y marcado por la intervención de Josep Maria Subirachs. El contraste con el Nacimiento revela que la unidad de la basílica no depende de repetir una estética, sino de sostener un programa común mediante lenguajes distintos.\n\nEl recorrido culmina ante la fachada de la Gloria, todavía en desarrollo. Allí se abordan su programa simbólico, su relación con la calle Mallorca y los desafíos de continuar hoy un proyecto concebido en otro tiempo. El cierre conecta a Gaudí, patrimonio, ingeniería, ciudad y futuro.',
    translations = jsonb_set(coalesce(p.translations,'{}'::jsonb),'{en,long_description}',to_jsonb(E'Experience Sagrada Família not as an isolated monument, but as a living work that has transformed its neighbourhood, crossed generations of architects and sculptors, and continues to engage with Barcelona. This outdoor daytime tour follows the perimeter of the basilica to understand the project before Gaudí, his gradual transformation of it into a radical proposal, and why its construction still requires interpretation, technology and contemporary decisions. Daylight reveals reliefs, materials, geometry and urban relationships that are often overlooked.\n\nThe experience begins with a general reading of the temple and its plan. The Nativity façade then shows how nature, life and the continuity of Gaudí’s workshop become keys to observation. While moving between façades, the apse helps explain the inherited foundation of the project and Gaudí’s transformation of it, but it is not a separate stop.\n\nThe Passion façade introduces an austere, dramatic language centred on the final days of Jesus and shaped by Josep Maria Subirachs. Its contrast with the Nativity façade shows that the basilica’s unity lies not in repeating one style, but in sustaining a common programme through different languages.\n\nThe route ends at the still-developing Glory façade, exploring its symbolism, its relationship with Carrer de Mallorca and the challenge of continuing a project conceived in another era. The conclusion connects Gaudí, heritage, engineering, city and future.'::text),true),
    updated_at=now()
from public.routes r
where p.route_id=r.id and r.slug='sagrada-familia';

-- The apse is contextual material along the walk, not a standalone stop.
delete from public.route_stops s
using public.routes r
where s.route_id=r.id and r.slug='sagrada-familia-nocturna' and lower(s.title)=lower('Zona del ábside');

update public.route_stops s
set sort_order=s.sort_order+100
from public.routes r
where s.route_id=r.id and r.slug='sagrada-familia-nocturna' and s.sort_order>2;

update public.route_stops s
set sort_order=s.sort_order-101
from public.routes r
where s.route_id=r.id and r.slug='sagrada-familia-nocturna' and s.sort_order>102;

-- Prevent an older unpublished draft from restoring the removed stop later.
update public.route_drafts d
set content=jsonb_set(
  d.content,
  '{stop_details}',
  coalesce((select jsonb_agg(item) from jsonb_array_elements(coalesce(d.content->'stop_details','[]'::jsonb)) item where lower(item->>'title')<>lower('Zona del ábside')),'[]'::jsonb),
  true
)
from public.routes r
where d.route_id=r.id and r.slug='sagrada-familia-nocturna' and d.content ? 'stop_details';
-- Restoring an intentionally hidden product means publishing it again.
create or replace function public.set_route_archived(p_route_id uuid,p_archived boolean)
returns public.routes language plpgsql security definer set search_path=public as $$
declare v_result public.routes;
begin
  if not public.is_active_admin() then raise exception 'admin_access_required' using errcode='42501'; end if;
  update public.routes
  set status=case when p_archived then 'inactive'::public.route_status else 'published'::public.route_status end,
      featured=case when p_archived then false else featured end,
      updated_at=now()
  where id=p_route_id returning * into v_result;
  if v_result.id is null then raise exception 'route_not_found' using errcode='P0002'; end if;
  insert into public.audit_log(admin_id,action,entity_type,entity_id,details)
  values(auth.uid(),case when p_archived then 'route_archived' else 'route_republished' end,'route',p_route_id::text,jsonb_build_object('archived',p_archived,'resulting_status',v_result.status));
  return v_result;
end $$;
revoke all on function public.set_route_archived(uuid,boolean) from public,anon;
grant execute on function public.set_route_archived(uuid,boolean) to authenticated;