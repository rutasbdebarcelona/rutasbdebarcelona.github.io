-- Default admin availability view: all published/bookable routes, with optional filtering.
create or replace function public.get_admin_availability_overview(p_route_id uuid,p_from date,p_to date)
returns table(id uuid,route_id uuid,route_title text,slot_date date,slot_time text,capacity integer,reserved_places integer,remaining_places integer,booking_count bigint,booking_references text[],private_blocked boolean,available boolean,admin_open boolean)
language plpgsql stable security definer set search_path=public as $$
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;
  return query
  select s.id,r.id,r.title,(s.starts_at at time zone 'Europe/Madrid')::date,to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI'),s.capacity,s.reserved_places,greatest(s.capacity-s.reserved_places,0),count(b.id),coalesce(array_agg(b.public_reference order by b.created_at) filter(where b.id is not null),'{}'),coalesce(bool_or(b.modality in('private','partner')),false),s.available,s.admin_open
  from public.schedules s
  join public.route_variants v on v.id=s.variant_id
  join public.routes r on r.id=v.route_id and r.status='published' and r.status_label in('Ruta inicial','Disponible')
  left join public.bookings b on (b.schedule_id=s.id or (b.schedule_id is null and b.route_id=r.id and b.preferred_date=(s.starts_at at time zone 'Europe/Madrid')::date and b.preferred_time=to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI'))) and b.status in('received','reviewing','confirmed')
  where (p_route_id is null or r.id=p_route_id) and (s.starts_at at time zone 'Europe/Madrid')::date between p_from and p_to
  group by s.id,r.id,r.title order by s.starts_at,r.title;
end $$;

revoke all on function public.get_admin_availability_overview(uuid,date,date) from public,anon;
grant execute on function public.get_admin_availability_overview(uuid,date,date) to authenticated;
