alter table public.route_commercial_variants add column if not exists commercial_data jsonb not null default '{}'::jsonb;

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
        insert into public.route_commercial_variants(route_id,variant_key,kind,title,short_description,full_description,duration_minutes,schedule_notes,meeting_override,active,sort_order,translations,commercial_data)
        values(p_route_id,coalesce(nullif(trim(v_variant->>'variant_key'),''),'variant-'||v_i),coalesce(nullif(v_variant->>'kind',''),'custom'),trim(v_variant->>'title'),nullif(trim(v_variant->>'short_description'),''),nullif(trim(v_variant->>'full_description'),''),nullif(v_variant->>'duration_minutes','')::integer,nullif(trim(v_variant->>'schedule_notes'),''),nullif(trim(v_variant->>'meeting_override'),''),coalesce((v_variant->>'active')::boolean,false),v_i,coalesce(v_variant->'translations','{}'),v_variant - array['title','title_en','variant_key','kind','short_description','short_description_en','full_description','full_description_en','duration_minutes','schedule_notes','meeting_override','active','translations']::text[]);v_i:=v_i+1;
      end if;
    end loop;
  end if;
end $$;
