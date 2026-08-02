import { supabase } from './supabase';

export type HomeImageSettings = {
  url:string; altEs:string; altEn:string;
  desktopFit:'cover'|'contain'; mobileFit:'cover'|'contain';
  desktopX:number; desktopY:number; mobileX:number; mobileY:number;
  desktopZoom:number; mobileZoom:number;
  desktopRatio:'3/2'|'16/9'|'4/3'; mobileRatio:'3/2'|'4/3'|'1/1';
};
export type HomeSectionKey='routes'|'method'|'partner';
export type HomeLocaleContent = {
  homeKicker:string; homeTitle:string; homeAccent:string; homeLead:string; homeNote:string;
  heroRoutesLabel:string; heroGuideLabel:string; heroBookLabel:string; trustItems:string[];
  routesKicker:string; routesTitle:string; routesIntro:string;
  methodKicker:string; methodQuote:string;
  method1Label:string; method1Title:string; method1Body:string;
  method2Label:string; method2Title:string; method2Body:string;
  method3Label:string; method3Title:string; method3Body:string;
  partnerKicker:string; partnerTitle:string; partnerBody:string; partnerButton:string;
  contactTitle:string; contactIntro:string;
};
export type SiteDesign = {
  colors:{forest:string;forest2:string;cream:string;paper:string;ink:string;clay:string;gold:string};
  fontPair:'editorial'|'classic'|'modern'; layout:'editorial'|'compact'|'airy'; logo:'symbol-text'|'full'|'symbol';
  home:{heroImage:HomeImageSettings;methodImage:HomeImageSettings;sectionVisibility:Record<HomeSectionKey,boolean>;sectionOrder:HomeSectionKey[]};
  content:Record<'es'|'en',HomeLocaleContent>;
};

const heroImage:HomeImageSettings={url:'/images/sagrada-familia.jpg',altEs:'Vista de la Sagrada Família desde una de sus plazas',altEn:'View of the Sagrada Família from one of its surrounding squares',desktopFit:'cover',mobileFit:'cover',desktopX:50,desktopY:45,mobileX:52,mobileY:45,desktopZoom:100,mobileZoom:100,desktopRatio:'16/9',mobileRatio:'4/3'};
const methodImage:HomeImageSettings={url:'/images/editorial/metodo-propio-eixample-horizontal-v2.webp',altEs:'Vista aérea del trazado urbano del Eixample de Barcelona',altEn:'Aerial view of Barcelona’s Eixample street grid',desktopFit:'cover',mobileFit:'cover',desktopX:50,desktopY:50,mobileX:50,mobileY:50,desktopZoom:100,mobileZoom:100,desktopRatio:'3/2',mobileRatio:'3/2'};
export const defaultSiteDesign:SiteDesign={
  colors:{forest:'#16382f',forest2:'#0d2922',cream:'#fbf8f2',paper:'#f4efe6',ink:'#18231f',clay:'#b75f43',gold:'#c59b52'},fontPair:'editorial',layout:'editorial',logo:'symbol-text',
  home:{heroImage,methodImage,sectionVisibility:{routes:true,method:true,partner:true},sectionOrder:['routes','method','partner']},
  content:{
    es:{homeKicker:'Rutas culturales en Barcelona',homeTitle:'Barcelona no solo se visita.',homeAccent:'Se aprende a mirar.',homeLead:'Recorridos con contexto, conversación y una mirada propia para entender lo que la ciudad todavía tiene delante de los ojos.',homeNote:'Historias conectadas con el lugar, no discursos repetidos frente a una postal.',heroRoutesLabel:'Explorar las rutas',heroGuideLabel:'Conoce al guía',heroBookLabel:'Reservar ruta',trustItems:['Grupos pequeños','Español e inglés','Reserva sin pago'],routesKicker:'Elige tu manera de entrar',routesTitle:'Tres rutas, tres Barcelonas',routesIntro:'Cada experiencia tiene un ritmo y una pregunta distinta. Encuentra la que conversa mejor contigo.',methodKicker:'Un método propio',methodQuote:'La ciudad no es un catálogo de monumentos. Es una conversación entre capas.',method1Label:'01 / OBSERVAR',method1Title:'Lo que está delante',method1Body:'La forma, la piedra, la calle y sus usos abren la conversación.',method2Label:'02 / CONECTAR',method2Title:'Las capas del lugar',method2Body:'Historia y contexto aparecen cuando ayudan a entender lo visible.',method3Label:'03 / CONVERSAR',method3Title:'Una ruta viva',method3Body:'Preguntas, ritmo atento y espacio para construir una mirada propia.',partnerKicker:'Hoteles, agencias y grupos',partnerTitle:'Una ruta también puede adaptarse a tu público.',partnerBody:'Diseñamos versiones por duración, idioma, perfil del grupo y contexto de la visita.',partnerButton:'Hablar de una colaboración',contactTitle:'Hablemos de tu visita',contactIntro:'Para cualquier otra pregunta, puedes escribirnos al correo o contactarnos por teléfono.'},
    en:{homeKicker:'Cultural tours in Barcelona',homeTitle:"You don't just visit Barcelona.",homeAccent:'You learn how to see it.',homeLead:'Tours with context, conversation and a distinctive point of view to understand what the city still holds in plain sight.',homeNote:'Stories connected to the place, rather than a repeated speech in front of a postcard.',heroRoutesLabel:'Explore the tours',heroGuideLabel:'Meet your guide',heroBookLabel:'Book a tour',trustItems:['Small groups','Spanish and English','Book without payment'],routesKicker:'Choose your way in',routesTitle:'Three tours, three Barcelonas',routesIntro:'Each experience has its own pace and guiding question. Find the one that speaks to you.',methodKicker:'A method of our own',methodQuote:'The city is not a catalogue of monuments. It is a conversation between layers.',method1Label:'01 / OBSERVE',method1Title:'What is in front of us',method1Body:'Form, stone, streets and everyday uses begin the conversation.',method2Label:'02 / CONNECT',method2Title:'The layers of place',method2Body:'History and context appear when they help us understand what we see.',method3Label:'03 / CONVERSE',method3Title:'A living tour',method3Body:'Questions, an attentive pace and space to build your own point of view.',partnerKicker:'Hotels, agencies and groups',partnerTitle:'A tour can also be adapted to your guests.',partnerBody:'We tailor duration, language, group profile and the context of the visit.',partnerButton:'Discuss a collaboration',contactTitle:'Let us talk about your visit',contactIntro:'For any further questions, write to our email address or contact us by phone.'}
  }
};
const clone=<T>(value:T):T=>JSON.parse(JSON.stringify(value));
const bounded=(value:unknown,fallback:number,min=0,max=160)=>Number.isFinite(Number(value))?Math.min(max,Math.max(min,Number(value))):fallback;
const imageSettings=(input:any,fallback:HomeImageSettings):HomeImageSettings=>({...fallback,...(input||{}),desktopX:bounded(input?.desktopX,fallback.desktopX,0,100),desktopY:bounded(input?.desktopY,fallback.desktopY,0,100),mobileX:bounded(input?.mobileX,fallback.mobileX,0,100),mobileY:bounded(input?.mobileY,fallback.mobileY,0,100),desktopZoom:bounded(input?.desktopZoom,fallback.desktopZoom,100,160),mobileZoom:bounded(input?.mobileZoom,fallback.mobileZoom,100,160)});
export function normalizeSiteDesign(input:any):SiteDesign{
  const base=clone(defaultSiteDesign),source=input&&typeof input==='object'?input:{};
  const order=(Array.isArray(source.home?.sectionOrder)?source.home.sectionOrder:base.home.sectionOrder).filter((item:unknown):item is HomeSectionKey=>['routes','method','partner'].includes(String(item))),unique=[...new Set(order)];
  for(const key of base.home.sectionOrder)if(!unique.includes(key))unique.push(key);
  return {...base,...source,colors:{...base.colors,...source.colors},home:{...base.home,...source.home,heroImage:imageSettings(source.home?.heroImage,base.home.heroImage),methodImage:imageSettings(source.home?.methodImage,base.home.methodImage),sectionVisibility:{...base.home.sectionVisibility,...source.home?.sectionVisibility},sectionOrder:unique},content:{es:{...base.content.es,...source.content?.es,trustItems:Array.isArray(source.content?.es?.trustItems)?source.content.es.trustItems:base.content.es.trustItems},en:{...base.content.en,...source.content?.en,trustItems:Array.isArray(source.content?.en?.trustItems)?source.content.en.trustItems:base.content.en.trustItems}}};
}
let cached:Promise<SiteDesign>|null=null;
export function getPublicSiteDesign(){if(!cached)cached=(async()=>{if(!supabase)return clone(defaultSiteDesign);const {data,error}=await supabase.rpc('get_public_site_design');return normalizeSiteDesign(error||!data?defaultSiteDesign:data)})();return cached;}
export const fontVariables=(pair:SiteDesign['fontPair'])=>pair==='modern'?{sans:"'DM Sans',system-ui,sans-serif",serif:"'DM Sans',system-ui,sans-serif"}:pair==='classic'?{sans:"Georgia,'Times New Roman',serif",serif:"Georgia,'Times New Roman',serif"}:{sans:"'DM Sans',system-ui,sans-serif",serif:"'Newsreader',Georgia,serif"};
