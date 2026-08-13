// @ts-nocheck
import { getAdminSiteDesign,saveSiteDesignDraft,publishSiteDesign } from '../lib/admin';
import { normalizeSiteDesign,pageVisualKeys,publicPageKeys } from '../lib/site-settings';
import { uploadSiteImage } from '../lib/site-media';
import { setupMediaAssistant } from '../lib/media-corrector';

const editor=document.querySelector('[data-pages-editor]');
if(editor)setup(editor as HTMLElement);

function setup(root:HTMLElement){
  const form=root.querySelector('[data-pages-form]') as HTMLFormElement,$=(selector:string)=>root.querySelector(selector) as HTMLElement|null;
  let current:any=null;
  const pending={full:null as File|null,symbol:null as File|null,guide:null as File|null};
  const urls={full:'',symbol:'',guide:''};
  const pendingVisuals=Object.fromEntries(pageVisualKeys.map(key=>[key,null])) as Record<string,File|null>;
  const visualUrls=Object.fromEntries(pageVisualKeys.map(key=>[key,''])) as Record<string,string>;
  const field=(name:string)=>form.elements.namedItem(name) as HTMLInputElement|HTMLSelectElement;
  const assistants={
    full:setupMediaAssistant(field('fullLogoFile') as HTMLInputElement,{defaultRatio:'3/2',onPreview:file=>previewFile('full',file)}),
    symbol:setupMediaAssistant(field('symbolLogoFile') as HTMLInputElement,{defaultRatio:'1/1',onPreview:file=>previewFile('symbol',file)}),
    guide:setupMediaAssistant(field('guidePhotoFile') as HTMLInputElement,{defaultRatio:'1/1',onPreview:file=>previewFile('guide',file)})
  };
  const visualAssistants=Object.fromEntries(pageVisualKeys.map(key=>[key,setupMediaAssistant(field(`${key}VisualFile`) as HTMLInputElement,{defaultRatio:'16/9',onPreview:file=>previewVisual(key,file)})]));

  root.querySelectorAll('[data-page-tab]').forEach(button=>button.addEventListener('click',()=>{const id=(button as HTMLElement).dataset.pageTab;root.querySelectorAll('[data-page-tab]').forEach(item=>item.classList.toggle('active',item===button));root.querySelectorAll('[data-page-pane]').forEach(item=>(item as HTMLElement).hidden=(item as HTMLElement).dataset.pagePane!==id);}));
  function previewFile(slot:'full'|'symbol'|'guide',file:File){pending[slot]=file;if(urls[slot])URL.revokeObjectURL(urls[slot]);urls[slot]=URL.createObjectURL(file);const image=$(`[data-brand-preview="${slot}"]`) as HTMLImageElement;if(image)image.src=urls[slot];}
  function updateVisualPreview(key:string){
    const src=visualUrls[key]||field(`${key}VisualUrl`).value.trim(),fit=field(`${key}VisualFit`).value,x=field(`${key}VisualX`).value,y=field(`${key}VisualY`).value,presentation=field(`${key}VisualPresentation`).value;
    root.querySelectorAll(`[data-page-visual-preview="${key}"]`).forEach(node=>{const image=node as HTMLImageElement;image.src=src;image.hidden=!src;image.style.objectFit=fit;image.style.objectPosition=`${x}% ${y}%`;});
    root.querySelectorAll(`[data-page-visual-frame="${key}"]`).forEach(node=>{(node as HTMLElement).dataset.presentation=presentation;(node as HTMLElement).classList.toggle('is-contained',fit==='contain');});
  }
  function previewVisual(key:string,file:File){pendingVisuals[key]=file;if(visualUrls[key])URL.revokeObjectURL(visualUrls[key]);visualUrls[key]=URL.createObjectURL(file);const presentation=field(`${key}VisualPresentation`);if(presentation.value==='none')presentation.value='background';updateVisualPreview(key);}

  function fill(settings:any,state=''){
    current=normalizeSiteDesign(settings);
    for(const slot of ['full','symbol'] as const){field(`${slot}LogoUrl`).value=current.branding[`${slot}LogoUrl`];field(`${slot}LogoAlt`).value=current.branding[`${slot}LogoAlt`];const image=$(`[data-brand-preview="${slot}"]`) as HTMLImageElement;if(image)image.src=current.branding[`${slot}LogoUrl`];}
    field('guidePhotoUrl').value=current.editorial.es.guidePhotoUrl;const guideImage=$('[data-brand-preview="guide"]') as HTMLImageElement;if(guideImage)guideImage.src=current.editorial.es.guidePhotoUrl;
    for(const key of pageVisualKeys){const visual=current.pageVisuals[key];field(`${key}VisualUrl`).value=visual.url;field(`${key}VisualPresentation`).value=visual.presentation;field(`${key}VisualFit`).value=visual.fit;field(`${key}VisualX`).value=String(visual.x);field(`${key}VisualY`).value=String(visual.y);field(`${key}VisualAltEs`).value=visual.altEs;field(`${key}VisualAltEn`).value=visual.altEn;field(`${key}VisualLinkUrl`).value=visual.linkUrl;field(`${key}VisualLinkLabelEs`).value=visual.linkLabelEs;field(`${key}VisualLinkLabelEn`).value=visual.linkLabelEn;updateVisualPreview(key);}
    for(const key of publicPageKeys)(field(`${key}PageVisible`) as HTMLInputElement).checked=current.pageVisibility[key];
    for(const action of ['book','routes','guide']){field(`${action}Order`).value=String(current.home.heroActionOrder.indexOf(action)+1);field(`${action}Link`).value=current.home.heroActionLinks[action];}
    root.querySelectorAll('[data-copy-key]').forEach(control=>{const element=control as HTMLInputElement,key=element.dataset.copyKey!,locale=element.dataset.copyLocale!;element.value=current.editorial[locale][key]??'';});
    for(const locale of ['es','en']){const area=root.querySelector(`[data-faq-locale="${locale}"]`) as HTMLTextAreaElement;area.value=current.editorial[locale].faqs.map((item:any)=>`${item.question} | ${item.answer}`).join('\n');}
    const status=$('[data-pages-state]');if(status)status.textContent=state;
  }

  function read(){
    const settings=normalizeSiteDesign(JSON.parse(JSON.stringify(current)));
    for(const slot of ['full','symbol'] as const){settings.branding[`${slot}LogoUrl`]=field(`${slot}LogoUrl`).value.trim();settings.branding[`${slot}LogoAlt`]=field(`${slot}LogoAlt`).value.trim();}
    settings.editorial.es.guidePhotoUrl=field('guidePhotoUrl').value.trim();settings.editorial.en.guidePhotoUrl=settings.editorial.es.guidePhotoUrl;
    for(const key of pageVisualKeys)settings.pageVisuals[key]={url:field(`${key}VisualUrl`).value.trim(),presentation:field(`${key}VisualPresentation`).value,fit:field(`${key}VisualFit`).value,x:Number(field(`${key}VisualX`).value),y:Number(field(`${key}VisualY`).value),altEs:field(`${key}VisualAltEs`).value.trim(),altEn:field(`${key}VisualAltEn`).value.trim(),linkUrl:field(`${key}VisualLinkUrl`).value.trim(),linkLabelEs:field(`${key}VisualLinkLabelEs`).value.trim(),linkLabelEn:field(`${key}VisualLinkLabelEn`).value.trim()};
    for(const key of publicPageKeys)settings.pageVisibility[key]=(field(`${key}PageVisible`) as HTMLInputElement).checked;
    const order=['book','routes','guide'].map(action=>({action,position:Number(field(`${action}Order`).value)}));if(new Set(order.map(item=>item.position)).size!==3)throw new Error('Los tres botones deben tener posiciones diferentes.');settings.home.heroActionOrder=order.sort((a,b)=>a.position-b.position).map(item=>item.action);for(const action of ['book','routes','guide'])settings.home.heroActionLinks[action]=field(`${action}Link`).value.trim();
    root.querySelectorAll('[data-copy-key]').forEach(control=>{const element=control as HTMLInputElement;settings.editorial[element.dataset.copyLocale!][element.dataset.copyKey!]=element.value.trim();});
    for(const locale of ['es','en']){const area=root.querySelector(`[data-faq-locale="${locale}"]`) as HTMLTextAreaElement;settings.editorial[locale].faqs=area.value.split(/\r?\n/).map(line=>line.split('|')).filter(parts=>parts.length>=2&&parts[0].trim()&&parts.slice(1).join('|').trim()).map(parts=>({question:parts.shift()!.trim(),answer:parts.join('|').trim()})).slice(0,30);}
    return settings;
  }

  async function withUploads(){
    const settings=read();
    for(const slot of ['full','symbol'] as const)if(pending[slot]){const prepared=await assistants[slot].getResult(),file=prepared?.file||pending[slot]!;settings.branding[`${slot}LogoUrl`]=await uploadSiteImage(file,prepared?.corrected?prepared.original:undefined);field(`${slot}LogoUrl`).value=settings.branding[`${slot}LogoUrl`];pending[slot]=null;assistants[slot].reset();if(urls[slot]){URL.revokeObjectURL(urls[slot]);urls[slot]='';}}
    if(pending.guide){const prepared=await assistants.guide.getResult(),file=prepared?.file||pending.guide;const url=await uploadSiteImage(file,prepared?.corrected?prepared.original:undefined);settings.editorial.es.guidePhotoUrl=url;settings.editorial.en.guidePhotoUrl=url;field('guidePhotoUrl').value=url;pending.guide=null;assistants.guide.reset();if(urls.guide){URL.revokeObjectURL(urls.guide);urls.guide='';}}
    for(const key of pageVisualKeys)if(pendingVisuals[key]){const assistant=(visualAssistants as any)[key],prepared=await assistant.getResult(),file=prepared?.file||pendingVisuals[key]!;const url=await uploadSiteImage(file,prepared?.corrected?prepared.original:undefined);settings.pageVisuals[key].url=url;field(`${key}VisualUrl`).value=url;pendingVisuals[key]=null;assistant.reset();if(visualUrls[key]){URL.revokeObjectURL(visualUrls[key]);visualUrls[key]='';}}
    return settings;
  }

  async function save(publish=false){const message=$('[data-pages-message]')!,buttons=[...form.querySelectorAll('button')] as HTMLButtonElement[];buttons.forEach(button=>button.disabled=true);message.textContent='';try{const settings=await withUploads();await saveSiteDesignDraft(settings);current=settings;if(publish){const result=await publishSiteDesign();message.textContent=result.deployStarted?'Publicado. GitHub Pages se está actualizando.':'Publicado, pero la actualización automática no se inició.';fill(result.settings||settings,'Versión pública vigente');}else{message.textContent='Borrador guardado. La web pública no ha cambiado.';fill(settings,'Borrador pendiente');}}catch(error:any){message.textContent=error.message||'No fue posible guardar los contenidos.';}finally{buttons.forEach(button=>button.disabled=false);}}
  form.addEventListener('input',event=>{const name=(event.target as HTMLInputElement)?.name||'';const match=name.match(/^(.+)Visual(Presentation|Fit|X|Y)$/);if(match&&pageVisualKeys.includes(match[1] as any))updateVisualPreview(match[1]);});
  form.addEventListener('submit',event=>{event.preventDefault();void save(false)});$('[data-pages-publish]')?.addEventListener('click',()=>{if(confirm('¿Publicar los contenidos de todas las páginas en castellano e inglés?'))void save(true)});
  void getAdminSiteDesign().then(data=>fill(data.draft||data.published,data.draft?'Borrador pendiente':'Versión pública vigente')).catch((error:any)=>{const message=$('[data-pages-message]');if(message)message.textContent=error.message||'No fue posible cargar los contenidos.';});
}
