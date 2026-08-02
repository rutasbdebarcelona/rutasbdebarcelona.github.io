import { supabase } from './supabase';

export async function uploadSiteImage(file:File){
  if(!supabase)throw new Error('Supabase no está configurado.');
  if(!file.type.startsWith('image/'))throw new Error('Selecciona una imagen JPG, PNG, WebP o AVIF.');
  if(file.size<=0||file.size>15728640)throw new Error('La imagen debe pesar menos de 15 MB.');
  const extension=(file.name.split('.').pop()||'webp').toLowerCase().replace(/[^a-z0-9]/g,'').slice(0,8)||'webp';
  const storagePath=`site/${crypto.randomUUID()}.${extension}`;
  const {error}=await supabase.storage.from('route-media').upload(storagePath,file,{contentType:file.type,upsert:false});
  if(error)throw error;
  return supabase.storage.from('route-media').getPublicUrl(storagePath).data.publicUrl;
}
