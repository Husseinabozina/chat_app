# Mingle portfolio site — source, boundaries and delivery

## Purpose

The Mingle showcase is an independently authored, responsive static case study using **real simulator captures** supplied by the project owner (October 6, 2026). It replaces the earlier concept-only page. It should lead with the actual product visuals and video rather than unsupported claims about unimplemented app behaviour.

## Media provenance

- Seven source iPhone 17 Pro simulator PNGs provided in the conversation: splash, sign-in, sign-up, profile setup, empty chats, populated chats and profile.
- Two original `.mov` simulator screen recordings (approximately 15.14 and 4.56 seconds) supplied in the same exchange.
- Three screenshot stills (`conversation.webp`, `people.webp`, `unread.webp`) extracted from the footage for the gallery and video poster states.
- Screenshots resized to 659 px wide for web delivery; WebP lossily compressed for fast loading. Video encoded to H.264 MP4, 540 px wide at 24fps (no audio stream in supplied videos).
- **Privacy:** The source registration screenshot contained an email address. Its published derivative `site/assets/sign-up.webp` replaces that field text with a privacy label. Do not upload the unredacted original PNG.

## Distinguish portfolio evidence from version-controlled runtime

The screenshots and recordings reflect a recent **user-supplied local simulator build**. They are not a claim that the new UI flows have been merged into the GitHub `master` baseline described in [CURRENT_STATE.md](project/CURRENT_STATE.md). Current repository facts:

- Flutter client is feature-first and still uses its legacy Firebase-backed chat experience.
- NestJS/PostgreSQL REST backend implements auth, user discovery, direct conversations, durable text messaging and read states.
- The custom backend has **not yet** been integrated into the active Flutter mobile client.
- Socket.IO realtime backend is planned in an approved protocol contract, but **not implemented**.
- There is no safe and verified public APK for download at this checkpoint.

Update these statements and the root README when implementation milestones move forward. Do not create fictitious app screens, fake performance stats or misleading production-readiness badges.

## Structure / publishing

The top-level `index.html` loads static CSS/JavaScript from `site/`. The showcase Pages GitHub Action validates it and stages only the root entry point, `.nojekyll` and `site/` assets on pushes to `master`. No backend secrets or mobile source files are published through Pages.

Run local validations from the repository root:

```sh
node --check site/main.js
node site/check.mjs
```

Deploy destination (after the workflow succeeds): `https://husseinabozina.github.io/chat_app/`.

## Accessibility and usability

- Actual original images are interactive gallery items with a modal and arrow-key navigation, not CSS placeholders.
- Videos are native `<video controls>` elements; audio and autoplay are deliberately disabled.
- Responsive viewport support; skip navigation, alt text, visible focus and `prefers-reduced-motion`.
- Product typography and palette are echoed, while site layout uses a more editorial, restrained treatment to avoid competing with screenshots.

## Later checkpoints

As the repo's mobile UI catches up with the recorded local demo, add traceable in-repository screenshot capture recipes, safe demo fixtures and feature checks. Only surface a demo APK when tested and appropriate for public access.
