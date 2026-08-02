-- Hide an optional price by leaving its editor field empty.
update public.routes set display_price_group=null, updated_at=now() where slug='sagrada-familia';
update public.route_translations rt set display_price_group=null, updated_at=now() from public.routes r where rt.route_id=r.id and r.slug='sagrada-familia';
update public.route_drafts d set content=jsonb_set(jsonb_set(d.content,'{display_price_group}',to_jsonb(''::text),true),'{en,display_price_group}',to_jsonb(''::text),true), updated_at=now() from public.routes r where d.route_id=r.id and r.slug='sagrada-familia';