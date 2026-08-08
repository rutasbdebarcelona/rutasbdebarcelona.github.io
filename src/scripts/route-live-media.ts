const root = document.querySelector<HTMLElement>('[data-route-live]');

interface RouteMediaItem {
  kind: 'image' | 'video' | 'document' | 'audio' | 'map';
  role: 'hero' | 'gallery' | 'attachment';
  storage_path: string;
  title?: string | null;
  alt_text?: string | null;
  mime_type?: string | null;
  sort_order: number;
  status: 'published';
}

if (root) {
  const url = root.dataset.supabaseUrl;
  const key = root.dataset.supabaseKey;
  const slug = root.dataset.routeSlug;
  if (url && key && slug) {
    const endpoint = new URL(`${url}/rest/v1/routes`);
    endpoint.searchParams.set('select','primary_image_path,primary_image_alt,route_media(id,kind,role,storage_path,title,alt_text,mime_type,sort_order,status)');
    endpoint.searchParams.set('slug', `eq.${slug}`);
    endpoint.searchParams.set('route_media.status', 'eq.published');
    const assetUrl = (storagePath: string) => {
      if (/^https?:/i.test(storagePath)) return storagePath;
      if (storagePath.startsWith('/')) return new URL(storagePath, window.location.origin).toString();
      const encodedPath = storagePath.split('/').map(encodeURIComponent).join('/');
      return new URL(`${url}/storage/v1/object/public/route-media/${encodedPath}`).toString();
    };
    fetch(endpoint, {headers: { apikey: key, Authorization: `Bearer ${key}` }})
      .then((response) => {if (!response.ok) throw new Error('route_media_request_failed');return response.json();})
      .then(([route]) => {
        if (!route) return;
        const hero = root.querySelector<HTMLImageElement>('[data-route-hero-image]');
        if (hero && route.primary_image_path) {hero.src=assetUrl(route.primary_image_path);hero.alt=route.primary_image_alt||hero.alt;}
        const media: RouteMediaItem[] = (Array.isArray(route.route_media)?route.route_media:[]).filter((item:RouteMediaItem)=>item.status==='published');
        const gallery=media.filter(item=>(item.kind==='image'||item.kind==='video')&&item.role==='gallery').sort((a,b)=>a.sort_order-b.sort_order);
        const documents=media.filter(item=>item.role==='attachment').sort((a,b)=>a.sort_order-b.sort_order);
        const gallerySection=root.querySelector<HTMLElement>('[data-route-gallery]'),galleryList=root.querySelector<HTMLElement>('[data-route-gallery-list]');
        if(gallerySection&&galleryList&&gallery.length){galleryList.replaceChildren();gallery.forEach(item=>{const figure=document.createElement('figure');if(item.kind==='video'){const video=document.createElement('video');video.src=assetUrl(item.storage_path);video.controls=true;video.preload='metadata';video.playsInline=true;video.setAttribute('aria-label',item.alt_text||item.title||'Video de la ruta');figure.append(video);}else{const image=document.createElement('img');image.src=assetUrl(item.storage_path);image.alt=item.alt_text||'';image.loading='lazy';figure.append(image);}if(item.title){const caption=document.createElement('figcaption');caption.textContent=item.title;figure.append(caption);}galleryList.append(figure);});gallerySection.hidden=false;}
        const documentSection=root.querySelector<HTMLElement>('[data-route-documents]'),documentList=root.querySelector<HTMLElement>('[data-route-document-list]');
        if(documentSection&&documentList&&documents.length){documentList.replaceChildren();documents.forEach(item=>{const link=document.createElement('a');link.href=assetUrl(item.storage_path);link.target='_blank';link.rel='noopener';link.textContent=`${item.kind==='audio'?'Escuchar':'Abrir'}: ${item.title||'Documento de la ruta'}`;documentList.append(link);});documentSection.hidden=false;}
      })
      .catch(()=>{/* La versión estática publicada permanece disponible como respaldo. */});
  }
}