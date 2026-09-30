# Competitor and Pattern Research

## Purpose

Competitor research is used to understand proven messaging patterns, user expectations, interaction models, and product tradeoffs.

It is **not** used to copy proprietary visual designs or reproduce another product screen-for-screen.

## Products reviewed

### WhatsApp

Useful observations:

- Conversation access is fast and visually simple.
- Search and unread-oriented filtering reduce friction in large chat lists.
- Message actions such as reply, edit, delete, reactions, and pinning are progressively disclosed rather than always visible.
- Delivery/read state is subtle and familiar.
- The product keeps the main chat surface focused despite supporting many capabilities.

Derived decisions for this project:

- Keep the conversation list visually calm.
- Prefer simple filtering/search over many top-level tabs.
- Keep message metadata subtle.
- Put secondary message actions behind contextual interaction.

### Telegram

Useful observations:

- Strong navigation within replies, pinned content, search, and large message histories.
- Rich messaging features can coexist with a responsive composer and message surface.
- Folders/topics/channels demonstrate how quickly messaging products can become platform-sized.

Derived decisions:

- Borrow interaction lessons for reply/navigation and long histories.
- Do not adopt Telegram-scale platform scope.
- Keep groups, channels, bots, and community features out of the initial release.

### Signal

Useful observations:

- User identity, usernames, message requests, reactions, and privacy-oriented flows can be clear without social-feed mechanics.
- A people/profile flow can support discovery and conversation initiation without becoming a dating experience.

Derived decisions:

- Separate **People** from **Chats**.
- Allow profile-first conversation initiation.
- Keep identity and messaging focused without swipe/match mechanics.

### Messenger

Useful observations:

- Friendly visual personality can coexist with a mainstream messaging product.
- Themes, reactions, presence, media, and expressive interaction can make the product feel social without requiring a feed.
- Visual warmth is compatible with production messaging UX.

Derived decisions:

- Use a warm, playful visual language while keeping information architecture simple.
- Treat reactions/presence as optional enhancements, not core dependencies.

### Discord

Useful observations:

- Long-press/contextual message actions scale well as features grow.
- Reply, reactions, copy/edit/delete, and media actions are easier to manage when not permanently displayed.
- Composer capability can grow over time without redesigning the entire screen if its structure is extensible.

Derived decisions:

- Design contextual message actions from the beginning.
- Design the composer to support attachments and reply state without coupling it to future features.

## Cross-product UX conclusions

Common high-value patterns:

- Clear conversation list hierarchy
- Search
- Unread state
- Timestamp/date grouping
- Typing feedback
- Contextual message actions
- Reply
- Media
- Delivery/read feedback
- Pagination for long histories
- Notification routing into the relevant conversation
- Empty/loading/error/offline states that feel intentional

## What we intentionally reject

The project should not accumulate features simply because a major messenger has them.

Specifically, the initial product rejects:

- Stories/status as a product pillar
- Channels and communities
- Bots
- Calls
- Dating/matching mechanics
- Large-scale social discovery
- Feature-heavy navigation

## Portfolio interpretation

The research should be visible in the final product as **reasoned product decisions**, not visual imitation.

Examples:

- Pagination demonstrates scalable message-history handling.
- Retry demonstrates resilient state and network behavior.
- Read/unread state demonstrates data modeling and realtime coordination.
- Image messages demonstrate media upload/storage concerns.
- Notification deep links demonstrate navigation and platform integration.
- Contextual message actions demonstrate interaction design without cluttering the chat surface.
