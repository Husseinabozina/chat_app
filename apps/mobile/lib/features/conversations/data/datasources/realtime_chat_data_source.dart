import 'dart:async';
import 'dart:math';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/failures/app_failure.dart';
import '../../../../core/network/rest_api_client.dart';
import '../../domain/entities/conversation_event.dart';
import '../models/conversation_dto.dart';
import '../models/realtime_event_dto.dart';
import 'conversation_sources.dart';

final class RealtimeChatDataSource implements ConversationsRealtimeSource {
  factory RealtimeChatDataSource({
    required Uri serverUrl,
    required RestApiClient api,
  }) => RealtimeChatDataSource._(serverUrl, api);

  RealtimeChatDataSource._(this._serverUrl, this._api);

  static const _eventNames = [
    'message.created',
    'message.updated',
    'message.deleted',
    'conversation.updated',
    'read.updated',
    'typing.started',
    'typing.stopped',
  ];

  final Uri _serverUrl;
  final RestApiClient _api;
  final StreamController<ConversationEvent> _events =
      StreamController<ConversationEvent>.broadcast();
  final Random _random = Random();
  io.Socket? _socket;
  Timer? _retryTimer;
  int _retryCount = 0;
  bool _wanted = false;
  bool _hasConnected = false;
  bool _needsRefresh = false;
  int _connectionEpoch = 0;

  bool _current(int epoch) => _wanted && epoch == _connectionEpoch;

  @override
  Stream<ConversationEvent> get events => _events.stream;

  bool get isConnected => _socket?.connected ?? false;

  @override
  Future<void> connect() async {
    _wanted = true;
    final epoch = ++_connectionEpoch;
    _retryTimer?.cancel();
    _retryTimer = null;
    try {
      await _connectOnce(epoch);
    } on AppFailure catch (failure) {
      if (!_current(epoch)) return;
      if (failure.kind == FailureKind.unauthorized) {
        _wanted = false;
      } else {
        _scheduleRetry();
      }
      rethrow;
    }
  }

  Future<void> _connectOnce(int epoch) async {
    if (_needsRefresh) {
      await _api.refreshSession();
      if (!_current(epoch)) return;
      _needsRefresh = false;
    }
    final token = await _api.accessToken();
    if (!_current(epoch)) return;
    final previous = _socket;
    _socket = null;
    previous?.dispose();

    final socket = io.io(
      _serverUrl.resolve('/realtime').toString(),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'accessToken': token})
          .disableAutoConnect()
          .disableReconnection()
          .enableForceNew()
          .build(),
    );
    _socket = socket;
    final ready = Completer<void>();

    socket.on('connection.ready', (dynamic raw) {
      if (!_current(epoch) || !identical(_socket, socket)) return;
      try {
        final envelope = asObject(raw);
        if (envelope['protocolVersion'] != 1 ||
            envelope['type'] != 'connection.ready') {
          throw const FormatException('Invalid connection.ready envelope.');
        }
        final event = RealtimeReady(
          eventId: envelope['eventId'] as String,
          occurredAt: asDate(envelope['occurredAt']),
          isReconnect: _hasConnected,
        );
        _hasConnected = true;
        _retryCount = 0;
        _retryTimer?.cancel();
        _retryTimer = null;
        _events.add(event);
        if (!ready.isCompleted) ready.complete();
      } catch (error) {
        if (!ready.isCompleted) ready.completeError(error);
        socket.dispose();
      }
    });

    for (final name in _eventNames) {
      socket.on(name, (dynamic raw) {
        if (!_current(epoch) || !identical(_socket, socket)) return;
        try {
          _events.add(eventFromEnvelope(name, raw));
        } catch (error) {
          _events.addError(
            AppFailure(
              kind: FailureKind.unknown,
              debugMessage: 'Invalid $name event: $error',
            ),
          );
        }
      });
    }

    socket.on('connect_error', (dynamic error) {
      if (!_current(epoch) || !identical(_socket, socket)) return;
      if (error is Map && error['data'] is Map) {
        final details = error['data'] as Map;
        if (details['code'] == 'UNAUTHORIZED') _needsRefresh = true;
      }
      if (!ready.isCompleted) {
        ready.completeError(
          AppFailure(kind: FailureKind.network, debugMessage: '$error'),
        );
      }
      _scheduleRetry();
    });

    socket.on('disconnect', (dynamic reason) {
      if (!_current(epoch) || !identical(_socket, socket)) return;
      _events.add(
        RealtimeDisconnected(
          eventId: 'disconnect-${DateTime.now().microsecondsSinceEpoch}',
          occurredAt: DateTime.now().toUtc(),
        ),
      );
      if (!ready.isCompleted) {
        ready.completeError(
          AppFailure(kind: FailureKind.network, debugMessage: '$reason'),
        );
      }
      _scheduleRetry();
    });

    socket.connect();
    try {
      await ready.future.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      if (identical(_socket, socket)) _socket = null;
      socket.dispose();
      throw const AppFailure(
        kind: FailureKind.network,
        debugMessage: 'Realtime connection timed out.',
      );
    }
  }

  @override
  Future<void> setTyping(String conversationId, {required bool typing}) async {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      throw const AppFailure(
        kind: FailureKind.network,
        debugMessage: 'Realtime is disconnected.',
      );
    }

    final acknowledgement = Completer<void>();
    socket.emitWithAck(
      typing ? 'typing.start' : 'typing.stop',
      {'conversationId': conversationId},
      ack: (dynamic raw) {
        try {
          final result = asObject(raw);
          if (result['ok'] == true) {
            acknowledgement.complete();
          } else {
            acknowledgement.completeError(
              AppFailure(
                kind: FailureKind.validation,
                debugMessage: '${asObject(result['error'])['code']}',
              ),
            );
          }
        } catch (error) {
          acknowledgement.completeError(error);
        }
      },
    );
    await acknowledgement.future.timeout(const Duration(seconds: 5));
  }

  void _scheduleRetry() {
    if (!_wanted || _retryTimer != null) return;
    final exponential = min(30000, 1000 * (1 << min(_retryCount, 5)));
    _retryCount += 1;
    final jittered = (exponential * (0.75 + _random.nextDouble() * 0.5))
        .round();

    final epoch = _connectionEpoch;
    _retryTimer = Timer(Duration(milliseconds: jittered), () async {
      _retryTimer = null;
      if (!_current(epoch)) return;
      try {
        await _connectOnce(epoch);
      } on AppFailure catch (failure) {
        if (!_current(epoch)) return;
        if (failure.kind == FailureKind.unauthorized) {
          _wanted = false;
          _events.addError(failure);
          return;
        }
        _scheduleRetry();
      } catch (_) {
        if (_current(epoch)) _scheduleRetry();
      }
    });
  }

  @override
  void disconnect() {
    _connectionEpoch++;
    _wanted = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    final socket = _socket;
    _socket = null;
    socket?.dispose();
    _hasConnected = false;
    _needsRefresh = false;
  }

  Future<void> close() async {
    disconnect();
    await _events.close();
  }
}
