import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/presentation/chat_ui.dart';
import '../../../conversations/domain/entities/conversation.dart';
import '../../../conversations/domain/repositories/conversations_repository.dart';
import '../../../conversations/presentation/pages/conversation_page.dart';
import '../../domain/users_repository.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({
    required this.users,
    required this.conversations,
    required this.currentUserId,
    super.key,
  });
  final UsersRepository users;
  final ConversationsRepository conversations;
  final String currentUserId;
  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  Timer? _debounce;
  int _generation = 0;
  String _query = '';
  CursorPage<UserProfile>? _page;
  bool _busy = false;
  Object? _error;
  void _changed(String value) {
    _debounce?.cancel();
    _generation++;
    setState(() {
      _query = value.trim();
      _page = null;
      _error = null;
      _busy = _query.isNotEmpty;
    });
    if (_query.isNotEmpty) {
      _debounce = Timer(const Duration(milliseconds: 350), () => _search());
    }
  }

  Future<void> _search({bool more = false}) async {
    if (_query.isEmpty) return;
    final generation = ++_generation;
    final previous = _page;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = await widget.users.search(
        _query,
        cursor: more ? previous?.nextCursor : null,
      );
      if (!mounted || generation != _generation) return;
      final items = <String, UserProfile>{
        if (more && previous != null)
          for (final u in previous.items) u.id: u,
        for (final u in page.items) u.id: u,
      };
      setState(
        () => _page = CursorPage(
          items: items.values.toList(),
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
        ),
      );
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = e);
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const WarmHeader('People', 'A new conversation is a name away.'),
              const SizedBox(height: 16),
              TextField(
                maxLength: 80,
                decoration: const InputDecoration(
                  hintText: 'Search name or username',
                  prefixIcon: Icon(Icons.search),
                  counterText: '',
                ),
                onChanged: _changed,
              ),
            ],
          ),
        ),
      ),
      if (_busy) const SliverToBoxAdapter(child: LinearProgressIndicator()),
      if (_error != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: Text(friendlyError(_error!))),
                TextButton(
                  onPressed: _busy ? null : _search,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      if (_page == null || _page!.items.isEmpty)
        SliverToBoxAdapter(
          child: StatusPanel(
            _query.isEmpty
                ? 'Search by a name or username to start a chat.'
                : _busy
                ? 'Searching…'
                : 'No people found.',
          ),
        ),
      SliverList.builder(
        itemCount: _page?.items.length ?? 0,
        itemBuilder: (context, i) {
          final p = _page!.items[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Material(
              color: Theme.of(context).colorScheme.surface
                  .withValues(alpha: .85),
              borderRadius: BorderRadius.circular(22),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                leading: InitialAvatar(p.label),
                title: Text(p.label),
                subtitle: Text(p.username == null ? '' : '@${p.username}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PublicProfilePage(
                      userId: p.id,
                      users: widget.users,
                      conversations: widget.conversations,
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      if (_page?.hasMore ?? false)
        SliverToBoxAdapter(
          child: TextButton(
            onPressed: _busy ? null : () => _search(more: true),
            child: const Text('Load more people'),
          ),
        ),
    ],
  );
}

class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({
    required this.userId,
    required this.users,
    required this.conversations,
    required this.currentUserId,
    this.allowMessage = true,
    super.key,
  });
  final String userId;
  final UsersRepository users;
  final ConversationsRepository conversations;
  final String currentUserId;
  final bool allowMessage;
  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  UserProfile? _profile;
  Object? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
    });
    try {
      final p = await widget.users.getProfile(widget.userId);
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _message() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final c = await widget.conversations.openDirect(widget.userId);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ConversationPage(
            repository: widget.conversations,
            users: widget.users,
            conversation: c,
            currentUserId: widget.currentUserId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: MingleBackdrop(
      child: _error != null
          ? StatusPanel(friendlyError(_error!), action: _load)
          : _profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: InitialAvatar(_profile!.label, radius: 56)),
                  const SizedBox(height: 24),
                  Text(
                    _profile!.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (_profile!.username != null)
                    Text(
                      '@${_profile!.username}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (_profile!.bio?.isNotEmpty ?? false)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(_profile!.bio!),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (widget.allowMessage &&
                      widget.userId != widget.currentUserId)
                    FilledButton(
                      onPressed: _busy ? null : _message,
                      child: Text(_busy ? 'Opening…' : 'Message'),
                    ),
                ],
              ),
            ),
    ),
  );
}
