// @ts-nocheck
import { getAdminSiteDesign,saveSiteDesignDraft,publishSiteDesign,discardSiteDesignDraft,getSiteDesignRevisions,revertSiteDesignRevision } from '../lib/admin';
import { uploadSiteImage } from '../lib/site-media';
import { setupMediaAssistant } from '../lib/media-corrector';
import { defaultSiteDesign,normalizeSiteDesign } from '../lib/site-settings';

const clone=value=>JSON.parse(JSON.stringify(value));
const textFields={homeKicker:'HomeKicker',homeTitle:'HomeTitle',homeAccent:'HomeAccent',homeLead:'HomeLead',heroRoutesLabel:'HeroRoutesLabel',heroGuideLabel:'HeroGuideLabel',heroBookLabel:'HeroBookLabel',routesKicker:'RoutesKicker',routesTitle:'RoutesTitle',routesIntro:'RoutesIntro',methodKicker:'MethodKicker',methodQuote:'MethodQuote',method1Label:'Method1Label',method1Title:'Method1Title',method1Body:'Method1Body',method2Label:'Method2Label',method2Title:'Method2Title',method2Body:'Method2Body',method3Label:'Method3Label',method3Title:'Method3Title',method3Body:'Method3Body',partnerKicker:'PartnerKicker',partnerTitle:'PartnerTitle',partnerBody:'PartnerBody',partnerButton:'PartnerButton',contactTitle:'ContactTitle',contactIntro:'ContactIntro',reviewsHeroKicker:'ReviewsHeroKicker',reviewsHeroTitle:'ReviewsHeroTitle',reviewsHeroIntro:'ReviewsHeroIntro',reviewsListKicker:'ReviewsListKicker',reviewsListTitle:'ReviewsListTitle',reviewsTrustText:'ReviewsTrustText',reviewsEmpty:'ReviewsEmpty',reviewsFormKicker:'ReviewsFormKicker',reviewsFormTitle:'ReviewsFormTitle',reviewsFormIntro:'ReviewsFormIntro'};
const imageFields={hero:{url:'heroImageUrl',altEs:'heroImageAltEs',altEn:'heroImageAltEn',desktopFit:'heroDesktopFit',mobileFit:'heroMobileFit',desktopX:'heroDesktopX',desktopY:'heroDesktopY',mobileX:'heroMobileX',mobileY:'heroMobileY',desktopZoom:'heroDesktopZoom',mobileZoom:'heroMobileZoom'},method:{url:'methodImageUrl',altEs:'methodImageAltEs',altEn:'methodImageAltEn',desktopFit:'methodDesktopFit',mobileFit:'methodMobileFit',desktopX:'methodDesktopX',desktopY:'methodDesktopY',mobileX:'methodMobileX',mobileY:'methodMobileY',desktopZoom:'methodDesktopZoom',mobileZoom:'methodMobileZoom',desktopOpacity:'methodDesktopOpacity',mobileOpacity:'methodMobileOpacity',presentation:'methodPresentation',desktopRatio:'methodDesktopRatio',mobileRatio:'methodMobileRatio'}};

export function setupHomeEditor(app){
  const $=selector=>app.querySelector(selector),form=$('[data-design-form]');
  let current=normalizeSiteDesign(defaultSiteDesign),pending={hero:null,method:null},objectUrls={hero:'',method:''};
  const field=name=>form.elements[name],get=name=>String(field(name)?.value??'').trim(),set=(name,value)=>{if(field(name))field(name).value=value??''};
  const src=slot=>objectUrls[slot]||get(`${slot}ImageUrl`);
  const center=$('[data-editorial-center]');let lastData=null;
  const switchEditorialPane=(name,focus='')=>{
    if(!center)return;
    center.querySelectorAll('[data-editorial-tab]').forEach(button=>button.classList.toggle('active',button.dataset.editorialTab===name));
    center.querySelectorAll('[data-editorial-pane]').forEach(pane=>pane.hidden=pane.dataset.editorialPane!==name);
    if(focus){
      const details=[...center.querySelectorAll('.home-editor-section')].find(item=>item.querySelector('summary')?.textContent?.toLowerCase().includes(focus==='method'?'método':'cabecera'));
      if(details){details.open=true;requestAnimationFrame(()=>details.scrollIntoView({behavior:'smooth',block:'start'}));}
    }
  };
  const translationGaps=settings=>Object.keys(textFields).filter(key=>String(settings.content.es[key]||'').trim()&&!String(settings.content.en[key]||'').trim()).length;
  function renderChecklist(settings){
    const list=$('[data-editorial-checklist]');if(!list)return;
    const gaps=translationGaps(settings),images=['hero','method'].map(slot=>settings.home[slot+'Image']),checks=[
      {ok:gaps===0,text:gaps?gaps+' campos en inglés están pendientes':'Castellano e inglés completos'},
      {ok:images.every(image=>image.url),text:images.every(image=>image.url)?'Imágenes principales asignadas':'Falta una imagen principal'},
      {ok:images.every(image=>image.altEs&&image.altEn),text:images.every(image=>image.altEs&&image.altEn)?'Textos alternativos ES/EN completos':'Faltan textos alternativos de imágenes'},
      {ok:new Set(settings.home.sectionOrder).size===3,text:'Orden de secciones válido'},
      {ok:true,text:'La web pública permanece intacta hasta confirmar Publicar'}
    ];
    list.innerHTML='';checks.forEach(check=>{const item=document.createElement('li');item.textContent=check.text;item.classList.toggle('warning',!check.ok);list.append(item);});
  }
  function renderCenter(data){
    if(!center||!data)return;lastData=data;const settings=normalizeSiteDesign(data.draft||data.published),gaps=translationGaps(settings),date=value=>value?new Intl.DateTimeFormat('es-ES',{dateStyle:'medium',timeStyle:'short'}).format(new Date(value)):'';
    $('[data-editorial-state]').textContent=data.draft?'Borrador pendiente':'Web publicada';
    $('[data-editorial-updated]').textContent=data.draft?'Guardado '+date(data.updated_at):'Publicado '+date(data.published_at);
    $('[data-editorial-draft-state]').textContent=data.draft?'Pendiente':'Sin cambios';
    $('[data-editorial-draft-help]').textContent=data.draft?'La web pública todavía no ha cambiado':'Puedes comenzar una edición segura';
    $('[data-editorial-language-state]').textContent=gaps?gaps+' pendientes':'ES + EN';
    $('[data-editorial-language-help]').textContent=gaps?'Revísalos antes de publicar':'Ambos idiomas tienen contenido';
    $('[data-editorial-next-title]').textContent=data.draft?'Comprobar el borrador':'Editar «Un método propio»';
    $('[data-editorial-next-copy]').textContent=data.draft?'Abre Publicación y revisa la página real antes de confirmar.':'El cambio comenzará como borrador y no será público.';
    renderChecklist(settings);
  }
  async function loadHistory(){
    const box=$('[data-editorial-history]'),empty=$('[data-editorial-history-empty]');if(!box||!empty)return;
    box.innerHTML='';try{const revisions=await getSiteDesignRevisions();empty.hidden=revisions.length>0;for(const revision of revisions){const row=document.createElement('article'),copy=document.createElement('p'),button=document.createElement('button'),title=revision.settings?.content?.es?.homeTitle||'Portada anterior';row.className='editorial-history-row';const strong=document.createElement('strong'),small=document.createElement('small');strong.textContent=title;small.textContent=new Intl.DateTimeFormat('es-ES',{dateStyle:'medium',timeStyle:'short'}).format(new Date(revision.created_at));copy.append(strong,small);button.type='button';button.className='button outline';button.textContent='Restaurar esta versión';button.onclick=async()=>{if(!window.confirm('¿Restaurar esta versión? La versión actual quedará guardada en el historial.'))return;button.disabled=true;try{const result=await revertSiteDesignRevision(revision.id);const data=await getAdminSiteDesign();fill(result.settings,'Versión restaurada y publicada');renderCenter(data);await loadHistory();$('[data-design-message]').textContent=result.deployStarted?'Versión restaurada. La web se está actualizando.':'Versión restaurada; revisa el estado del despliegue.';}catch(error){$('[data-design-message]').textContent=error.message||'No fue posible restaurar la versión.';}finally{button.disabled=false;}};row.append(copy,button);box.append(row);}}catch(error){empty.hidden=false;empty.textContent='El historial estará disponible al aplicar la migración del centro editorial.';}}
  center?.querySelectorAll('[data-editorial-tab]').forEach(button=>button.addEventListener('click',()=>switchEditorialPane(button.dataset.editorialTab)));
  center?.querySelectorAll('[data-editorial-open]').forEach(button=>button.addEventListener('click',()=>switchEditorialPane(button.dataset.editorialOpen,button.dataset.editorialFocus||'')));
  center?.querySelectorAll('[data-editorial-admin-view]').forEach(button=>button.addEventListener('click',()=>app.querySelector('[data-admin-view="'+button.dataset.editorialAdminView+'"]')?.click()));
  $('[data-editorial-refresh-history]')?.addEventListener('click',loadHistory);
  function fill(settings,state='Versión pública vigente'){
    current=normalizeSiteDesign(settings);pending={hero:null,method:null};
    field('fontPair').value=current.fontPair;field('layout').value=current.layout;field('logo').value=current.logo;
    Object.entries(current.colors).forEach(([key,value])=>set(key,value));
    for(const channel of ['instagram','tripadvisor','getyourguide','linkedin']){set(channel+'Url',current.social[channel].url);field(channel+'Visible').checked=current.social[channel].visible;}
    for(const locale of ['es','en']){const prefix=locale;for(const [property,suffix] of Object.entries(textFields))set(prefix+suffix,current.content[locale][property]);set(prefix+'TrustItems',current.content[locale].trustItems.join('\n'));}
    for(const slot of ['hero','method'])for(const [property,name] of Object.entries(imageFields[slot]))set(name,current.home[`${slot}Image`][property]);
    for(const key of ['routes','method','partner']){field(`${key}Visible`).checked=current.home.sectionVisibility[key];set(`${key}Order`,current.home.sectionOrder.indexOf(key)+1);}
    $('[data-design-state]').textContent=state;preview();
  }
  function read(){
    const settings=clone(current);settings.fontPair=get('fontPair');settings.layout=get('layout');settings.logo=get('logo');
    for(const key of Object.keys(settings.colors))settings.colors[key]=get(key);
    for(const channel of ['instagram','tripadvisor','getyourguide','linkedin'])settings.social[channel]={url:get(channel+'Url'),visible:field(channel+'Visible').checked};
    for(const locale of ['es','en']){for(const [property,suffix] of Object.entries(textFields))settings.content[locale][property]=get(locale+suffix);settings.content[locale].trustItems=get(locale+'TrustItems').split(/\r?\n/).map(x=>x.trim()).filter(Boolean).slice(0,5);}
    for(const slot of ['hero','method'])for(const [property,name] of Object.entries(imageFields[slot]))settings.home[`${slot}Image`][property]=['desktopX','desktopY','mobileX','mobileY','desktopZoom','mobileZoom','desktopOpacity','mobileOpacity'].includes(property)?Number(get(name)):get(name);
    settings.home.sectionVisibility={routes:field('routesVisible').checked,method:field('methodVisible').checked,partner:field('partnerVisible').checked};
    const positions=['routes','method','partner'].map(key=>({key,position:Number(get(`${key}Order`))}));if(new Set(positions.map(item=>item.position)).size!==3)throw new Error('Cada sección debe tener una posición diferente.');settings.home.sectionOrder=positions.sort((a,b)=>a.position-b.position).map(item=>item.key);
    return normalizeSiteDesign(settings);
  }
  function readSafe(){try{return read()}catch{return current}}
  function preview(){
    const settings=readSafe(),fontPair=settings.fontPair,displayFont=fontPair==='brand'?"'Archivo',sans-serif":fontPair==='lato'?"'Lato',sans-serif":fontPair==='modern'?"'DM Sans',sans-serif":fontPair==='classic'?"Georgia,serif":"'Newsreader',Georgia,serif",bodyFont=fontPair==='brand'?"'Archivo',sans-serif":fontPair==='lato'?"'Lato',sans-serif":fontPair==='classic'?"Georgia,serif":"'DM Sans',sans-serif";
    for(const slot of ['hero','method']){
      const currentImage=$('[data-current-image="'+slot+'"]'),currentSrc=src(slot);
      if(!currentImage)continue;
      currentImage.hidden=!currentSrc;
      if(currentSrc)currentImage.src=currentSrc;else currentImage.removeAttribute('src');
    }
    document.querySelectorAll('[data-output]').forEach(output=>{const input=field(output.dataset.output);output.textContent=input?`${input.value}${input.name.includes('Zoom')?'%':''}`:''});
    for(const mode of ['desktop','mobile']){
      const hero=settings.home.heroImage,method=settings.home.methodImage,heroImg=$(`[data-preview-hero-image="${mode}"]`),methodImg=$(`[data-preview-method-image="${mode}"]`),methodFrame=$(`[data-preview-method="${mode}"]`);
      heroImg.src=src('hero');heroImg.style.objectFit=hero[`${mode}Fit`];heroImg.style.objectPosition=`${hero[`${mode}X`]}% ${hero[`${mode}Y`]}%`;heroImg.style.transform=`scale(${hero[`${mode}Zoom`]/100})`;
      methodImg.src=src('method');methodImg.style.objectFit=method[`${mode}Fit`];methodImg.style.objectPosition=`${method[`${mode}X`]}% ${method[`${mode}Y`]}%`;methodImg.style.transform=`scale(${method[`${mode}Zoom`]/100})`;methodImg.style.opacity=String(method[`${mode}Opacity`]/100);methodFrame.style.aspectRatio=method[`${mode}Ratio`];methodFrame.classList.toggle('is-background',method.presentation==='background');methodFrame.parentElement.classList.toggle('image-background-preview',method.presentation==='background');
      const card=$(`[data-preview-hero="${mode}"]`),previewCard=card.closest('.home-preview');previewCard?.style.setProperty('--preview-serif',displayFont);previewCard?.style.setProperty('--preview-sans',bodyFont);card.style.backgroundColor=settings.colors.forest;
    }
    const c=settings.content.es;for(const [selector,value] of [['[data-preview-kicker]',c.homeKicker],['[data-preview-title]',c.homeTitle],['[data-preview-accent]',c.homeAccent],['[data-preview-lead]',c.homeLead],['[data-preview-kicker-mobile]',c.homeKicker],['[data-preview-title-mobile]',c.homeTitle],['[data-preview-accent-mobile]',c.homeAccent],['[data-preview-method-kicker]',c.methodKicker],['[data-preview-method-quote]',c.methodQuote],['[data-preview-method-kicker-mobile]',c.methodKicker],['[data-preview-method-quote-mobile]',c.methodQuote]]){const node=$(selector);if(node)node.textContent=value;}
  }
  function selectImage(slot,file){if(!file)return;if(!file.type.startsWith('image/')||file.size>15728640){$('[data-design-message]').textContent='Selecciona una imagen válida de menos de 15 MB.';field(`${slot}ImageFile`).value='';return}if(objectUrls[slot])URL.revokeObjectURL(objectUrls[slot]);pending[slot]=file;objectUrls[slot]=URL.createObjectURL(file);preview();}
  const assistants={hero:setupMediaAssistant(field('heroImageFile'),{defaultRatio:'16/9',onPreview:file=>selectImage('hero',file)}),method:setupMediaAssistant(field('methodImageFile'),{defaultRatio:'3/2',onPreview:file=>selectImage('method',file)})};
  async function withUploads(){const settings=read();for(const slot of ['hero','method'])if(pending[slot]){const prepared=await assistants[slot].getResult(),file=prepared?.file||pending[slot];settings.home[`${slot}Image`].url=await uploadSiteImage(file,prepared?.corrected?prepared.original:undefined);set(`${slot}ImageUrl`,settings.home[`${slot}Image`].url);pending[slot]=null;assistants[slot].reset();if(objectUrls[slot]){URL.revokeObjectURL(objectUrls[slot]);objectUrls[slot]='';}}return settings;}
  async function load(){const data=await getAdminSiteDesign();fill(data.draft||data.published,data.draft?'Borrador pendiente de publicación':'Versión pública vigente');renderCenter(data);await loadHistory();}
  field('methodPresentation')?.addEventListener('change',()=>{if(get('methodPresentation')==='background'&&Number(get('methodDesktopOpacity'))===100){set('methodDesktopOpacity',35);set('methodMobileOpacity',35)}preview()});
  form?.addEventListener('input',preview);
  form?.addEventListener('submit',async event=>{event.preventDefault();const button=event.submitter,message=$('[data-design-message]');button.disabled=true;message.textContent='';try{const settings=await withUploads();await saveSiteDesignDraft(settings);current=settings;$('[data-design-state]').textContent='Borrador pendiente de publicación';message.textContent='Borrador guardado. La web pública no ha cambiado.';renderCenter(await getAdminSiteDesign());}catch(error){message.textContent=error.message||'No fue posible guardar la portada.';}finally{button.disabled=false;}});
  $('[data-design-publish]')?.addEventListener('click',async()=>{if(!window.confirm('¿Publicar esta portada en castellano e inglés?'))return;const button=$('[data-design-publish]'),message=$('[data-design-message]');button.disabled=true;message.textContent='';try{const settings=await withUploads();await saveSiteDesignDraft(settings);const result=await publishSiteDesign();current=normalizeSiteDesign(result.settings||settings);$('[data-design-state]').textContent='Versión pública vigente';message.textContent=result.deployStarted?'Publicado. GitHub Pages se está actualizando.':'Publicado, pero no fue posible iniciar la actualización de GitHub Pages.';renderCenter(await getAdminSiteDesign());await loadHistory();}catch(error){message.textContent=error.message||'No fue posible publicar la portada.';}finally{button.disabled=false;}});
  $('[data-design-discard]')?.addEventListener('click',async()=>{if(!window.confirm('¿Descartar el borrador y recuperar la portada pública?'))return;const published=await discardSiteDesignDraft();fill(published,'Versión pública vigente');$('[data-design-message]').textContent='Borrador descartado.';renderCenter(await getAdminSiteDesign());});
  $('[data-design-defaults]')?.addEventListener('click',()=>{if(window.confirm('¿Cargar los valores iniciales? Aún tendrás que guardarlos o publicarlos.'))fill(defaultSiteDesign,'Valores iniciales cargados, aún sin guardar');});
  return {load};
}
