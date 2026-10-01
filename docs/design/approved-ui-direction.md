# Approved UI Direction and Screen Decisions

## Status

This document records the visual decisions explicitly approved during the design exploration so future UI generation and Flutter implementation do not drift.

The purpose is to stop re-exploring already accepted direction and move forward screen by screen.

---

## 1. Approved visual identity

The app uses a:

**Soft Pastel Minimal / Playful Social Messaging** direction.

Core characteristics:

- Blush pink, cream, off-white, warm gray, charcoal.
- Soft gradients and rounded surfaces.
- Friendly, airy composition.
- Decorative illustration details in the background.
- Gentle clouds, paper planes, windows, books, plants, abstract room/landscape scenes.
- Soft shadows and warm visual depth.
- Clear messaging-product identity.

The app must feel social and warm, but **not like a dating app**.

---

## 2. Explicit content constraints

### Do not use

- Dating/match/swipe language.
- Romantic pairings.
- Male/female couple imagery.
- Sexual or relationship-coded visuals.
- Human portraits with detailed facial features.
- Decorative people whose face/details become a focal point.

### Prefer

- Abstract avatars.
- Initials.
- Landscape/image avatars.
- Object-based illustrations.
- Cropped/partial human silhouettes without detailed facial features where necessary.
- Environmental illustrations: books, windows, plants, paper planes, rooms, desks, clouds, landscapes.

---

## 3. Typography decision

The typography should match the spirit of the first approved UI reference:

- Rounded.
- Friendly.
- Geometric.
- Light-to-medium weight for body text.
- Soft, playful headings without becoming childish.

The exact font family is not locked yet.

Reference direction is closer to:

- Quicksand-like
- Comfortaa-like

The final production font must be validated for:

- Readability.
- English.
- Arabic.
- Mixed Arabic/English.
- Long chat messages.
- Dynamic text scaling.
- Flutter rendering.

Until then, every visual mockup should preserve this rounded/friendly typographic character rather than using heavy generic bold fonts.

---

## 4. Approved Chats Home direction

Chats Home is approved in principle around the following structure:

```text
Decorative soft header
Chats title
Search conversations
Lightweight filters
Pinned conversation area where justified
Conversation list
Unread badges
New-chat action
Rounded bottom navigation
```

### Visual treatment

- Pink/cream decorative header.
- Background ornament integrated into the app, not a plain empty background.
- Decorative elements may include clouds, window shapes, foliage, paper planes, books, or other non-living objects.
- Conversation avatars can use landscapes, objects, initials, or simple non-detailed visual marks.
- Unread badges use the stronger pink accent.
- Search and filter controls remain soft and rounded.
- Bottom navigation feels custom and integrated rather than default Material.

### Functional caution

The high-fidelity visual exploration may show extra categories while exploring layout, but implementation must follow the product scope.

Initial product navigation remains:

- Chats
- People
- Profile

Any extra tab such as Files or Groups requires an explicit later scope decision.

Initial conversation filters remain intentionally minimal:

- All
- Unread

Pinned can exist if formally accepted as a scoped feature later.

---

## 5. Approved Chat Screen direction

The chat surface should keep the same visual identity without sacrificing readability.

### Structure

```text
Chat header
Message history
Date/unread contextual elements
Reply/edit state
Composer
Keyboard/safe area
```

### Header

- Back.
- Abstract/neutral avatar.
- Conversation/user name.
- Typing state when active.
- Minimal contextual actions.

### Message area

- Warm, quiet backdrop.
- Decorative background elements are allowed only where they do not compete with text.
- Sender/receiver bubbles are rounded and visually distinct.
- Metadata remains subtle.
- Message grouping reduces visual repetition.

### Supported message states

The final visual system must account for:

- Text.
- Image.
- Reply.
- Edit.
- Sending.
- Sent.
- Read.
- Failed.
- Retry.
- Typing.
- Unread separator.

### Contextual actions

Initial V1 message actions:

- Reply.
- Copy.
- Edit own message.
- Delete own message.

Reactions, pin, forward, voice notes, and other actions are not automatically approved just because they appeared in visual exploration. They require a product-scope decision first.

### Composer

The composer should support:

- Text.
- Attachment entry.
- Reply context.
- Edit context.
- Send state.
- Disabled state.
- Keyboard expansion.

Future features must not be visually implied as committed unless they enter scope.

---

## 6. Decorative asset strategy

The app should not feel visually empty.

Allowed decorative assets include:

- Cloud clusters.
- Paper-plane motifs.
- Windows.
- Leaves/plants.
- Books.
- Desks/workspaces.
- Landscapes.
- Abstract architecture.
- Mail/message objects.
- Light sparkles/stars.
- Soft abstract blobs and scalloped/organic separators.

These assets can be:

- Full background illustrations.
- Small edge decorations.
- Header illustrations.
- Empty-state art.
- Avatar art.
- Decorative separators.

### Asset rule

Do not bake functional UI into a single static background image.

Prefer separating:

- Background decoration.
- Functional controls.
- Content cards.
- Interactive components.

This preserves responsiveness, accessibility, and maintainability.

---

## 7. Design progression rule

From this point onward:

1. Do not generate another full-app collage unless explicitly requested.
2. Work on one screen or one tightly related flow at a time.
3. Each screen must inherit the approved design system.
4. Each screen must respect the content constraints above.
5. Every new visual concept must be checked against the actual feature scope before treating it as approved.
6. Once a screen is approved, document its visual decisions before moving on.
7. Avoid re-opening settled visual direction unless a real usability/accessibility problem appears.

---

## 8. Next screen order

After locking Chats Home and Chat Screen direction:

1. People
2. User Profile
3. Auth / Sign In
4. Create Account
5. Complete Profile
6. My Profile
7. Edit Profile
8. Settings
9. Non-happy-state variants

This order prioritizes the core social/messaging experience before secondary screens.


---

## 9. AI collaboration guardrail

This is a standing project rule:

- **Do not generate any image, mockup, moodboard, or visual board unless the user explicitly asks for an image.**
- Approval of a visual direction does not imply permission to generate another image.
- When the next project step is architecture, documentation, implementation, testing, or another non-visual task, proceed with that task instead of returning to image generation.
- Repeated visual generation is treated as workflow drift, not progress.
- If a visual artifact is needed later, generate only the specific screen/asset requested rather than a full-app collage unless the user explicitly asks for one.

This guardrail exists to keep the AI workflow aligned with the project plan and prevent repeated visual work from replacing the actual next engineering task.


## 10. Approved Chats preview — 2026-10-01

The user reattached the original pastel Mingle board and requested implementation. After an isolated avatar asset caused confusion, the user requested a complete Chats preview before further implementation. The full-screen concept at `docs/design/references/approved-chats-preview.png` was displayed; the user explicitly approved it and asked to continue.

This locks the direction of this iteration: soft cloud/paper-plane/leaf decoration at the edges; cream/blush surfaces; readable rounded navy typography; small circular illustrated avatars; soft search, All/Unread filters, clear direct-conversation rows and rounded Chats/People/new-chat/Profile navigation. The plus is a new-chat action, not a fourth product section. Reference groups/files/presence are not added to scope.

The concept is an AI-rendered visual target, not a screenshot or proof of implementation. Match it in Flutter and compare the actual native rendering before declaring visual QA passed. Typography family/asset refinements may be necessary to reproduce the approved appearance. Keep controls/content as native widgets. Do not generate further mockups or visual boards without a specific request.
