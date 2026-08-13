-- Route-specific weekly availability. Existing bookings are never deleted.
create table if not exists public.route_schedule_rules(
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references public.routes(id) on delete cascade,
  weekday smallint not null check(weekday between 1 and 7),
  slot_time time not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(route_id,weekday,slot_time)
);

alter table public.route_schedule_rules enable row level security;
revoke all on public.route_schedule_rules from anon,authenticated;

-- Preserve the currently configured pattern as an editable starting point.
insert into public.route_schedule_rules(route_id,weekday,slot_time)
select distinct v.route_id,
       extract(isodow from s.starts_at at time zone 'Europe/Madrid')::smallint,
       (s.starts_at at time zone 'Europe/Madrid')::time
from public.schedules s
join public.route_variants v on v.id=s.variant_id
join public.routes r on r.id=v.route_id
where s.starts_at>now() and s.admin_open
  and (r.slug<>'sagrada-familia-nocturna' or to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI')='22:00')
on conflict do nothing;

-- The nocturnal Sagrada Família product has one valid daily time: 22:00.
delete from public.route_schedule_rules rr
using public.routes r
where rr.route_id=r.id and r.slug='sagrada-familia-nocturna';
insert into public.route_schedule_rules(route_id,weekday,slot_time)
select r.id,d,'22:00'::time
from public.routes r cross join generate_series(1,7) d
where r.slug='sagrada-familia-nocturna'
on conflict do nothing;

-- Remove incorrect future nocturnal slots when empty; preserve occupied ones as closed history.
update public.schedules s
set admin_open=false,available=false
from public.route_variants v,public.routes r
where s.variant_id=v.id and v.route_id=r.id and v.name='Reserva web'
  and r.slug='sagrada-familia-nocturna' and s.starts_at>now()
  and to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI')<>'22:00'
  and exists(select 1 from public.bookings b where b.schedule_id=s.id);
delete from public.schedules s
using public.route_variants v,public.routes r
where s.variant_id=v.id and v.route_id=r.id and v.name='Reserva web'
  and r.slug='sagrada-familia-nocturna' and s.starts_at>now()
  and to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI')<>'22:00'
  and not exists(select 1 from public.bookings b where b.schedule_id=s.id);

create or replace function public.get_admin_route_schedule_rules(p_route_id uuid)
returns table(weekday smallint,slot_time text)
language plpgsql security definer set search_path=public as $$
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;
  return query
  select rr.weekday,to_char(rr.slot_time,'HH24:MI')
  from public.route_schedule_rules rr
  where rr.route_id=p_route_id and rr.active
  order by rr.slot_time,rr.weekday;
end $$;

create or replace function public.admin_replace_route_schedule_rules(p_route_id uuid,p_rules jsonb)
returns integer language plpgsql security definer set search_path=public as $$
declare v_rule jsonb; v_day integer; v_time text; v_count integer:=0;
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;
  if not exists(select 1 from public.routes where id=p_route_id) then raise exception 'route_not_found'; end if;
  if jsonb_typeof(coalesce(p_rules,'[]'::jsonb))<>'array' then raise exception 'invalid_rules'; end if;
  delete from public.route_schedule_rules where route_id=p_route_id;
  for v_rule in select value from jsonb_array_elements(coalesce(p_rules,'[]'::jsonb)) loop
    v_day:=(v_rule->>'weekday')::integer; v_time:=trim(v_rule->>'time');
    if v_day not between 1 and 7 or v_time!~'^(?:[01][0-9]|2[0-3]):[0-5][0-9]$' then raise exception 'invalid_rule'; end if;
    insert into public.route_schedule_rules(route_id,weekday,slot_time)
    values(p_route_id,v_day,v_time::time) on conflict do nothing;
  end loop;
  -- Reconcile already generated future slots with the new rules.
  update public.schedules s
  set admin_open=false,available=false
  from public.route_variants v
  where s.variant_id=v.id and v.route_id=p_route_id and v.name='Reserva web' and s.starts_at>now()
    and not exists(
      select 1 from public.route_schedule_rules rr
      where rr.route_id=p_route_id and rr.active
        and rr.weekday=extract(isodow from s.starts_at at time zone 'Europe/Madrid')::integer
        and rr.slot_time=(s.starts_at at time zone 'Europe/Madrid')::time
    )
    and exists(select 1 from public.bookings b where b.schedule_id=s.id);
  delete from public.schedules s
  using public.route_variants v
  where s.variant_id=v.id and v.route_id=p_route_id and v.name='Reserva web' and s.starts_at>now()
    and not exists(
      select 1 from public.route_schedule_rules rr
      where rr.route_id=p_route_id and rr.active
        and rr.weekday=extract(isodow from s.starts_at at time zone 'Europe/Madrid')::integer
        and rr.slot_time=(s.starts_at at time zone 'Europe/Madrid')::time
    )
    and not exists(select 1 from public.bookings b where b.schedule_id=s.id);
  select count(*) into v_count from public.route_schedule_rules where route_id=p_route_id and active;
  return v_count;
end $$;

create or replace function public.admin_set_availability(p_route_id uuid,p_date date,p_time text,p_capacity integer,p_open boolean)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_variant uuid; v_start timestamptz; v_end timestamptz; v_duration integer; v_id uuid; v_has_bookings boolean;
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;
  if p_date<=current_date or p_time!~'^(?:[01][0-9]|2[0-3]):[0-5][0-9]$' or p_capacity not between 1 and 15 then raise exception 'invalid_slot'; end if;
  if p_open and not exists(
    select 1 from public.route_schedule_rules rr
    where rr.route_id=p_route_id and rr.active
      and rr.weekday=extract(isodow from p_date)::integer and rr.slot_time=p_time::time
  ) then raise exception 'slot_not_in_route_schedule'; end if;
  select id into v_variant from public.route_variants where route_id=p_route_id and name='Reserva web' limit 1;
  if v_variant is null then insert into public.route_variants(route_id,name,mode,active) values(p_route_id,'Reserva web','private',true) returning id into v_variant; end if;
  v_start:=((p_date::text||' '||p_time)::timestamp at time zone 'Europe/Madrid');
  select id into v_id from public.schedules where variant_id=v_variant and starts_at=v_start;
  if not p_open then
    if v_id is null then return null; end if;
    select exists(select 1 from public.bookings where schedule_id=v_id) into v_has_bookings;
    if not v_has_bookings then delete from public.schedules where id=v_id; return v_id; end if;
    update public.schedules set admin_open=false,available=false where id=v_id;
    return v_id;
  end if;
  select coalesce(duration_minutes_max,90) into v_duration from public.routes where id=p_route_id;
  v_end:=v_start+make_interval(mins=>v_duration);
  insert into public.schedules(variant_id,starts_at,ends_at,capacity,available,admin_open)
  values(v_variant,v_start,v_end,p_capacity,true,true)
  on conflict(variant_id,starts_at) do update set ends_at=excluded.ends_at,
    capacity=greatest(excluded.capacity,public.schedules.reserved_places),admin_open=true,
    available=public.schedules.reserved_places<greatest(excluded.capacity,public.schedules.reserved_places)
  returning id into v_id;
  update public.schedules s set available=s.admin_open and s.reserved_places<s.capacity and not exists(
    select 1 from public.bookings b where b.schedule_id=s.id and b.status in('received','reviewing','confirmed') and b.modality in('private','partner')
  ) where s.id=v_id;
  return v_id;
end $$;

create or replace function public.admin_generate_availability_month(p_route_id uuid,p_month date,p_capacity integer default 15)
returns integer language plpgsql security definer set search_path=public as $$
declare d date; r record; n integer:=0;
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;
  if p_capacity not between 1 and 15 then raise exception 'invalid_capacity'; end if;
  d:=date_trunc('month',p_month)::date;
  while d<(date_trunc('month',p_month)+interval '1 month')::date loop
    if d>current_date then
      for r in select to_char(slot_time,'HH24:MI') as slot_time from public.route_schedule_rules
               where route_id=p_route_id and active and weekday=extract(isodow from d)::integer order by slot_time loop
        perform public.admin_set_availability(p_route_id,d,r.slot_time,p_capacity,true); n:=n+1;
      end loop;
    end if;
    d:=d+1;
  end loop;
  return n;
end $$;

revoke all on function public.get_admin_route_schedule_rules(uuid) from public,anon;
revoke all on function public.admin_replace_route_schedule_rules(uuid,jsonb) from public,anon;
revoke all on function public.admin_set_availability(uuid,date,text,integer,boolean) from public,anon;
revoke all on function public.admin_generate_availability_month(uuid,date,integer) from public,anon;
grant execute on function public.get_admin_route_schedule_rules(uuid) to authenticated;
grant execute on function public.admin_replace_route_schedule_rules(uuid,jsonb) to authenticated;
grant execute on function public.admin_set_availability(uuid,date,text,integer,boolean) to authenticated;
grant execute on function public.admin_generate_availability_month(uuid,date,integer) to authenticated;
