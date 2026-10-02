# Message notification checkpoint

2026-10-02. Branch `feat/push-notifications`, based on exact PR #25 final HEAD `ce43154864b9520a4f7178c180e764801e00c6a3`. Baseline Backend CI #85 and Mobile CI #35 passed on that commit.

## Implemented

- Authenticated `GET /v1/devices/status`, `POST /v1/devices` and `DELETE /v1/devices/installations/:installationId`. Register accepts installation UUID, FCM token and ios/android platform; never accepts a caller-supplied account/session.
- Migration adds unique nullable installation_id and nullable session_id FK to existing device_tokens. Legacy rows without a backing session are excluded. Registration/rotation/account transfer is serialized by actor row/session/advisory locks, retains one installation, respects existing global token uniqueness and limits active recent devices to 20 per account.
- Sending targets recipient membership plus non-revoked/unexpired backing sessions, recent tokens, unmuted unread nondeleted messages. Eligibility is checked again before provider calls; invalid provider tokens are revoked conditionally. Only newly created durable messages enqueue; stable client-id retries do not enqueue duplicates. Read/edit/delete/realtime commands remain unchanged.
- FCM Admin SDK14.5.0 pinned in backend lockfile. Explicit PUSH_ENABLED=true + FCM_PROJECT_ID; credentials use ADC/GOOGLE_APPLICATION_CREDENTIALS outside Git. No personal Firebase CLI credential is copied into the server.
- Notifications contain generic Mingle/new-message copy without sender/text/photo URL. Data contains versionless type=message plus target user/conversation/message UUIDs; client verifies target account then retrieves an authorized canonical conversation summary from new GET /v1/conversations/:id.
- Flutter existing firebase_messaging is wrapped in an optional domain push port. Per-account device preference, explicit permission request from Settings, token refresh, resume registration, server revocation before disable, device installation persisted separately from session. Cold getInitialMessage and background onMessageOpenedApp are handled with deduplication; initial routing waits for restore/onboarding and does not bypass profile completion. Foreground native alerts are suppressed while realtime updates the app.
- Settings reflects server/device availability; a missing server configuration does not present an enabled notification feature. Backend project ID must match existing client Firebase options.
- Native Android INTERNET (required for release REST) and POST_NOTIFICATIONS permission. iOS entitlements and debug development/profile-release production APS setting, remote-notification/fetch modes and auto-init disabled until opt-in. Only these new settings are staged; existing native migrations/linker changes remain local/unpublished. No native build launched.

## Delivery boundary

V1 push is best effort after the SQL commit: an in-memory queue holds at most 100 pending IDs, two jobs run concurrently, and messages older than five minutes are excluded. It is neither a durable outbox nor an exactly-once delivery promise. SDK retry behavior can still duplicate delivery after response loss. Generic OS notifications already handed to FCM/APNs can remain after logout/deletion; the open path rejects another account and rechecks membership. Offline logout retains the established best-effort remote revocation limit. Foreground alerts, badge counts, per-chat settings UI, durable retry workers and delivery receipts are not silently added.

## Account configuration and verification

Existing client project `chatapp2-29a9e` / iOS bundle com.example.chatApp3 / Android com.example.chat_app3. Firebase connector is authenticated and lists this project as ACTIVE; no cloud/project/IAM configuration changed. Latest CLI15.32.1 checked per firebase-basics skill. No local server ADC environment/default file or code-signing identity is present in the inspected locations. An Apple Developer membership question is pending. This does not establish that APNs is absent in the remote project; it has not been inspected.

Host format/analyze and backend lint/typecheck/build pass during implementation; local migration and existing CI are recorded on publication. Existing suites remain unchanged; no new suite added. CI with PUSH_ENABLED off does not exercise provider delivery, installation transfer/routing/permission matrix or native push. Do not claim actual FCM/APNs delivery or release readiness.

To activate: provide scoped server credentials for existing project, enable FCM HTTP v1 API, configure APNs key in Firebase and a matching signing team/provisioning identity, rebuild/run the user-owned native app, then enable New messages in Settings and accept device permission. Actual two-device cold/background/logout/token-rotation/read-race/offline acceptance remains required.

## Vercel assessment (2026-10-02)

Official current docs support NestJS Functions and WebSockets/Socket.IO in public Beta. Socket.IO requires websocket transport (already used by mobile); connections end at function duration and future clients may reach different instances. Current in-memory server rooms/pubsub/session-revocation coordination are single-instance; a Vercel deployment needs an external shared adapter/coordination plus external PostgreSQL and private compatible object storage. No Vercel deploy/configuration or architecture rewrite included here. A persistent single-server/container host fits the existing V1 architecture with less adaptation; this is an architectural assessment, not measured provider performance or a final vendor choice.

Sources: https://vercel.com/docs/functions/websockets ; https://vercel.com/docs/frameworks/backend/nestjs ; https://firebase.google.com/docs/cloud-messaging/flutter/get-started ; https://firebase.google.com/docs/cloud-messaging/send/v1-api

## Next

Finish account/provider configuration and actual delivery/native acceptance; public deployment hardening/storage lifecycle and signing/release. Preserve user build ownership; no merges/force push. CURRENT_STATE and PR metadata must record exact final HEAD/checks.
