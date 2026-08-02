-- Product workbench: structured route content remains in route_drafts until explicit publication.
-- Existing public routes, bookings and schedules are not changed by this migration.

create table if not exists public.route_product_profiles (
  route_id uuid primary key references public.routes(id) on delete cascade,
  short_description text,
  long_description text,
  highlights text[] not null default '{}',
  categories text[] not null default '{}',
  itinerary_summary text,
  booking_cutoff_hours integer check (booking_cutoff_hours is null or booking_cutoff_hours between 0 and 8760),
  closure_dates date[] not null default '{}',
  max_group_size integer check (max_group_size is null or max_group_size between 1 and 50),
  meeting_address text,
  meeting_reference text,
  meeting_instructions text,
  meeting_transport text,
  what_to_bring text[] not null default '{}',
  cancellation_policy text,
  private_notes text,
  translations jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.route_stops
  add column if not exists short_description text,
  add column if not exists full_description text,
  add column if not exists duration_minutes integer,
  add column if not exists practical_info text,
  add column if not exists accessibility text,
  add column if not exists latitude numeric(9,6),
  add column if not exists longitude numeric(9,6),
  add column if not exists image_path text,
  add column if not exists image_alt text,
  add column if not exists translations jsonb not null default '{}'::jsonb;

create table if not exists public.route_commercial_variants (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references public.routes(id) on delete cascade,
  variant_key text not null,
  kind text not null default 'custom' check (kind in ('day','night','seasonal','private','custom')),
  title text not null,
  short_description text,
  full_description text,
  duration_minutes integer check (duration_minutes is null or duration_minutes > 0),
  schedule_notes text,
  meeting_override text,
  active boolean not null default false,
  sort_order integer not null default 0,
  translations jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(route_id,variant_key)
);

alter table public.route_product_profiles enable row level security;
alter table public.route_commercial_variants enable row level security;
drop policy if exists admin_route_product_profiles on public.route_product_profiles;
create policy admin_route_product_profiles on public.route_product_profiles using(public.is_active_admin()) with check(public.is_active_admin());
drop policy if exists public_route_product_profiles on public.route_product_profiles;
drop policy if exists admin_route_commercial_variants on public.route_commercial_variants;
create policy admin_route_commercial_variants on public.route_commercial_variants using(public.is_active_admin()) with check(public.is_active_admin());
drop policy if exists public_route_commercial_variants on public.route_commercial_variants;
create policy public_route_commercial_variants on public.route_commercial_variants for select using(active and exists(select 1 from public.routes r where r.id=route_id and r.status='published'));
grant select,insert,update,delete on public.route_product_profiles,public.route_commercial_variants to authenticated;
revoke all on public.route_product_profiles from anon;
grant select on public.route_commercial_variants to anon;

create or replace function public.save_route_product_draft(p_route_id uuid,p_product jsonb,p_stops jsonb,p_variants jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_content jsonb;
begin
  if not public.is_active_admin() then raise exception 'admin_access_required' using errcode='42501'; end if;
  if not exists(select 1 from public.routes where id=p_route_id) then raise exception 'route_not_found' using errcode='P0002'; end if;
  if jsonb_typeof(coalesce(p_stops,'[]'::jsonb))<>'array' or jsonb_typeof(coalesce(p_variants,'[]'::jsonb))<>'array' then raise exception 'invalid_product_structure' using errcode='22023'; end if;
  insert into public.route_drafts(route_id,content)
  values(p_route_id,jsonb_build_object('product_profile',coalesce(p_product,'{}'::jsonb),'stop_details',coalesce(p_stops,'[]'::jsonb),'commercial_variants',coalesce(p_variants,'[]'::jsonb)))
  on conflict(route_id) do update set content=public.route_drafts.content||excluded.content,updated_at=now()
  returning content into v_content;
  insert into public.audit_log(admin_id,action,entity_type,entity_id,details) values(auth.uid(),'route_product_draft_saved','route',p_route_id::text,jsonb_build_object('draft_only',true));
  return v_content;
end $$;

create or replace function public.publish_route_product_draft(p_route_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v_draft jsonb;v_product jsonb;v_stop jsonb;v_variant jsonb;v_i integer:=0;
begin
  if not public.is_active_admin() then raise exception 'admin_access_required' using errcode='42501'; end if;
  select content into v_draft from public.route_drafts where route_id=p_route_id for update;
  if v_draft is null then return; end if;
  v_product:=coalesce(v_draft->'product_profile','{}'::jsonb);
  if v_draft ? 'product_profile' then
    insert into public.route_product_profiles(route_id,short_description,long_description,highlights,categories,itinerary_summary,booking_cutoff_hours,closure_dates,max_group_size,meeting_address,meeting_reference,meeting_instructions,meeting_transport,what_to_bring,cancellation_policy,private_notes,translations)
    values(p_route_id,nullif(trim(v_product->>'short_description'),''),nullif(trim(v_product->>'long_description'),''),array(select jsonb_array_elements_text(coalesce(v_product->'highlights','[]'))),array(select jsonb_array_elements_text(coalesce(v_product->'categories','[]'))),nullif(trim(v_product->>'itinerary_summary'),''),nullif(v_product->>'booking_cutoff_hours','')::integer,array(select value::date from jsonb_array_elements_text(coalesce(v_product->'closure_dates','[]'))),nullif(v_product->>'max_group_size','')::integer,nullif(trim(v_product->>'meeting_address'),''),nullif(trim(v_product->>'meeting_reference'),''),nullif(trim(v_product->>'meeting_instructions'),''),nullif(trim(v_product->>'meeting_transport'),''),array(select jsonb_array_elements_text(coalesce(v_product->'what_to_bring','[]'))),nullif(trim(v_product->>'cancellation_policy'),''),nullif(trim(v_product->>'private_notes'),''),coalesce(v_product->'translations','{}'))
    on conflict(route_id) do update set short_description=excluded.short_description,long_description=excluded.long_description,highlights=excluded.highlights,categories=excluded.categories,itinerary_summary=excluded.itinerary_summary,booking_cutoff_hours=excluded.booking_cutoff_hours,closure_dates=excluded.closure_dates,max_group_size=excluded.max_group_size,meeting_address=excluded.meeting_address,meeting_reference=excluded.meeting_reference,meeting_instructions=excluded.meeting_instructions,meeting_transport=excluded.meeting_transport,what_to_bring=excluded.what_to_bring,cancellation_policy=excluded.cancellation_policy,private_notes=excluded.private_notes,translations=excluded.translations,updated_at=now();
  end if;
  if v_draft ? 'stop_details' then
    delete from public.route_stops where route_id=p_route_id;
    for v_stop in select value from jsonb_array_elements(coalesce(v_draft->'stop_details','[]')) loop
      if nullif(trim(v_stop->>'title'),'') is not null then
        insert into public.route_stops(route_id,title,sort_order,short_description,full_description,duration_minutes,practical_info,accessibility,latitude,longitude,image_path,image_alt,translations)
        values(p_route_id,trim(v_stop->>'title'),v_i,nullif(trim(v_stop->>'short_description'),''),nullif(trim(v_stop->>'full_description'),''),nullif(v_stop->>'duration_minutes','')::integer,nullif(trim(v_stop->>'practical_info'),''),nullif(trim(v_stop->>'accessibility'),''),nullif(v_stop->>'latitude','')::numeric,nullif(v_stop->>'longitude','')::numeric,nullif(trim(v_stop->>'image_path'),''),nullif(trim(v_stop->>'image_alt'),''),coalesce(v_stop->'translations','{}'));v_i:=v_i+1;
      end if;
    end loop;
  end if;
  if v_draft ? 'commercial_variants' then
    delete from public.route_commercial_variants where route_id=p_route_id;
    v_i:=0;
    for v_variant in select value from jsonb_array_elements(coalesce(v_draft->'commercial_variants','[]')) loop
      if nullif(trim(v_variant->>'title'),'') is not null then
        insert into public.route_commercial_variants(route_id,variant_key,kind,title,short_description,full_description,duration_minutes,schedule_notes,meeting_override,active,sort_order,translations)
        values(p_route_id,coalesce(nullif(trim(v_variant->>'variant_key'),''),'variant-'||v_i),coalesce(nullif(v_variant->>'kind',''),'custom'),trim(v_variant->>'title'),nullif(trim(v_variant->>'short_description'),''),nullif(trim(v_variant->>'full_description'),''),nullif(v_variant->>'duration_minutes','')::integer,nullif(trim(v_variant->>'schedule_notes'),''),nullif(trim(v_variant->>'meeting_override'),''),coalesce((v_variant->>'active')::boolean,false),v_i,coalesce(v_variant->'translations','{}'));v_i:=v_i+1;
      end if;
    end loop;
  end if;
end $$;

create or replace function public.publish_route_complete(p_route_id uuid)
returns public.routes language plpgsql security definer set search_path=public as $$
declare v_result public.routes;v_structured jsonb;
begin
  if not public.is_active_admin() then raise exception 'admin_access_required' using errcode='42501'; end if;
  select content into v_structured from public.route_drafts where route_id=p_route_id for update;
  select * into v_result from public.publish_route_draft(p_route_id);
  if v_structured ? 'product_profile' or v_structured ? 'stop_details' or v_structured ? 'commercial_variants' then
    insert into public.route_drafts(route_id,content) values(p_route_id,v_structured) on conflict(route_id) do update set content=excluded.content,updated_at=now();
    perform public.publish_route_product_draft(p_route_id);
    delete from public.route_drafts where route_id=p_route_id;
  end if;
  return v_result;
end $$;

revoke all on function public.save_route_product_draft(uuid,jsonb,jsonb,jsonb),public.publish_route_product_draft(uuid),public.publish_route_complete(uuid) from public,anon;
grant execute on function public.save_route_product_draft(uuid,jsonb,jsonb,jsonb),public.publish_route_product_draft(uuid),public.publish_route_complete(uuid) to authenticated;

-- Editable message taxonomy: old message keys remain valid for history, while active choices drive new forms.
create table if not exists public.message_types(
  key text primary key check(key~'^[a-z0-9-]+$'),label_es text not null,label_en text not null,description_es text,description_en text,active boolean not null default true,sort_order integer not null default 0,created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
insert into public.message_types(key,label_es,label_en,sort_order) values
 ('general','Consulta general','General enquiry',10),('partner','Hotel, agencia o partner','Hotel, agency or partner',20),('private','Grupo privado','Private group',30),('press','Prensa o colaboración','Press or collaboration',40)
on conflict(key) do nothing;
alter table public.message_types enable row level security;
drop policy if exists public_message_types on public.message_types;create policy public_message_types on public.message_types for select using(active or public.is_active_admin());
drop policy if exists admin_message_types on public.message_types;create policy admin_message_types on public.message_types for all using(public.is_active_admin()) with check(public.is_active_admin());
grant select on public.message_types to anon,authenticated;grant insert,update on public.message_types to authenticated;
alter table public.messages drop constraint if exists messages_inquiry_type_check;

create or replace function public.save_message_type(p_key text,p_label_es text,p_label_en text,p_description_es text,p_description_en text,p_active boolean,p_sort_order integer)
returns public.message_types language plpgsql security definer set search_path=public as $$
declare v_result public.message_types;
begin
 if not public.is_active_admin() then raise exception 'admin_access_required' using errcode='42501';end if;
 if p_key!~'^[a-z0-9-]+$' or char_length(trim(p_label_es))<2 or char_length(trim(p_label_en))<2 then raise exception 'invalid_message_type' using errcode='22023';end if;
 insert into public.message_types(key,label_es,label_en,description_es,description_en,active,sort_order) values(p_key,trim(p_label_es),trim(p_label_en),nullif(trim(p_description_es),''),nullif(trim(p_description_en),''),p_active,greatest(0,p_sort_order))
 on conflict(key) do update set label_es=excluded.label_es,label_en=excluded.label_en,description_es=excluded.description_es,description_en=excluded.description_en,active=excluded.active,sort_order=excluded.sort_order,updated_at=now() returning * into v_result;return v_result;
end $$;
revoke all on function public.save_message_type(text,text,text,text,text,boolean,integer) from public,anon;grant execute on function public.save_message_type(text,text,text,text,text,boolean,integer) to authenticated;

create or replace function public.submit_contact_message(payload jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_customer public.customers;v_message public.messages;v_name text:=trim(payload->>'name');v_email text:=lower(trim(payload->>'email'));v_body text:=trim(payload->>'message');v_type text:=coalesce(payload->>'type','general');v_locale text:=coalesce(payload->>'locale','es');
begin
 if coalesce(payload->>'website','')<>'' then raise exception 'invalid_request';end if;if coalesce((payload->>'privacy')::boolean,false) is not true then raise exception 'privacy_required';end if;if char_length(v_name) not between 2 and 120 then raise exception 'invalid_name';end if;if v_email is null or v_email!~'^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'invalid_email';end if;if char_length(v_body) not between 2 and 3000 then raise exception 'invalid_message';end if;if v_locale not in('es','en') or not exists(select 1 from public.message_types where key=v_type and active) then raise exception 'invalid_option';end if;
 insert into public.customers(full_name,email) values(v_name,v_email) on conflict(email) do update set full_name=excluded.full_name,updated_at=now() returning * into v_customer;
 select * into v_message from public.messages where customer_id=v_customer.id and body=v_body and created_at>now()-interval '5 minutes' order by created_at desc limit 1;if found then return jsonb_build_object('ok',true,'duplicate',true,'message_id',v_message.id);end if;
 insert into public.messages(customer_id,subject,body,inquiry_type,locale) values(v_customer.id,case when v_locale='en' then 'Website enquiry' else 'Consulta desde la web' end,v_body,v_type,v_locale) returning * into v_message;return jsonb_build_object('ok',true,'duplicate',false,'message_id',v_message.id);
end $$;
revoke all on function public.submit_contact_message(jsonb) from public;grant execute on function public.submit_contact_message(jsonb) to anon,authenticated;
