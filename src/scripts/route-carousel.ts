document.querySelectorAll<HTMLElement>('[data-route-carousel]').forEach(carousel=>{
 const track=carousel.querySelector<HTMLElement>('[data-carousel-track]'),previous=carousel.querySelector<HTMLButtonElement>('[data-carousel-prev]'),next=carousel.querySelector<HTMLButtonElement>('[data-carousel-next]');
 if(!track)return;
 const move=(direction:number)=>track.scrollBy({left:direction*Math.max(track.clientWidth*.82,280),behavior:'smooth'});
 previous?.addEventListener('click',()=>move(-1));next?.addEventListener('click',()=>move(1));
});
