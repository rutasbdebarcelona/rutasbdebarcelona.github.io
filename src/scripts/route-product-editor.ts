// @ts-nocheck
const lines=(value='')=>String(value||'').split(/\r?\n/).map(item=>item.trim()).filter(Boolean);
const list=value=>Array.isArray(value)?value:[];
const field=(card,name)=>card.querySelector(`[data-field="${name}"]`);
const make=(tag,className,text='')=>{const node=document.createElement(tag);if(className)node.className=className;if(text)node.textContent=text;return node};
const input=(name,label,type='text',full=false)=>{const wrap=make('label',`field${full?' full':''}`),title=make('span','',label),control=document.createElement(type==='textarea'?'textarea':'input');control.dataset.field=name;if(type==='textarea')control.rows=4;else control.type=type;wrap.append(title,control);return wrap};
const actions=(card,onMove,onRemove)=>{const box=make('div','structured-editor-actions');[['↑','Subir',-1],['↓','Bajar',1]].forEach(([symbol,label,delta])=>{const button=make('button','button outline',symbol);button.type='button';button.title=label;button.onclick=()=>onMove(card,delta);box.append(button)});const remove=make('button','button outline','Retirar');remove.type='button';remove.onclick=()=>onRemove(card);box.append(remove);return box};

function stopCard(data={},move,remove){
 const card=make('article','structured-editor-card route-stop-card'),head=make('div','structured-editor-head'),heading=make('strong','','Parada'),grid=make('div','form-grid');
 card.dataset.structuredCard='stop';head.append(heading,actions(card,move,remove));
 grid.append(
  input('title','Título de la parada'),input('title_en','Title in English'),
  input('short_description','Resumen público','textarea',true),input('short_description_en','Public summary in English','textarea',true),
  input('full_description','Descripción ampliada','textarea',true),input('full_description_en','Extended description in English','textarea',true),
  input('duration_minutes','Minutos aproximados','number'),input('practical_info','Información práctica','textarea'),
  input('accessibility','Accesibilidad de esta parada','textarea'),input('media_paths','Fotos o videos (una ruta o URL por línea)','textarea',true),
  input('image_alt','Texto alternativo de medios','textarea'),input('image_alt_en','Media alt text','textarea')
 );
 card.append(head,grid);
 Object.entries(data).forEach(([key,value])=>{const control=field(card,key);if(control)control.value=Array.isArray(value)?value.join('\n'):value??''});
 return card;
}

export function setupRouteProductEditor(root){
 const form=root.querySelector('[data-route-form]'),stopList=root.querySelector('[data-route-stop-list]');
 const move=(card,delta)=>{const sibling=delta<0?card.previousElementSibling:card.nextElementSibling;if(sibling)delta<0?card.parentElement.insertBefore(card,sibling):card.parentElement.insertBefore(sibling,card)};
 const remove=card=>{if(confirm('¿Retirar esta parada del borrador?'))card.remove()};
 const addStop=data=>stopList.append(stopCard(data,move,remove));
 root.querySelector('[data-route-stop-add]')?.addEventListener('click',()=>addStop());
 const set=(name,value)=>{if(form.elements[name])form.elements[name].value=value??''};
 const check=(name,value)=>{if(form.elements[name])form.elements[name].checked=value!==false};
 const load=data=>{
  const profile=data?.product_profile||{},en=profile.translations?.en||{},settings=profile.page_settings||{};
  set('productShortDescription',profile.short_description);set('productLongDescription',profile.long_description);
  set('productHighlights',list(profile.highlights).join('\n'));set('productCategories',list(profile.categories).join(', '));
  set('productItinerary',profile.itinerary_summary);set('productMaxGroup',profile.max_group_size);set('productCutoff',profile.booking_cutoff_hours);
  set('productSchedule',profile.schedule_notes);set('productClosureDates',list(profile.closure_dates).join('\n'));
  set('productWhatToBring',list(profile.what_to_bring).join('\n'));set('productCancellation',profile.cancellation_policy);
  set('productPrivateNotes',profile.private_notes);set('meetingAddress',profile.meeting_address);set('meetingReference',profile.meeting_reference);
  set('meetingInstructions',profile.meeting_instructions);set('meetingTransport',profile.meeting_transport);
  set('productShortDescriptionEn',en.short_description);set('productLongDescriptionEn',en.long_description);
  set('productHighlightsEn',list(en.highlights).join('\n'));set('productItineraryEn',en.itinerary_summary);
  set('productScheduleEn',en.schedule_notes);set('meetingInstructionsEn',en.meeting_instructions);set('meetingTransportEn',en.meeting_transport);
  set('galleryMode',settings.gallery_mode||'carousel');set('stopsMediaMode',settings.stops_media_mode||'carousel');set('stopsDisplayMode',settings.stops_display_mode||'cards');
  check('showHighlights',settings.show_highlights);check('showMeetingPoint',settings.show_meeting_point);check('showAccessibility',settings.show_accessibility);
  stopList.innerHTML='';list(data?.stop_details).forEach(addStop);
 };
 const cards=()=>[...stopList.querySelectorAll('[data-structured-card]')].map(card=>Object.fromEntries([...card.querySelectorAll('[data-field]')].map(control=>[control.dataset.field,control.value.trim()])));
 const serialize=()=>{
  const stops=cards().map(item=>({...item,media_paths:lines(item.media_paths),translations:{en:{title:item.title_en,short_description:item.short_description_en,full_description:item.full_description_en,image_alt:item.image_alt_en}}}));
  const product={
   short_description:form.elements.productShortDescription.value.trim(),long_description:form.elements.productLongDescription.value.trim(),
   highlights:lines(form.elements.productHighlights.value),categories:String(form.elements.productCategories.value).split(',').map(value=>value.trim()).filter(Boolean),
   itinerary_summary:form.elements.productItinerary.value.trim(),max_group_size:form.elements.productMaxGroup.value,
   booking_cutoff_hours:form.elements.productCutoff.value,schedule_notes:form.elements.productSchedule.value.trim(),
   closure_dates:lines(form.elements.productClosureDates.value),what_to_bring:lines(form.elements.productWhatToBring.value),
   cancellation_policy:form.elements.productCancellation.value.trim(),private_notes:form.elements.productPrivateNotes.value.trim(),
   meeting_address:form.elements.meetingAddress.value.trim(),meeting_reference:form.elements.meetingReference.value.trim(),
   meeting_instructions:form.elements.meetingInstructions.value.trim(),meeting_transport:form.elements.meetingTransport.value.trim(),
   page_settings:{gallery_mode:form.elements.galleryMode.value,stops_media_mode:form.elements.stopsMediaMode.value,stops_display_mode:form.elements.stopsDisplayMode.value,show_highlights:form.elements.showHighlights.checked,show_meeting_point:form.elements.showMeetingPoint.checked,show_accessibility:form.elements.showAccessibility.checked},
   translations:{en:{short_description:form.elements.productShortDescriptionEn.value.trim(),long_description:form.elements.productLongDescriptionEn.value.trim(),highlights:lines(form.elements.productHighlightsEn.value),itinerary_summary:form.elements.productItineraryEn.value.trim(),schedule_notes:form.elements.productScheduleEn.value.trim(),meeting_instructions:form.elements.meetingInstructionsEn.value.trim(),meeting_transport:form.elements.meetingTransportEn.value.trim()}}
  };
  return{product,stops,variants:[]};
 };
 return{load,serialize};
}
