import { supabase } from './supabase';

export type SiteDesign = {
  colors: { forest:string; forest2:string; cream:string; paper:string; ink:string; clay:string; gold:string };
  fontPair: 'editorial'|'classic'|'modern';
  layout: 'editorial'|'compact'|'airy';
  logo: 'symbol-text'|'full'|'symbol';
  content: Record<'es'|'en', { homeKicker:string; homeTitle:string; homeAccent:string; homeLead:string; homeNote:string; contactTitle:string; contactIntro:string }>;
};

export const defaultSiteDesign: SiteDesign = {
  colors:{forest:'#16382f',forest2:'#0d2922',cream:'#fbf8f2',paper:'#f4efe6',ink:'#18231f',clay:'#b75f43',gold:'#c59b52'},
  fontPair:'editorial',layout:'editorial',logo:'symbol-text',
  content:{
    es:{homeKicker:'Rutas culturales en Barcelona',homeTitle:'Barcelona no solo se visita.',homeAccent:'Se aprende a mirar.',homeLead:'Recorridos con contexto, conversación y una mirada propia para entender lo que la ciudad todavía tiene delante de los ojos.',homeNote:'Historias conectadas con el lugar, no discursos repetidos frente a una postal.',contactTitle:'Hablemos de tu visita',contactIntro:'Para cualquier otra pregunta, puedes escribirnos al correo o contactarnos por teléfono.'},
    en:{homeKicker:'Cultural tours in Barcelona',homeTitle:'Barcelona is not only visited.',homeAccent:'You learn how to see it.',homeLead:'Tours with context, conversation and a distinctive point of view to understand what the city still holds in plain sight.',homeNote:'Stories connected to the place, rather than a repeated speech in front of a postcard.',contactTitle:'Let us talk about your visit',contactIntro:'For any further questions, write to our email address or contact us by phone.'}
  }
};

let cached: Promise<SiteDesign>|null=null;
export function getPublicSiteDesign(){
  if(!cached) cached=(async()=>{
    if(!supabase)return defaultSiteDesign;
    const {data,error}=await supabase.rpc('get_public_site_design');
    return error||!data?defaultSiteDesign:data as SiteDesign;
  })();
  return cached;
}

export const fontVariables=(pair:SiteDesign['fontPair'])=>pair==='modern'
  ? {sans:"'DM Sans',system-ui,sans-serif",serif:"'DM Sans',system-ui,sans-serif"}
  : pair==='classic'
    ? {sans:"Georgia,'Times New Roman',serif",serif:"Georgia,'Times New Roman',serif"}
    : {sans:"'DM Sans',system-ui,sans-serif",serif:"'Newsreader',Georgia,serif"};