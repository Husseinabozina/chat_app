# Chat App portfolio site

The responsive static site is served from `index.html` with supporting assets in `site/`. It is a **portfolio presentation**, not the running Flutter application.

## Verified content boundary

- **Mobile today:** Flutter client uses its legacy Firebase-backed messaging flow.
- **Backend today:** NestJS/PostgreSQL supports authentication, user discovery, one-to-one conversations, durable REST text messages, read pointers, edits and soft deletes.
- **Not yet integrated:** Flutter mobile and the custom backend.
- **Not yet shipped:** Socket.IO realtime backend, multi-conversation redesign, media, push and production deployment.
- **Illustrations:** The phone UI on the page is created with HTML/CSS to present the **approved** visual direction from `docs/design/approved-ui-direction.md`. These are not runtime screenshots.

Keep these statements synchronized with `docs/project/CURRENT_STATE.md` after major milestones. Replace illustrative UI with actual verified screenshots only once the new Flutter screens are running and captured.

## Development

From the repository root:

```sh
python3 -m http.server 4173
# open http://localhost:4173/
node --check site/main.js
node site/check.mjs
```

The site has no build dependencies. The optional Google Fonts request uses fallback system fonts when offline.

## GitHub Pages publishing

`.github/workflows/showcase-pages.yml` validates pull requests and publishes on a push to `master` or manual run. It stages **only** the static site files rather than exposing the backend/source tree as public Pages content.

For first-time publishing, in **Settings → Pages**, select **GitHub Actions** as the build/deployment source and ensure Actions has permission to deploy Pages. Merge the PR and verify the workflow has completed successfully, then visit:

**https://husseinabozina.github.io/chat_app/**

This URL is an intended destination and must not be represented as live until the Pages workflow has succeeded.

## Add actual Flutter screenshots later

1. Capture the running product using sample/non-private content, and review each image.
2. Add suitable optimized image files to `site/assets/screens/`.
3. Replace the illustrative preview or add an accessible gallery, keeping clear labels between product concepts and real application captures.
4. Update the main README and link the published site from the shared `app-showroom` catalog after verifying it is reachable.

An Android download link should appear **only** when a tested APK actually exists and its backend/Firebase configuration is safe for a public demo. Never advertise an APK solely because a Flutter project can be built.

## Site checklist

- Responsive layout (phone, tablet and desktop).
- Keyboard-accessible screen selector and reduced-motion support.
- Documented in-progress status, current/next milestones and source links.
- No fake APK, false realtime claim or unverified implementation screenshots.
