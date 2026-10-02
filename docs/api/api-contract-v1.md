# REST API Contract v1

Base path:

```text
/v1
```

This is a design contract, not generated implementation code yet.

---

## 1. Response conventions

Successful endpoints return explicit resource/pagination objects.

Errors use a stable shape:

```json
{
  "error": {
    "code": "USERNAME_TAKEN",
    "message": "Username is already in use.",
    "details": {}
  }
}
```

The mobile app should primarily branch on stable `code`, not parse human-readable text.

---

## 2. Authentication

### Register

```http
POST /v1/auth/register
```

Body:

```json
{
  "email": "user@example.com",
  "password": "..."
}
```

Returns session/auth data and current user identity.

### Login

```http
POST /v1/auth/login
```

### Refresh

```http
POST /v1/auth/refresh
```

### Logout

```http
POST /v1/auth/logout
```

---

## 3. Current user/profile

### Get current user

```http
GET /v1/users/me
```

### Update current profile

```http
PATCH /v1/users/me
```

Supported V1 fields:

- displayName
- username
- bio
- avatar reference

---

## 4. People search

```http
GET /v1/users?query=huss&cursor=...&limit=20
```

Returns paginated user summaries.

Do not return password/auth/session fields.

### Get user profile

```http
GET /v1/users/:userId
```

---

## 5. Conversations

### List conversations

```http
GET /v1/conversations?cursor=...&limit=20
```

Conversation summary includes enough data for the Chats screen without extra per-row requests:

- id
- other participant summary for direct chat
- last-message summary
- unread count
- updated timestamp

### Create or resolve direct conversation

```http
POST /v1/conversations/direct
```

Body:

```json
{
  "userId": "target-user-id"
}
```

The endpoint is idempotent at product level: if the direct conversation already exists, return it.

---

## 6. Messages

### List message history

```http
GET /v1/conversations/:conversationId/messages?before=cursor&limit=40
```

Response includes:

- items
- nextCursor
- hasMore

### Send message

```http
POST /v1/conversations/:conversationId/messages
```

Body example:

```json
{
  "clientMessageId": "client-generated-uuid",
  "type": "text",
  "text": "Hello",
  "replyToMessageId": null,
  "attachments": []
}
```

`clientMessageId` provides idempotent retry.

### Edit message

```http
PATCH /v1/messages/:messageId
```

### Delete message

```http
DELETE /v1/messages/:messageId
```

Authorization and product time/window rules are server-owned.

---

## 7. Read state

```http
POST /v1/conversations/:conversationId/read
```

Body:

```json
{
  "upToMessageId": "message-id"
}
```

The server updates the authenticated member's read pointer and emits a realtime receipt/update event where appropriate.

---

## 8. Private photo upload (implemented in PR #25)

All media routes require the bearer access token. One image per message is supported; multiple attachments/files/video remain deferred.

```http
POST /v1/media/uploads
```

```json
{
  "purpose": "message",
  "conversationId": "conversation-uuid",
  "mimeType": "image/jpeg",
  "sizeBytes": 123456
}
```

Use `purpose: "avatar"` without a conversation for a profile photo. JPEG/PNG/WebP, at most 6 MiB; conversation membership is checked. Returns `{mediaId, upload: {url, fields}, expiresInSeconds: 300}`. Send a multipart POST to that storage URL with all signed fields and the `file` part last. Never send the API bearer token to storage.

```http
POST /v1/media/:mediaId/complete
```

Owner-only completion validates bytes/format/pixels/orientation, rejects animated input, strips metadata and stores sanitized JPEG. Returns `{mediaId, width, height}`. Completion is idempotent; raw upload completion deadline is 20 minutes and ready unclaimed IDs expire after 7 days.

For a message send `type: "image"`, `imageMediaId: "ready-media-uuid"`, optional `text` caption and normal `clientMessageId`/reply fields to the existing message endpoint. Membership, owner, purpose and conversation are checked under the transaction; an image cannot be reused for another message. Response adds nullable `imageMediaId`. Text messages require nonempty text; image captions may be empty. Edit requires nonempty text. Soft-deleted messages return no image reference.

```http
PATCH /v1/media/:mediaId/avatar
GET /v1/media/:mediaId/content
```

Avatar attachment is owner-only and returns `avatarUrl: "/v1/media/:mediaId/content"`. Persist this API reference. The authenticated content route returns `{url, expiresInSeconds: 300, width, height}` for a signed download; do not persist its URL. Active profile photos are visible to authenticated users; message photos require membership and a live/nondeleted message. Unattached photo preview is owner-only. Previously granted URLs may remain usable until their five-minute expiry after deletion. There is no anonymous public bucket.

Storage supports signed POST (exercised locally with MinIO); public provider compatibility and deployment remain unverified. No image bytes travel over Socket.IO. Media-specific errors currently use the common HTTP exception envelope rather than the planned dedicated MEDIA_* codes listed below.

---

## 9. Device registration (planned; not implemented)

```http
POST /v1/devices
DELETE /v1/devices/:deviceId
```

Used to register/revoke push-notification tokens.

---

## 10. Pagination conventions

- Cursor-based.
- Server-enforced maximum limit.
- Cursor is opaque to clients.
- Ordering must remain deterministic.

---

## 11. Authentication failures

Typical stable error codes:

- INVALID_CREDENTIALS
- TOKEN_EXPIRED
- UNAUTHORIZED
- FORBIDDEN
- USER_NOT_FOUND
- USERNAME_TAKEN
- EMAIL_TAKEN
- CONVERSATION_NOT_FOUND
- MESSAGE_NOT_FOUND
- VALIDATION_ERROR
- RATE_LIMITED
- MEDIA_TOO_LARGE
- UNSUPPORTED_MEDIA_TYPE

The exact list can evolve without changing the envelope.

## Read-state recovery query

`GET /v1/conversations/:conversationId/read-state` requires authentication and
membership, returning `404 CONVERSATION_NOT_FOUND` for missing or inaccessible
conversations. It returns both direct-conversation members:

```json
{
  "conversationId": "uuid",
  "members": [
    {
      "userId": "uuid",
      "lastReadMessageId": "uuid-or-null",
      "lastReadAt": "ISO-timestamp-or-null",
      "lastReadMessageCreatedAt": "ISO-timestamp-or-null"
    }
  ]
}
```

Unread members have null pointer fields. `lastReadMessageCreatedAt` plus
`lastReadMessageId` identifies the canonical read position even outside the
loaded history window. No message content or session details are returned.
The query is read-only and creates no events. The existing mark-read response
and `read.updated` event also include `lastReadMessageCreatedAt` as an additive
field. Commands, membership authorization, and monotonic read semantics are
unchanged. Mobile fetches this snapshot when opening/loading history and when
resynchronizing loaded chats after reconnect.
