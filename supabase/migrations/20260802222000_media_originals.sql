-- Private source files for the reusable media corrector.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('media-originals','media-originals',false,26214400,array['image/jpeg','image/png','image/webp','image/avif','image/gif'])
on conflict (id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists "media originals admin select" on storage.objects;
create policy "media originals admin select" on storage.objects for select to authenticated
using (bucket_id='media-originals' and public.is_active_admin());

drop policy if exists "media originals admin insert" on storage.objects;
create policy "media originals admin insert" on storage.objects for insert to authenticated
with check (bucket_id='media-originals' and public.is_active_admin());

drop policy if exists "media originals admin delete" on storage.objects;
create policy "media originals admin delete" on storage.objects for delete to authenticated
using (bucket_id='media-originals' and public.is_active_admin());
