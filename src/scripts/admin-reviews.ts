// @ts-nocheck
import { getAdminReviews,setReviewStatus } from '../lib/admin';

export function setupAdminReviews(app){
  const $=selector=>app.querySelector(selector);
  async function load(){
    const box=$('[data-admin-reviews]'),error=$('[data-reviews-error]');
    if(!box)return;
    error.textContent='';box.innerHTML='';
    try{
      const reviews=await getAdminReviews();
      if(!reviews.length){box.innerHTML='<p class="admin-empty">Aún no hay reseñas.</p>';return;}
      reviews.forEach(review=>{
        const route=Array.isArray(review.routes)?review.routes[0]:review.routes,booking=Array.isArray(review.bookings)?review.bookings[0]:review.bookings,card=document.createElement('article');card.className='admin-review-card';
        const meta=document.createElement('div');meta.className='admin-review-meta';meta.innerHTML=`<span>${'★'.repeat(review.rating)}${'☆'.repeat(5-review.rating)}</span><span>${review.status==='pending'?'Pendiente':review.status==='published'?'Publicada':'Rechazada'}</span><span>${route?.title||'Ruta'}</span><span>${booking?.public_reference||'Sin referencia'}</span>`;
        const title=document.createElement('h3');title.textContent=review.display_name;const body=document.createElement('p');body.textContent=review.body;
        const actions=document.createElement('div');actions.className='admin-review-actions';
        for(const [status,label] of [['published','Publicar'],['rejected','Rechazar'],['pending','Dejar pendiente']]){const button=document.createElement('button');button.type='button';button.className=status==='published'?'button primary':'button outline';button.textContent=label;button.disabled=review.status===status;button.onclick=async()=>{button.disabled=true;try{await setReviewStatus(review.id,status);await load()}catch(x){error.textContent=x.message||'No fue posible actualizar la reseña.'}finally{button.disabled=false}};actions.append(button)}
        card.append(meta,title,body,actions);box.append(card);
      });
    }catch(x){error.textContent=x.message||'No fue posible cargar las reseñas.';}
  }
  $('[data-reviews-refresh]')?.addEventListener('click',load);
  return {load};
}
