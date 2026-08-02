import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type'};
const json = (body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,'Content-Type':'application/json'}});
const esc = (value:unknown)=>String(value??'').replace(/[&<>"']/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[char]!));

Deno.serve(async request=>{
  if(request.method==='OPTIONS')return new Response('ok',{headers:cors});
  if(request.method!=='POST')return json({error:'method_not_allowed'},405);
  const supabaseUrl=Deno.env.get('SUPABASE_URL');
  const serviceKey=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if(!supabaseUrl||!serviceKey)return json({error:'server_not_configured'},500);
  const {messageId}=await request.json().catch(()=>({}));
  if(!messageId)return json({error:'message_id_required'},400);
  const supabase=createClient(supabaseUrl,serviceKey,{auth:{persistSession:false}});
  const {data:message,error:claimError}=await supabase.rpc('claim_message_notification',{p_message_id:messageId});
  if(claimError)return json({error:'notification_claim_failed'},500);
  if(!message)return json({ok:true,alreadyProcessed:true});
  const resendKey=Deno.env.get('RESEND_API_KEY');
  const recipient=Deno.env.get('BOOKING_NOTIFICATION_EMAIL');
  const from=Deno.env.get('BOOKING_NOTIFICATION_FROM')||'Rutas B <onboarding@resend.dev>';
  if(!resendKey||!recipient){await supabase.rpc('release_message_notification',{p_message_id:messageId});return json({error:'email_not_configured'},500);}
  const labels:Record<string,string>={general:'Consulta general',partner:'Hotel / agencia / partner',private:'Grupo privado',press:'Prensa / colaboración'};
  const subject=`Nuevo mensaje web · ${message.customer_name}`;
  const html=`<div style="font-family:Arial,sans-serif;color:#15251f;line-height:1.6;max-width:640px"><h1 style="font-family:Georgia,serif">Nuevo mensaje desde Rutas B</h1><p><strong>Tipo:</strong> ${esc(labels[message.inquiry_type]||message.inquiry_type)}</p><p><strong>Nombre:</strong> ${esc(message.customer_name)}</p><p><strong>Correo:</strong> ${esc(message.customer_email)}</p><p><strong>Idioma:</strong> ${message.locale==='en'?'English':'Castellano'}</p><div style="background:#f3efe7;padding:20px;margin:22px 0;white-space:pre-wrap">${esc(message.body)}</div><p>El mensaje también está disponible en el panel privado de Rutas B.</p></div>`;
  const response=await fetch('https://api.resend.com/emails',{method:'POST',headers:{Authorization:`Bearer ${resendKey}`,'Content-Type':'application/json'},body:JSON.stringify({from,to:[recipient],reply_to:message.customer_email,subject,html})});
  if(!response.ok){await supabase.rpc('release_message_notification',{p_message_id:messageId});return json({error:'email_delivery_failed'},502);}
  await supabase.rpc('complete_message_notification',{p_message_id:messageId});
  return json({ok:true});
});
