-- Set the commercial capacity ceiling to fifteen without disturbing existing bookings.
alter table public.bookings drop constraint if exists bookings_participant_count_check;
alter table public.bookings add constraint bookings_participant_count_check check(participant_count between 1 and 15) not valid;
alter table public.bookings validate constraint bookings_participant_count_check;

update public.schedules
set capacity=greatest(15,reserved_places),
    available=admin_open and reserved_places<greatest(15,reserved_places)
where starts_at>now();

create or replace function public.admin_set_availability(p_route_id uuid,p_date date,p_time text,p_capacity integer,p_open boolean)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_variant uuid; v_start timestamptz; v_end timestamptz; v_duration integer; v_id uuid;
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;
  if p_date<=current_date or p_time not in ('10:00','12:00','18:00','22:00') or p_capacity not between 1 and 15 then raise exception 'invalid_slot'; end if;
  if p_time in ('10:00','12:00') and extract(isodow from p_date) not in (6,7) then raise exception 'weekend_only_slot'; end if;
  select id into v_variant from public.route_variants where route_id=p_route_id and name='Reserva web' limit 1;
  if v_variant is null then insert into public.route_variants(route_id,name,mode,active) values(p_route_id,'Reserva web','private',true) returning id into v_variant; end if;
  select coalesce(duration_minutes_max,90) into v_duration from public.routes where id=p_route_id;
  v_start := ((p_date::text||' '||p_time)::timestamp at time zone 'Europe/Madrid'); v_end:=v_start+make_interval(mins=>v_duration);
  insert into public.schedules(variant_id,starts_at,ends_at,capacity,available,admin_open) values(v_variant,v_start,v_end,p_capacity,p_open,p_open)
  on conflict(variant_id,starts_at) do update set ends_at=excluded.ends_at,capacity=greatest(excluded.capacity,public.schedules.reserved_places),admin_open=excluded.admin_open,available=excluded.admin_open and public.schedules.reserved_places<greatest(excluded.capacity,public.schedules.reserved_places)
  returning id into v_id; return v_id;
end $$;

create or replace function public.admin_generate_availability_month(p_route_id uuid,p_month date,p_capacity integer default 15)
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

create or replace function public.submit_booking_request(payload jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_route public.routes;v_customer public.customers;v_existing public.bookings;v_booking public.bookings;v_schedule public.schedules;v_email text:=lower(trim(payload->>'email'));v_name text:=trim(payload->>'name');v_date date;v_people integer:=(payload->>'people')::integer;
begin
 if v_people not between 1 and 15 then raise exception 'invalid_people'; end if;
 if coalesce(payload->>'website','')<>'' then raise exception 'invalid_request';end if;if char_length(v_name) not between 2 and 120 then raise exception 'invalid_name';end if;if v_email!~'^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'invalid_email';end if;v_date:=(payload->>'date')::date;if v_date<=current_date then raise exception 'invalid_date';end if;
 select * into v_route from public.routes where slug=payload->>'route' and status='published' and status_label in('Ruta inicial','Disponible');if not found then raise exception 'route_unavailable';end if;
 insert into public.customers(full_name,email,phone) values(v_name,v_email,nullif(trim(payload->>'phone'),'')) on conflict(email) do update set full_name=excluded.full_name,phone=coalesce(excluded.phone,customers.phone) returning * into v_customer;
 select * into v_existing from public.bookings where customer_id=v_customer.id and route_id=v_route.id and preferred_date=v_date and status in('received','reviewing','confirmed') and created_at>now()-interval '15 minutes' order by created_at desc limit 1;if found then return jsonb_build_object('reference',v_existing.public_reference,'duplicate',true);end if;
 select s.* into v_schedule from public.schedules s join public.route_variants v on v.id=s.variant_id where v.route_id=v_route.id and s.admin_open and s.available and (s.starts_at at time zone 'Europe/Madrid')::date=v_date and to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI')=payload->>'time' and s.reserved_places+v_people<=s.capacity for update of s limit 1;if not found then raise exception 'slot_unavailable';end if;
 insert into public.bookings(customer_id,route_id,schedule_id,preferred_date,preferred_time,language,participant_count,modality,special_requests,privacy_accepted_at) values(v_customer.id,v_route.id,v_schedule.id,v_date,payload->>'time',payload->>'language',v_people,payload->>'modality',nullif(trim(payload->>'notes'),''),now()) returning * into v_booking;return jsonb_build_object('reference',v_booking.public_reference,'duplicate',false);
end $$;

revoke all on function public.admin_set_availability(uuid,date,text,integer,boolean) from public,anon;
grant execute on function public.admin_set_availability(uuid,date,text,integer,boolean) to authenticated;
revoke all on function public.admin_generate_availability_month(uuid,date,integer) from public,anon;
grant execute on function public.admin_generate_availability_month(uuid,date,integer) to authenticated;
revoke all on function public.submit_booking_request(jsonb) from public;
grant execute on function public.submit_booking_request(jsonb) to anon,authenticated;
