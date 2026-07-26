-- Preserve private/partner slot blocks while allowing shared bookings to consume seats.
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
  returning id into v_id;
  update public.schedules s set available=s.admin_open and s.reserved_places<s.capacity and not exists(select 1 from public.bookings b where b.schedule_id=s.id and b.status in ('received','reviewing','confirmed') and b.modality in ('private','partner')) where s.id=v_id;
  return v_id;
end $$;

update public.schedules s
set available=s.admin_open and s.reserved_places<s.capacity and not exists(
  select 1 from public.bookings b
  where b.schedule_id=s.id
    and b.status in ('received','reviewing','confirmed')
    and b.modality in ('private','partner')
)
where s.starts_at>now();

revoke all on function public.admin_set_availability(uuid,date,text,integer,boolean) from public,anon;
grant execute on function public.admin_set_availability(uuid,date,text,integer,boolean) to authenticated;
