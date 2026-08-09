import assert from 'node:assert/strict';
import test from 'node:test';
import { mergeRouteLocaleEditorData, mergeRouteProductEditorData, routeStopEditorValues } from '../src/lib/route-stop-editor-values.js';

test('keeps Spanish stop content and exposes every saved English translation', () => {
  const values = routeStopEditorValues({
    title: 'Fachada del Nacimiento',
    short_description: 'La naturaleza organiza la fachada.',
    translations: { en: {
      title: 'Nativity Facade',
      short_description: 'Nature organises the facade.',
      full_description: 'A complete English description.',
      image_alt: 'Nativity Facade at the Sagrada Familia',
    } },
  });
  assert.equal(values.title, 'Fachada del Nacimiento');
  assert.equal(values.title_en, 'Nativity Facade');
  assert.equal(values.short_description_en, 'Nature organises the facade.');
  assert.equal(values.full_description_en, 'A complete English description.');
  assert.equal(values.image_alt_en, 'Nativity Facade at the Sagrada Familia');
});

test('uses empty editable English fields only when no translation exists', () => {
  const values = routeStopEditorValues({ title: 'Parada nueva' });
  assert.equal(values.title_en, '');
  assert.equal(values.short_description_en, '');
  assert.equal(values.full_description_en, '');
  assert.equal(values.image_alt_en, '');
});

test('hydrates legacy drafts from published bilingual content without overwriting draft edits', () => {
  const merged = mergeRouteProductEditorData(
    { itinerary_summary: 'Recorrido', translations: { en: { itinerary_summary: 'Route' } } },
    [{ title: 'Parada', translations: { en: { title: 'Stop', short_description: 'English summary' } } }],
    { product_profile: { schedule_notes: '18:00' }, stop_details: [{ title: 'Parada editada' }] },
  );
  assert.equal(merged.product_profile.schedule_notes, '18:00');
  assert.equal(merged.product_profile.translations.en.itinerary_summary, 'Route');
  assert.equal(merged.stop_details[0].title, 'Parada editada');
  assert.equal(merged.stop_details[0].translations.en.title, 'Stop');
  assert.equal(merged.stop_details[0].translations.en.short_description, 'English summary');
});
test('stale blank drafts cannot erase published bilingual route content', () => {
  const route = mergeRouteLocaleEditorData(
    { title: 'Medieval Barcelona', display_area: 'Gothic Quarter' },
    { title: '', display_area: '   ' },
    { title: 'Fallback title' },
  );
  assert.equal(route.title, 'Medieval Barcelona');
  assert.equal(route.display_area, 'Gothic Quarter');
});

test('stale blank structured drafts cannot erase published product or stop translations', () => {
  const merged = mergeRouteProductEditorData(
    { itinerary_summary: 'Recorrido', translations: { en: { itinerary_summary: 'Route summary' } } },
    [{ title: 'Parada', translations: { en: { title: 'Stop' } } }],
    { product_profile: { translations: { en: { itinerary_summary: '' } } }, stop_details: [{ title: '', translations: { en: { title: '' } } }] },
  );
  assert.equal(merged.product_profile.translations.en.itinerary_summary, 'Route summary');
  assert.equal(merged.stop_details[0].title, 'Parada');
  assert.equal(merged.stop_details[0].translations.en.title, 'Stop');
});