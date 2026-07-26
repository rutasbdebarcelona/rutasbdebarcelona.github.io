-- Expose real booking occupancy in the internal availability calendar.
drop function if exists public.get_admin_availability(uuid,date,date);
create function public.get_admin_availability(p_route_id uuid,p_from date,p_to date)
returns table(id uuid,slot_date date,slot_time text,capacity integer,reserved_places integer,remaining_places integer,booking_count integer,private_blocked boolean,booking_references text[],available boolean,admin_open boolean)
language plpgsql stable security definer set search_path=public as $$
begin
 if not public.is_active_admin() then raise exception 'not_authorized'; end if;
 return query
 select s.id,(s.starts_at at time zone 'Europe/Madrid')::date,to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI'),s.capacity,
   coalesce(sum(b.participant_count) filter(where b.id is not null),0)::integer,
   greatest(s.capacity-coalesce(sum(b.participant_count) filter(where b.id is not null),0),0)::integer,
   count(b.id)::integer,coalesce(bool_or(b.modality in('private','partner')),false),
   coalesce(array_agg(b.public_reference order by b.created_at) filter(where b.id is not null),'{}'::text[]),s.available,s.admin_open
 from public.schedules s
 join public.route_variants v on v.id=s.variant_id
 left join public.bookings b on b.schedule_id=s.id and b.status in('received','reviewing','confirmed')
 where v.route_id=p_route_id and (s.starts_at at time zone 'Europe/Madrid')::date between p_from and p_to
 group by s.id,s.starts_at,s.capacity,s.available,s.admin_open order by s.starts_at;
end $$;
revoke all on function public.get_admin_availability(uuid,date,date) from public,anon;
grant execute on function public.get_admin_availability(uuid,date,date) to authenticated;
