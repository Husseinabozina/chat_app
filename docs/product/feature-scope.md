# Feature Scope

## Scope principle

The project intentionally favors **fewer features implemented deeply** over a large collection of shallow features.

A feature earns a place in the initial release when it provides strong user value, demonstrates useful engineering skill, fits the product direction, and does not create disproportionate scope.

## Initial portfolio scope

### Authentication and profile

- Sign up
- Sign in
- Sign out
- Profile setup
- Profile image
- Display name
- Unique username
- Short bio
- Edit profile

### People

- Search users by name or username
- User profile view
- Start a conversation
- Reuse an existing one-to-one conversation instead of creating duplicates
- Empty/search/no-results states

### Conversations

- Conversation list
- Last-message preview
- Timestamp
- Unread count
- Read/unread handling
- Conversation search
- Loading, empty, error, and offline-aware states

### Messaging

- One-to-one realtime text messages
- Message timestamps
- Message grouping
- Image messages
- Reply to message
- Edit own message
- Delete own message
- Sending state
- Sent state
- Read state
- Failed state
- Retry failed messages
- Typing indicator
- Message pagination / load older messages
- Unread separator/positioning where useful

### Notifications and navigation

- Push notifications
- Notification routing/deep linking into the relevant conversation
- Foreground/background handling appropriate to the chosen backend and notification stack

### Reliability and product behavior

- Offline-aware behavior
- Graceful network errors
- Retry strategy
- Validation with user-friendly errors
- No raw backend/Firebase errors shown directly to users

### Appearance and settings

- Light / dark / system appearance
- Notification settings where supported
- Basic profile/account settings

## Strong candidates after the core is stable

These may be added only after the initial scope is complete and verified:

- Message reactions
- Voice notes
- Presence / online / last seen
- Pin conversations

The project should select only a small number of these, not all by default.

## Later, not initial scope

- In-chat full-text search
- Message pinning
- Groups
- Disappearing messages
- Advanced privacy controls
- Blocked-user management
- Storage-management tooling
- Chat backup

## Explicitly out of scope for the initial project

- Stories/status
- Audio/video calls
- Channels
- Communities
- Bots
- Live location
- Social feed
- Match/swipe mechanics
- Dating-specific interactions
- Polls unless later justified by a broader group-chat direction
- AI features added only for novelty

## Feature selection rubric

Before adding a new feature, evaluate:

1. **User value** — does it solve a real messaging need?
2. **Portfolio value** — does it demonstrate a meaningful engineering capability?
3. **Architecture value** — does it introduce a worthwhile problem to model or solve?
4. **Implementation cost** — is the complexity justified?
5. **Product fit** — does it strengthen the focused one-to-one messenger?
6. **Quality risk** — will it reduce time available for testing, polish, and reliability?

A visually impressive feature should not displace a less flashy feature with greater engineering value such as pagination, retry, offline behavior, or delivery state.

## Scope freeze rule

Once implementation begins, additions should be treated as scope changes. New ideas go into a backlog first and are not automatically added to the current release.
