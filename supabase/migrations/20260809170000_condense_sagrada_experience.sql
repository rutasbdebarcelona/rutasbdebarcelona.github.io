-- Condense the public experience copy while preserving the full route arc.
update public.route_product_profiles p
set long_description = 'Esta ruta exterior recorre el perímetro de la Sagrada Família para entenderla como una obra viva, vinculada a su barrio y construida por varias generaciones. La lectura comienza con el origen del proyecto y la transformación radical que Gaudí introdujo en él. La luz diurna permite observar materiales, geometrías y relieves que suelen pasar inadvertidos. En la fachada del Nacimiento aparecen naturaleza, vida y continuidad; el ábside muestra la base heredada y su transformación. La fachada de la Pasión propone un lenguaje austero y dramático, marcado por Josep Maria Subirachs, cuyo contraste con el Nacimiento revela la unidad del programa más allá de un único estilo. El recorrido culmina ante la fachada de la Gloria, todavía en desarrollo, para abordar su simbolismo, su relación con la calle Mallorca y el papel de la ingeniería contemporánea. El cierre conecta a Gaudí, patrimonio, ciudad y futuro.',
    translations = jsonb_set(
      coalesce(p.translations,'{}'::jsonb),
      '{en,long_description}',
      to_jsonb('This outdoor route follows the perimeter of Sagrada Família to understand it as a living work, connected to its neighbourhood and shaped by several generations. It begins with the project’s origins and Gaudí’s radical transformation of it. Daylight reveals materials, geometry and reliefs that are easy to overlook. The Nativity façade speaks of nature, life and continuity; the apse shows the inherited foundation and its transformation. The Passion façade introduces an austere, dramatic language shaped by Josep Maria Subirachs. Its contrast with the Nativity façade shows how a shared programme can unite different styles. The route ends at the still-developing Glory façade, exploring its symbolism, its relationship with Carrer de Mallorca and the role of contemporary engineering. The conclusion connects Gaudí, heritage, city and future.'::text),
      true
    ),
    updated_at = now()
from public.routes r
where p.route_id=r.id and r.slug='sagrada-familia';