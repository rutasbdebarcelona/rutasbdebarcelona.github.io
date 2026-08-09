-- Complete legacy bilingual pairs without replacing existing editorial content.
-- New drafts are also protected in the editor by merging missing published fields.
do $$
begin
  update public.route_product_profiles p
  set translations=coalesce(p.translations,'{}'::jsonb)||jsonb_build_object(
    'en',coalesce(p.translations->'en','{}'::jsonb)||jsonb_build_object('schedule_notes','Schedule pending.')
  ),updated_at=now()
  from public.routes r
  where p.route_id=r.id and r.slug='barcino'
    and coalesce(trim(p.schedule_notes),'')<>''
    and coalesce(trim(p.translations#>>'{en,schedule_notes}'),'')='';

  update public.route_product_profiles p
  set translations=coalesce(p.translations,'{}'::jsonb)||jsonb_build_object(
    'en',coalesce(p.translations->'en','{}'::jsonb)||jsonb_build_object(
      'itinerary_summary','Passeig de Gràcia / Consell de Cent → Bruc 49 → Torre de les Aigües Gardens',
      'schedule_notes','Schedule pending.'
    )
  ),updated_at=now()
  from public.routes r
  where p.route_id=r.id and r.slug='cerda';

  update public.route_product_profiles p
  set translations=coalesce(p.translations,'{}'::jsonb)||jsonb_build_object(
    'en',coalesce(p.translations->'en','{}'::jsonb)||jsonb_build_object(
      'itinerary_summary','Plaça de Gaudí → Nativity Façade → Passion Façade → Glory Façade'
    )
  ),updated_at=now()
  from public.routes r
  where p.route_id=r.id and r.slug='sagrada-familia-nocturna'
    and coalesce(trim(p.translations#>>'{en,itinerary_summary}'),'')='';

  update public.route_product_profiles p
  set translations=coalesce(p.translations,'{}'::jsonb)||jsonb_build_object(
    'en',coalesce(p.translations->'en','{}'::jsonb)||jsonb_build_object(
      'itinerary_summary','Plaça Nova → Bishop’s Gate → Plaça Sant Jaume → Jewish Quarter → Temple of Augustus → Plaça del Rei',
      'schedule_notes','Schedule pending.',
      'highlights',jsonb_build_array('The walls by night','The Jewish Quarter and squares after dark','Architecture and memory')
    )
  ),updated_at=now()
  from public.routes r
  where p.route_id=r.id and r.slug='barcino-nocturna';

  update public.route_stops s
  set translations=coalesce(s.translations,'{}'::jsonb)||jsonb_build_object(
    'en',coalesce(s.translations->'en','{}'::jsonb)||jsonb_build_object('full_description',v.description)
  )
  from public.routes r,
  (values
    (0,'The walls, towers and entrance layout introduce the scale and defensive logic of Barcino. This stop distinguishes ancient heritage, historical reconstruction and later urban identities.'),
    (1,'The gate reveals how the Roman enclosure was reinterpreted in medieval and modern Barcelona, combining surviving fabric, reconstruction and civic symbolism.'),
    (2,'The square connects the Roman forum with the institutions and ceremonies of the city that developed above it.'),
    (3,'Streets, names and urban gaps help reconstruct the experience of the medieval Jewish community without turning it into scenery.'),
    (4,'The temple connects religion, power and representation at the heart of the Roman city.'),
    (5,'The square shows how each period rests on the previous one and reorganises its meaning.')
  ) as v(sort_order,description)
  where s.route_id=r.id and r.slug='barcino' and s.sort_order=v.sort_order
    and coalesce(trim(s.translations#>>'{en,full_description}'),'')='';

  update public.route_stops s
  set translations=coalesce(s.translations,'{}'::jsonb)||jsonb_build_object(
    'en',coalesce(s.translations->'en','{}'::jsonb)||jsonb_build_object('full_description',v.description)
  )
  from public.routes r,
  (values
    (0,'Distance makes it possible to recognise the silhouette, lighting and relationship with the open space at night.'),
    (1,'Night lighting changes the hierarchy of shadows, reliefs and details across the Nativity Façade.'),
    (2,'The Passion Façade becomes a dramatic scene in which geometry and shadow intensify its narrative.'),
    (3,'The final stop connects the night-time experience with the future of the project and its everyday urban setting.')
  ) as v(sort_order,description)
  where s.route_id=r.id and r.slug='sagrada-familia-nocturna' and s.sort_order=v.sort_order
    and coalesce(trim(s.translations#>>'{en,full_description}'),'')='';

  update public.route_stops s
  set full_description=v.description
  from public.routes r,
  (values
    (0,'Sitúa la obra de Gaudí dentro del Eixample y de la ciudad que cambia alrededor de la basílica, relacionando el templo con su entorno urbano y con su prolongado proceso de construcción.'),
    (1,'Lee la Fachada del Nacimiento a través de la naturaleza, la vida y el trabajo colectivo. Su densidad de piedra permite reconocer el lenguaje simbólico de Gaudí y la continuidad de su taller.'),
    (2,'Contrasta la geometría austera de la Fachada de la Pasión con el Nacimiento. Las esculturas de Subirachs convierten los últimos días de Jesús en una secuencia de tensión, muerte y transformación.'),
    (3,'Cierra ante la Fachada de la Gloria, todavía en desarrollo, para comprender su programa simbólico, la relación con la calle Mallorca y el desafío de completar un proyecto histórico en la Barcelona contemporánea.')
  ) as v(sort_order,description)
  where s.route_id=r.id and r.slug='sagrada-familia' and s.sort_order=v.sort_order
    and coalesce(trim(s.full_description),'')='';

  update public.route_drafts set content=content||jsonb_build_object('bilingual_reviewed',false),updated_at=now()
  where route_id in (select id from public.routes where slug in ('barcino','cerda','sagrada-familia-nocturna','barcino-nocturna','sagrada-familia'));
end $$;