import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const css = readFileSync(new URL('../src/styles/global.css', import.meta.url), 'utf8');

test('mobile route cards cannot collapse into vertical text columns', () => {
  assert.match(css, /\.route-carousel-shell \.route-carousel\{[^}]*display:flex!important[^}]*overflow-x:auto/s);
  assert.match(css, /\.route-carousel-shell \.route-carousel>\.route-card\{[^}]*flex:0 0 100%!important[^}]*min-width:100%!important/s);
  assert.doesNotMatch(css, /word-break\s*:\s*break-all/i);
  assert.doesNotMatch(css, /writing-mode\s*:\s*vertical/i);
});

test('all other horizontal public collections retain explicit mobile widths', () => {
  assert.match(css, /\.route-gallery--carousel>div\[data-route-gallery-list\][\s\S]*\.related-routes-list\{[^}]*display:flex!important[^}]*overflow-x:auto/s);
  assert.match(css, /\.route-gallery--carousel>div\[data-route-gallery-list\]>figure\{[^}]*flex:0 0 88%/s);
  assert.match(css, /\.route-stop-media--carousel>\*\{[^}]*flex:0 0 92%/s);
  assert.match(css, /\.related-routes-list>a\{[^}]*flex:0 0 min\(84vw,340px\)/s);
  assert.match(css, /\.compare-scroll\{[^}]*overflow-x:auto/s);
});

test('comparison becomes readable route cards on mobile', () => {
  const comparison = readFileSync(new URL('../src/components/RouteComparison.astro', import.meta.url), 'utf8');
  assert.match(css, /\.compare-desktop\{display:none\}/);
  assert.match(css, /\.compare-mobile\{display:grid;gap:18px\}/);
  assert.match(comparison, /class="compare-mobile"/);
  assert.match(comparison, /class="compare-card"/);
  assert.doesNotMatch(comparison, />\s*(?:Característica|Feature)\s*</i);
});
test('public mobile page titles stay larger than major section titles', () => {
  assert.match(css, /--public-page-title:clamp\(2\.75rem,11vw,3\.35rem\);--public-section-title:clamp\(2rem,8\.5vw,2\.5rem\)/);
  assert.match(css, /\.page-hero>\.page-hero-copy h1,\.page-hero\.compact h1,\.route-hero-copy h1\{font-size:var\(--public-page-title\)!important/);
  assert.match(css, /\.editorial-layout h2,\.reviews-page \.split-heading h2,\.detail-main h2,\.partner-card h2\{font-size:var\(--public-section-title\)!important/);
});

test('mobile home hero stays in normal flow and inside the viewport', () => {
  assert.match(css, /\.home-route-hero-copy\{[^}]*position:relative[^}]*inset:auto[^}]*bottom:auto[^}]*width:calc\(100% - 32px\)[^}]*box-sizing:border-box/s);
  assert.match(css, /\.home-route-hero-copy \.hero-actions\{[^}]*grid-template-columns:minmax\(0,1fr\)[^}]*width:100%/s);
  assert.match(css, /\.home-route-hero-copy \.hero-actions \.button\{[^}]*width:100%[^}]*min-width:0[^}]*box-sizing:border-box/s);
});
