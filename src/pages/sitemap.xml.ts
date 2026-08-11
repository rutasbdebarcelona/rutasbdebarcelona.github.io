import type {APIRoute} from 'astro';
import {getPublicRoutes} from '../lib/public-routes';
import {getPublicSiteDesign,type PublicPageKey} from '../lib/site-settings';

export const GET:APIRoute=async({site})=>{
 const origin=(site||new URL('https://rutasbdebarcelona.github.io')).toString().replace(/\/$/,'');
 const design=await getPublicSiteDesign();
 const publicPages:Array<[string,PublicPageKey]>=[['rutas','routes'],['comparar','compare'],['sobre','guide'],['preguntas','faq'],['contacto','contact'],['reservar','booking'],['resenas','reviews'],['publicaciones','publications']];
 const fixed=['/','/en/','/privacidad/','/condiciones/','/en/privacidad/','/en/condiciones/',...publicPages.filter(([,key])=>design.pageVisibility[key]).flatMap(([path])=>[`/${path}/`,`/en/${path}/`])];
 const routes=await getPublicRoutes();
 const routePaths=design.pageVisibility.routes?routes.flatMap(route=>[`/rutas/${route.slug}/`,`/en/rutas/${route.slug}/`]):[];
 const paths=[...fixed,...routePaths];
 const body=`<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${[...new Set(paths)].map(path=>`  <url><loc>${origin}${path}</loc></url>`).join('\n')}\n</urlset>\n`;
 return new Response(body,{headers:{'Content-Type':'application/xml; charset=utf-8'}});
};