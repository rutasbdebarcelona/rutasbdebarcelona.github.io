import type {APIRoute} from 'astro';
import {getPublicRoutes} from '../lib/public-routes';

export const GET:APIRoute=async({site})=>{
 const origin=(site||new URL('https://rutasbdebarcelona.github.io')).toString().replace(/\/$/,'');
 const fixed=['/','/rutas/','/comparar/','/sobre/','/preguntas/','/contacto/','/reservar/','/resenas/','/publicaciones/','/privacidad/','/condiciones/','/en/','/en/rutas/','/en/comparar/','/en/sobre/','/en/preguntas/','/en/contacto/','/en/reservar/','/en/resenas/','/en/publicaciones/','/en/privacidad/','/en/condiciones/'];
 const routes=await getPublicRoutes();
 const paths=[...fixed,...routes.flatMap(route=>[`/rutas/${route.slug}/`,`/en/rutas/${route.slug}/`])];
 const body=`<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${[...new Set(paths)].map(path=>`  <url><loc>${origin}${path}</loc></url>`).join('\n')}\n</urlset>\n`;
 return new Response(body,{headers:{'Content-Type':'application/xml; charset=utf-8'}});
};