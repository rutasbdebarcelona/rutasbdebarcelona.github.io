-- Normalize the two legacy test labels requested by the owner.
update public.bookings
set preferred_time='12:00'
where preferred_time in ('flexible','midday');

-- Link active bookings to their exact existing schedule without changing reference, date or customer data.
update public.bookings b
set schedule_id=(
 select s.id from public.schedules s join public.route_variants v on v.id=s.variant_id
 where v.route_id=b.route_id
   and (s.starts_at at time zone 'Europe/Madrid')::date=b.preferred_date
   and to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI')=b.preferred_time
 order by (v.name='Reserva web') desc,s.starts_at,s.id limit 1
)
where b.schedule_id is null
  and b.status in('received','reviewing','confirmed')
  and b.preferred_time in('10:00','12:00','18:00','22:00')
  and exists(
   select 1 from public.schedules s join public.route_variants v on v.id=s.variant_id
   where v.route_id=b.route_id
     and (s.starts_at at time zone 'Europe/Madrid')::date=b.preferred_date
     and to_char(s.starts_at at time zone 'Europe/Madrid','HH24:MI')=b.preferred_time
  );
