# Data Model v1

## Scope

The model supports the initial one-to-one messenger while avoiding decisions that would block future group conversations.

Names below are conceptual; exact ORM/database naming can be refined during implementation.

---

## 1. User

Key fields:

```text
id
email
email_normalized
password_hash
display_name
username
username_normalized
bio
avatar_storage_key
created_at
updated_at
```

Constraints:

- `email_normalized` is required, lowercase, and unique.
- `username_normalized` is lowercase and unique when present.
- `username`, `display_name`, `bio`, and avatar data may be null immediately after account registration because profile completion is a separate product step.
- Avatar persistence stores an object-storage key rather than assuming a permanent public URL.
- Password material is stored only as a password hash; raw passwords are never persisted.

---

## 2. Conversation

```text
id
type              // direct initially
direct_key         // canonical participant pair for direct chats
last_message_id
created_at
updated_at
```

For a direct conversation, `direct_key` can be generated from the sorted participant IDs and protected by a unique constraint.

This prevents duplicate one-to-one conversations at the database level, not only in UI logic.

---

## 3. ConversationMember

```text
conversation_id
user_id
joined_at
last_read_message_id
last_read_at
muted_until        // optional/later
```

Primary/unique key:

```text
(conversation_id, user_id)
```

Even though V1 is direct chat, membership is modeled separately so group support is not structurally blocked.

---

## 4. Message

```text
id
client_message_id
conversation_id
sender_id
type               // text, image
text
reply_to_message_id
created_at
edited_at
deleted_at
```

Important constraints/indexes:

- unique `(sender_id, client_message_id)` for idempotent retry
- index `(conversation_id, created_at, id)` for cursor pagination
- foreign key for reply target

A deleted message can be soft-deleted initially so conversation history remains structurally consistent.

---

## 5. Attachment

```text
id
message_id
kind
storage_key
mime_type
size_bytes
width
height
created_at
```

V1 needs image attachments.

Additional fields may be added later for audio/video only if those features enter scope.

Store an object/storage key rather than assuming permanent public URLs.

---

## 6. DeviceToken

```text
id
user_id
token
platform
device_id          // if available/appropriate
last_seen_at
created_at
revoked_at
```

Used for push notifications.

A user may have multiple devices.

---

## 7. RefreshSession

Conceptual fields:

```text
id
user_id
token_hash
expires_at
created_at
revoked_at
device_metadata
```

Never store raw long-lived refresh tokens when a hashed/session approach is available.

---

## 8. Read-state model

V1 uses a member-level read pointer:

```text
ConversationMember.last_read_message_id
ConversationMember.last_read_at
```

For one-to-one chat, this is enough to derive whether the recipient has read a given message.

If future group semantics require per-message/per-user receipt history, introduce a separate MessageReceipt table then rather than paying that complexity upfront.

---

## 9. Message status

Client visual status:

```text
sending
sent
read
failed
```

Server persistence does not store `failed`; failure is a local client delivery state.

`sent` means the server durably accepted the message.

`read` is derived from recipient read progress.

A separate `delivered` state is intentionally deferred unless the product defines reliable device-delivery semantics.

---

## 10. Pagination

Message history uses cursor pagination based on stable ordering such as:

```text
(created_at, id)
```

Do not use large offset pagination for message history.

---

## 11. Conversation list ordering

Default ordering:

- most recent effective message/activity first

Conversation-list queries should avoid loading entire message histories.

Use last-message reference/summary carefully and transactionally where necessary.

---

## 12. Deletion semantics

V1 recommendation:

- Account deletion behavior requires a dedicated product/privacy decision.
- Message delete initially supports sender-authorized message deletion according to product rules.
- Physical media cleanup can be asynchronous after references are removed.

Do not invent retention guarantees until deployment/privacy policy is defined.
