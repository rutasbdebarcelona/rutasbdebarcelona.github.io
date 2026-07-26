const root = document.querySelector<HTMLElement>('[data-route-live]');

interface RouteMediaItem {
  kind: 'image' | 'document' | 'audio' | 'map';
  role: 'hero' | 'gallery' | 'attachment';
  storage_path: string;
  title?: string | null;
  alt_text?: string | null;
  sort_order: number;
}

if (root) {
  const url = root.dataset.supabaseUrl;
  const key = root.dataset.supabaseKey;
  const slug = root.dataset.routeSlug;

  if (url && key && slug) {
    const endpoint = new URL(`${url}/rest/v1/routes`);
    endpoint.searchParams.set(
      'select',
      'primary_image_path,primary_image_alt,route_media(id,kind,role,storage_path,title,alt_text,mime_type,sort_order,status)',
    );
    endpoint.searchParams.set('slug', `eq.${slug}`);

    fetch(endpoint, {
      headers: { apikey: key, Authorization: `Bearer ${key}` },
    })
      .then((response) => {
        if (!response.ok) throw new Error('route_media_request_failed');
        return response.json();
      })
      .then(([route]) => {
        if (!route) return;

        const assetUrl = (path: string, downloadName = '') => {
          const encodedPath = path.split('/').map(encodeURIComponent).join('/');
          const asset = new URL(`${url}/storage/v1/object/public/route-media/${encodedPath}`);
          if (downloadName) asset.searchParams.set('download', downloadName);
          return asset.toString();
        };

        const hero = root.querySelector<HTMLImageElement>('[data-route-hero-image]');
        if (hero && route.primary_image_path) {
          hero.src = /^https?:/i.test(route.primary_image_path)
            ? route.primary_image_path
            : route.primary_image_path.startsWith('/')
              ? new URL(route.primary_image_path, window.location.origin).toString()
              : assetUrl(route.primary_image_path);
          hero.alt = route.primary_image_alt || hero.alt;
        }

        const media: RouteMediaItem[] = Array.isArray(route.route_media) ? route.route_media : [];
        const gallery = media
          .filter((item) => item.kind === 'image' && item.role === 'gallery')
          .sort((a, b) => a.sort_order - b.sort_order);
        const documents = media
          .filter((item) => item.role === 'attachment')
          .sort((a, b) => a.sort_order - b.sort_order);

        const gallerySection = root.querySelector<HTMLElement>('[data-route-gallery]');
        const galleryList = root.querySelector<HTMLElement>('[data-route-gallery-list]');
        if (gallerySection && galleryList) {
          galleryList.replaceChildren();
          gallery.forEach((item) => {
            const figure = document.createElement('figure');
            const image = document.createElement('img');
            image.src = assetUrl(item.storage_path);
            image.alt = item.alt_text || '';
            image.loading = 'lazy';
            figure.append(image);
            if (item.title) {
              const caption = document.createElement('figcaption');
              caption.textContent = item.title;
              figure.append(caption);
            }
            galleryList.append(figure);
          });
          gallerySection.hidden = gallery.length === 0;
        }

        const documentSection = root.querySelector<HTMLElement>('[data-route-documents]');
        const documentList = root.querySelector<HTMLElement>('[data-route-document-list]');
        if (documentSection && documentList) {
          documentList.replaceChildren();
          documents.forEach((item) => {
            const link = document.createElement('a');
            const title = item.title || 'Documento de la ruta';
            const extension = item.storage_path.match(/\.([a-z0-9]{2,8})$/i)?.[1];
            const downloadName = /\.[a-z0-9]{2,8}$/i.test(title) || !extension ? title : title + '.' + extension;
            link.href = assetUrl(item.storage_path, downloadName);
            link.target = '_blank';
            link.rel = 'noopener';
            link.textContent = `${item.kind === 'audio' ? 'Escuchar' : 'Descargar'}: ${title}`;
            documentList.append(link);
          });
          documentSection.hidden = documents.length === 0;
        }
      })
      .catch(() => {
        // La versión estática publicada permanece disponible como respaldo.
      });
  }
}
