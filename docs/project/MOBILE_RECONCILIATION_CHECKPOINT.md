# Mobile reconciliation and backend session lifecycle

Checkpoint date: 2026-10-01. Base: PR #16 / `b0a68f4908a60facea617655b358e478b22a7004`.

## Delivered boundaries

`ConversationsRepository` exposes immutable domain snapshots and REST commands;
`ApiConversationsRepository` composes replaceable REST/realtime sources.
`BackendAccountRepository` defines email/password accounts without importing the
legacy image-required Firebase registration contract. `BackendSessionController`
owns account-scoped cache/subscriptions/socket lifetime.

## Correctness rules

- Server IDs reconcile canonical messages; one client ID and payload survive send retries.
- REST and socket observations reconcile in either order, including a post-commit
  socket confirmation followed by an interrupted REST response.
- Deleted state is terminal. Confirmed local deletes hide text without inventing
  a server deletion timestamp. Newer edits cannot be overwritten by older creates/edits.
- Message/read positions use `(createdAt, id)`. Event IDs are bounded deduplication
  keys, not a replay cursor. Event time and client clocks do not order read pointers.
- Every connection-ready notification triggers REST resync. Loaded list/history
  windows and both members' read pointers are refreshed; events are buffered while
  this runs. Buffer overflow invalidates and repeats the snapshot.
- Conversation summaries lack a durable revision. They invalidate the REST list
  instead of overwriting unread counts using uncertain event/request ordering.
- Background pause disconnects without erasing durable cache. Foreground resume
  reconnects and resyncs. Typing is transient, throttled, and expires locally.
- Logout/account replacement reject late REST/auth/refresh responses, serialize
  storage writes, and erase account caches. Delayed successful auth/refresh
  responses revoke returned refresh tokens on a best-effort basis.

## Necessary backend addition

The existing backend could update read pointers but offered no recovery query.
An offline client could restore messages and unread counts while missing another
member's read receipt. `GET /v1/conversations/:id/read-state` now restores both
members' canonical positions and enforces membership in the query. It returns
404 to outsiders and missing conversations, and 401 without authentication.
An additive canonical-position field on mark-read/read events also permits
comparison outside the loaded message window. No migration or dependency change.

## Limits and next checkpoint

The legacy Firebase entrypoint is still active. The new backend path is staged
for the approved direct-conversation UI. Cache/outgoing data is in memory; there
is no durable offline outbox. Summary invalidations may issue extra REST calls.
Message edits share timestamp-based versioning, without an independent revision.
Real-device two-account backend/socket integration remains to be verified with
the new UI. Presence, media, push, outbox/Redis and public deployment hardening
remain separate work.

Next: review the open stack, then implement the approved backend account,
conversation-list/history UI and lifecycle hooks with repository contracts.
Include a two-account integration pass for send/retry/edit/delete/read/reconnect.
Do not claim Firebase entrypoint migration or public deployment is complete.

## Verified result

PR #17 is stacked above #16 and ready for review, unmerged. Implementation
commit `9c369dc661d4e59341318304c3b779eeb5425991` passed Backend CI
[run #82](https://github.com/Husseinabozina/chat_app/actions/runs/36798100758)
and Mobile CI
[run #16](https://github.com/Husseinabozina/chat_app/actions/runs/36798100980).
Backend: 20 tests passed; mobile: 37 passed. GitHub's synthetic PR merge tree
matches the implementation tree exactly; this was not a branch merge.
Local format/analyze/tests and backend static/build checks also passed.
Final documentation HEAD/checks are recorded in the PR verification section.
