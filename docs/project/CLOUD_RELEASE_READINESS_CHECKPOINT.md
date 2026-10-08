# Cloud Release Readiness — 2026-10-08

## Baseline and scope

Branch `feat/cloud-release-readiness`, above PR #28
`feat/backend-vercel-deployment`. Actual starting HEAD:
`67a5b10170a616164898b5ade0655621bc7b829c`.
Fresh baseline Backend CI run `37643337414` and Mobile CI run
`37643337450` both succeeded. PR #28 is open/Ready for review.
This checkpoint is PR #31. Portfolio PRs #29/#30 were merged independently into
`master` by the other project conversation; they contain the site/media rather
than a newer app/backend runtime. The root README links their live showcase.

## Changes

- Root README describes Mingle, our custom NestJS backend, the active Flutter
  composition, cloud providers, supported behavior and release gaps.
- FCM accepts a server-side service-account JSON secret on Vercel. It must
  match the configured Firebase project; malformed credentials produce a fixed
  error without exposing their contents. Local ADC remains supported.
- Bounded push jobs register `waitUntil` at enqueue against the originating
  request, including queued jobs. Closing resolves abandoned pending jobs.
  This keeps best-effort dispatch alive after the response; it does not add a
  durable queue/outbox guarantee.
- Existing health suite covers invalid credentials and queued request
  continuations without external FCM calls.
- Dedicated `scripts/seed-cloud-showcase.mjs` creates fictional reserved-domain
  accounts through authenticated API routes. Stable IDs reuse messages, existing
  direct conversations and media. It targets the verified production origin;
  the separate local seeder retains its loopback-only guard.
- Cloud fixture successfully created: `@mingle_demo`, 12 fictional peers,
  eight conversations, 56 text messages and an image, with object avatars and
  mixed Arabic/English content. Credentials are operator-local, not in Git.
  Sessions created by the seeder were logged out. Existing local accounts and
  credentials were not migrated.
- Local ignored editor launch configurations select the cloud origin explicitly.

## Verification and boundaries

Local Node 24 formatting/lint/source and test typechecking/build passed.
Implementation `8d7db4c10e2ede90c48518591a99b8a9a4e4337c` passed Backend CI
`37729000280` and both Mobile CI jobs in `37729000332`. Existing complete
compiled-app E2E and two-account REST/realtime acceptance remain green.
Production artifact `dpl_LVuvky8EzijF1ivoKxwhmPd1pdQF` was health-verified,
promoted and assigned the stable public origin. Fresh public auth/durable
messages/idempotency/cursors/read/edit, private Sharp/Blob/membership denial,
Socket.IO reconnect/REST recovery and logout checks all passed. Verification
fixtures were cleaned by exact recorded identity; the cloud showcase remains.
Final exact HEAD, GitHub CI runs and deployment acceptance are recorded in PR
metadata after publication to avoid a self-referential commit hash.
The local health-suite attempt could not start with unavailable local database
services; disposable GitHub CI is the complete E2E acceptance gate.

No Simulator interaction, native build or native visual acceptance was performed.
Pre-existing Flutter-generated platform migrations/linker fixes and
`ios/Podfile.lock` remain local and excluded from this checkpoint.

Production `PUSH_ENABLED=false`: FCM credentials, APNs configuration and actual
device delivery/account-routing remain unverified. A local Apple Development
identity exists; that alone does not establish push provisioning.

## Next

Supply scoped server credentials for existing Firebase project
`chatapp2-29a9e`, then verify provider authorization and user-owned native
delivery. Continue public abuse controls and media cleanup before a store
release. Device acceptance and PR-stack review remain separate; no merge or
force push occurred.
