import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../../core/failures/app_failure.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/conversation_event.dart';
import '../../domain/repositories/conversations_repository.dart';
import '../datasources/conversation_sources.dart';

final class ApiConversationsRepository implements ConversationsRepository {
  ApiConversationsRepository(
    this._rest,
    this._realtime, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  final ConversationsRestSource _rest;
  final ConversationsRealtimeSource _realtime;
  final _states = StreamController<ConversationsState>.broadcast();
  final _conversations = <String, ConversationSummary>{};
  final _messages = <String, Map<String, ConversationMessage>>{};
  final _messagePages = <String, CursorPage<ConversationMessage>>{};
  final _outgoing = <String, OutgoingMessage>{};
  final _sending = <String, Future<ConversationMessage>>{};
  final _deleted = <String, DateTime>{};
  final _localDeleted = <String>{};
  final _reads = <String, ReadPointer>{};
  final _typing = <String, TypingIndicator>{};
  final _typingVersions = <String, DateTime>{};
  final _typingSent = <String, DateTime>{};
  final _recentEvents = <String>{};
  final _buffer = <ConversationEvent>[];
  StreamSubscription<ConversationEvent>? _subscription;
  Timer? _typingExpiry;
  Future<void>? _syncing;
  String? _userId;
  int _generation = 0;
  bool _closed = false;
  bool _dirty = false;
  bool _bufferOverflow = false;
  bool _paused = false;
  bool _hasMore = false;
  String? _nextCursor;
  ConversationConnection _connection = ConversationConnection.stopped;
  AppFailure? _failure;

  @override
  ConversationsState get currentState {
    final conversations = _conversations.values.toList()
      ..sort((a, b) => _order(b.updatedAt, b.id, a.updatedAt, a.id));
    return ConversationsState(
      connection: _connection,
      conversations: CursorPage(
        items: List.unmodifiable(conversations),
        hasMore: _hasMore,
        nextCursor: _nextCursor,
      ),
      messages: Map.unmodifiable({
        for (final entry in _messages.entries) entry.key: _page(entry.key),
      }),
      outgoing: List.unmodifiable(_outgoing.values),
      readPointers: List.unmodifiable(_reads.values),
      typing: List.unmodifiable(_typing.values),
      failure: _failure,
    );
  }

  @override
  Stream<ConversationsState> watchState() => Stream.multi((controller) {
    final subscription = _states.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.add(currentState);
    controller.onCancel = subscription.cancel;
  });

  /// Session owner calls this before opening a realtime connection.
  Future<void> start(String userId) async {
    final stopping = stop();
    final generation = _generation;
    await stopping;
    if (generation != _generation) return;
    if (_closed) throw StateError('Repository is closed.');
    _userId = userId;
    _connection = ConversationConnection.connecting;
    _subscription = _realtime.events.listen(
      _onEvent,
      onError: (Object error) {
        if (!_active(generation)) return;
        _failure = _asFailure(error);
        _scheduleSync();
        _emit();
      },
    );
    _emit();
    try {
      await _realtime.connect();
    } catch (error) {
      if (!_active(generation)) return;
      _connection = ConversationConnection.offline;
      _failure = _asFailure(error);
      _emit();
    }
    if (_active(generation)) await resynchronize();
  }

  Future<void> stop() async {
    _generation++;
    _userId = null;
    _realtime.disconnect();
    final subscription = _subscription;
    _subscription = null;
    _typingExpiry?.cancel();
    _typingExpiry = null;
    _syncing = null;
    _dirty = false;
    _bufferOverflow = false;
    _buffer.clear();
    _conversations.clear();
    _messages.clear();
    _messagePages.clear();
    _outgoing.clear();
    _sending.clear();
    _deleted.clear();
    _localDeleted.clear();
    _reads.clear();
    _typing.clear();
    _typingVersions.clear();
    _typingSent.clear();
    _recentEvents.clear();
    _hasMore = false;
    _nextCursor = null;
    _paused = false;
    _socketReady = false;
    _connection = ConversationConnection.stopped;
    _failure = null;
    _emit();
    await subscription?.cancel();
  }

  void pauseRealtime() {
    _paused = true;
    _socketReady = false;
    _realtime.disconnect();
    _typing.clear();
    _typingVersions.clear();
    _typingSent.clear();
    _typingExpiry?.cancel();
    _connection = ConversationConnection.offline;
    _emit();
  }

  Future<void> resumeRealtime() async {
    _requireUser();
    _paused = false;
    final generation = _generation;
    _connection = ConversationConnection.connecting;
    _socketReady = false;
    _emit();
    try {
      await _realtime.connect();
    } catch (error) {
      if (_active(generation)) {
        _connection = ConversationConnection.offline;
        _failure = _asFailure(error);
        _emit();
      }
    }
    if (_active(generation)) await resynchronize();
  }

  @override
  Future<void> resynchronize() {
    _requireUser();
    if (_syncing != null) return _syncing!;
    final generation = _generation;
    final completer = Completer<void>();
    _syncing = completer.future;
    _connection = ConversationConnection.syncing;
    _emit();
    // Install the pending future before issuing REST requests or receiving events.
    void finish() {
      if (_active(generation)) {
        _syncing = null;
        _emit();
      }
    }

    unawaited(
      _synchronize(generation).then(
        (_) {
          finish();
          completer.complete();
        },
        onError: (Object error, StackTrace trace) {
          finish();
          completer.completeError(error, trace);
        },
      ),
    );
    return completer.future;
  }

  Future<void> _synchronize(int generation) async {
    try {
      // Summary payloads have no durable revision. If one arrives during a
      // snapshot request, invalidate and refetch instead of guessing its order.
      do {
        _dirty = false;
        _bufferOverflow = false;
        final conversationPages = <CursorPage<ConversationSummary>>[];
        final target = _conversations.length;
        String? cursor;
        var fetched = 0;
        do {
          final page = await _rest.listConversations(cursor: cursor);
          if (!_active(generation)) return;
          conversationPages.add(page);
          fetched += page.items.length;
          cursor = page.nextCursor;
          if (!page.hasMore || cursor == null || fetched >= target) break;
        } while (true);

        final messagePages = <String, List<CursorPage<ConversationMessage>>>{};
        final readStates = <ReadPointer>[];
        for (final id in _messages.keys.toList()) {
          final pages = <CursorPage<ConversationMessage>>[];
          final target = _messages[id]?.length ?? 0;
          String? before;
          var fetched = 0;
          do {
            final page = await _rest.listMessages(id, before: before);
            if (!_active(generation)) return;
            pages.add(page);
            fetched += page.items.length;
            before = page.nextCursor;
            if (!page.hasMore || before == null || fetched >= target) break;
          } while (true);
          messagePages[id] = pages;
          readStates.addAll(await _rest.getReadState(id));
          if (!_active(generation)) return;
        }
        if (!_active(generation)) return;
        _conversations.clear();
        for (final page in conversationPages) {
          for (final conversation in page.items) {
            _conversations[conversation.id] = conversation;
          }
        }
        _hasMore = conversationPages.last.hasMore;
        _nextCursor = conversationPages.last.nextCursor;
        for (final entry in messagePages.entries) {
          for (final page in entry.value) {
            for (final message in page.items) {
              _mergeMessage(message, authoritative: true);
            }
          }
          _messagePages[entry.key] = entry.value.last;
        }
        for (final pointer in readStates) {
          _mergeRead(pointer);
        }
        final events = List<ConversationEvent>.of(_buffer);
        _buffer.clear();
        for (final event in events) {
          if (event is ConversationChanged) {
            _dirty = true;
          } else {
            _apply(event);
          }
        }
        if (_bufferOverflow) _dirty = true;
      } while (_dirty && _active(generation));
      if (!_active(generation)) return;
      _failure = null;
      _connection = _paused || !_socketReady
          ? ConversationConnection.offline
          : ConversationConnection.live;
    } catch (error) {
      if (!_active(generation)) return;
      // Preserve durable resource events, but do not apply unordered summaries.
      final events = List<ConversationEvent>.of(_buffer);
      _buffer.clear();
      for (final event in events) {
        if (event is! ConversationChanged) _apply(event);
      }
      _failure = _asFailure(error);
      _connection = ConversationConnection.offline;
      rethrow;
    }
  }

  bool _socketReady = false;

  void _onEvent(ConversationEvent event) {
    if (_userId == null || _paused) return;
    if (event is RealtimeReady) {
      _socketReady = true;
      _scheduleSync();
      return;
    }
    if (event is RealtimeDisconnected) {
      _socketReady = false;
      _connection = ConversationConnection.offline;
      _typing.clear();
      _typingVersions.clear();
      _typingSent.clear();
      _emit();
      return;
    }
    if (!_recentEvents.add(event.eventId)) return;
    if (_recentEvents.length > 512) _recentEvents.remove(_recentEvents.first);
    if (_syncing != null) {
      if (_buffer.length >= 1024) {
        _bufferOverflow = true;
        _dirty = true;
      } else {
        _buffer.add(event);
      }
      return;
    }
    if (event is ConversationChanged) {
      _scheduleSync();
    } else {
      _apply(event);
      _emit();
    }
  }

  void _scheduleSync() {
    if (_userId == null || _closed) return;
    if (_syncing != null) {
      _dirty = true;
      return;
    }
    unawaited(resynchronize().catchError((Object _) {}));
  }

  void _apply(ConversationEvent event) {
    switch (event) {
      case MessageChanged():
        _mergeMessage(event.message);
      case MessageDeleted():
        final previous = _deleted[event.messageId];
        if (previous == null || event.deletedAt.isAfter(previous)) {
          _deleted[event.messageId] = event.deletedAt;
        }
        final message = _messages[event.conversationId]?[event.messageId];
        if (message != null) _mergeMessage(message);
      case ReadChanged():
        _mergeRead(event.pointer);
      case TypingChanged():
        final key = '${event.conversationId}:${event.userId}';
        final previous = _typingVersions[key];
        if (previous != null && !event.occurredAt.isAfter(previous)) return;
        _typingVersions[key] = event.occurredAt;
        if (event.isTyping &&
            event.expiresAt != null &&
            event.expiresAt!.isAfter(_now().toUtc())) {
          _typing[key] = TypingIndicator(
            conversationId: event.conversationId,
            userId: event.userId,
            expiresAt: event.expiresAt!,
          );
        } else {
          _typing.remove(key);
        }
        _scheduleTypingExpiry();
      case ConversationChanged() || RealtimeReady() || RealtimeDisconnected():
        break;
    }
  }

  void _mergeMessage(
    ConversationMessage incoming, {
    bool authoritative = false,
  }) {
    final messages = _messages.putIfAbsent(incoming.conversationId, () => {});
    final previous = messages[incoming.id];
    if (incoming.deletedAt != null) {
      final deletion = _deleted[incoming.id];
      if (deletion == null || incoming.deletedAt!.isAfter(deletion)) {
        _deleted[incoming.id] = incoming.deletedAt!;
      }
    }
    if (!authoritative &&
        previous != null &&
        (previous.editedAt ?? previous.createdAt) ==
            (incoming.editedAt ?? incoming.createdAt) &&
        previous.text != incoming.text &&
        !_deleted.containsKey(incoming.id) &&
        !_localDeleted.contains(incoming.id)) {
      // Millisecond edit timestamps can tie. REST resolves conflicting content;
      // arrival order and publication timestamps are not resource revisions.
      _scheduleSync();
      return;
    }
    var message = incoming;
    if (previous != null &&
        (previous.editedAt ?? previous.createdAt).isAfter(
          incoming.editedAt ?? incoming.createdAt,
        )) {
      message = previous;
    }
    final deletion = _deleted[incoming.id];
    if (deletion != null || _localDeleted.contains(incoming.id)) {
      message = ConversationMessage(
        id: message.id,
        clientMessageId: message.clientMessageId,
        conversationId: message.conversationId,
        senderId: message.senderId,
        createdAt: message.createdAt,
        replyToMessageId: message.replyToMessageId,
        editedAt: message.editedAt,
        deletedAt: deletion,
        deletionConfirmed: true,
      );
    }
    messages[incoming.id] = message;
    final outgoing = _outgoing[incoming.clientMessageId];
    if (outgoing != null &&
        outgoing.senderId == incoming.senderId &&
        outgoing.conversationId == incoming.conversationId) {
      _outgoing.remove(incoming.clientMessageId);
    }
  }

  void _mergeRead(ReadPointer pointer) {
    final key = '${pointer.conversationId}:${pointer.userId}';
    final previous = _reads[key];
    final messages = _messages[pointer.conversationId];
    final incomingPosition =
        pointer.lastReadMessageCreatedAt ??
        messages?[pointer.lastReadMessageId]?.createdAt;
    final previousPosition =
        previous?.lastReadMessageCreatedAt ??
        messages?[previous?.lastReadMessageId]?.createdAt;
    if (incomingPosition == null ||
        (previous != null && previousPosition == null)) {
      // Old V1 events may lack the optional canonical position. Resolve ambiguity
      // through REST rather than use event or client clocks as message ordering.
      _scheduleSync();
      return;
    }
    if (previous != null &&
        _order(
              incomingPosition,
              pointer.lastReadMessageId,
              previousPosition!,
              previous.lastReadMessageId,
            ) <=
            0) {
      return;
    }
    _reads[key] = ReadPointer(
      conversationId: pointer.conversationId,
      userId: pointer.userId,
      lastReadMessageId: pointer.lastReadMessageId,
      lastReadAt: pointer.lastReadAt,
      lastReadMessageCreatedAt: incomingPosition,
    );
  }

  @override
  Future<void> loadMoreConversations() async {
    _requireUser();
    final generation = _generation;
    final pending = _syncing;
    if (pending != null) await pending;
    _check(generation);
    if (!_hasMore || _nextCursor == null) return;
    final cursor = _nextCursor;
    final page = await _rest.listConversations(cursor: cursor);
    _check(generation);
    // A concurrent resync replaces the cursor; refetch rather than merge stale
    // unread-count snapshots into the current list.
    if (_syncing != null || _nextCursor != cursor) return;
    for (final conversation in page.items) {
      _conversations.putIfAbsent(conversation.id, () => conversation);
    }
    _hasMore = page.hasMore;
    _nextCursor = page.nextCursor;
    _emit();
  }

  @override
  Future<ConversationSummary> openDirect(String userId) async {
    _requireUser();
    final generation = _generation;
    final conversation = await _rest.openDirect(userId);
    _check(generation);
    _conversations.putIfAbsent(conversation.id, () => conversation);
    _scheduleSync();
    _emit();
    return _conversations[conversation.id]!;
  }

  @override
  Future<void> loadMessages(String conversationId, {bool older = false}) async {
    _requireUser();
    final generation = _generation;
    final current = _messagePages[conversationId];
    if (older &&
        (current == null || !current.hasMore || current.nextCursor == null)) {
      return;
    }
    final page = await _rest.listMessages(
      conversationId,
      before: older ? current?.nextCursor : null,
    );
    _check(generation);
    final reads = await _rest.getReadState(conversationId);
    _check(generation);
    _messages.putIfAbsent(conversationId, () => {});
    for (final message in page.items) {
      _mergeMessage(message);
    }
    if (!older || identical(_messagePages[conversationId], current)) {
      _messagePages[conversationId] = page;
    }
    for (final pointer in reads) {
      _mergeRead(pointer);
    }
    _emit();
  }

  @override
  OutgoingMessage prepareMessage(
    String conversationId,
    String text, {
    String? replyToMessageId,
  }) {
    final userId = _requireUser();
    final message = OutgoingMessage(
      clientMessageId: const Uuid().v4(),
      conversationId: conversationId,
      senderId: userId,
      text: text,
      replyToMessageId: replyToMessageId,
      status: OutgoingStatus.pending,
    );
    _outgoing[message.clientMessageId] = message;
    _emit();
    return message;
  }

  @override
  Future<ConversationMessage> sendOutgoing(String clientMessageId) {
    _requireUser();
    final pending = _sending[clientMessageId];
    if (pending != null) return pending;
    final outgoing = _outgoing[clientMessageId];
    if (outgoing == null) {
      for (final messages in _messages.values) {
        for (final message in messages.values) {
          if (message.senderId == _userId &&
              message.clientMessageId == clientMessageId) {
            return Future.value(message);
          }
        }
      }
      throw StateError('Unknown outgoing message.');
    }
    final generation = _generation;
    _outgoing[clientMessageId] = outgoing.withStatus(OutgoingStatus.sending);
    _emit();
    final future = _send(outgoing, generation);
    _sending[clientMessageId] = future;
    return future;
  }

  Future<ConversationMessage> _send(
    OutgoingMessage outgoing,
    int generation,
  ) async {
    try {
      final result = await _rest.sendMessage(
        outgoing.conversationId,
        outgoing.text,
        clientMessageId: outgoing.clientMessageId,
        replyToMessageId: outgoing.replyToMessageId,
      );
      _check(generation);
      _mergeMessage(result);
      _scheduleSync();
      return _messages[result.conversationId]![result.id]!;
    } catch (error) {
      if (_active(generation)) {
        for (final message
            in _messages[outgoing.conversationId]?.values ??
                <ConversationMessage>[]) {
          if (message.senderId == outgoing.senderId &&
              message.clientMessageId == outgoing.clientMessageId) {
            return message;
          }
        }
      }
      if (_active(generation) &&
          _outgoing.containsKey(outgoing.clientMessageId)) {
        _outgoing[outgoing.clientMessageId] = outgoing.withStatus(
          OutgoingStatus.failed,
        );
        _failure = _asFailure(error);
      }
      rethrow;
    } finally {
      if (_active(generation)) {
        _sending.remove(outgoing.clientMessageId);
        _emit();
      }
    }
  }

  @override
  Future<ConversationMessage> editMessage(
    String conversationId,
    String messageId,
    String text,
  ) async {
    _requireUser();
    final generation = _generation;
    final message = await _rest.editMessage(messageId, text);
    _check(generation);
    if (message.conversationId != conversationId) {
      throw StateError('Conversation mismatch.');
    }
    _mergeMessage(message);
    _scheduleSync();
    _emit();
    return _messages[conversationId]![messageId]!;
  }

  @override
  Future<void> deleteMessage(String conversationId, String messageId) async {
    _requireUser();
    final generation = _generation;
    await _rest.deleteMessage(messageId);
    _check(generation);
    // DELETE returns 204. Confirm a local tombstone without inventing a server
    // timestamp; background REST resync obtains the canonical deletedAt value.
    _localDeleted.add(messageId);
    final message = _messages[conversationId]?[messageId];
    if (message != null) _mergeMessage(message);
    _emit();
    _scheduleSync();
  }

  @override
  Future<ReadPointer> markRead(String conversationId, String messageId) async {
    final userId = _requireUser();
    final generation = _generation;
    final pointer = await _rest.markRead(conversationId, messageId, userId);
    _check(generation);
    _mergeRead(pointer);
    _scheduleSync();
    _emit();
    return _reads['$conversationId:$userId'] ?? pointer;
  }

  @override
  Future<void> setTyping(String conversationId, {required bool typing}) async {
    _requireUser();
    final generation = _generation;
    final now = _now().toUtc();
    final previous = _typingSent[conversationId];
    if (typing &&
        previous != null &&
        now.difference(previous) < const Duration(seconds: 3)) {
      return;
    }
    if (typing) {
      _typingSent[conversationId] = now;
    } else {
      _typingSent.remove(conversationId);
    }
    try {
      await _realtime.setTyping(conversationId, typing: typing);
      _check(generation);
    } catch (_) {
      if (_active(generation) && typing && _typingSent[conversationId] == now) {
        _typingSent.remove(conversationId);
      }
      rethrow;
    }
  }

  void _scheduleTypingExpiry() {
    _typingExpiry?.cancel();
    if (_typing.isEmpty) return;
    final now = _now().toUtc();
    _typing.removeWhere((_, value) => !value.expiresAt.isAfter(now));
    if (_typing.isEmpty) return;
    final next = _typing.values
        .map((v) => v.expiresAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    _typingExpiry = Timer(next.difference(now), () {
      _scheduleTypingExpiry();
      _emit();
    });
  }

  CursorPage<ConversationMessage> _page(String id) {
    final messages = _messages[id]!.values.toList()
      ..sort((a, b) => _order(a.createdAt, a.id, b.createdAt, b.id));
    final page = _messagePages[id];
    return CursorPage(
      items: List.unmodifiable(messages),
      hasMore: page?.hasMore ?? false,
      nextCursor: page?.nextCursor,
    );
  }

  bool _active(int generation) =>
      !_closed && _userId != null && generation == _generation;
  void _check(int generation) {
    if (!_active(generation)) {
      throw const AppFailure(
        kind: FailureKind.unauthorized,
        debugMessage: 'Session changed during request.',
      );
    }
  }

  String _requireUser() {
    if (_userId == null || _closed) {
      throw const AppFailure(kind: FailureKind.unauthorized);
    }
    return _userId!;
  }

  void _emit() {
    if (!_closed) _states.add(currentState);
  }

  AppFailure _asFailure(Object error) => error is AppFailure
      ? error
      : AppFailure(kind: FailureKind.unknown, debugMessage: '$error');
  int _order(DateTime a, String aId, DateTime b, String bId) {
    final time = a.compareTo(b);
    return time == 0 ? aId.compareTo(bId) : time;
  }

  Future<void> close() async {
    await stop();
    _closed = true;
    await _states.close();
  }
}
