-- Editorial quality pass: distinct voices, complete bilingual copy and clean UTF-8.
-- Keeps route status, bookings, availability and operational data unchanged.

do $$
declare
  v_day uuid;
  v_night uuid;
  v_barcino uuid;
  v_barcino_night uuid;
  v_cerda uuid;
  v_born uuid;
  v_cafeborn uuid;
begin
  select id into v_day from public.routes where slug='sagrada-familia';
  select id into v_night from public.routes where slug='sagrada-familia-nocturna';
  select id into v_barcino from public.routes where slug='barcino';
  select id into v_barcino_night from public.routes where slug='barcino-nocturna';
  select id into v_cerda from public.routes where slug='cerda';
  select id into v_born from public.routes where slug='vista-previa-born';
  select id into v_cafeborn from public.routes where slug='cafeborn';

  update public.routes set
    short_description='Cuando cae la noche, la basílica cambia de escala: la luz separa volúmenes, acentúa símbolos y transforma la relación entre el templo y la ciudad.',
    full_description='Una lectura exterior de la Sagrada Família cuando la iluminación y la oscuridad alteran su presencia urbana. El recorrido no repite la visita diurna: utiliza sombras, encuadres y contrastes para observar cómo las fachadas se vuelven escenas, cómo las torres ordenan el cielo y cómo el proyecto continúa dialogando con una ciudad que nunca se detiene.',
    promise='La noche no oculta la Sagrada Família: revela otra arquitectura.',
    eyebrow='Arquitectura · noche · percepción'
  where id=v_night;

  update public.route_product_profiles set
    short_description='Cuando cae la noche, la basílica cambia de escala: la luz separa volúmenes, acentúa símbolos y transforma su relación con Barcelona.',
    long_description='La Sagrada Família nocturna propone una experiencia distinta, no una repetición de la ruta diurna. Al desaparecer parte del ruido visual, la iluminación selecciona elementos, profundiza relieves y convierte cada fachada en una escena. Comenzamos en la Plaça de Gaudí para comprender la silueta completa y el modo en que las torres organizan el horizonte. Desde allí, la fachada del Nacimiento permite observar cómo la luz reconstruye una superficie poblada de vida. El recorrido continúa hacia la Pasión, donde la austeridad, las sombras y la tensión escultórica producen una lectura radicalmente diferente. Cerramos frente a la Gloria, relacionando el templo inacabado con la Barcelona contemporánea y con el tiempo largo de una obra que sigue transformándose. Es una caminata exterior para mirar con calma, reconocer contrastes y entender por qué la noche cambia la arquitectura que creíamos conocer.',
    highlights=array['La silueta del templo recortada sobre la ciudad','Nacimiento: relieve, luz y profundidad','Pasión: sombra, escena y tensión','Gloria y el proyecto todavía abierto','Una lectura nocturna independiente de la visita diurna'],
    itinerary_summary='Plaça de Gaudí · Fachada del Nacimiento · Fachada de la Pasión · Fachada de la Gloria',
    translations=jsonb_build_object('en',jsonb_build_object(
      'short_description','After dark, the basilica changes scale: light separates volumes, sharpens symbols and transforms its relationship with Barcelona.',
      'long_description','The night tour of the Sagrada Família is a distinct experience, not a repeat of the daytime route. As part of the visual noise disappears, lighting selects details, deepens reliefs and turns each façade into a scene. We begin in Plaça de Gaudí to understand the complete silhouette and the way the towers organise the skyline. The Nativity façade then reveals how light reconstructs a surface filled with life. At the Passion façade, austerity, shadow and sculptural tension create a radically different reading. We close at the Glory façade, connecting the unfinished church with contemporary Barcelona and with the long timescale of a project that is still changing. This outdoor walk invites you to slow down, recognise contrasts and discover why night alters an architecture you thought you knew.',
      'highlights',array['The basilica outlined against the city','Nativity: relief, light and depth','Passion: shadow, scene and tension','Glory and the unfinished project','A night reading independent from the daytime tour'],
      'itinerary_summary','Plaça de Gaudí · Nativity façade · Passion façade · Glory façade'))
  where route_id=v_night;

  update public.routes set
    title='Barcino medieval',
    short_description='Cruza dos mil años de ciudad leyendo murallas, plazas y calles como piezas de una Barcelona que ha cambiado sin borrar del todo sus capas.',
    full_description='Barcino medieval no presenta el Gòtic como un decorado. Sigue las huellas con las que Roma, la ciudad medieval y el poder contemporáneo han ocupado, reinterpretado y a veces reinventado el mismo espacio urbano.',
    promise='Las piedras no cuentan una sola historia: muestran quién pudo construir, ocupar y recordar la ciudad.',
    eyebrow='Roma · ciudad medieval · memoria urbana',
    primary_image_alt='Muralla y puerta histórica de Barcelona en Plaça Nova'
  where id=v_barcino;

  update public.route_product_profiles set
    short_description='Cruza dos mil años de ciudad leyendo murallas, plazas y calles como piezas de una Barcelona que cambió sin borrar del todo sus capas.',
    long_description='Barcino medieval propone entrar al Gòtic sin aceptar que todo lo antiguo pertenece al mismo momento. La ruta comienza en Plaça Nova, donde la puerta y la muralla permiten reconstruir los límites de la colonia romana y observar cómo la ciudad posterior se apoyó literalmente sobre ellos. En el Portal del Bisbe distinguimos patrimonio, recreación e imagen urbana; en Plaça Sant Jaume, la continuidad del centro político enlaza el foro con las instituciones actuales. El Call obliga a leer también ausencias, desplazamientos y memorias difíciles, mientras las columnas del Temple d’August devuelven escala al centro simbólico de Barcino. El cierre en Plaça del Rei reúne arquitectura, representación del poder y capas de relato. No buscamos una postal medieval: aprendemos a separar épocas, detectar operaciones de memoria y comprender por qué la Barcelona visible es el resultado de muchas ciudades superpuestas.',
    highlights=array['La puerta y la muralla de la colonia romana','El Gòtic entre patrimonio y construcción de imagen','La continuidad política de Plaça Sant Jaume','El Call: presencia, ausencia y memoria urbana','El Temple d’August y la escala de Barcino','Plaça del Rei como escenario de poder'],
    itinerary_summary='Plaça Nova · Portal del Bisbe · Plaça Sant Jaume · El Call · Temple d’August · Plaça del Rei',
    translations=jsonb_build_object('en',jsonb_build_object(
      'short_description','Cross two thousand years of urban history by reading walls, squares and streets as parts of a Barcelona that changed without fully erasing its layers.',
      'long_description','Medieval Barcino enters the Gothic Quarter without pretending that everything old belongs to the same period. At Plaça Nova, the gate and Roman wall reconstruct the limits of the colony and show how later Barcelona was built directly upon them. The Bishop’s Gate helps us distinguish heritage from historical recreation and urban image-making. Plaça Sant Jaume links the Roman forum with the city’s continuing political centre. The Jewish Quarter asks us to read absences, displacement and difficult memory, while the columns of the Temple of Augustus restore the scale of Barcino’s symbolic heart. Plaça del Rei brings architecture, power and historical narrative together. This is not a medieval postcard: it is a method for separating periods, detecting acts of memory and understanding the many cities contained in the Barcelona we see today.',
      'highlights',array['The gate and wall of the Roman colony','The Gothic Quarter between heritage and image-making','The political continuity of Plaça Sant Jaume','The Jewish Quarter: presence, absence and urban memory','The Temple of Augustus and the scale of Barcino','Plaça del Rei as a stage for power'],
      'itinerary_summary','Plaça Nova · Bishop’s Gate · Plaça Sant Jaume · Jewish Quarter · Temple of Augustus · Plaça del Rei'))
  where route_id=v_barcino;

  update public.routes set
    title='Barcino medieval · Nocturna',
    short_description='Cuando baja el ruido del centro, la antigua Barcelona aparece en umbrales, silencios y cambios de escala que de día suelen pasar inadvertidos.',
    full_description='Una lectura nocturna de la ciudad romana y medieval centrada en la percepción: qué ilumina la ciudad, qué deja en sombra y cómo cambian las huellas históricas cuando las calles recuperan profundidad.',
    promise='La oscuridad no añade misterio: permite distinguir mejor las huellas.',
    eyebrow='Roma · noche · percepción urbana'
  where id=v_barcino_night;

  update public.route_product_profiles set
    short_description='Cuando baja el ruido del centro, la antigua Barcelona aparece en umbrales, silencios y cambios de escala que de día pasan inadvertidos.',
    long_description='Barcino medieval · Nocturna utiliza la ciudad después de oscurecer como una herramienta de lectura. En Plaça Nova, la iluminación recorta la antigua frontera urbana y devuelve escala a las torres. El Portal del Bisbe se convierte en una escena donde conviven historia material, recreación y deseo de ciudad medieval. Plaça Sant Jaume, más despejada, permite observar con precisión la arquitectura del poder; las calles del Call recuperan profundidad y hacen visibles tanto sus trazas como sus ausencias. Cerca del Temple d’August, el espacio cerrado concentra la relación entre religión, representación y centro urbano. La llegada a Plaça del Rei muestra cómo la luz selecciona volúmenes y organiza una memoria pública. No buscamos leyendas fáciles ni una atmósfera artificial: usamos la noche para mirar con más atención una ciudad construida sobre sus propias huellas.',
    highlights=array['La muralla como límite iluminado','Umbrales y construcción del imaginario gótico','La arquitectura del poder con la plaza en calma','El Call y la memoria de sus ausencias','La noche como herramienta de observación urbana'],
    itinerary_summary='Plaça Nova · Portal del Bisbe · Plaça Sant Jaume · El Call · Temple d’August · Plaça del Rei',
    translations=jsonb_build_object('en',jsonb_build_object(
      'short_description','As the city centre grows quieter, ancient Barcelona emerges through thresholds, silences and shifts of scale that often go unnoticed by day.',
      'long_description','Medieval Barcino at Night uses the city after dark as a tool for observation. At Plaça Nova, lighting outlines the ancient boundary and restores scale to the towers. The Bishop’s Gate becomes a scene where material history, recreation and the desire for a medieval city coexist. A quieter Plaça Sant Jaume reveals the architecture of power, while the streets of the Jewish Quarter regain depth and make both traces and absences visible. Near the Temple of Augustus, the enclosed space focuses the relationship between religion, representation and the urban centre. Plaça del Rei shows how light selects volumes and organises public memory. Rather than relying on easy legends or artificial mystery, the route uses night to look more carefully at a city built upon its own traces.',
      'highlights',array['The Roman wall as an illuminated boundary','Thresholds and the making of the Gothic image','The architecture of power in a quieter square','The Jewish Quarter and the memory of absence','Night as a tool for urban observation'],
      'itinerary_summary','Plaça Nova · Bishop’s Gate · Plaça Sant Jaume · Jewish Quarter · Temple of Augustus · Plaça del Rei'))
  where route_id=v_barcino_night;

  update public.routes set
    title='Cerdà: la ciudad de 113 metros',
    short_description='La cuadrícula deja de ser fondo: chaflanes, manzanas e interiores revelan el proyecto urbano que todavía organiza la vida cotidiana del Eixample.',
    full_description='Una caminata para convertir la forma urbana en una herramienta de lectura: del plan de Cerdà a la ciudad realmente construida, habitada y transformada.',
    promise='Aprender a mirar el Eixample es descubrir que una calle también es una decisión social.',
    eyebrow='Urbanismo · Eixample · vida cotidiana',
    primary_image_alt='Vista aérea de la trama urbana del Eixample de Barcelona'
  where id=v_cerda;

  update public.route_product_profiles set
    short_description='La cuadrícula deja de ser fondo: chaflanes, manzanas e interiores revelan el proyecto que todavía organiza la vida cotidiana del Eixample.',
    long_description='Cerdà: la ciudad de 113 metros convierte el Eixample en un documento que se puede recorrer. En lugar de contemplar la cuadrícula desde arriba, la medimos con el cuerpo: la anchura de las calles, el giro de los chaflanes, la continuidad de las fachadas y el ritmo de cada cruce muestran que la forma urbana organiza movilidad, luz, comercio y encuentros. El inicio en Passeig de Gràcia y Consell de Cent sitúa el plan como una respuesta técnica y política a la expansión de Barcelona. En Carrer del Bruc observamos cómo una regla común admite diferencias arquitectónicas y usos cambiantes. El interior de manzana de los Jardins de la Torre de les Aigües permite comparar la aspiración higienista con la ciudad que finalmente se construyó y transformó. La ruta no celebra una cuadrícula perfecta: analiza la distancia productiva entre proyecto, intereses, modificaciones y vida cotidiana.',
    highlights=array['La manzana de 113 metros como unidad urbana','El chaflán: visibilidad, giro y encuentro','Una regla común capaz de producir diferencias','El interior de manzana y la aspiración higienista','La distancia entre el plan y la ciudad construida'],
    itinerary_summary='Passeig de Gràcia / Consell de Cent · Carrer del Bruc, 49 · Jardins de la Torre de les Aigües',
    translations=jsonb_build_object('en',jsonb_build_object(
      'short_description','The grid stops being a background: chamfers, blocks and interiors reveal the urban project that still organises everyday life in the Eixample.',
      'long_description','Cerdà: the 113-metre City turns the Eixample into a document you can walk through. Instead of viewing the grid from above, we measure it with the body: street width, chamfered corners, continuous façades and the rhythm of each crossing show how urban form organises movement, light, commerce and encounters. Passeig de Gràcia and Consell de Cent introduce the plan as both a technical and political response to Barcelona’s expansion. Carrer del Bruc shows how a common rule can accommodate architectural difference and changing uses. Inside the block at the Torre de les Aigües Gardens, we compare the hygienist ambition with the city that was ultimately built and transformed. The route does not celebrate a perfect grid; it studies the productive distance between a plan, competing interests, later changes and everyday urban life.',
      'highlights',array['The 113-metre block as an urban unit','The chamfer: visibility, turning and encounter','A common rule that can produce difference','The block interior and the hygienist ambition','The distance between the plan and the built city'],
      'itinerary_summary','Passeig de Gràcia / Consell de Cent · 49 Carrer del Bruc · Torre de les Aigües Gardens'))
  where route_id=v_cerda;

  update public.routes set
    short_description='Entre Santa Caterina y el Palau, el barrio explica cómo mercados, pasajes, cultura y vida cotidiana producen una centralidad distinta de la postal monumental.',
    full_description='Una vista previa construida desde investigación propia para leer Sant Pere y su entorno cultural antes de entrar al Palau de la Música.',
    promise='Antes del monumento está el barrio que lo hizo posible.',
    eyebrow='Cultura · barrio · arquitectura viva',
    primary_image_alt='Entorno urbano de Sant Pere, Santa Caterina y la Ribera'
  where id=v_born;

  update public.route_product_profiles set
    short_description='Entre Santa Caterina y el Palau, mercados, pasajes, cultura y vida cotidiana producen una centralidad distinta de la postal monumental.',
    long_description='Vista Previa Born: Palau y Sant Pere comienza antes del monumento. El Mercat de Santa Caterina abre una lectura sobre renovación urbana, comercio y continuidad barrial; las calles y pasajes de Sant Pere muestran una ciudad cultural que se desarrolla fuera de los grandes ejes turísticos. En Antic Teatre, patrimonio construido, creación independiente y usos cotidianos comparten un mismo espacio. La llegada al Palau de la Música permite comprender su fachada no como un objeto aislado, sino como una escena pública vinculada a la historia cultural y asociativa del barrio. El cierre en Café Palau devuelve la arquitectura a la experiencia diaria. La ruta está en preparación y permanece abierta a depuración editorial y operativa, pero su propuesta ya es clara: comprender cómo una institución cultural se inserta en un tejido de mercados, viviendas, talleres, pasajes y públicos diversos.',
    highlights=array['Santa Caterina: mercado, renovación y continuidad','Sant Pere y una cultura fuera de los grandes ejes','Antic Teatre: patrimonio y creación independiente','El Palau de la Música como escena pública','Café Palau y la vuelta a la vida cotidiana'],
    itinerary_summary='Mercat de Santa Caterina · Sant Pere y sus pasajes · Antic Teatre · Palau de la Música · Café Palau',
    translations=jsonb_build_object('en',jsonb_build_object(
      'short_description','Between Santa Caterina and the Palau, markets, passages, culture and daily life create a centre unlike the monumental postcard.',
      'long_description','Born Preview: Palau and Sant Pere begins before the monument. Santa Caterina Market opens a reading of urban renewal, commerce and neighbourhood continuity. The streets and passages of Sant Pere reveal a cultural city that develops beyond the main tourist axes. At Antic Teatre, built heritage, independent creation and everyday use share the same space. Reaching the Palau de la Música allows us to understand its façade not as an isolated object but as a public scene connected to the cultural and associative history of the neighbourhood. Café Palau returns architecture to daily experience. The route is still in preparation and open to editorial and operational refinement, but its proposition is already clear: to understand how a cultural institution sits within a fabric of markets, homes, workshops, passages and diverse publics.',
      'highlights',array['Santa Caterina: market, renewal and continuity','Sant Pere and culture beyond the main axes','Antic Teatre: heritage and independent creation','The Palau de la Música as a public scene','Café Palau and the return to daily life'],
      'itinerary_summary','Santa Caterina Market · Sant Pere and its passages · Antic Teatre · Palau de la Música · Café Palau'))
  where route_id=v_born;

  update public.route_product_profiles set
    short_description=coalesce(nullif(short_description,''),'Un laboratorio editorial sobre cafés, cultura y vida cotidiana en el Born.'),
    long_description=coalesce(nullif(long_description,''),'CaféBorn permanece como producto archivado y editable: un espacio para depurar una investigación propia sobre cafés, sociabilidad, patrimonio y transformación urbana antes de decidir su futura forma pública.'),
    translations=jsonb_set(coalesce(translations,'{}'::jsonb),'{en}',coalesce(translations->'en','{}'::jsonb) || jsonb_build_object('short_description','An editorial laboratory on cafés, culture and everyday life in the Born.','long_description','CaféBorn remains archived and editable: a space to refine original research on cafés, sociability, heritage and urban change before deciding its future public form.'),true)
  where route_id=v_cafeborn;

  -- Repair inherited mojibake and complete Barcino stop copy in both languages.
  update public.route_stops s set
    title=x.title,
    short_description=x.short_es,
    full_description=x.full_es,
    translations=jsonb_build_object('en',jsonb_build_object('title',x.title_en,'short_description',x.short_en,'full_description',x.full_en))
  from (values
    (v_barcino,0,'Plaça Nova y la puerta de Barcino','La muralla permite reconocer el límite de la colonia romana dentro de la ciudad actual.','Torres, puerta y trazado introducen la escala defensiva de Barcino y la forma en que Barcelona creció apoyándose sobre sus límites.','Plaça Nova and the gate of Barcino','The wall reveals the boundary of the Roman colony within the present city.','Towers, gate and street line introduce the defensive scale of Barcino and the way later Barcelona grew upon its boundaries.'),
    (v_barcino,1,'Portal del Bisbe','La imagen medieval del Gòtic convive aquí con estructuras y relatos de épocas distintas.','La parada distingue patrimonio antiguo, recreación histórica e identidad urbana construida para comprender por qué el Gòtic también es una imagen moderna.','Bishop’s Gate','The medieval image of the Gothic Quarter coexists with structures and stories from different periods.','This stop distinguishes ancient heritage, historical recreation and constructed urban identity, revealing why the Gothic Quarter is also a modern image.'),
    (v_barcino,2,'Plaça Sant Jaume','El centro político actual conserva una continuidad urbana que atraviesa siglos.','La plaza enlaza el foro romano con instituciones, ceremonias y disputas posteriores por el centro simbólico de Barcelona.','Plaça Sant Jaume','Today’s political centre preserves an urban continuity spanning centuries.','The square connects the Roman forum with later institutions, ceremonies and disputes over Barcelona’s symbolic centre.'),
    (v_barcino,3,'El Call','La trama estrecha conserva huellas de convivencia, segregación y transformación social.','Calles, nombres y vacíos permiten reconstruir la presencia de la comunidad judía medieval sin reducir su historia a un decorado pintoresco.','The Jewish Quarter','The narrow urban fabric preserves traces of coexistence, segregation and social change.','Streets, names and absences help reconstruct the presence of the medieval Jewish community without reducing its history to picturesque scenery.'),
    (v_barcino,4,'Temple d’August','Las columnas conservadas devuelven la escala simbólica del foro de Barcino.','El templo relaciona religión, poder y representación en el corazón de la colonia romana y obliga a imaginar una arquitectura hoy contenida dentro de otra.','Temple of Augustus','The surviving columns restore the symbolic scale of Barcino’s forum.','The temple connects religion, power and representation at the heart of the Roman colony and asks us to imagine an architecture now contained inside another.'),
    (v_barcino,5,'Plaça del Rei','El cierre reúne poder, arquitectura y memoria en uno de los conjuntos más densos del Gòtic.','La plaza permite observar cómo cada época se apoya en la anterior, selecciona lo que conserva y reorganiza su significado público.','Plaça del Rei','The final stop brings power, architecture and memory together in one of the Gothic Quarter’s densest ensembles.','The square shows how each period builds upon the previous one, selects what to preserve and reorganises its public meaning.')
  ) as x(route_id,sort_order,title,short_es,full_es,title_en,short_en,full_en)
  where s.route_id=x.route_id and s.sort_order=x.sort_order;

  -- Register static galleries without changing hero images or route visibility.
  insert into public.route_media(route_id,kind,role,storage_path,title,alt_text,mime_type,file_size_bytes,status,sort_order)
  select * from (values
    (v_barcino,'image','gallery','/images/routes/barcino/placa-nova.webp',null,'Muralla y Portal del Bisbe en Plaça Nova','image/webp',1::bigint,'published',0),
    (v_barcino,'image','gallery','/images/routes/barcino/placa-sant-jaume.webp',null,'Plaça Sant Jaume en el centro histórico de Barcelona','image/webp',1::bigint,'published',1),
    (v_barcino,'image','gallery','/images/routes/barcino/temple-august.webp',null,'Columnas del Temple d’August de Barcelona','image/webp',1::bigint,'published',2),
    (v_barcino,'image','gallery','/images/routes/barcino/placa-del-rei.webp',null,'Conjunto histórico de Plaça del Rei','image/webp',1::bigint,'published',3),
    (v_cerda,'image','gallery','/images/routes/cerda/eixample-aeri.webp',null,'Vista aérea de la cuadrícula del Eixample','image/webp',1::bigint,'published',0),
    (v_cerda,'image','gallery','/images/routes/cerda/eixample-xamfrans.webp',null,'Manzanas y chaflanes del Eixample de Barcelona','image/webp',1::bigint,'published',1),
    (v_cerda,'image','gallery','/images/routes/cerda/jardins-torre-aigues.webp',null,'Interior de manzana en los Jardins de la Torre de les Aigües','image/webp',1::bigint,'published',2),
    (v_cerda,'image','gallery','/images/routes/cerda/placa-cerda.webp',null,'Placa urbana dedicada a Ildefons Cerdà','image/webp',1::bigint,'published',3)
  ) as m(route_id,kind,role,storage_path,title,alt_text,mime_type,file_size_bytes,status,sort_order)
  where m.route_id is not null
  on conflict (storage_path) do update set route_id=excluded.route_id,alt_text=excluded.alt_text,status='published',sort_order=excluded.sort_order;
end $$;
