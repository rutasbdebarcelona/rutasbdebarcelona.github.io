import { supabase, supabaseConfigured } from './supabase';

export type ReviewPayload={reference:string;email:string;displayName:string;rating:number;body:string;privacy:boolean;website?:string};

export async function getPublishedReviews(){
  if(!supabaseConfigured||!supabase)return [];
  const {data,error}=await supabase.from('reviews').select('id,display_name,rating,body,published_at,routes(title,slug)').eq('status','published').order('published_at',{ascending:false}).limit(50);
  if(error)throw error;
  return data??[];
}

export async function submitVerifiedReview(input:ReviewPayload){
  if(!supabaseConfigured||!supabase)throw new Error('service_unavailable');
  const payload={reference:input.reference,email:input.email,display_name:input.displayName,rating:input.rating,body:input.body,privacy:input.privacy,website:input.website||''};
  const {data,error}=await supabase.rpc('submit_verified_review',{payload});
  if(error)throw error;
  return data;
}
