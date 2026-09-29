# High-Fidelity Screen Planning

## Status

This document translates the approved product scope and Design System v1 into a concrete screen-by-screen plan.

It is intentionally positioned **between** product/UX planning and pixel-perfect high-fidelity mockups.

The goal is to remove ambiguity before visual production and Flutter implementation by defining:

- Screen purpose
- Information hierarchy
- Component composition
- Content expectations
- Interaction behavior
- Loading / empty / error / offline states
- Responsive/adaptive considerations
- Accessibility requirements
- Technical implications that the UI must not hide

This document does **not** yet freeze exact pixel coordinates or final illustrations.

---

# 1. Screen inventory

## Unauthenticated

1. Welcome / Sign In
2. Create Account
3. Complete Profile

## Authenticated primary navigation

4. Chats
5. People
6. My Profile

## Secondary/detail screens

7. User Profile
8. Conversation / Chat
9. Edit Profile
10. Settings / Appearance
11. Image Preview / Send
12. Contextual message actions / sheets

The initial visual-design pass should prioritize:

1. Welcome / Auth
2. Chats
3. People
4. User Profile
5. Chat

These five screens validate nearly the entire visual language.

---

# 2. Global mobile frame

## Target baseline

Primary design baseline:

- Mobile-first
- Portrait
- Common phone width: approximately 390-430 logical pixels
- Minimum compact width to validate: approximately 320-360 logical pixels
- Large-phone validation: approximately 430-480 logical pixels
- Tablet validation follows after the phone composition is stable

No component should be hard-coded to a single screenshot width.

## Safe areas

All screens must respect:

- Status bar
- Display cutouts
- Bottom gesture/home area
- Keyboard insets
- Platform text scaling

## Standard screen rhythm

Typical phone composition:

```text
Safe area
↓
Top/header region
↓
Primary content
↓
Optional floating/contextual action
↓
Bottom navigation or composer
↓
Safe area
```

Default horizontal content padding starts at 20dp and may reduce to 16dp on narrow screens.

---

# 3. Welcome / Sign In

## Purpose

Provide a warm first impression and allow a returning user to authenticate without visual clutter.

## Visual intent

The screen should establish the product personality immediately:

- Warm off-white background
- Soft blush decorative region/shape
- Friendly illustration or abstract social/message illustration
- Strong but not oversized headline
- Minimal form
- One clear primary action

The screen must not communicate dating.

## Information hierarchy

```text
Brand / mark
Illustration or visual accent
Headline
Supporting copy
Email field
Password field
Primary Sign In button
Secondary Create Account action
Optional password recovery link
```

## Recommended copy direction

Headline examples should communicate connection or conversation, not romance.

Example tone:

```text
Stay connected.
Talk naturally.
```

Final brand copy is deferred until the product name is chosen.

## Components

- Brand mark
- Hero illustration
- `AppTextField` — email
- `AppTextField` — password
- `AppButton` — primary sign in
- Text action — create account
- Text action — forgot password, if included in initial auth scope

## States

- Default
- Focused field
- Validation error
- Invalid credentials
- Loading/authenticating
- Network failure
- Password visible/hidden
- Keyboard visible

## Interaction notes

- Sign In remains disabled or safely rejected until minimum valid input exists.
- Keyboard actions move logically email → password → submit.
- Loading does not resize the primary button.
- Authentication errors appear close to the form and in human language.

## Accessibility

- Inputs have persistent semantic labels.
- Error messages are associated with the relevant field.
- Illustration is decorative unless it communicates necessary content.
- Primary CTA remains reachable with large text.

---

# 4. Create Account

## Purpose

Create credentials with minimum friction.

## Information hierarchy

```text
Back
Create your account
Short supporting sentence
Name
Email
Password
Confirm password
Create Account
Already have an account? Sign In
```

Profile image and extended profile information are intentionally deferred to the next screen.

## Why separate account and profile setup

This avoids:

- A visually heavy registration form
- Mixing authentication errors with media-upload errors
- Excessive cognitive load
- Tight coupling between account creation and optional profile enrichment

## States

- Validation errors
- Email already used
- Password requirement feedback
- Submitting
- Network failure
- Account-created transition

---

# 5. Complete Profile

## Purpose

Turn a new account into a recognizable identity before entering the messenger.

## Composition

```text
Progress / subtle step indication
Title
Profile avatar
Change/Add photo
Display name
Username
Short bio
Finish
Optional skip only if product rules allow it
```

## Avatar

Large profile avatar becomes the visual anchor.

Possible treatment:

- 104-120dp
- Soft accent halo or decorative blush shape
- Camera/edit badge
- Fallback initials

## Username behavior

The UI should support:

- Available
- Checking
- Unavailable
- Invalid characters
- Network failure while validating

Do not rely on red/green color alone.

## Upload behavior

If avatar upload is required:

- Show progress without freezing the entire screen.
- Preserve entered text if upload fails.
- Allow retry.

---

# 6. Main navigation shell

## Tabs

```text
Chats | People | Profile
```

## Visual treatment

- Soft floating/rounded navigation container
- Selected tab uses primary/accent identity
- Inactive icons use secondary text
- Labels remain visible
- Safe-area aware

## Navigation behavior

- Preserve scroll position when switching tabs where practical.
- Tapping the currently selected tab may scroll to top if this behavior is adopted consistently.
- Deep links should be able to open a conversation independently of the currently selected tab.

---

# 7. Chats screen

## Purpose

Give the user fast access to active conversations and unread activity.

## Visual hierarchy

```text
Greeting / compact identity row (optional)
Chats title
Search conversations
All / Unread filter
Conversation list
Bottom navigation
```

The screen should remain calm and spacious despite potentially large lists.

## Header options

Preferred direction:

```text
Chats
[small current-user avatar or subtle action]
```

Avoid an oversized decorative header that steals space from conversation content.

A contextual greeting may be explored in mockups but is not mandatory.

## Search

Use `AppSearchField` with:

- Search icon
- Placeholder
- Clear button
- Debounced query
- Search-state feedback

## Filter

Initial filter set:

- All
- Unread

Do not add extra categories unless product research later justifies them.

## Conversation tile

Each row contains:

```text
Avatar
Name                         Time
Last message preview      Unread badge
Optional outgoing status
```

### Hierarchy

1. Name
2. Last-message preview
3. Unread state
4. Timestamp
5. Secondary status

## Row behavior

Tap:
- Open conversation

Long press / context:
- Optional future actions such as pin/mute

Initial version should not overload the row.

## Message preview rules

Examples:

- Text: actual preview
- Image: "Photo" with icon
- Deleted message: neutral system copy
- Failed outgoing: failure indicator + preview
- Draft, only if draft persistence is implemented later

## Screen states

### Loading

Prefer skeleton conversation rows rather than a full-screen spinner.

### Empty

```text
Friendly illustration

No conversations yet

Find someone and start a conversation.

[ Find people ]
```

### Search empty

```text
No conversations found
```

### Error

Keep retry near the failed content region.

### Offline with cache

- Keep conversation list visible.
- Show subtle offline banner.
- Timestamp/cache freshness should not create unnecessary anxiety.

---

# 8. People screen

## Purpose

Help users discover another registered user and begin a conversation without dating-style mechanics.

## Composition

```text
People title
Search by name or username
Suggested / Recent people (optional)
People results/list
Bottom navigation
```

## Core rule

People = "Who can I talk to?"

Chats = "Who am I already talking to?"

Keep this distinction visible in copy and navigation.

## People tile

```text
Avatar
Display name
@username
Short role/bio line when available
```

Optional trailing action:
- Message icon/button only if it does not make the list visually busy.

Preferred default:
- Tap the row → User Profile.

## Search states

- Initial
- Debouncing/searching
- Results
- No results
- Error
- Offline

## Suggested people

If included, keep logic deliberately simple in V1.

Avoid implying a dating/recommendation algorithm.

Possible sources:

- Recent signups
- Recent interactions
- Simple deterministic list

Implementation is optional.

---

# 9. User Profile

## Purpose

Provide identity/context before a user starts a conversation.

This is the screen that can borrow most strongly from the selected visual reference while avoiding dating semantics.

## Visual composition

```text
Back
Large avatar
Display name
@username
Role / short descriptor
Bio card
Optional interest/tag chips
Primary Message button
```

## Visual anchor

The large avatar and soft decorative backdrop can create the playful-social identity.

Possible elements:

- Blush organic background shape
- Soft off-white card
- Small interest chips
- Strong primary Message CTA

## Avoid

- Hearts as primary language
- Like/dislike
- Swipe
- Match
- Romantic congratulation language
- Distance/compatibility metadata

## Message CTA behavior

If conversation exists:
- Open existing conversation

If not:
- Resolve/create one-to-one conversation, then open it

The user should not know or care about duplicate-prevention logic.

## States

- Loading
- Profile found
- User unavailable/deleted
- Error
- Message CTA loading

---

# 10. Chat screen

## Purpose

This is the highest-frequency and most behaviorally complex screen in the product.

Visual beauty is important, but reading and sending messages must remain effortless.

## Primary structure

```text
Chat header
↓
Message history
↓
Unread / date / typing contextual elements
↓
Reply/edit context when active
↓
Composer
↓
Keyboard / safe area
```

---

## 10.1 Chat header

### Content

```text
Back
Avatar
Name
Presence/typing line
Context menu
```

Possible state examples:

```text
Ahmed
typing...
```

or

```text
Ahmed
online
```

If presence is not implemented in V1, keep only typing when active.

### Tap behavior

Tapping identity opens User Profile / Conversation Info.

---

## 10.2 Message history

### Background

Use a quiet warm background.

Avoid a busy patterned wallpaper in V1; it competes with long-message readability and weakens the clean portfolio direction.

### Width

Message bubbles should typically max out around 70-76% of available width on phones.

Long content may use slightly more width if readability requires it.

### Alignment

- Own message: trailing side
- Other participant: leading side

Must naturally adapt to RTL if localization is introduced.

---

## 10.3 Date separator

Example:

```text
Today
```

Treatment:

- Small soft pill or low-emphasis text
- Centered
- Not visually stronger than messages

---

## 10.4 Message grouping

Consecutive messages from the same participant within a reasonable time window should visually group.

Possible treatment:

- Reduced vertical gap
- Adjusted bubble corners
- Avatar shown only where needed

Avoid extreme custom bubble tails that increase implementation complexity with little product value.

---

## 10.5 Own message bubble

Possible visual direction:

- Soft blush / primary-related surface
- Dark readable text
- Small timestamp/status aligned naturally

Variants:

- Sending
- Sent
- Read
- Failed
- Edited
- Reply
- Image
- Caption

Status remains subtle.

---

## 10.6 Received message bubble

Possible visual direction:

- White/surface card in light mode
- Neutral dark surface in dark mode
- Strong text contrast
- Optional avatar at group boundary if visual testing proves useful

---

## 10.7 Message status

Need a distinguishable visual model for:

- Sending
- Sent
- Read
- Failed

Do not rely solely on color.

Failed state should have a tappable/contextual retry affordance.

---

## 10.8 Reply preview

Inside the composer:

```text
Replying to Ahmed                ×
Can you send the screenshots?
```

Inside the sent bubble:

```text
Ahmed
Can you send the screenshots?
────────────────────────────
Sure, one second.
```

The quoted section should be visually subordinate to the new content.

---

## 10.9 Image message

Image bubble supports:

- Thumbnail/content
- Loading
- Upload progress
- Failed upload
- Retry
- Optional caption
- Tap to preview larger

Use rounded clipping consistent with the bubble.

---

## 10.10 Unread separator

When entering at an unread boundary:

```text
──────── 3 unread messages ────────
```

Should be noticeable without becoming a major banner.

---

## 10.11 Typing

Preferred initial placement:

Chat header secondary line.

Alternative animated three-dot indicator may be explored but should not duplicate the header state.

Use one clear representation in the final design.

---

# 11. Chat composer

## Collapsed composition

```text
[ + ] [ Message...                         ] [ Send ]
```

## Visual direction

- Rounded
- Soft elevated surface
- Comfortable one-handed use
- Clearly separated from message history
- Pink send action without making the entire composer saturated

## Text behavior

- One-line initial height
- Expand to a controlled multi-line maximum
- Preserve enough message history when expanded
- Send icon enabled only when sendable content exists

## Attachment

Tap + opens a soft bottom sheet:

```text
Camera
Photo Library
```

Future items such as documents/voice must not be added until scoped.

## Reply state

Reply preview sits directly above or integrated into the composer as one component.

## Edit state

Use a clear "Editing message" context with cancel action.

Do not make edit mode visually indistinguishable from new-message mode.

---

# 12. Image Preview / Send

## Purpose

Give the user control before media is uploaded.

## Composition

```text
Close/back
Large image preview
Optional caption
Send
```

## States

- Ready
- Compressing/preparing if visible
- Uploading
- Failed
- Retry

Avoid starting irreversible upload before the user confirms unless product behavior intentionally chooses immediate upload.

---

# 13. Contextual message actions

## Trigger

Long press or platform-appropriate context gesture.

## V1 actions

For any message where valid:

- Reply
- Copy

For own message:

- Edit
- Delete

## Layout direction

Possible implementations:

- Context menu
- Bottom sheet
- Floating reaction/action strip if reactions are later added

Choose one interaction model and keep it consistent.

## Destructive behavior

Delete uses error/destructive semantic styling and confirmation when the action cannot be trivially reversed.

---

# 14. My Profile

## Purpose

Show account identity and provide access to editing/settings.

## Composition

```text
Profile title
Large avatar
Display name
@username
Bio
Edit Profile
Settings rows
Log out
Bottom navigation
```

Potential settings rows:

- Notifications
- Appearance
- About
- Account actions

Avoid fake settings that have no working behavior.

---

# 15. Edit Profile

## Composition

```text
Back
Edit profile
Avatar
Change photo
Display name
Username
Bio
Save
```

## UX rules

- Show unsaved-change state if needed.
- Preserve data when photo upload fails.
- Username validation supports checking/available/unavailable.
- Save should communicate progress without blocking unrelated navigation indefinitely.

---

# 16. Settings / Appearance

## Initial scope

### Appearance

- System
- Light
- Dark

### Notifications

Only expose settings the app can actually honor.

### Account

Possible later:

- Sign out
- Delete account

Privacy settings should not be invented before backend semantics exist.

---

# 17. Cross-screen states matrix

| Surface | Loading | Empty | Error | Offline | Action failure |
|---|---|---|---|---|---|
| Auth | button | n/a | form/global | network notice | retry |
| Chats | skeleton | yes | yes | cached/banner | n/a |
| People | query/loading | no results | yes | yes | n/a |
| User Profile | profile skeleton | unavailable | yes | possible cache | Message retry |
| Chat | history loading | first-message state | yes | cached history | send retry |
| Profile | skeleton | n/a | yes | cached | save retry |

Every high-fidelity mockup set should show at least the major non-happy states, not only the ideal content screen.

---

# 18. High-fidelity deliverable set

The visual design phase should eventually produce at least:

## Auth

- Sign In — default
- Sign In — validation/error
- Create Account
- Complete Profile

## Chats

- Content
- Unread state
- Empty
- Search/no results
- Offline/cached

## People

- Initial/content
- Search results
- No results

## User Profile

- Standard profile
- Message CTA loading/error if visually distinct

## Chat

- Standard conversation
- Reply mode
- Image message
- Failed message + retry
- Typing state
- Unread separator
- Image preview
- Context actions
- Keyboard/composer expanded

## Profile/settings

- My Profile
- Edit Profile
- Appearance

This does not mean every state needs a completely separate artboard if variants/components can communicate it clearly.

---

# 19. Prototype interactions to validate

Before Flutter implementation, a clickable prototype should validate the highest-risk flows:

1. Sign In → Chats
2. Chats → Conversation
3. People → User Profile → Message → Conversation
4. Chat → Reply
5. Chat → Image preview → Send
6. Chat → Failed message → Retry
7. Profile → Edit Profile
8. Appearance → Dark mode representation

The prototype is used to validate UX flow, not backend correctness.

---

# 20. Handoff annotations

Each high-fidelity screen should eventually document:

- Component names
- Design token usage
- Spacing intent
- Responsive behavior
- Scroll behavior
- Keyboard behavior
- Empty/loading/error variants
- Animation/motion intent
- Accessibility semantics where non-obvious
- Data dependencies
- Navigation destination
- Any interaction whose implementation is not obvious from the static screen

This prevents the Flutter implementation from relying on visual guessing.

---

# 21. Technical constraints the design must respect

The design should not imply behavior that the architecture cannot reliably support.

Examples:

- Read state must have explicit backend semantics.
- Presence should not appear unless presence is actually implemented.
- Upload progress requires an observable media-upload state.
- Retry requires failed outgoing messages to remain modeled locally.
- Pagination needs a stable message ordering/cursor strategy.
- Search UI needs query/index semantics.
- Dark mode requires semantic tokens, not screenshot-specific colors.

Design and engineering decisions should evolve together.

---

# 22. Screen-design order

Recommended production order:

```text
1. Sign In / Auth
2. Chats
3. Chat
4. People
5. User Profile
6. Complete Profile
7. My Profile
8. Edit Profile
9. Settings
10. Non-happy-state variants
```

Why Chat moves early:

The chat screen stress-tests the design system more than any other surface:

- Typography
- Bubble colors
- spacing
- metadata
- status
- context actions
- composer
- keyboard
- image treatment
- dark mode
- realtime states

If the system works there, it is much more likely to work across the rest of the product.

---

# 23. Definition of done for screen planning

High-fidelity screen planning is complete when:

- Every V1 screen has a clear purpose.
- Screen hierarchy is unambiguous.
- Major components are identified.
- Navigation between screens is defined.
- Important states are enumerated.
- Content behavior is specified.
- Responsive constraints are known.
- Accessibility constraints are captured.
- Technical dependencies are visible.
- The visual designer can produce high-fidelity mockups without inventing product behavior.
- The Flutter engineer can later implement the design without reverse-engineering hidden UX decisions.

The next step after this document is **actual high-fidelity visual design/mockups**, followed by prototype validation and then system/backend architecture before production implementation.
