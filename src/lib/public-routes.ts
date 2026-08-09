import {createClient} from '@supabase/supabase-js';
import {publishedRoutes as fallbackRoutes,type TourRoute,type RouteStop} from '../data/routes';

const defaults={galleryMode:'grid',stopsMediaMode:'carousel',stopsDisplayMode:'cards',showHighlights:true,showMeetingPoint:true,showAccessibility:true,showLongDescription:true};

export async function getPublicRoutes():Promise<TourRoute[]>{
 const url=import.meta.env.PUBLIC_SUPABASE_URL,key=import.meta.env.PUBLIC_SUPABASE_PUBLISHABLE_KEY;
 if(!url||!key)return fallbackRoutes;
 const client=createClient(url,key);
 const {data,error}=await client.from('routes').select('slug,title,short_description,full_description,offered_languages,meeting_point_public,accessibility,includes,excludes,featured,eyebrow,promise,status_label,display_duration,display_format,display_area,display_starting_point,display_ending_point,audience,display_price_individual,display_price_group,primary_image_path,primary_image_alt,route_stops(title,sort_order,short_description,full_description,duration_minutes,practical_info,accessibility,media_paths,image_path,image_alt,translations),route_translations(*),route_product_profiles(short_description,long_description,highlights,itinerary_summary,schedule_notes,meeting_address,meeting_reference,meeting_instructions,meeting_transport,page_settings,translations),route_media(id,kind,role,storage_path,title,alt_text,mime_type,sort_order,status)').eq('status','published').order('sort_order');
 if(error||!data?.length)return fallbackRoutes;
 const publicUrl=(path:string,download:boolean|string=false)=>!path||path.startsWith('/')||/^https?:/i.test(path)?path:client.storage.from('route-media').getPublicUrl(path,download?{download}:undefined).data.publicUrl;
 const mapStop=(stop:any,locale='es'):RouteStop=>{
  const translation=locale==='en'?(stop.translations?.en||{}):{};
  const paths=(stop.media_paths||[]).map((path:string)=>publicUrl(path));
  if(!paths.length&&stop.image_path)paths.push(publicUrl(stop.image_path));
  return{title:translation.title||stop.title,shortDescription:translation.short_description||stop.short_description||'',fullDescription:translation.full_description||stop.full_description||'',durationMinutes:stop.duration_minutes||undefined,practicalInfo:translation.practical_info||stop.practical_info||'',accessibility:translation.accessibility||stop.accessibility||'',media:paths,imageAlt:translation.image_alt||stop.image_alt||translation.title||stop.title};
 };
 return data.map((route:any)=>{
  const profile=Array.isArray(route.route_product_profiles)?route.route_product_profiles[0]:route.route_product_profiles||{},profileEn=profile?.translations?.en||{};
  const orderedStops=[...(route.route_stops||[])].sort((a:any,b:any)=>a.sort_order-b.sort_order);
  const gallery=(route.route_media||[]).filter((item:any)=>['image','video'].includes(item.kind)&&item.role==='gallery'&&['published','pending_removal'].includes(item.status)).sort((a:any,b:any)=>a.sort_order-b.sort_order).map((item:any)=>({id:item.id,kind:item.kind,role:item.role,url:publicUrl(item.storage_path),title:item.title||'',altText:item.alt_text||route.title,mimeType:item.mime_type}));
  const documents=(route.route_media||[]).filter((item:any)=>item.role==='attachment'&&['published','pending_removal'].includes(item.status)).sort((a:any,b:any)=>a.sort_order-b.sort_order).map((item:any)=>({id:item.id,kind:item.kind,role:item.role,url:publicUrl(item.storage_path),title:item.title||'Documento de la ruta',altText:item.alt_text||'',mimeType:item.mime_type}));
  const translation=(route.route_translations||[]).find((item:any)=>item.locale==='en');
  const settings=profile?.page_settings||{};
  return{
   slug:route.slug,title:route.title,eyebrow:route.eyebrow||'',promise:route.promise||route.short_description||profile?.short_description||'',
   description:profile?.long_description||route.full_description||'',status:['Ruta inicial','Disponible'].includes(route.status_label)?'available':'in-development',
   statusLabel:route.status_label||'En preparación',duration:route.display_duration||'Pendiente de definición',format:route.display_format||'Pendiente de definición',
   area:route.display_area||'',languages:(route.offered_languages||[]).map((code:string)=>code==='es'?'Español':code==='en'?'English':code),audience:route.audience||[],
   startingPoint:route.display_starting_point||route.meeting_point_public||'',endingPoint:route.display_ending_point||'',stops:orderedStops.map((stop:any)=>stop.title),
   stopDetails:orderedStops.map((stop:any)=>mapStop(stop)),highlights:profile?.highlights||[],includes:route.includes||[],notIncluded:route.excludes||[],
   accessibility:route.accessibility||'',priceIndividual:route.display_price_individual||'',priceGroup:route.display_price_group||'',
   image:publicUrl(route.primary_image_path||''),imageAlt:route.primary_image_alt||route.title,gallery,documents,
   meetingAddress:profile?.meeting_address||'',meetingMapUrl:profile?.page_settings?.meeting_map_url||'',meetingReference:profile?.meeting_reference||'',meetingInstructions:profile?.meeting_instructions||'',meetingTransport:profile?.meeting_transport||'',
   scheduleNotes:profile?.schedule_notes||'',pageSettings:{...defaults,galleryMode:settings.gallery_mode||defaults.galleryMode,stopsMediaMode:settings.stops_media_mode||defaults.stopsMediaMode,stopsDisplayMode:settings.stops_display_mode||defaults.stopsDisplayMode,showHighlights:settings.show_highlights!==false,showMeetingPoint:settings.show_meeting_point!==false,showAccessibility:settings.show_accessibility!==false,showLongDescription:settings.show_long_description!==false},
   translationEn:translation?{title:translation.title,eyebrow:translation.eyebrow||'',promise:translation.promise||profileEn.short_description||'',description:profileEn.long_description||translation.full_description||'',statusLabel:translation.status_label||'',duration:translation.display_duration||'',format:translation.display_format||'',area:translation.display_area||'',languages:translation.offered_languages||[],audience:translation.audience||[],startingPoint:translation.display_starting_point||'',endingPoint:translation.display_ending_point||'',stops:translation.stops?.length?translation.stops:orderedStops.map((stop:any)=>mapStop(stop,'en').title),stopDetails:orderedStops.map((stop:any)=>mapStop(stop,'en')),highlights:profileEn.highlights||profile?.highlights||[],includes:translation.includes||[],notIncluded:translation.excludes||[],accessibility:translation.accessibility||'',priceIndividual:route.display_price_individual||'',priceGroup:route.display_price_group||'',meetingAddress:profile?.meeting_address||'',meetingMapUrl:profile?.page_settings?.meeting_map_url||'',meetingReference:profile?.meeting_reference||'',meetingInstructions:profileEn.meeting_instructions||profile?.meeting_instructions||'',meetingTransport:profileEn.meeting_transport||profile?.meeting_transport||'',scheduleNotes:profileEn.schedule_notes||profile?.schedule_notes||''}:undefined,
   featured:route.featured,published:true
  } as TourRoute;
 });
}
