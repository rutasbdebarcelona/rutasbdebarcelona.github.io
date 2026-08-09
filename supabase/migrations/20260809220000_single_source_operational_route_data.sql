-- Operational facts are entered once and shared by all locales.
-- Translated prose remains independent; prices and physical meeting data cannot diverge.

create or replace function public.enforce_shared_route_prices()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  select r.display_price_individual, r.display_price_group
    into new.display_price_individual, new.display_price_group
  from public.routes r
  where r.id = new.route_id;
  return new;
end;
$$;

drop trigger if exists route_translations_shared_prices on public.route_translations;
create trigger route_translations_shared_prices
before insert or update of display_price_individual, display_price_group, route_id
on public.route_translations
for each row execute function public.enforce_shared_route_prices();

create or replace function public.propagate_shared_route_prices()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.route_translations
  set display_price_individual = new.display_price_individual,
      display_price_group = new.display_price_group,
      updated_at = now()
  where route_id = new.id
    and (display_price_individual is distinct from new.display_price_individual
      or display_price_group is distinct from new.display_price_group);
  return new;
end;
$$;

drop trigger if exists routes_propagate_shared_prices on public.routes;
create trigger routes_propagate_shared_prices
after insert or update of display_price_individual, display_price_group
on public.routes
for each row execute function public.propagate_shared_route_prices();

update public.route_translations rt
set display_price_individual = r.display_price_individual,
    display_price_group = r.display_price_group,
    updated_at = now()
from public.routes r
where rt.route_id = r.id
  and (rt.display_price_individual is distinct from r.display_price_individual
    or rt.display_price_group is distinct from r.display_price_group);

update public.route_product_profiles p
set meeting_address = 'Avinguda de Gaudí, 2',
    meeting_reference = 'KFC · Avinguda de Gaudí',
    translations = jsonb_set(
      coalesce(p.translations, '{}'::jsonb),
      '{en,meeting_reference}',
      to_jsonb('KFC · Avinguda de Gaudí'::text),
      true
    ),
    updated_at = now()
from public.routes r
where p.route_id = r.id
  and r.slug in ('sagrada-familia', 'sagrada-familia-nocturna');