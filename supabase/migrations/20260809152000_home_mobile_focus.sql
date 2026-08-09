-- Reencuadra la imagen principal en móvil sin anular los controles editoriales.
update public.site_design_settings
set published = jsonb_set(
                  jsonb_set(published, '{home,heroImage,mobileX}', '52'::jsonb, true),
                  '{home,heroImage,mobileY}', '45'::jsonb, true
                ),
    draft = case
      when draft is null then null
      else jsonb_set(
             jsonb_set(draft, '{home,heroImage,mobileX}', '52'::jsonb, true),
             '{home,heroImage,mobileY}', '45'::jsonb, true
           )
    end,
    updated_at = now()
where id = true;