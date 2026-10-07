import { readFileSync, existsSync } from 'node:fs';
import assert from 'node:assert/strict';
const html = readFileSync('index.html','utf8');
const ids = [...html.matchAll(/\bid="([^"]+)"/g)].map(m => m[1]);
assert.equal(ids.length, new Set(ids).size, 'Duplicate HTML IDs');
for(const [,target] of html.matchAll(/href="#([^"]+)"/g)){
  assert(ids.includes(target), 'Broken anchor: #' + target);
}
for(const path of ['site/styles.css','site/main.js','site/assets/cover.svg','site/assets/brand.svg']){
  assert(existsSync(path), 'Missing asset: ' + path);
}
for(const marker of ['data-preview="chats"','data-preview="message"','data-preview="people"','data-pane="chats"','data-pane="message"','data-pane="people"']){
  assert(html.includes(marker), 'Missing screen switcher element: ' + marker);
}
assert(html.includes('not a runtime capture'), 'Missing visual honesty label');
assert(!/download[^\n]*\.apk/i.test(html), 'Do not link an unverified APK');
console.log('Site checks passed.');
