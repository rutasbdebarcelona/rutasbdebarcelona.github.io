const hasValue = value => {
  if (Array.isArray(value)) return value.length > 0;
  if (typeof value === 'string') return value.trim().length > 0;
  return value !== undefined && value !== null;
};

const mergeNonEmpty = (...sources) => sources.reduce((result, source) => {
  Object.entries(source || {}).forEach(([key, value]) => {
    if (hasValue(value)) result[key] = value;
  });
  return result;
}, {});

export function routeStopEditorValues(data = {}) {
  const en = data.translations?.en || {};
  return {
    ...data,
    title_en: en.title ?? '',
    short_description_en: en.short_description ?? '',
    full_description_en: en.full_description ?? '',
    image_alt_en: en.image_alt ?? '',
  };
}

const mergeNestedTranslations = (published = {}, draft = {}) => {
  const { translations: publishedTranslations, ...publishedBase } = published || {};
  const { translations: draftTranslations, ...draftBase } = draft || {};
  return {
    ...mergeNonEmpty(publishedBase, draftBase),
    translations: {
      ...(publishedTranslations || {}),
      ...(draftTranslations || {}),
      en: mergeNonEmpty(publishedTranslations?.en, draftTranslations?.en),
    },
  };
};

export function mergeRouteLocaleEditorData(published = {}, draft = {}, fallback = {}) {
  return mergeNonEmpty(fallback, published, draft);
}

export function mergeRouteProductEditorData(publishedProduct = {}, publishedStops = [], draft = {}) {
  const draftStops = Array.isArray(draft.stop_details) ? draft.stop_details : [];
  const count = Math.max(publishedStops.length, draftStops.length);
  return {
    product_profile: mergeNestedTranslations(publishedProduct || {}, draft.product_profile || {}),
    stop_details: Array.from({ length: count }, (_, index) =>
      mergeNestedTranslations(publishedStops[index] || {}, draftStops[index] || {})),
    commercial_variants: Array.isArray(draft.commercial_variants) ? draft.commercial_variants : [],
  };
}