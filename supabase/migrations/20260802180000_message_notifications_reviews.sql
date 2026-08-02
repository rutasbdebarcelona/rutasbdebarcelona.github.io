-- Notify administrators about contact messages and activate verified reviews.
alter table public.messages
  add column if not exists notification_claimed_at timestamptz,
  add column if not exists notification_sent_at timestamptz;

create or replace function public.submit_contact_message(payload jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare
  v_customer public.customers;
  v_message public.messages;
  v_name text:=trim(payload->>'name');
  v_email text:=lower(trim(payload->>'email'));
  v_body text:=trim(payload->>'message');
  v_type text:=coalesce(payload->>'type','general');
  v_locale text:=coalesce(payload->>'locale','es');
begin
  if coalesce(payload->>'website','')<>'' then raise exception 'invalid_request'; end if;
  if coalesce((payload->>'privacy')::boolean,false) is not true then raise exception 'privacy_required'; end if;
  if char_length(v_name) not between 2 and 120 then raise exception 'invalid_name'; end if;
  if v_email is null or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'invalid_email'; end if;
  if char_length(v_body) not between 2 and 3000 then raise exception 'invalid_message'; end if;
  if v_type not in ('general','partner','private','press') or v_locale not in ('es','en') then raise exception 'invalid_option'; end if;
  insert into public.customers(full_name,email) values(v_name,v_email)
    on conflict(email) do update set full_name=excluded.full_name,updated_at=now()
    returning * into v_customer;
  select * into v_message from public.messages
    where customer_id=v_customer.id and body=v_body and created_at>now()-interval '5 minutes'
    order by created_at desc limit 1;
  if found then return jsonb_build_object('ok',true,'duplicate',true,'message_id',v_message.id); end if;
  insert into public.messages(customer_id,subject,body,inquiry_type,locale)
    values(v_customer.id,case when v_locale='en' then 'Website enquiry' else 'Consulta desde la web' end,v_body,v_type,v_locale)
    returning * into v_message;
  return jsonb_build_object('ok',true,'duplicate',false,'message_id',v_message.id);
end $$;

create or replace function public.claim_message_notification(p_message_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_result jsonb;
begin
  update public.messages m set notification_claimed_at=now()
  from public.customers c
  where m.id=p_message_id and m.customer_id=c.id and m.notification_sent_at is null
    and (m.notification_claimed_at is null or m.notification_claimed_at<now()-interval '10 minutes')
  returning jsonb_build_object('id',m.id,'subject',m.subject,'body',m.body,'inquiry_type',m.inquiry_type,'locale',m.locale,'created_at',m.created_at,'customer_name',c.full_name,'customer_email',c.email,'customer_phone',c.phone) into v_result;
  return v_result;
end $$;

create or replace function public.complete_message_notification(p_message_id uuid)
returns void language sql security definer set search_path=public as $$
  update public.messages set notification_sent_at=coalesce(notification_sent_at,now()),notification_claimed_at=null where id=p_message_id;
$$;

create or replace function public.release_message_notification(p_message_id uuid)
returns void language sql security definer set search_path=public as $$
  update public.messages set notification_claimed_at=null where id=p_message_id and notification_sent_at is null;
$$;

create unique index if not exists reviews_one_per_booking on public.reviews(booking_id) where booking_id is not null;

create or replace function public.submit_verified_review(payload jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare
  v_booking public.bookings;
  v_customer public.customers;
  v_review public.reviews;
  v_email text:=lower(trim(payload->>'email'));
  v_reference text:=upper(trim(payload->>'reference'));
  v_name text:=trim(payload->>'display_name');
  v_body text:=trim(payload->>'body');
  v_rating integer:=(payload->>'rating')::integer;
begin
  if coalesce(payload->>'website','')<>'' then raise exception 'invalid_request'; end if;
  if coalesce((payload->>'privacy')::boolean,false) is not true then raise exception 'privacy_required'; end if;
  if v_email is null or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'invalid_email'; end if;
  if char_length(v_name) not between 2 and 80 then raise exception 'invalid_name'; end if;
  if char_length(v_body) not between 10 and 1500 or v_rating not between 1 and 5 then raise exception 'invalid_review'; end if;
  select b.* into v_booking from public.bookings b join public.customers c on c.id=b.customer_id
    where b.public_reference=v_reference and lower(c.email)=v_email and b.status in ('confirmed','completed') limit 1;
  if not found then raise exception 'booking_not_verified'; end if;
  select c.* into v_customer from public.customers c where c.id=v_booking.customer_id;
  if exists(select 1 from public.reviews where booking_id=v_booking.id) then raise exception 'review_already_exists'; end if;
  insert into public.reviews(booking_id,route_id,display_name,rating,body,status)
    values(v_booking.id,v_booking.route_id,v_name,v_rating,v_body,'pending') returning * into v_review;
  return jsonb_build_object('ok',true,'review_id',v_review.id,'status','pending');
end $$;

create or replace function public.admin_set_review_status(p_review_id uuid,p_status public.review_status)
returns public.reviews language plpgsql security definer set search_path=public as $$
declare v_review public.reviews;
begin
  if not public.is_active_admin() then raise exception 'not_authorized'; end if;
  update public.reviews set status=p_status,published_at=case when p_status='published' then coalesce(published_at,now()) else null end
    where id=p_review_id returning * into v_review;
  if not found then raise exception 'review_not_found'; end if;
  return v_review;
end $$;

revoke all on function public.claim_message_notification(uuid) from public,anon,authenticated;
revoke all on function public.complete_message_notification(uuid) from public,anon,authenticated;
revoke all on function public.release_message_notification(uuid) from public,anon,authenticated;
grant execute on function public.claim_message_notification(uuid) to service_role;
grant execute on function public.complete_message_notification(uuid) to service_role;
grant execute on function public.release_message_notification(uuid) to service_role;
revoke all on function public.submit_verified_review(jsonb) from public,anon,authenticated;
grant execute on function public.submit_verified_review(jsonb) to anon,authenticated;
revoke all on function public.admin_set_review_status(uuid,public.review_status) from public,anon;
grant execute on function public.admin_set_review_status(uuid,public.review_status) to authenticated;
