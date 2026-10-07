import { readFileSync, existsSync, statSync } from 'node:fs';
import assert from 'node:assert/strict';

const html = readFileSync('index.html', 'utf8');
const allIds = [...html.matchAll(/\bid="([^"]+)"/g)].map(m => m[1]);
assert.equal(allIds.length, new Set(allIds).size, 'HTML ids must be unique');
for (const [, target] of html.matchAll(/href="#([^"]+)"/g)) {
  assert(allIds.includes(target), `Broken anchor: #${target}`);
}

const relative = [...html.matchAll(/\b(?:src|href)="(site\/[^"?#]+)"/g)].map(m => m[1]);
for (const asset of new Set(relative)) {
  assert(existsSync(asset), `Missing site asset: ${asset}`);
  assert(statSync(asset).size > 0, `Empty site asset: ${asset}`);
}
assert(relative.filter(ref => ref.endsWith('.webp')).length >= 9, 'Actual screenshots required');
assert(relative.filter(ref => ref.endsWith('.mp4')).length === 2, 'Both real simulator videos required');
assert((html.match(/\bdata-image=/g) || []).length >= 9, 'Image gallery navigation missing');
assert(html.includes('privacy-redacted'), 'Privacy redaction note must remain visible');
assert(html.includes('not implemented or connected'), 'Realtime integration honesty disclaimer missing');
assert(!/\bhatest22\s*@/i.test(html), 'Personal email exposed in HTML');
assert(!/download[^\n]*\.apk/i.test(html), 'Do not advertise an unverified Android APK');
for(const video of ['site/assets/walkthrough.mp4','site/assets/states.mp4']) {
  assert(statSync(video).size < 3_000_000, `Oversized showcase video: ${video}`);
}
console.log('Mingle showcase checks passed.');
