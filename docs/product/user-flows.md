# User Flows

## Information architecture

Primary authenticated navigation:

```text
Chats
People
Profile
```

Meaning:

- **Chats** — people the user is already talking to.
- **People** — people the user can discover and start talking to.
- **Profile** — the current user's identity and settings.

This separation is intentional and avoids a dating-style "Discover" model.

## App launch

```text
Launch
→ initialize app
→ restore session
→ authenticated?
   ├─ no  → authentication
   └─ yes → main shell / chats
```

Initialization should be fast and should not introduce an artificial splash delay.

## Registration

```text
Welcome/Auth
→ Create account
→ email/password validation
→ account created
→ Complete profile
   → profile image
   → display name
   → username
   → short bio
→ Main shell
```

Relevant states:

- Validation error
- Username unavailable
- Image upload in progress
- Network failure
- Account creation failure
- Retry

## Sign in

```text
Welcome/Auth
→ Sign in
→ credentials submitted
→ success → Chats
→ failure → friendly actionable error
```

No raw infrastructure error should reach the UI.

## Find a person and start a chat

```text
People
→ search by name/username
→ results
→ open user profile
→ Message
→ existing conversation?
   ├─ yes → open it
   └─ no  → create/open one-to-one conversation
→ Chat
```

Invariant:

A pair of users should not accidentally create multiple independent one-to-one conversations unless product requirements explicitly change later.

## Conversation list

```text
Chats
→ load conversations
→ search/filter if needed
→ tap conversation
→ Chat
```

Primary information per row:

- Avatar
- Name
- Last-message preview
- Timestamp
- Unread badge
- Outgoing message status where useful

Required screen states:

- Loading
- Content
- Empty
- Error
- Offline/cached content

## Send a text message

```text
Chat
→ type
→ send
→ optimistic/sending state
→ backend accepted
→ sent state
→ recipient reads
→ read state
```

Failure path:

```text
send
→ failure
→ message remains visible as failed
→ user retries
→ success or remains failed
```

A failed message should not silently disappear.

## Reply

```text
Long press message
→ Reply
→ quoted-message context appears in composer
→ type response
→ send
→ new message displays reply reference
```

The user can cancel reply mode before sending.

## Edit own message

```text
Long press own message
→ Edit
→ edit state/composer
→ save
→ message updates
→ subtle "edited" indicator
```

## Delete own message

```text
Long press own message
→ Delete
→ confirm
→ delete
→ UI updates consistently
```

Advanced "delete for me / everyone" semantics are not required for the initial release unless later specified.

## Send an image

```text
Chat
→ attachment action
→ camera or gallery
→ preview
→ optional caption
→ send
→ upload progress/sending state
→ success or retryable failure
```

## Pagination

```text
Open chat
→ load recent page
→ scroll toward older history
→ request older page
→ preserve scroll position
→ append older messages
```

The application should not load an unbounded message history at once.

## Typing

```text
User begins typing
→ transient realtime event
→ other participant sees subtle typing state
→ typing stops / timeout / message sent
→ indicator disappears
```

Typing state should not be persisted as message history.

## Push notification

```text
Incoming message while app is backgrounded/closed
→ push notification
→ user taps notification
→ session/navigation resolves
→ target conversation opens
```

## Profile

```text
Profile tab
→ view own profile
→ Edit profile
→ modify supported fields
→ save
→ success/error state
```

## Global state model

Relevant product surfaces should explicitly consider:

- Loading
- Content
- Empty
- Error
- Offline
- Cached/partial content
- Action loading
- Action failure
- Retry
- Disabled
- Success feedback where needed

These states should inform both UI design and state-management architecture.
