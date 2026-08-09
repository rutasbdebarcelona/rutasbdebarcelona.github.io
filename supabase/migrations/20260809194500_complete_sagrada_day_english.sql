-- Complete the English counterpart of the daytime Sagrada Familia product.
-- Spanish editorial content is intentionally left untouched.
do $$
declare
  v_route_id uuid;
  v_product_en jsonb;
  v_stop_en jsonb;
begin
  select id into v_route_id from public.routes where slug='sagrada-familia';
  if v_route_id is null then return; end if;

  v_product_en := jsonb_build_object(
    'short_description','Discover Sagrada Familia on a guided outdoor tour. Read its facades, Gaudi''s vision and the living work that still transforms Barcelona.',
    'long_description',E'Experience Sagrada Familia not as an isolated monument, but as a living work that has transformed its neighbourhood, crossed generations of architects and sculptors, and continues to engage with Barcelona. This outdoor daytime tour follows the perimeter of the basilica to understand the project before Gaudi, his gradual transformation of it into a radical proposal, and why its construction still requires interpretation, technology and contemporary decisions. Daylight reveals reliefs, materials, geometry and urban relationships that are often overlooked.\n\nThe experience begins with a general reading of the temple and its plan. The Nativity Facade then shows how nature, life and the continuity of Gaudi''s workshop become keys to observation. While moving between facades, the apse helps explain the inherited foundation of the project and Gaudi''s transformation of it, but it is not a separate stop.\n\nThe Passion Facade introduces an austere, dramatic language centred on the final days of Jesus and shaped by Josep Maria Subirachs. Its contrast with the Nativity Facade shows that the basilica''s unity lies not in repeating one style, but in sustaining a common programme through different languages.\n\nThe route ends at the still-developing Glory Facade, exploring its symbolism, its relationship with Carrer de Mallorca and the challenge of continuing a project conceived in another era. The conclusion connects Gaudi, heritage, engineering, city and future.',
    'itinerary_summary','Placa de Gaudi -> Nativity Facade -> Passion Facade -> Glory Facade',
    'schedule_notes','Monday to Friday at 18:00. Saturday and Sunday at 10:00, 12:00 and 18:00.',
    'meeting_instructions','Look for a guide carrying a Rutas B de Barcelona sign and a green umbrella.',
    'meeting_transport','Sagrada Familia metro station, lines L2 and L5',
    'highlights',jsonb_build_array(
      'Walk around the exterior perimeter of Sagrada Familia on a guided daytime tour.',
      'Understand the project before Gaudi and the progressive transformation of its architecture.',
      'Learn to read the symbolic and visual differences between the Nativity, Passion and Glory facades.',
      'Discover how artists, architects and engineers continue a work begun in the nineteenth century.',
      'Interpret the relationship between the basilica, its neighbourhood and Barcelona''s urban future.',
      'Enjoy a small group and a narrative designed to sharpen the way you see.'
    )
  );

  update public.route_product_profiles
  set translations=jsonb_set(
        coalesce(translations,'{}'::jsonb),
        '{en}',
        coalesce(translations->'en','{}'::jsonb)||v_product_en,
        true
      ),updated_at=now()
  where route_id=v_route_id;

  update public.route_stops s
  set translations=jsonb_set(
        coalesce(s.translations,'{}'::jsonb),
        '{en}',
        coalesce(s.translations->'en','{}'::jsonb)||
        case s.sort_order
          when 0 then jsonb_build_object(
            'title','Gaudi, the Eixample and the city',
            'short_description','Gaudi''s work becomes clearer when placed within the Eixample and the city around it.',
            'full_description','Place Gaudi''s work within the Eixample and the changing city around the basilica, connecting the temple with its urban setting and its long construction process.'
          )
          when 1 then jsonb_build_object(
            'title','Nativity Facade',
            'short_description','The facade presents nature, life and collective work as a story built in stone.',
            'full_description','Read the Nativity Facade through nature, life and collective craftsmanship. Its dense stone imagery reveals Gaudi''s symbolic language and the continuity of his workshop.'
          )
          when 2 then jsonb_build_object(
            'title','Passion Facade',
            'short_description','The contrast of forms and sculpture turns the Passion into a reading of tension, death and transformation.',
            'full_description','Contrast the austere geometry of the Passion Facade with the Nativity. Subirachs''s sculptures turn the final days of Jesus into a sequence of tension, death and transformation.'
          )
          when 3 then jsonb_build_object(
            'title','Glory, the future and the Barcelona to come',
            'short_description','The facade still under development opens a question about the temple''s future and its relationship with Barcelona.',
            'full_description','End at the still-developing Glory Facade to consider its symbolic programme, Carrer de Mallorca and the challenge of completing a historic project in contemporary Barcelona.'
          )
          else '{}'::jsonb
        end,
        true
      )
  where s.route_id=v_route_id;

  update public.route_drafts d
  set content=jsonb_set(
    jsonb_set(
      d.content,
      '{product_profile,translations,en}',
      coalesce(d.content#>'{product_profile,translations,en}','{}'::jsonb)||v_product_en,
      true
    ),
    '{stop_details}',
    coalesce((
      select jsonb_agg(
        item||jsonb_build_object(
          'translations',
          jsonb_set(
            coalesce(item->'translations','{}'::jsonb),
            '{en}',
            coalesce(item#>'{translations,en}','{}'::jsonb)||
            case ordinality
              when 1 then jsonb_build_object('title','Gaudi, the Eixample and the city','short_description','Gaudi''s work becomes clearer when placed within the Eixample and the city around it.','full_description','Place Gaudi''s work within the Eixample and the changing city around the basilica, connecting the temple with its urban setting and its long construction process.')
              when 2 then jsonb_build_object('title','Nativity Facade','short_description','The facade presents nature, life and collective work as a story built in stone.','full_description','Read the Nativity Facade through nature, life and collective craftsmanship. Its dense stone imagery reveals Gaudi''s symbolic language and the continuity of his workshop.')
              when 3 then jsonb_build_object('title','Passion Facade','short_description','The contrast of forms and sculpture turns the Passion into a reading of tension, death and transformation.','full_description','Contrast the austere geometry of the Passion Facade with the Nativity. Subirachs''s sculptures turn the final days of Jesus into a sequence of tension, death and transformation.')
              when 4 then jsonb_build_object('title','Glory, the future and the Barcelona to come','short_description','The facade still under development opens a question about the temple''s future and its relationship with Barcelona.','full_description','End at the still-developing Glory Facade to consider its symbolic programme, Carrer de Mallorca and the challenge of completing a historic project in contemporary Barcelona.')
              else '{}'::jsonb
            end,
            true
          )
        ) order by ordinality
      )
      from jsonb_array_elements(coalesce(d.content->'stop_details','[]'::jsonb)) with ordinality as x(item,ordinality)
    ),'[]'::jsonb),
    true
  )||jsonb_build_object('bilingual_reviewed',false),
  updated_at=now()
  where d.route_id=v_route_id;
end $$;
