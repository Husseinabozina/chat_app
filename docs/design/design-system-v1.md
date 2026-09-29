# Design System v1

## Status

This document defines the first concrete design-system baseline for the messaging product.

It translates the agreed **Soft Pastel Minimal / Playful Social** direction into semantic tokens and component rules that can later be implemented in Flutter.

This is a **v1 foundation**, not a locked final visual specification. Values may be refined after high-fidelity screens, accessibility checks, and real-device review.

---

## 1. Design principles

The interface should feel:

- Warm, friendly, and modern.
- Soft and rounded without looking childish.
- Social and expressive without resembling a dating product.
- Spacious, but not wasteful.
- Memorable, but visually calm during long chat sessions.
- Consistent across light and dark appearance.
- Accessible and usable before being decorative.

### Core rules

1. **Chat content has priority over decoration.**
2. **Use pink as identity, not as visual noise.**
3. **Use semantic tokens instead of hard-coded colors and spacing.**
4. **Keep interaction states explicit: loading, disabled, failed, retry, offline.**
5. **Progressive disclosure:** secondary actions stay contextual.
6. **Motion should explain state, not delay the user.**

---

## 2. Color system

The moodboard reference is dominated by warm off-whites, blush surfaces, and a vivid pink accent.

The reference pink is intentionally preserved as an accent, but the primary filled-control color is darker so white text can meet accessibility contrast requirements.

### Light theme

| Token | Value | Usage |
|---|---|---|
| `background` | `#F8F4F6` | Main app background |
| `surface` | `#FFFFFF` | Cards, sheets, elevated content |
| `surfaceSoft` | `#F1E7EC` | Secondary containers |
| `surfaceStrong` | `#E8D6DE` | Selected/strong soft surface |
| `primary` | `#C83279` | Primary buttons, active controls |
| `primaryPressed` | `#B92469` | Pressed/strong state |
| `accent` | `#F568AC` | Decorative accent, badges, highlights |
| `accentSoft` | `#FCE0ED` | Soft accent containers |
| `textPrimary` | `#2D292B` | Main text |
| `textSecondary` | `#6D6066` | Supporting text |
| `textTertiary` | `#817279` | Low-emphasis text; use carefully |
| `border` | `#E7DDE1` | Input/card borders |
| `divider` | `#EFE7EA` | Subtle separators |
| `success` | `#2E7D5B` | Success/online where meaningful |
| `warning` | `#9A6700` | Warning state |
| `error` | `#B3261E` | Error/destructive actions |
| `info` | `#3C6E9E` | Informational state |

### Contrast note

The moodboard-style accent `#F568AC` is visually important but is too light to be the default background for small white text.

Therefore:

- `primary #C83279` is used for filled interactive controls with white content.
- `accent #F568AC` is used for decorative emphasis, selected indicators, illustration accents, and larger/non-text-critical surfaces.
- Contrast must be revalidated in the final Flutter theme and screen designs.

### Dark theme

| Token | Value | Usage |
|---|---|---|
| `background` | `#171316` | Main background |
| `surface` | `#221B20` | Cards/sheets |
| `surfaceSoft` | `#2C2228` | Secondary surfaces |
| `surfaceStrong` | `#3A2A32` | Strong/selected surfaces |
| `primary` | `#FF8BC3` | Primary accent on dark |
| `primaryOn` | `#32101F` | Text/icon on bright primary |
| `accent` | `#F568AC` | Brand accent |
| `accentSoft` | `#4B2438` | Soft accent container |
| `textPrimary` | `#F8F3F5` | Main text |
| `textSecondary` | `#C9BCC2` | Supporting text |
| `textTertiary` | `#A9959F` | Low emphasis |
| `border` | `#3D3037` | Borders |
| `divider` | `#30262B` | Dividers |

Dark mode is not a color inversion; components must be reviewed individually.

---

## 3. Typography

### Direction

Typography should feel friendly and contemporary while remaining highly readable in dense message histories.

Initial recommendation:

- Latin: **Plus Jakarta Sans**
- Arabic fallback/future localization: **Noto Sans Arabic**

The final font decision should be validated against real chat content, Arabic/English mixing, text scaling, and platform rendering.

### Type scale

| Style | Size | Line height | Weight | Typical usage |
|---|---:|---:|---:|---|
| Display | 32 | 40 | 700 | Hero/onboarding |
| H1 | 28 | 34 | 700 | Main page title |
| H2 | 24 | 30 | 700 | Major section title |
| Title | 20 | 26 | 600 | Card/header titles |
| Subtitle | 17 | 24 | 600 | Names, emphasized rows |
| Body Large | 16 | 24 | 500 | Important body/chat text |
| Body | 15 | 22 | 400 | Default body |
| Label | 14 | 20 | 600 | Buttons, tabs |
| Caption | 12 | 16 | 500 | Timestamp/status/meta |

Rules:

- Do not rely on font weight alone for hierarchy.
- Avoid very small metadata.
- Chat message text should remain comfortable at large text scale.
- Truncation must be deliberate, never accidental.

---

## 4. Spacing

Use a 4-point base system.

```text
xs   4
sm   8
md   12
lg   16
xl   20
2xl  24
3xl  32
4xl  40
5xl  48
```

Default screen horizontal padding:

- Phone: `20`
- Compact layouts: minimum `16`
- Larger layouts: increase using layout constraints rather than device-name checks.

Avoid arbitrary values such as 13, 17, 23 unless a specific optical adjustment is documented.

---

## 5. Radius

The product identity relies on rounded geometry.

```text
radiusSmall   12
radiusMedium  16
radiusLarge   20
radiusXL      24
radiusPill    999
```

Recommended usage:

- Inputs: 16-20
- Buttons: 18-20
- Cards: 20-24
- Message bubbles: about 20
- Chips: pill
- Bottom navigation container: 24+

Rounded does not mean every component uses the maximum radius.

---

## 6. Elevation and shadows

Shadows should be subtle and warm-neutral.

### Low

- Y: 2
- Blur: 8
- Spread: 0
- Opacity: approximately 4%

### Medium

- Y: 4
- Blur: 16
- Spread: 0
- Opacity: approximately 6%

### High

Reserved for modal surfaces only.

Avoid:

- Dark heavy shadows.
- Multiple decorative shadows.
- Using shadow where spacing or surface contrast is enough.

---

## 7. Iconography

Direction:

- Rounded/simple icons.
- Consistent visual weight.
- Prefer one icon family for core navigation/actions.
- Filled icons may represent selected state; outline icons represent inactive state.

Minimum interactive target remains larger than the visible icon.

---

## 8. Buttons

### Primary button

- Height: 52
- Radius: 18-20
- Background: `primary`
- Foreground: white in light theme
- Horizontal padding: 20-24
- Label: 14-16 semibold

States:

- Default
- Pressed
- Loading
- Disabled
- Error recovery where relevant

Loading should preserve button width to avoid layout jumps.

### Secondary button

- Soft accent/surface background.
- Primary-colored text/icon.
- Avoid strong borders unless hierarchy requires them.

### Text button

For low-priority actions such as:

- Cancel
- Skip
- "Already have an account"

Destructive actions use semantic error styling rather than brand pink.

---

## 9. Inputs

Base text field:

- Minimum height: 56
- Radius: 18
- Background: surface/surfaceSoft
- Border: subtle neutral border
- Horizontal content padding: 16
- Clear focused state
- Error text below, not inside the placeholder

States:

- Empty
- Filled
- Focused
- Disabled
- Error
- Loading/validation where necessary

Password fields support:

- Show/hide password
- Autofill
- Keyboard/action configuration

Search fields support:

- Search icon
- Clear action
- Debounced query behavior at the feature level
- Loading/no-results states

---

## 10. Avatars

Standard sizes:

```text
avatarSmall   32
avatarMedium  44
avatarLarge   56
avatarProfile 104-120
```

Every avatar implementation must define:

- Image
- Loading
- Missing image
- Broken image
- Accessibility label where useful

Use initials or a designed fallback rather than an empty gray circle.

---

## 11. Bottom navigation

Primary tabs:

1. Chats
2. People
3. Profile

Direction:

- Rounded/floating-feeling container.
- Visually integrated with the soft surface system.
- Clear selected indicator using brand pink.
- Labels remain readable; avoid icon-only ambiguity.
- Safe-area aware.

The navigation should feel custom but not fight platform expectations.

---

## 12. Conversation tile

Required content:

- Avatar
- Display name
- Last-message preview
- Timestamp
- Unread badge
- Outgoing status where useful

Rules:

- Name has strongest hierarchy.
- Preview is limited to one line in normal density.
- Timestamp never dominates.
- Unread badge uses vivid accent.
- Muted/system states remain distinguishable without relying on color alone.

Suggested vertical height: approximately 72-80 depending on text scale.

---

## 13. Message bubbles

### General

- Maximum width: approximately 70-76% of available chat width.
- Radius: about 20.
- Comfortable internal padding.
- Consecutive messages can visually group.
- Sender/receiver distinction should remain visible in both themes.

### Own message

Use a brand-related soft/primary surface, but keep long text comfortable.

### Other participant

Use neutral/soft surface.

### Metadata

Timestamp/read/edit status should be subtle but legible.

Do not permanently show:

- Reply
- Copy
- Edit
- Delete
- Reactions

These remain contextual.

### Bubble variants

The component should support:

- Text
- Image
- Text + image/caption
- Reply preview
- Sending
- Sent
- Read
- Failed/retry
- Edited

---

## 14. Chat composer

The composer is an extensible component, not merely a `TextField`.

### Base structure

```text
[ attachment ] [ flexible text input ........ ] [ send ]
```

Support:

- Multiline text
- Keyboard-safe expansion
- Attachment action
- Send enabled/disabled state
- Reply context
- Upload/sending feedback
- Future voice-note extension without redesigning the entire surface

Recommended:

- Minimum collapsed height: 52-56
- Radius: 20+
- Maximum text expansion should preserve enough chat context.

---

## 15. Contextual message actions

Trigger:

- Long press / platform-appropriate context interaction.

Initial actions:

- Reply
- Copy
- Edit (own message)
- Delete (own message)

Possible later:

- React
- Pin

The menu should use progressive disclosure and platform-appropriate placement.

---

## 16. Chips and filters

Use for:

- All / Unread
- Interests/profile tags if retained
- Lightweight filter states

Rules:

- Compact, rounded/pill.
- Clear selected state.
- Do not create a large category bar if the product only needs two filters.

---

## 17. Empty states

Every major empty state should provide:

1. A concise illustration or icon.
2. Clear explanation.
3. One useful next action when appropriate.

Example:

```text
No conversations yet

Find someone and start a conversation.

[ Find people ]
```

Never use technical copy such as "No data".

---

## 18. Error and offline states

### Error

- Explain what failed in human language.
- Offer retry when meaningful.
- Preserve useful content where possible.

### Offline

If cached data exists:

- Continue showing it.
- Add a subtle offline indicator.
- Preserve draft/action state where possible.

If no content exists:

- Show an offline-specific state and retry.

A failed outgoing message stays visible with a retry affordance.

---

## 19. Loading

Prefer contextual loading:

- Skeletons for conversation lists where beneficial.
- Inline spinner/progress for actions.
- Stable layout while sending/uploading.

Avoid full-screen blocking loaders for small actions.

---

## 20. Motion

### Motion tokens

```text
fast    120ms
normal  180ms
slow    240ms
```

Suggested uses:

- Press/selection: fast
- Navigation/component transition: normal
- Larger state transition: slow

Motion style:

- Soft ease-out.
- Minimal overshoot.
- Avoid repeated bounce.
- Never delay a send/navigation action for decoration.

Respect reduced-motion/accessibility preferences where technically available.

---

## 21. Accessibility baseline

Before a component is considered production-ready, verify:

- Text contrast.
- Non-text contrast for essential controls.
- Minimum interactive target around 48dp.
- Dynamic text scaling.
- Semantic labels.
- Keyboard/focus behavior where relevant.
- Status is not communicated by color alone.
- Error messages are understandable and associated with the relevant control.
- Message ordering remains understandable to assistive technology.

---

## 22. Responsive/adaptive behavior

Do not design only for a single screenshot size.

At minimum validate:

- Small phone
- Common phone
- Large phone
- Tablet

Layouts should respond to available width using constraints.

Future desktop/web layouts may use a two-pane conversation model:

```text
Conversation list | Active conversation
```

This is not required for the first mobile release but the architecture should not prevent it.

---

## 23. Component inventory for implementation

Initial reusable design-system components:

- `AppButton`
- `AppTextField`
- `AppSearchField`
- `AppAvatar`
- `AppChip`
- `AppBottomNavigation`
- `ConversationTile`
- `MessageBubble`
- `ChatComposer`
- `ReplyPreview`
- `EmptyState`
- `ErrorState`
- `OfflineBanner`
- `LoadingSkeleton`
- `AppSheet`

Do not make every visual element globally reusable by default. Promote a widget into the design system only when it represents a stable product pattern.

---

## 24. Flutter implementation direction

When implementation starts, tokens should map into centralized theme structures rather than scattered constants.

Conceptually:

```text
AppTheme
AppColors
AppTypography
AppSpacing
AppRadius
AppMotion
```

Prefer Flutter theme extensions or similarly typed theme structures for semantic product tokens.

Feature widgets should consume semantic tokens instead of hard-coded hex colors or arbitrary spacing.

---

## 25. Review checklist

Before freezing Design System v1:

- [ ] High-fidelity Auth screen validates typography and inputs.
- [ ] Chat list validates hierarchy, unread state, and search.
- [ ] People/profile validates avatar and card system.
- [ ] Chat screen validates bubbles, composer, metadata, reply, and failures.
- [ ] Light theme reviewed on real device.
- [ ] Dark theme reviewed on real device.
- [ ] Text scaling checked.
- [ ] Contrast checked.
- [ ] Motion checked at 60/120Hz where practical.
- [ ] Components remain consistent across screens.

The high-fidelity screens are the next validation layer; they may refine these tokens, but should not introduce unrelated one-off visual rules without justification.
