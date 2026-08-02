import { supabase } from '../lib/supabase';
import { fontVariables,normalizeSiteDesign } from '../lib/site-settings';

const params=new URLSearchParams(window.location.search);
if(params.get('preview')==='editorial')void startEditorialPreview();

async function startEditorialPreview(){
  const locale=document.documentElement.lang?.toLowerCase().startsWith('en')?'en':'es';
  const banner=document.createElement('aside');
  banner.className='editorial-preview-banner';
  banner.setAttribute('role','status');
  banner.innerHTML='<strong>Vista previa privada</strong><span data-preview-status>Comprobando tu sesión…</span><a href="'+location.pathname+'">Cerrar vista previa</a>';
  document.body.prepend(banner);
  if(!supabase){setStatus('Supabase no está configurado.');return;}
  const {data:{session}}=await supabase.auth.getSession();
  if(!session){setStatus('Inicia sesión en el panel para ver borradores.');banner.classList.add('error');return;}
  const {data,error}=await supabase.rpc('get_admin_site_design');
  if(error||!data){setStatus('No fue posible cargar el borrador.');banner.classList.add('error');return;}
  const settings=normalizeSiteDesign(data.draft||data.published);
  applyDesign(settings,locale);
  setStatus(data.draft?'Borrador no publicado · '+(locale==='en'?'English':'Castellano'):'No hay borrador: estás viendo la versión publicada.');
  document.body.classList.add('editorial-preview-active');
  function setStatus(message:string){const target=banner.querySelector('[data-preview-status]');if(target)target.textContent=message;}
}

function applyDesign(settings:any,locale:'es'|'en'){
  const root=document.documentElement,fonts=fontVariables(settings.fontPair);
  Object.entries(settings.colors).forEach(([key,value])=>root.style.setProperty('--'+key,String(value)));
  root.style.setProperty('--sans',fonts.sans);root.style.setProperty('--serif',fonts.serif);
  root.dataset.layout=settings.layout;root.dataset.logo=settings.logo;
  const content=settings.content[locale],base=import.meta.env.BASE_URL;
  const resolveUrl=(value:string)=>/^https?:/i.test(value)?value:base+String(value||'').replace(/^\//,'');
  const text=(parent:Element|null,selector:string,value:string)=>{const node=parent?.querySelector(selector);if(node)node.textContent=value||'';};

  const hero=document.querySelector('.home-route-hero');
  if(hero){
    applyImage(hero,settings.home.heroImage,'hero');
    const image=hero.querySelector('img');if(image){image.setAttribute('src',resolveUrl(settings.home.heroImage.url));image.setAttribute('alt',locale==='en'?settings.home.heroImage.altEn:settings.home.heroImage.altEs);}
    text(hero,'.route-hero-copy>.kicker',content.homeKicker);
    const title=hero.querySelector('.route-hero-copy>h1');if(title){title.textContent=content.homeTitle||'';const accent=document.createElement('em');accent.textContent=content.homeAccent||'';title.append(accent);}
    text(hero,'.route-hero-copy>p:not(.kicker)',content.homeLead);
    const actions=hero.querySelectorAll('.hero-actions a');[content.heroRoutesLabel,content.heroGuideLabel,content.heroBookLabel].forEach((label,index)=>{if(actions[index])actions[index].textContent=label||'';});
    const trust=hero.querySelector('.trust-row');if(trust){trust.innerHTML='';(content.trustItems||[]).filter(Boolean).forEach((item:string)=>{const li=document.createElement('li');li.textContent=item;trust.append(li);});}
  }

  const routes=document.querySelector('.home-routes-section');
  text(routes,'.section-heading .kicker',content.routesKicker);text(routes,'.section-heading h2',content.routesTitle);text(routes,'.carousel-heading-side>p',content.routesIntro);

  const method=document.querySelector('.authored-manifesto');
  if(method){
    text(method,'.manifesto-feature .kicker',content.methodKicker);text(method,'.manifesto-feature blockquote',content.methodQuote);
    const figure=method.querySelector('.manifesto-collage');if(figure){applyImage(figure,settings.home.methodImage,'method');const image=figure.querySelector('img');if(image){image.setAttribute('src',resolveUrl(settings.home.methodImage.url));image.setAttribute('alt',locale==='en'?settings.home.methodImage.altEn:settings.home.methodImage.altEs);}}
    const cards=method.querySelectorAll('.principles>div');
    for(let i=1;i<=3;i++){const card=cards[i-1];text(card,'span',content['method'+i+'Label']);text(card,'h3',content['method'+i+'Title']);text(card,'p',content['method'+i+'Body']);}
  }

  const partner=document.querySelector('.partner-section');
  text(partner,'.kicker',content.partnerKicker);text(partner,'h2',content.partnerTitle);text(partner,'.partner-card>div>p:not(.kicker)',content.partnerBody);text(partner,'.button',content.partnerButton);

  const sections:any={routes,method,partner},parent=method?.parentElement||routes?.parentElement||partner?.parentElement;
  if(parent)settings.home.sectionOrder.forEach((key:string)=>{const section=sections[key];if(section){section.hidden=!settings.home.sectionVisibility[key];parent.append(section);}});
}

function applyImage(container:Element,image:any,slot:'hero'|'method'){
  const style=(container as HTMLElement).style;
  style.setProperty('--image-desktop-x',image.desktopX+'%');style.setProperty('--image-desktop-y',image.desktopY+'%');style.setProperty('--image-mobile-x',image.mobileX+'%');style.setProperty('--image-mobile-y',image.mobileY+'%');
  style.setProperty('--image-desktop-zoom',String(image.desktopZoom/100));style.setProperty('--image-mobile-zoom',String(image.mobileZoom/100));style.setProperty('--image-desktop-fit',image.desktopFit);style.setProperty('--image-mobile-fit',image.mobileFit);
  if(slot==='method'){style.setProperty('--method-desktop-ratio',image.desktopRatio);style.setProperty('--method-mobile-ratio',image.mobileRatio);style.setProperty('--method-desktop-opacity',String(image.desktopOpacity/100));style.setProperty('--method-mobile-opacity',String(image.mobileOpacity/100));container.closest('.authored-manifesto')?.classList.toggle('method-image-background',image.presentation==='background');}
}
