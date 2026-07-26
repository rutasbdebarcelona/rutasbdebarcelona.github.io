# Editar la versión inglesa

La web inglesa se publica bajo `/en/` y comparte la misma lógica de reservas y Supabase que la versión española.

## Dónde editar

- Navegación, pie y etiquetas generales: `src/i18n/ui.ts`.
- Títulos, descripciones, paradas e información inglesa de las rutas: `src/i18n/routes.en.ts`.
- Portada y páginas inglesas: `src/pages/en/`.
- Formulario y mensajes compartidos de reserva: `src/scripts/booking-form.ts`.

## Regla de seguridad

No cambies los slugs de ruta (`sagrada-familia`, `barcino`, `cafeborn`) ni los valores de formularios. Esos códigos conectan ambos idiomas con las mismas reservas.

## Verificación

Después de editar, ejecutar `npm run build`. El resultado correcto debe indicar 0 errores y 0 advertencias.

## Pendiente conocido

El correo automático al cliente sigue usando la plantilla existente de Google Apps Script. La web y la confirmación en pantalla ya son bilingües; la plantilla de correo deberá recibir una variante inglesa en un lote posterior.
