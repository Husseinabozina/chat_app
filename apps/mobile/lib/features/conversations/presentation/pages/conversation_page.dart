import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/presentation/chat_ui.dart';
import '../../../users/domain/users_repository.dart';
import '../../../users/presentation/pages/people_page.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/conversations_repository.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    required this.repository,
    required this.users,
    required this.conversation,
    required this.currentUserId,
    super.key,
  });
  final ConversationsRepository repository;
  final UsersRepository users;
  final ConversationSummary conversation;
  final String currentUserId;
  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _viewport = GlobalKey();
  final _messageKeys = <String, GlobalKey>{};
  StreamSubscription<ConversationsState>? _subscription;
  late ConversationsState _state;
  ConversationMessage? _reply;
  ConversationMessage? _editing;
  bool _loading = true;
  bool _more = false;
  bool _savingEdit = false;
  bool _reading = false;
  bool _readScheduled = false;
  bool _foreground = true;
  Object? _loadError;
  Object? _readError;
  ConversationMessage? _lastRead;
  Timer? _typingStop;
  bool _historyReady = false;
  final _arrivingIds = <String>{};
  final _introducedClientIds = <(String, String)>{};
  String get _id => widget.conversation.id;
  List<ConversationMessage> get _messages =>
      _state.messages[_id]?.items.reversed.toList() ?? [];
  List<OutgoingMessage> get _outgoing => _state.outgoing
      .where((m) => m.conversationId == _id)
      .toList()
      .reversed
      .toList();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state = widget.repository.currentState;
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _subscription = widget.repository.watchState().listen((s) {
      if (!mounted) return;
      final previous = _state.messages[_id]?.items ?? [];
      final latest = previous.isEmpty ? null : previous.last;
      final oldIds = previous.map((m) => m.id).toSet();
      if (_historyReady && !_more) {
        for (final m in s.messages[_id]?.items ?? <ConversationMessage>[]) {
          if (!oldIds.contains(m.id) &&
              (latest == null || compareMessages(m, latest) > 0) &&
              _introducedClientIds.add((m.senderId, m.clientMessageId))) {
            _arrivingIds.add(m.id);
          }
        }
        final oldOutgoing = _state.outgoing
            .map((m) => m.clientMessageId)
            .toSet();
        for (final m in s.outgoing.where((m) => m.conversationId == _id)) {
          if (!oldOutgoing.contains(m.clientMessageId) &&
              _introducedClientIds.add((m.senderId, m.clientMessageId))) {
            _arrivingIds.add(m.clientMessageId);
          }
        }
      }
      setState(() => _state = s);
      _scheduleRead();
    });
    _scroll.addListener(_scheduleRead);
    unawaited(_load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _scheduleRead();
    } else {
      _stopTyping();
    }
  }

  Future<void> _load({bool older = false}) async {
    if (older && _more) return;
    setState(() {
      if (older) {
        _more = true;
      } else {
        _loading = true;
        _loadError = null;
      }
    });
    try {
      await widget.repository.loadMessages(_id, older: older);
    } catch (e) {
      if (mounted) {
        if (older) {
          showFailure(context, e);
        } else {
          setState(() => _loadError = e);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _more = false;
          if (!older) _historyReady = _loadError == null;
        });
        _scheduleRead();
      }
    }
  }

  void _scheduleRead() {
    if (_readScheduled || !mounted) return;
    _readScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readScheduled = false;
      if (mounted) unawaited(_readVisible());
    });
  }

  Future<void> _readVisible() async {
    if (!_foreground ||
        _loading ||
        _reading ||
        _readError != null ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    final render = _viewport.currentContext?.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return;
    final area = render.localToGlobal(Offset.zero) & render.size;
    ConversationMessage? candidate;
    for (final m in _messages) {
      if (m.senderId == widget.currentUserId) continue;
      final box = _messageKeys[m.id]?.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (!area.overlaps(rect) ||
          area.intersect(rect).height < math.min(48, rect.height / 2)) {
        continue;
      }
      if (candidate == null || compareMessages(m, candidate) > 0) candidate = m;
    }
    if (candidate == null ||
        (_lastRead != null && compareMessages(candidate, _lastRead!) <= 0)) {
      return;
    }
    for (final p in _state.readPointers.where(
      (p) => p.conversationId == _id && p.userId == widget.currentUserId,
    )) {
      if (covers(p, candidate, _messages)) {
        _lastRead = candidate;
        return;
      }
    }
    _reading = true;
    try {
      await widget.repository.markRead(_id, candidate.id);
      _lastRead = candidate;
    } catch (e) {
      if (mounted) setState(() => _readError = e);
    } finally {
      _reading = false;
      if (mounted && _readError == null) _scheduleRead();
    }
  }

  void _typing(String value) {
    _typingStop?.cancel();
    if (value.trim().isEmpty) {
      _stopTyping();
      return;
    }
    unawaited(
      widget.repository.setTyping(_id, typing: true).catchError((Object _) {}),
    );
    _typingStop = Timer(const Duration(seconds: 3), _stopTyping);
  }

  void _stopTyping() {
    _typingStop?.cancel();
    unawaited(
      widget.repository.setTyping(_id, typing: false).catchError((Object _) {}),
    );
  }

  Future<void> _send() async {
    final value = _text.text.trim();
    if (value.isEmpty || messageLength(value) > 4000 || _savingEdit) return;
    final editing = _editing;
    if (editing != null) {
      setState(() => _savingEdit = true);
      try {
        await widget.repository.editMessage(_id, editing.id, value);
        if (mounted) {
          setState(() {
            _editing = null;
            _text.clear();
          });
        }
      } catch (e) {
        if (mounted) showFailure(context, e);
      } finally {
        if (mounted) setState(() => _savingEdit = false);
      }
    } else {
      try {
        final outgoing = widget.repository.prepareMessage(
          _id,
          value,
          replyToMessageId: _reply?.id,
        );
        setState(() {
          _reply = null;
          _text.clear();
        });
        _stopTyping();
        if (_scroll.hasClients) {
          unawaited(
            _scroll.animateTo(
              0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
            ),
          );
        }
        await widget.repository.sendOutgoing(outgoing.clientMessageId);
      } catch (e) {
        if (mounted) showFailure(context, e);
      }
    }
  }

  Future<void> _retry(OutgoingMessage m) async {
    try {
      await widget.repository.sendOutgoing(m.clientMessageId);
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<void> _actions(ConversationMessage m) async {
    if (m.isDeleted || _savingEdit) return;
    final own = m.senderId == widget.currentUserId;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in [
              'Reply',
              'Copy',
              if (own) 'Edit',
              if (own) 'Delete',
            ])
              ListTile(
                leading: MingleIcon(switch (a) {
                  'Reply' => MingleGlyph.reply,
                  'Copy' => MingleGlyph.copy,
                  'Edit' => MingleGlyph.edit,
                  _ => MingleGlyph.trash,
                }),
                title: Text(a),
                onTap: () => Navigator.of(c).pop(a),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'Reply':
        setState(() {
          _reply = m;
          _editing = null;
        });
      case 'Copy':
        await Clipboard.setData(ClipboardData(text: m.text ?? ''));
      case 'Edit':
        setState(() {
          _editing = m;
          _reply = null;
          _text.text = m.text ?? '';
        });
      case 'Delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Delete this message?'),
            content: const Text('The message will be removed for both of you.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(c).colorScheme.error,
                  foregroundColor: Theme.of(c).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(c).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm != true || !mounted) return;
        try {
          await widget.repository.deleteMessage(_id, m.id);
          if (mounted && _editing?.id == m.id) {
            setState(() {
              _editing = null;
              _text.clear();
            });
          }
        } catch (e) {
          if (mounted) showFailure(context, e);
        }
    }
  }

  Future<void> _profile() async {
    _stopTyping();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicProfilePage(
          userId: widget.conversation.otherUser.id,
          users: widget.users,
          conversations: widget.repository,
          currentUserId: widget.currentUserId,
          allowMessage: false,
        ),
      ),
    );
    if (mounted) _scheduleRead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTyping();
    unawaited(_subscription?.cancel());
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final other = widget.conversation.otherUser;
    final name = other.displayName ?? other.username ?? 'Chat member';
    final typing = _state.typing.any(
      (t) => t.conversationId == _id && t.userId != widget.currentUserId,
    );
    final messages = _messages;
    final outgoing = _outgoing;
    final hasMore = _state.messages[_id]?.hasMore ?? false;
    final contextMessage = _editing ?? _reply;
    final deletedEditing =
        _editing != null &&
        messages.any((m) => m.id == _editing!.id && m.isDeleted);
    _scheduleRead();
    return Scaffold(
      appBar: AppBar(
        leading: const MingleBackButton(),
        flexibleSpace: const MingleBackdrop(
          intensity: .4,
          child: SizedBox.expand(),
        ),
        title: InkWell(
          onTap: _profile,
          child: Row(
            children: [
              InitialAvatar(name, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (typing)
                      const MingleTyping()
                    else
                      Text(
                        (other.username != null
                            ? '@${other.username}'
                            : 'Direct conversation'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: MingleBackdrop(
        intensity: .28,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              if (_state.connection == ConversationConnection.offline)
                MaterialBanner(
                  content: const Text(
                    'Connection paused. Messages may need a retry.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        try {
                          await widget.repository.resynchronize();
                        } catch (e) {
                          if (context.mounted) showFailure(context, e);
                        }
                      },
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: Text(friendlyError(_loadError!))),
                      TextButton(
                        onPressed: () => _load(),
                        child: const Text('Retry history'),
                      ),
                    ],
                  ),
                ),
              if (_readError != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Read status could not be saved.'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _readError = null);
                          _scheduleRead();
                        },
                        child: const Text('Retry read'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SizedBox(
                  key: _viewport,
                  child: _loading && messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : messages.isEmpty && outgoing.isEmpty
                      ? const StatusPanel(
                          'Say hello to start the conversation.',
                        )
                      : ListView.builder(
                          controller: _scroll,
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              outgoing.length +
                              messages.length +
                              (hasMore ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i < outgoing.length) {
                              final m = outgoing[i];
                              return MessageCard(
                                key: ValueKey(m.clientMessageId),
                                animateArrival: _arrivingIds.remove(
                                  m.clientMessageId,
                                ),
                                text: m.text,
                                own: true,
                                status: m.status == OutgoingStatus.failed
                                    ? 'Failed · Tap to retry'
                                    : 'Sending…',
                                onTap: m.status == OutgoingStatus.failed
                                    ? () => _retry(m)
                                    : null,
                              );
                            }
                            final index = i - outgoing.length;
                            if (index == messages.length) {
                              return TextButton(
                                onPressed: _more
                                    ? null
                                    : () => _load(older: true),
                                child: Text(
                                  _more ? 'Loading…' : 'Load older messages',
                                ),
                              );
                            }
                            final m = messages[index];
                            final own = m.senderId == widget.currentUserId;
                            final read =
                                own &&
                                _state.readPointers.any(
                                  (p) =>
                                      p.conversationId == _id &&
                                      p.userId != widget.currentUserId &&
                                      covers(p, m, messages),
                                );
                            final reply = m.replyToMessageId == null
                                ? null
                                : messages
                                      .where((r) => r.id == m.replyToMessageId)
                                      .firstOrNull;
                            final date = m.createdAt.toLocal();
                            final previous = index + 1 < messages.length
                                ? messages[index + 1].createdAt.toLocal()
                                : null;
                            final showDate =
                                previous == null ||
                                date.year != previous.year ||
                                date.month != previous.month ||
                                date.day != previous.day;
                            final older = index + 1 < messages.length
                                ? messages[index + 1]
                                : null;
                            final newer = index > 0
                                ? messages[index - 1]
                                : null;
                            bool groupedWith(ConversationMessage? neighbor) =>
                                neighbor != null &&
                                !m.isDeleted &&
                                !neighbor.isDeleted &&
                                neighbor.senderId == m.senderId &&
                                m.replyToMessageId == null &&
                                neighbor.replyToMessageId == null &&
                                m.createdAt
                                        .difference(neighbor.createdAt)
                                        .abs() <
                                    const Duration(minutes: 5) &&
                                m.createdAt.toLocal().year ==
                                    neighbor.createdAt.toLocal().year &&
                                m.createdAt.toLocal().month ==
                                    neighbor.createdAt.toLocal().month &&
                                m.createdAt.toLocal().day ==
                                    neighbor.createdAt.toLocal().day;
                            return Column(
                              key: ValueKey(m.id),
                              children: [
                                if (showDate)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${date.day}/${date.month}/${date.year}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ),
                                  ),
                                MessageCard(
                                  groupedBefore: groupedWith(older),
                                  groupedAfter: groupedWith(newer),
                                  animateArrival: _arrivingIds.remove(m.id),
                                  key: _messageKeys.putIfAbsent(
                                    m.id,
                                    GlobalKey.new,
                                  ),
                                  text: m.isDeleted
                                      ? 'Message deleted'
                                      : m.text ?? '',
                                  own: own,
                                  deleted: m.isDeleted,
                                  quote:
                                      m.isDeleted || m.replyToMessageId == null
                                      ? null
                                      : reply == null
                                      ? 'Reply to an earlier message'
                                      : reply.isDeleted
                                      ? 'Message deleted'
                                      : reply.text,
                                  status:
                                      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}${m.editedAt != null && !m.isDeleted ? ' · edited' : ''}${own && !m.isDeleted
                                          ? read
                                                ? ' · Read'
                                                : ' · Sent'
                                          : ''}',
                                  onLongPress: m.isDeleted
                                      ? null
                                      : () => _actions(m),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),
              if (contextMessage != null)
                ListTile(
                  title: Text(
                    _editing != null
                        ? deletedEditing
                              ? 'This message was deleted'
                              : 'Editing message'
                        : 'Replying',
                  ),
                  subtitle: Text(
                    contextMessage.isDeleted
                        ? 'Message deleted'
                        : contextMessage.text ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Cancel',
                    onPressed: _savingEdit
                        ? null
                        : () => setState(() {
                            if (_editing != null) _text.clear();
                            _reply = null;
                            _editing = null;
                          }),
                    icon: const MingleIcon(MingleGlyph.close),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        enabled: !_savingEdit,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 4000,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          hintText: 'Message…',
                          counterText: '',
                          errorText: messageLength(_text.text.trim()) > 4000
                              ? 'Use at most 4,000 characters.'
                              : null,
                        ),
                        onChanged: (v) {
                          _typing(v);
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    MinglePress(
                      enabled:
                          _text.text.trim().isNotEmpty &&
                          messageLength(_text.text.trim()) <= 4000 &&
                          !_savingEdit &&
                          !deletedEditing,
                      child: IconButton.filled(
                        tooltip: _editing == null
                            ? 'Send message'
                            : 'Save edit',
                        style: IconButton.styleFrom(
                          minimumSize: const Size(50, 50),
                        ),
                        onPressed:
                            _text.text.trim().isEmpty ||
                                messageLength(_text.text.trim()) > 4000 ||
                                _savingEdit ||
                                deletedEditing
                            ? null
                            : _send,
                        icon: MingleIcon(
                          _editing == null
                              ? MingleGlyph.plane
                              : MingleGlyph.check,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int compareMessages(ConversationMessage a, ConversationMessage b) {
  final t = a.createdAt.compareTo(b.createdAt);
  return t != 0 ? t : a.id.compareTo(b.id);
}

bool covers(
  ReadPointer pointer,
  ConversationMessage message,
  List<ConversationMessage> loaded,
) {
  final position =
      pointer.lastReadMessageCreatedAt ??
      loaded
          .where((m) => m.id == pointer.lastReadMessageId)
          .firstOrNull
          ?.createdAt;
  if (pointer.lastReadMessageId == message.id) return true;
  if (position == null) return false;
  final time = position.compareTo(message.createdAt);
  return time > 0 ||
      (time == 0 && pointer.lastReadMessageId.compareTo(message.id) >= 0);
}

class MessageCard extends StatelessWidget {
  const MessageCard({
    required this.text,
    required this.own,
    required this.status,
    this.quote,
    this.deleted = false,
    this.onTap,
    this.onLongPress,
    this.animateArrival = false,
    this.groupedBefore = false,
    this.groupedAfter = false,
    super.key,
  });
  final bool groupedBefore;
  final bool groupedAfter;
  final String text;
  final bool own;
  final String status;
  final String? quote;
  final bool deleted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool animateArrival;
  @override
  Widget build(BuildContext context) => MingleArrival(
    animate: animateArrival,
    child: Align(
      alignment: own
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Padding(
        padding: EdgeInsets.only(top: groupedBefore ? 1 : 6, bottom: 1),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .76,
          ),
          child: Material(
            color: own
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface
                : const Color(0xFFFFFDFC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(!own && groupedBefore ? 7 : 22),
                topEnd: Radius.circular(own && groupedBefore ? 7 : 22),
                bottomStart: Radius.circular(
                  own
                      ? 22
                      : groupedAfter
                      ? 7
                      : 5,
                ),
                bottomEnd: Radius.circular(
                  !own
                      ? 22
                      : groupedAfter
                      ? 7
                      : 5,
                ),
              ),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              onLongPress: onLongPress,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (quote != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: BorderDirectional(
                            start: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          quote!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Text(
                      text,
                      textDirection: messageDirection(text),
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: 15.5,
                        fontStyle: deleted
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          status,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        if (own &&
                            !deleted &&
                            (status.endsWith('Read') ||
                                status.endsWith('Sent')))
                          AnimatedSwitcher(
                            duration: MingleMotion.duration(
                              context,
                              milliseconds: 140,
                            ),
                            child: MingleIcon(
                              status.endsWith('Read')
                                  ? MingleGlyph.read
                                  : MingleGlyph.check,
                              key: ValueKey(status.endsWith('Read')),
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

TextDirection messageDirection(String text) {
  final first = RegExp(r'[A-Za-z\u0621-\u064A\u066E-\u06D3]')
      .firstMatch(text)
      ?.group(0);
  return first != null && first.codeUnitAt(0) > 127
      ? TextDirection.rtl
      : TextDirection.ltr;
}

// Match the server validator's Unicode length (surrogate pairs and variation selectors).
int messageLength(String text) => text
    .replaceAllMapped(
      RegExp(r'([^\uFE0F\uFE0E])[\uFE0F\uFE0E]', unicode: true),
      (m) => m[1]!,
    )
    .runes
    .length;
