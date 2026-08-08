create table if not exists public.editorial_posts(
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check(slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  status text not null default 'draft' check(status in('draft','published','archived')),
  title_es text not null default '', title_en text not null default '',
  excerpt_es text not null default '', excerpt_en text not null default '',
  body_es text not null default '', body_en text not null default '',
  seo_title_es text not null default '', seo_title_en text not null default '',
  seo_description_es text not null default '', seo_description_en text not null default '',
  cover_url text not null default '', cover_alt_es text not null default '', cover_alt_en text not null default '',
  tags text[] not null default '{}',
  published_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), created_by uuid default auth.uid()
);
alter table public.editorial_posts enable row level security;
drop policy if exists admin_editorial_posts on public.editorial_posts;
create policy admin_editorial_posts on public.editorial_posts for all to authenticated using(public.is_active_admin()) with check(public.is_active_admin());
drop policy if exists public_editorial_posts on public.editorial_posts;
create policy public_editorial_posts on public.editorial_posts for select to anon,authenticated using(status='published');
create or replace function public.touch_editorial_post() returns trigger language plpgsql as $$begin new.updated_at=now();if new.status='published' and new.published_at is null then new.published_at=now();end if;return new;end$$;
drop trigger if exists editorial_posts_touch on public.editorial_posts;
create trigger editorial_posts_touch before insert or update on public.editorial_posts for each row execute function public.touch_editorial_post();
