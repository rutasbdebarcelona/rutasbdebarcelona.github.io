-- Close contact-message UX and connect bookings to real availability.
alter table public.messages add column if not exists inquiry_type text not null default 'general';
alter table public.messages add column if not exists locale text not null default 'es';
alter table public.schedules add column if not exists admin_open boolean not null default true;

do $$ begin
  if not exists(select 1 from pg_constraint where conname='messages_inquiry_type_check') then alter table public.messages add constraint messages_inquiry_type_check check(inquiry_type in ('general','partner','private','press')); end if;
  if not exists(select 1 from pg_constraint where conname='messages_locale_check') then alter table public.messages add constraint messages_locale_check check(locale in ('es','en')); end if;
end $$;

create or replace function public.submit_contact_message(payload jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_customer public.customers; v_message public.messages; v_name text:=trim(payload->>'name'); v_email text:=lower(trim(payload->>'email')); v_body text:=trim(payload->>'message'); v_type text:=coalesce(payload->>'type','general'); v_locale text:=coalesce(payload->>'locale','es');
begin
  if coalesce(payload->>'website','')<>'' then raise exception 'invalid_request'; end if;
  if coalesce((payload->>'privacy')::boolean,false) is not true then raise exception 'privacy_required'; end if;
  if char_length(v_name) not between 2 and 120 then raise exception 'invalid_name'; end if;
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'invalid_email'; end if;
  if char_length(v_body) not between 2 and 3000 then raise exception 'invalid_message'; end if;
  if v_type not in ('general','partner','private','press') or v_locale not in ('es','en') then raise exception 'invalid_option'; end if;
  insert into public.customers(full_name,email) values(v_name,v_email) on conflict(email) do update set full_name=excluded.full_name,updated_at=now() returning * into v_customer;
  select * into v_message from public.messages where customer_id=v_customer.id and body=v_body and created_at>now()-interval '5 minutes' order by created_at desc limit 1;
  if found then return jsonb_build_object('ok',true,'duplicate',true); end if;
  insert into public.messages(customer_id,subject,body,inquiry_type,locale) values(v_customer.id,case when v_locale='en' then 'Website enquiry' else 'Consulta desde la web' end,v_body,v_type,v_locale) returning * into v_message;
  return jsonb_build_object('ok',true,'duplicate',false);
end $$;

create or replace function public.mark_message_read(p_message_id uuid,p_read boolean default true)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;
  update public.messages set read_at=case when p_read then now() else null end where id=p_message_id;
end $$;

create or replace function public.admin_set_availability(p_route_id uuid,p_date date,p_time text,p_capacity integer,p_open boolean)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_variant uuid; v_start timestamptz; v_end timestamptz; v_duration integer; v_id uuid;
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;
  if p_date<=current_date or p_time not in ('10:00','12:00','18:00','22:00') or p_capacity not between 1 and 50 then raise exception 'invalid_slot'; end if;
  if p_time in ('10:00','12:00') and extract(isodow from p_date) not in (6,7) then raise exception 'weekend_only_slot'; end if;
  select id into v_variant from public.route_variants where route_id=p_route_id and name='Reserva web' limit 1;
  if v_variant is null then insert into public.route_variants(route_id,name,mode,active) values(p_route_id,'Reserva web','private',true) returning id into v_variant; end if;
  select coalesce(duration_minutes_max,90) into v_duration from public.routes where id=p_route_id;
  v_start := ((p_date::text||' '||p_time)::timestamp at time zone 'Europe/Madrid'); v_end:=v_start+make_interval(mins=>v_duration);
  insert into public.schedules(variant_id,starts_at,ends_at,capacity,available,admin_open) values(v_variant,v_start,v_end,p_capacity,p_open,p_open)
  on conflict(variant_id,starts_at) do update set ends_at=excluded.ends_at,capacity=greatest(excluded.capacity,public.schedules.reserved_places),admin_open=excluded.admin_open,available=excluded.admin_open and public.schedules.reserved_places<greatest(excluded.capacity,public.schedules.reserved_places)
  returning id into v_id; return v_id;
end $$;

create or replace function public.admin_generate_availability_month(p_route_id uuid,p_month date,p_capacity integer default 50)
returns integer language plpgsql security definer set search_path=public as $$
declare d date; t text; n integer:=0;
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;
  d:=date_trunc('month',p_month)::date;
  while d<(date_trunc('month',p_month)+interval '1 month')::date loop
    if d>current_date then
      foreach t in array(case when extract(isodow from d) in(6,7) then array['10:00','12:00','18:00','22:00'] else array['18:00','22:00'] end) loop perform public.admin_set_availability(p_route_id,d,t,p_capacity,true); n:=n+1; end loop;
    end if; d:=d+1;
  end loop; return n;
end $$;

create or replace function public.get_public_availability(p_route_slug text,p_from date,p_to date)
returns table(slot_date date,slot_time text,capacity integer,reserved_places integer) language sql stable security definer set search_path=public as $$
 select (s.starts_at at time zone 'Europe/Madrid')::date,to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI'),s.capacity,s.reserved_places
 from public.schedules s join public.route_variants v on v.id=s.variant_id join public.routes r on r.id=v.route_id
 where r.slug=p_route_slug and r.status='published' and v.active and s.admin_open and s.available and s.starts_at>now() and (s.starts_at at time zone 'Europe/Madrid')::date between p_from and p_to and s.reserved_places<s.capacity order by s.starts_at;
$$;

create or replace function public.get_admin_availability(p_route_id uuid,p_from date,p_to date)
returns table(id uuid,slot_date date,slot_time text,capacity integer,reserved_places integer,available boolean,admin_open boolean) language plpgsql stable security definer set search_path=public as $$
begin
 if not public.is_active_admin() then raise exception 'not_authorized'; end if;
 return query select s.id,(s.starts_at at time zone 'Europe/Madrid')::date,to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI'),s.capacity,s.reserved_places,s.available,s.admin_open from public.schedules s join public.route_variants v on v.id=s.variant_id where v.route_id=p_route_id and (s.starts_at at time zone 'Europe/Madrid')::date between p_from and p_to order by s.starts_at;
end $$;

create or replace function public.refresh_booking_schedule()
returns trigger language plpgsql security definer set search_path=public as $$
declare sid uuid:=coalesce(new.schedule_id,old.schedule_id); total_places integer; private_taken boolean;
begin
 if sid is null then return coalesce(new,old); end if;
 select coalesce(sum(participant_count),0),coalesce(bool_or(modality in('private','partner')),false) into total_places,private_taken from public.bookings where schedule_id=sid and status in('received','reviewing','confirmed');
 update public.schedules set reserved_places=least(capacity,total_places),available=admin_open and not private_taken and total_places<capacity where id=sid;
 return coalesce(new,old);
end $$;
drop trigger if exists refresh_booking_schedule_trigger on public.bookings;
create trigger refresh_booking_schedule_trigger after insert or update of status,schedule_id,participant_count,modality or delete on public.bookings for each row execute function public.refresh_booking_schedule();

create or replace function public.claim_booking_notification(p_reference text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_result jsonb;
begin
 update public.bookings b set notification_claimed_at=now() from public.customers c,public.routes r where b.public_reference=upper(trim(p_reference)) and b.customer_id=c.id and b.route_id=r.id and (b.notification_sent_at is null or b.customer_notification_sent_at is null) and (b.notification_claimed_at is null or b.notification_claimed_at<now()-interval '10 minutes') returning jsonb_build_object('reference',b.public_reference,'route_title',r.title,'route_slug',r.slug,'preferred_date',b.preferred_date,'preferred_time',b.preferred_time,'language',b.language,'participant_count',b.participant_count,'modality',b.modality,'special_requests',b.special_requests,'customer_name',c.full_name,'customer_email',c.email,'customer_phone',c.phone,'admin_notification_pending',b.notification_sent_at is null,'customer_notification_pending',b.customer_notification_sent_at is null) into v_result; return v_result;
end $$;

create or replace function public.submit_booking_request(payload jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_route public.routes;v_customer public.customers;v_existing public.bookings;v_booking public.bookings;v_schedule public.schedules;v_email text:=lower(trim(payload->>'email'));v_name text:=trim(payload->>'name');v_date date;v_people integer:=(payload->>'people')::integer;
begin
 if coalesce(payload->>'website','')<>'' then raise exception 'invalid_request';end if;if char_length(v_name) not between 2 and 120 then raise exception 'invalid_name';end if;if v_email!~'^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'invalid_email';end if;v_date:=(payload->>'date')::date;if v_date<=current_date then raise exception 'invalid_date';end if;
 select * into v_route from public.routes where slug=payload->>'route' and status='published' and status_label in('Ruta inicial','Disponible');if not found then raise exception 'route_unavailable';end if;
 insert into public.customers(full_name,email,phone) values(v_name,v_email,nullif(trim(payload->>'phone'),'')) on conflict(email) do update set full_name=excluded.full_name,phone=coalesce(excluded.phone,customers.phone) returning * into v_customer;
 select * into v_existing from public.bookings where customer_id=v_customer.id and route_id=v_route.id and preferred_date=v_date and status in('received','reviewing','confirmed') and created_at>now()-interval '15 minutes' order by created_at desc limit 1;if found then return jsonb_build_object('reference',v_existing.public_reference,'duplicate',true);end if;
 select s.* into v_schedule from public.schedules s join public.route_variants v on v.id=s.variant_id where v.route_id=v_route.id and s.admin_open and s.available and (s.starts_at at time zone 'Europe/Madrid')::date=v_date and to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI')=payload->>'time' and s.reserved_places+v_people<=s.capacity for update of s limit 1;if not found then raise exception 'slot_unavailable';end if;
 insert into public.bookings(customer_id,route_id,schedule_id,preferred_date,preferred_time,language,participant_count,modality,special_requests,privacy_accepted_at) values(v_customer.id,v_route.id,v_schedule.id,v_date,payload->>'time',payload->>'language',v_people,payload->>'modality',nullif(trim(payload->>'notes'),''),now()) returning * into v_booking;return jsonb_build_object('reference',v_booking.public_reference,'duplicate',false);
end $$;

revoke all on function public.submit_contact_message(jsonb) from public,anon,authenticated;grant execute on function public.submit_contact_message(jsonb) to anon,authenticated;
revoke all on function public.mark_message_read(uuid,boolean) from public,anon;grant execute on function public.mark_message_read(uuid,boolean) to authenticated;
revoke all on function public.admin_set_availability(uuid,date,text,integer,boolean) from public,anon;grant execute on function public.admin_set_availability(uuid,date,text,integer,boolean) to authenticated;
revoke all on function public.admin_generate_availability_month(uuid,date,integer) from public,anon;grant execute on function public.admin_generate_availability_month(uuid,date,integer) to authenticated;
revoke all on function public.get_public_availability(text,date,date) from public;grant execute on function public.get_public_availability(text,date,date) to anon,authenticated;
revoke all on function public.get_admin_availability(uuid,date,date) from public,anon;grant execute on function public.get_admin_availability(uuid,date,date) to authenticated;

-- Seed the currently bookable route for the next 120 days so launch availability is not interrupted.
insert into public.route_variants(route_id,name,mode,active) select id,'Reserva web','private',true from public.routes where slug='sagrada-familia' on conflict do nothing;
with calendar_days as(select d::date as slot_day from generate_series(current_date+1,current_date+120,interval '1 day') d), slot_times as(select slot_day,unnest(case when extract(isodow from slot_day) in(6,7) then array['10:00','12:00','18:00','22:00'] else array['18:00','22:00'] end) as slot_time from calendar_days), target as(select v.id as variant_id,t.slot_day,t.slot_time,coalesce(r.duration_minutes_max,90) as duration from slot_times t cross join public.routes r join public.route_variants v on v.route_id=r.id and v.name='Reserva web' where r.slug='sagrada-familia') insert into public.schedules(variant_id,starts_at,ends_at,capacity,reserved_places,available,admin_open) select variant_id,((slot_day::text||' '||slot_time)::timestamp at time zone 'Europe/Madrid'),((slot_day::text||' '||slot_time)::timestamp at time zone 'Europe/Madrid')+make_interval(mins=>duration),50,0,true,true from target on conflict(variant_id,starts_at) do nothing;