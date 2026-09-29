# Visual Direction

## Direction

The agreed visual language is:

**Soft Pastel Minimal / Playful Social UI**

Key attributes:

- Warm
- Friendly
- Airy
- Rounded
- Minimal
- Illustration-friendly
- Social, but not dating-oriented
- Memorable without becoming visually noisy

The reference direction uses soft surfaces, generous spacing, rounded geometry, subtle elevation, and a blush-pink accent system.

## Color direction

Initial palette direction, subject to accessibility and design-system validation:

- Off-white / warm near-white backgrounds
- Blush pink surfaces
- Stronger pink primary accent
- Warm gray secondary text and borders
- Charcoal primary text

Approximate reference colors may start around:

```text
Background:     #F6F0F2
Blush surface:  #F0AACB
Primary accent: #F55BA5
Primary text:   #2D2C2C
```

These are direction-setting references, not final tokens. The production palette must be rebuilt as semantic design tokens and checked for contrast.

## Visual characteristics

### Surfaces

- Large rounded corners
- Soft cards
- Minimal hard borders
- Subtle shadows/elevation
- Generous breathing room
- Avoid dense enterprise-style panels

### Typography

Typography should feel:

- Friendly
- Highly readable
- Modern
- Slightly rounded where appropriate
- Calm rather than decorative

Readability takes priority over novelty, especially in chat histories.

### Avatars

Avatars are an important visual anchor in:

- People
- Profiles
- Conversation list
- Chat header

Use consistent sizing, fallback behavior, and loading/error states.

### Navigation

The primary navigation should feel integrated with the visual system rather than looking like an untouched default Material widget.

Current direction:

- Rounded/floating-feeling bottom navigation
- Chats
- People
- Profile

### Conversation list

Priorities:

- Strong identity/avatar hierarchy
- Name and last-message preview
- Timestamp
- Unread badge
- Clear but quiet message state
- Search near the top
- Optional lightweight All/Unread filtering

### Chat surface

The chat UI should remain visually calm even as capability grows.

Support:

- Rounded message bubbles
- Date separators
- Message grouping
- Subtle timestamps
- Reply previews
- Delivery/read state
- Failed/retry state
- Image messages
- Typing state
- Unread separator
- Contextual message actions

Avoid permanently showing every possible message action.

### Composer

The composer should be designed as an extensible component rather than only a TextField.

Initial requirements:

- Text input
- Send
- Attachment entry point
- Reply context
- Disabled/loading states
- Keyboard-safe layout

Future additions such as voice notes should be possible without rebuilding the entire chat screen.

## Non-dating rule

The visual inspiration includes social/dating-style references, but the product identity must not communicate dating.

Avoid:

- Match language
- Swipe-to-like/dislike
- Hearts as the primary interaction language
- Couple/match celebration screens
- Romantic discovery copy

Replace those patterns with:

- People
- Profiles
- Message
- Conversations
- Connection through chat

## Illustration use

Illustrations may be used selectively for:

- Onboarding
- Empty states
- Friendly feedback states

They should support the product rather than dominate the interface.

## Motion

Motion should be:

- Short
- Soft
- Purposeful
- State-explanatory

Potential uses:

- Navigation transitions
- Composer state changes
- New message insertion
- Retry/success feedback
- Empty-state micro-interactions

Avoid long decorative animation that delays task completion.

## Dark mode

Dark mode should be designed, not mechanically inverted.

It should preserve:

- Warmth
- Pink accent identity
- Readable message contrast
- Distinction between sender/receiver surfaces
- Accessible text and controls

## Accessibility requirements

The final design system must validate:

- Text contrast
- Touch-target sizing
- Dynamic text scaling
- Semantic labels
- Focus/keyboard behavior where applicable
- Color-independent status communication

## Reference policy

External UI references are moodboard material, not implementation specifications.

For each reference, extract:

1. What visual or interaction idea is useful?
2. Why does it work?
3. Does it fit this product?
4. How should it be adapted into the project's own system?

The final product should have a coherent identity rather than appear as a collage of copied screens.
