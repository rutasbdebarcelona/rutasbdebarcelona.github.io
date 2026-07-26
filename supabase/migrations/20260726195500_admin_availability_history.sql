-- Keep the internal availability calendar historically complete, including legacy bookings without a schedule.
drop function if exists public.get_admin_availability(uuid,date,date);
create function public.get_admin_availability(p_route_id uuid,p_from date,p_to date)
returns table(id uuid,slot_date date,slot_time text,capacity integer,reserved_places integer,remaining_places integer,booking_count integer,private_blocked boolean,booking_references text[],available boolean,admin_open boolean)
language plpgsql stable security definer set search_path=public as $$
begin
 if not public.is_active_admin() then raise exception 'not_authorized'; end if;
 return query
 with scheduled as (
  select s.id,(s.starts_at at time zone 'Europe/Madrid')::date as slot_date,to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI') as slot_time,s.capacity,
    coalesce(sum(b.participant_count) filter(where b.id is not null),0)::integer as reserved_places,
    greatest(s.capacity-coalesce(sum(b.participant_count) filter(where b.id is not null),0),0)::integer as remaining_places,
    count(b.id)::integer as booking_count,coalesce(bool_or(b.modality in('private','partner')),false) as private_blocked,
    coalesce(array_agg(b.public_reference order by b.created_at) filter(where b.id is not null),'{}'::text[]) as booking_references,s.available,s.admin_open
  from public.schedules s
  join public.route_variants v on v.id=s.variant_id
  left join public.bookings b on (b.schedule_id=s.id or (b.schedule_id is null and b.route_id=p_route_id and b.preferred_date=(s.starts_at at time zone 'Europe/Madrid')::date and b.preferred_time=to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI'))) and b.status in('received','reviewing','confirmed')
  where v.route_id=p_route_id and (s.starts_at at time zone 'Europe/Madrid')::date between p_from and p_to
  group by s.id,s.starts_at,s.capacity,s.available,s.admin_open
 ), legacy as (
  select null::uuid as id,b.preferred_date as slot_date,b.preferred_time as slot_time,15::integer as capacity,
    sum(b.participant_count)::integer as reserved_places,greatest(15-sum(b.participant_count),0)::integer as remaining_places,
    count(b.id)::integer as booking_count,bool_or(b.modality in('private','partner')) as private_blocked,
    array_agg(b.public_reference order by b.created_at) as booking_references,false as available,false as admin_open
  from public.bookings b
  where b.route_id=p_route_id and b.schedule_id is null and b.preferred_date between p_from and p_to
    and b.status in('received','reviewing','confirmed')
    and not exists(select 1 from public.schedules s join public.route_variants v on v.id=s.variant_id where v.route_id=p_route_id and (s.starts_at at time zone 'Europe/Madrid')::date=b.preferred_date and to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI')=b.preferred_time)
  group by b.preferred_date,b.preferred_time
 )
 select x.id,x.slot_date,x.slot_time,x.capacity,x.reserved_places,x.remaining_places,x.booking_count,x.private_blocked,x.booking_references,x.available,x.admin_open
 from (select * from scheduled union all select * from legacy) x
 order by x.slot_date,x.slot_time;
end $$;
revoke all on function public.get_admin_availability(uuid,date,date) from public,anon;
grant execute on function public.get_admin_availability(uuid,date,date) to authenticated;