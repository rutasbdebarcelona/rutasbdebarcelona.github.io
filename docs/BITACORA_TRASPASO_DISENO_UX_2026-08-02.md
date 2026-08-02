# Rutas B de Barcelona — bitácora funcional para diseño y UX

**Fecha de corte:** 2 de agosto de 2026  
**Estado:** producto mínimo funcional publicado; comienza la etapa de consolidación visual, editorial y UX.  
**Web pública:** https://rutasbdebarcelona.github.io/  
**Repositorio:** https://github.com/rutasbdebarcelona/rutasbdebarcelona.github.io

## 1. Qué es el proyecto

Rutas B es una web comercial para presentar y reservar rutas culturales en Barcelona. Su propuesta no es mostrar una lista genérica de monumentos, sino ofrecer recorridos con contexto, conversación y una mirada de autor.

La primera ruta operativa es **De Gaudí a la Sagrada Familia**. El catálogo también contempla **Barcino** y **CafèBorn**, todavía en preparación. El producto debe poder crecer con nuevas rutas, materiales e idiomas sin rehacer la web.

## 2. Objetivo de producto y de marca

La web debe transmitir:

- autoría y criterio cultural, no apariencia de plantilla o “web hecha por IA”;
- confianza suficiente para reservar;
- claridad y calidez, sin lenguaje grandilocuente;
- una experiencia cuidada en celular y escritorio;
- identidad reconocible mediante logo, fotografía, tipografía, color y ritmo editorial;
- coherencia completa entre castellano e inglés;
- autonomía para que Daniel edite contenidos habituales sin tocar código.

La dirección visual actual es **editorial contemporánea**: verde bosque, crema, arcilla y dorado; titulares con serif y textos funcionales con sans serif. Es una base, no un sistema cerrado.

## 3. Estado real: qué ya funciona

### Web pública

- Portada, catálogo, fichas de ruta, página del guía, preguntas, contacto, comparación, reserva, confirmación y páginas legales provisionales.
- Versión castellana en `/` y versión inglesa en `/en/`.
- Selector ES/EN y navegación móvil.
- Logo oficial e imágenes principales integradas.
- Diseño adaptable a celular y escritorio.
- Folletos, documentos, audios, mapas o imágenes pueden vincularse a una ruta.
- Los documentos se abren en una pestaña nueva.

### Reservas y disponibilidad

- Formulario conectado a Supabase.
- La ruta de Sagrada Família aparece por defecto en la reserva.
- Aforo máximo operativo: **15 personas por franja**.
- Horarios: **10:00 y 12:00 solo fines de semana; 18:00 y 22:00 todos los días**.
- La disponibilidad descuenta las plazas reservadas y bloquea franjas privadas o de partners.
- Al público no se le muestra el aforo total: ve disponibilidad y avisos cuando quedan pocas plazas.
- La confirmación muestra referencia, ruta, fecha, horario y punto de encuentro.
- La fecha de creación de cada reserva queda almacenada y visible en el panel.

### Correos

- Aviso administrativo de nueva reserva mediante Resend.
- Confirmación al cliente mediante Google Apps Script y Gmail.
- Existe una plantilla bilingüe ES/EN con logo en `integrations/google-apps-script/confirmaciones-bilingues.gs`.
- **Control pendiente:** comprobar que esa versión exacta esté implementada como versión activa en Google Apps Script; guardar el código no basta, hay que crear una nueva implementación.

### Panel privado

- Acceso administrativo y recuperación de contraseña.
- Resumen operativo.
- Reservas: listado, búsqueda, filtros, ficha, estados, notas internas, historial y exportación CSV.
- Disponibilidad: calendario por ruta, ocupación, plazas restantes, bloqueos e histórico desde la primera reserva.
- Mensajes: formulario público conectado y bandeja interna.
- Rutas: edición completa, borradores, publicación, duplicación, historial y reversión.
- Edición inglesa dentro del mismo editor de ruta.
- Multimedia: imagen principal, galería/mapa y adjuntos.
- Diseño: colores, combinación tipográfica, densidad de layout, variante de logo y textos principales ES/EN.
- Reseñas: módulo desacoplado, todavía no operativo ni publicado.

## 4. Arquitectura resumida

| Capa | Tecnología | Función |
|---|---|---|
| Interfaz | Astro 5 + TypeScript | Páginas estáticas, componentes y formularios |
| Datos y autenticación | Supabase | Rutas, reservas, disponibilidad, mensajes, usuarios, Storage y RLS |
| Publicación | GitHub Actions + GitHub Pages | Compilación y despliegue de la web |
| Correo administrativo | Resend | Aviso de nueva reserva |
| Correo al cliente | Gmail + Google Apps Script | Confirmación bilingüe desde la cuenta de Rutas B |

Los cambios editoriales se guardan primero como **borrador** y luego se publican. Publicar actualiza Supabase y dispara una reconstrucción de GitHub Pages; puede tardar algunos minutos.

## 5. Qué puede cambiar el diseñador sin programar

Desde **Administración → Diseño**:

- colores principales;
- tres pares tipográficos preconfigurados;
- tres densidades de layout;
- variante de logo;
- textos principales de portada y contacto en castellano e inglés.

Desde **Administración → Rutas**:

- títulos, textos, duración, zona, formato, puntos de inicio y fin;
- idiomas, público, accesibilidad, incluidos y no incluidos;
- precio individual y de grupo;
- paradas;
- contenido inglés equivalente;
- orden y ruta destacada;
- fotografía principal, galería, mapas, folletos, documentos y audio.

## 6. Qué todavía requiere código

- cambiar la composición estructural de las páginas;
- crear nuevos tipos de bloques o componentes;
- ajustar escala tipográfica más allá de las tres parejas disponibles;
- modificar comportamiento del menú, formularios o calendario;
- crear un editor visual de disposición tipo constructor de páginas;
- añadir un idioma nuevo completo, como catalán;
- cambiar reglas de reservas, capacidad o disponibilidad;
- integrar mapas interactivos, analítica, SEO avanzado o un dominio propio.

La forma de trabajo recomendada es: **el diseñador define en Figma o mediante especificaciones claras; Codex implementa en componentes reutilizables; ambos revisan móvil y escritorio antes de publicar**.

## 7. Problemas y deudas conocidas

1. El panel aún muestra algunos errores técnicos en bruto. Por ejemplo, `route_draft_required` solo significa “no existe un borrador pendiente para publicar”. Debe convertirse en lenguaje humano y desactivar acciones imposibles.
2. El editor de diseño es seguro, pero no es todavía un constructor visual libre.
3. La sincronización ES/EN funciona dentro del editor, pero toda publicación debe verificarse en ambos idiomas.
4. Los correos bilingües deben probarse de extremo a extremo después de cada nueva implementación de Apps Script.
5. Las páginas legales siguen siendo provisionales.
6. El módulo de reseñas está desactivado hasta disponer de un flujo real y consentimiento.
7. Debe decidirse si “Comparar” aporta valor real; si no, conviene retirarlo de navegación.
8. Falta una auditoría final de accesibilidad, contraste, foco de teclado, tamaños táctiles y rendimiento de imágenes.
9. La identidad necesita reglas de uso del logo y variantes preparadas, no solo archivos sueltos.

## 8. Principios que no deben romperse

- No cambiar los slugs `sagrada-familia`, `barcino` y `cafeborn`: conectan idiomas, reservas y base de datos.
- No exponer `.env`, claves privadas, service role, tokens ni respaldos.
- No modificar datos remotos directamente cuando existe un flujo administrativo o una migración.
- No borrar reservas de prueba o reales para “limpiar” la interfaz.
- No publicar una versión inglesa incompleta o con tipografía distinta.
- No usar el logo deformado, recortado o con proporciones arbitrarias.
- Cada cambio debe revisarse primero en **Android vertical** y **PC**; luego tablet y celular horizontal.
- Compilar con `npm run build`: el cierre correcto es **0 errores y 0 advertencias**.

## 9. Norte de diseño: punto de cierre

La etapa de diseño se considerará cerrada cuando exista:

1. **Sistema visual definido:** logo, paleta, tipografías, escala, espaciado, botones, formularios, iconografía y fotografía.
2. **Cinco plantillas coherentes:** portada, catálogo, ficha de ruta, reserva/confirmación y página informativa.
3. **Versión móvil resuelta:** cabecera compacta, idioma visible, reserva accesible, menú no invasivo y títulos sin cortes.
4. **Contenido bilingüe equivalente:** misma jerarquía, tono y tipografía en ES/EN.
5. **Panel utilizable:** acciones claras, estados visibles, errores humanos y vista previa fiable.
6. **Prueba completa:** descubrir ruta → revisar disponibilidad → reservar → recibir correos → ver reserva y ocupación en el panel.

Ese es el cierre concreto: una web con identidad de autor, operable por Daniel y lista para recibir público sin asistencia técnica cotidiana.

## 10. Ruta de trabajo recomendada

### Fase A — sesión con el diseñador

- Recorrer la web real en celular y PC.
- Identificar tres fortalezas que se conservan y cinco fricciones prioritarias.
- Definir personalidad visual en tres palabras y reunir 3–5 referencias pertinentes.
- Elegir tratamiento del logo, pareja tipográfica y criterio fotográfico.
- Dibujar el sistema común de cabecera, hero, secciones, tarjetas y pie.

**Salida:** una dirección visual aprobada, no varias alternativas abiertas.

### Fase B — diseño del sistema

- Crear tokens de color, tipografía y espaciado.
- Diseñar componentes y estados: normal, hover, foco, error, vacío, cargando y publicado.
- Resolver primero Android vertical y PC.

**Salida:** mini design system y componentes reutilizables.

### Fase C — cinco pantallas clave

1. Portada.
2. Catálogo.
3. Ficha de Sagrada Família.
4. Reserva y confirmación.
5. Panel: rutas, disponibilidad y reservas.

**Salida:** prototipo navegable o especificaciones medibles.

### Fase D — implementación por lotes

- Lote 1: cabecera, navegación, tipografía y sistema general.
- Lote 2: portada y catálogo.
- Lote 3: ficha de ruta y multimedia.
- Lote 4: reserva, confirmación y correos.
- Lote 5: panel interno y mensajes de error.

Cada lote termina con revisión ES/EN, móvil/PC, compilación y publicación.

### Fase E — cierre comercial

- Revisión legal y de privacidad.
- Prueba real de reservas y correos.
- Accesibilidad y rendimiento.
- Metadatos, favicon, previews sociales y analítica mínima.
- Decidir dominio propio cuando exista presupuesto; GitHub Pages puede seguir operando mientras tanto.

## 11. Agenda sugerida para la reunión de hoy

1. **10 min:** explicar propuesta y usuario objetivo.
2. **15 min:** revisar portada y flujo de reserva en celular.
3. **15 min:** revisar ficha de ruta y sistema editorial.
4. **15 min:** acordar dirección visual única.
5. **15 min:** definir entregable del diseñador: Figma, guía visual o ambos.
6. **10 min:** priorizar el primer lote implementable.

## 12. Archivos y lugares clave

- Configuración modular: `src/config/site.ts`
- Sistema visual y estilos: `src/styles/global.css`
- Configuración editable de diseño: `src/lib/site-settings.ts`
- Cabecera y navegación: `src/components/Header.astro`
- Panel privado: `src/components/AdminApp.astro` y `src/scripts/admin-app.ts`
- Páginas castellanas: `src/pages/`
- Páginas inglesas: `src/pages/en/`
- Datos públicos de rutas: `src/lib/public-routes.ts`
- Plantilla de correo: `integrations/google-apps-script/confirmaciones-bilingues.gs`
- Migraciones: `supabase/migrations/`
- Imágenes de marca: `public/images/marca/`
- Imágenes y materiales dinámicos: Supabase Storage, administrados desde el panel.

## 13. Definición del próximo paso

El próximo paso no es añadir funciones aisladas. Es **cerrar el sistema visual y las cinco plantillas clave**, empezando por portada, ficha de ruta y reserva en móvil. Con esa base aprobada, el resto de las páginas se adapta al mismo lenguaje y el panel se pule sin volver a rediseñar cada pantalla por separado.
