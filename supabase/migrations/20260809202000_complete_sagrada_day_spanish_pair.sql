-- Fill the two missing Spanish operational fields required by the bilingual guard.
-- Existing editorial content and every English translation are preserved.
do $$
declare
  v_route_id uuid;
  v_itinerary text := 'Plaça de Gaudí → Fachada del Nacimiento → Fachada de la Pasión → Fachada de la Gloria';
  v_schedule text := 'Lunes a viernes a las 18:00. Sábados y domingos a las 10:00, 12:00 y 18:00.';
begin
  select id into v_route_id from public.routes where slug='sagrada-familia';
  if v_route_id is null then return; end if;

  update public.route_product_profiles
  set itinerary_summary=coalesce(nullif(trim(itinerary_summary),''),v_itinerary),
      schedule_notes=coalesce(nullif(trim(schedule_notes),''),v_schedule),
      updated_at=now()
  where route_id=v_route_id;

  update public.route_drafts
  set content=jsonb_set(
        jsonb_set(
          content,
          '{product_profile,itinerary_summary}',
          to_jsonb(coalesce(nullif(trim(content#>>'{product_profile,itinerary_summary}'),''),v_itinerary)),
          true
        ),
        '{product_profile,schedule_notes}',
        to_jsonb(coalesce(nullif(trim(content#>>'{product_profile,schedule_notes}'),''),v_schedule)),
        true
      )||jsonb_build_object('bilingual_reviewed',false),
      updated_at=now()
  where route_id=v_route_id;
end $$;
