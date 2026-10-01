import 'package:flutter/material.dart';

import '../../../../core/presentation/chat_ui.dart';
import '../../../users/domain/users_repository.dart';
import '../../domain/repositories/conversations_repository.dart';
import 'conversation_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({
    required this.repository,
    required this.users,
    required this.currentUserId,
    required this.onFindPeople,
    super.key,
  });
  final ConversationsRepository repository;
  final UsersRepository users;
  final String currentUserId;
  final VoidCallback onFindPeople;
  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  String _query = '';
  bool _unread = false;
  bool _more = false;
  late final _stream = widget.repository.watchState();
  Future<void> _refresh() async {
    try {
      await widget.repository.resynchronize();
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<void> _loadMore() async {
    if (_more) return;
    setState(() => _more = true);
    try {
      await widget.repository.loadMoreConversations();
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _more = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<ConversationsState>(
    stream: _stream,
    initialData: widget.repository.currentState,
    builder: (context, snapshot) {
      final s = snapshot.data!;
      final filtered = s.conversations.items
          .where(
            (c) =>
                (!_unread || c.unreadCount > 0) &&
                '${c.otherUser.displayName ?? ''} ${c.otherUser.username ?? ''}'
                    .toLowerCase()
                    .contains(_query.toLowerCase()),
          )
          .toList();
      return RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const WarmHeader('Chats', 'Good chats. Brighter days.'),
                        const SizedBox(height: 16),
                        TextField(
                          maxLength: 80,
                          decoration: const InputDecoration(
                            hintText: 'Search chats',
                            prefixIcon: Icon(Icons.search),
                            counterText: '',
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ChoiceChip(
                                label: const Text('All'),
                                selected: !_unread,
                                onSelected: (_) =>
                                    setState(() => _unread = false),
                              ),
                              ChoiceChip(
                                label: const Text('Unread'),
                                selected: _unread,
                                onSelected: (_) =>
                                    setState(() => _unread = true),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (s.connection == ConversationConnection.offline)
                    MaterialBanner(
                      content: const Text(
                        'Connection paused. Your loaded chats are still here.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  if (s.failure != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(child: Text(friendlyError(s.failure!))),
                          TextButton(
                            onPressed: _refresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child:
                    s.conversations.items.isEmpty &&
                        (s.connection == ConversationConnection.connecting ||
                            s.connection == ConversationConnection.syncing)
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : StatusPanel(
                        _query.isNotEmpty || _unread
                            ? 'No conversations found in loaded chats.'
                            : 'No conversations yet. Find someone and say hello.',
                        action: widget.onFindPeople,
                        label: 'Find people',
                      ),
              ),
            SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final c = filtered[i];
                final name =
                    c.otherUser.displayName ??
                    c.otherUser.username ??
                    'Chat member';
                final last = c.lastMessage;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Material(
                    color: c.unreadCount > 0
                        ? Theme.of(context).colorScheme.primaryContainer
                              .withValues(alpha: .38)
                        : Theme.of(context).colorScheme.surface
                              .withValues(alpha: .8),
                    borderRadius: BorderRadius.circular(22),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      leading: InitialAvatar(name),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: c.unreadCount > 0
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        last == null
                            ? 'Say hello'
                            : last.deletedAt != null
                            ? 'Message deleted'
                            : last.text ?? '',
                        textDirection: messageDirection(last?.text ?? ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _time(last?.createdAt ?? c.updatedAt),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          if (c.unreadCount > 0)
                            Badge(label: Text('${c.unreadCount}')),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ConversationPage(
                            repository: widget.repository,
                            users: widget.users,
                            conversation: c,
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (s.conversations.hasMore)
              SliverToBoxAdapter(
                child: TextButton(
                  onPressed: _more ? null : _loadMore,
                  child: Text(_more ? 'Loading…' : 'Load more chats'),
                ),
              ),
          ],
        ),
      );
    },
  );
}

String _time(DateTime value) {
  final t = value.toLocal();
  final now = DateTime.now();
  if (t.year != now.year || t.month != now.month || t.day != now.day) {
    return '${t.day}/${t.month}';
  }
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
