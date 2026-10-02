import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/failures/app_failure.dart';
import '../../../core/network/rest_api_client.dart';
import '../../../firebase_options.dart';
import '../../conversations/data/models/conversation_dto.dart';
import '../../conversations/domain/entities/conversation.dart';
import '../domain/push_repository.dart';

/// Only FCM transport lives here. Account, message and routing authority stays REST.
final class FcmPushRepository implements PushRepository {
  FcmPushRepository(this.api, this.storage);
  final RestApiClient api;
  final FlutterSecureStorage storage;
  final _states = StreamController<PushStatus>.broadcast();
  final _opens = StreamController<NotificationTarget>.broadcast();
  final _opened = <String>{};
  StreamSubscription<String>? _tokens;
  StreamSubscription<RemoteMessage>? _interactions;
  Future<void>? _firebase;
  String? _userId;
  String? _installation;
  int _generation = 0;
  bool _closed = false;
  PushStatus _status = const PushStatus();
  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
  @override
  PushStatus get status => _status;
  @override
  Stream<PushStatus> watchStatus() => Stream.multi((controller) {
    final subscription = _states.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.add(_status);
    controller.onCancel = subscription.cancel;
  });
  @override
  Stream<NotificationTarget> watchOpens() => _opens.stream;
  void _emit(PushStatus value) {
    if (!_closed) {
      _status = value;
      _states.add(value);
    }
  }

  bool _current(int generation) =>
      !_closed && generation == _generation && _userId != null;
  String _preference(String userId) => 'mingle_push_enabled_v1_$userId';
  Future<String> _installationId() async {
    if (_installation != null) return _installation!;
    final saved = await storage.read(key: 'mingle_push_installation_v1');
    _installation = saved ?? const Uuid().v4();
    if (saved == null) {
      await storage.write(
        key: 'mingle_push_installation_v1',
        value: _installation,
      );
    }
    return _installation!;
  }

  @override
  void bindUser(String? userId) {
    if (_userId == userId || _closed) return;
    _generation++;
    _userId = userId;
    _opened.clear();
    _emit(const PushStatus());
    if (userId != null) unawaited(refresh());
  }

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: false,
        );
    _tokens ??= FirebaseMessaging.instance.onTokenRefresh.listen(
      (_) {
        if (_status.enabled && !_status.busy) unawaited(refresh());
      },
      onError: (Object _) {
        if (_userId != null) {
          _emit(
            PushStatus(
              available: _status.available,
              enabled: _status.enabled,
              detail: 'Could not refresh notifications. Try again.',
            ),
          );
        }
      },
    );
    _interactions ??= FirebaseMessaging.onMessageOpenedApp.listen(_open);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _open(initial);
  }

  Future<void> _ensureFirebase() async {
    _firebase ??= _initializeFirebase();
    try {
      await _firebase;
    } catch (_) {
      _firebase = null;
      rethrow;
    }
  }

  void _open(RemoteMessage message) {
    final data = message.data;
    final userId = data['userId'];
    final conversationId = data['conversationId'];
    final messageId = data['messageId'];
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (_closed ||
        data['type'] != 'message' ||
        userId != _userId ||
        conversationId is! String ||
        messageId is! String ||
        !uuid.hasMatch(conversationId) ||
        !uuid.hasMatch(messageId) ||
        !_opened.add(messageId)) {
      return;
    }
    if (_opened.length > 64) _opened.remove(_opened.first);
    _opens.add(NotificationTarget(userId as String, conversationId, messageId));
  }

  @override
  Future<void> refresh() async {
    if (_closed || _userId == null || _status.busy) return;
    final generation = _generation;
    final userId = _userId!;
    _emit(
      PushStatus(
        available: _status.available,
        enabled: _status.enabled,
        busy: true,
      ),
    );
    try {
      if (!_supported) {
        if (_current(generation)) {
          _emit(
            const PushStatus(
              detail: 'Notifications are not available on this device.',
            ),
          );
        }
        return;
      }
      final server = await api.request('GET', '/devices/status');
      if (!_current(generation)) return;
      if (server['available'] != true) {
        _emit(const PushStatus(detail: 'Notifications are not available yet.'));
        return;
      }
      if (server['projectId'] !=
          DefaultFirebaseOptions.currentPlatform.projectId) {
        _emit(const PushStatus(detail: 'Notifications are not available yet.'));
        return;
      }
      final desired = await storage.read(key: _preference(userId)) == 'true';
      if (!_current(generation)) return;
      _emit(PushStatus(available: true, enabled: desired, busy: true));
      if (desired) await _register(generation, prompt: false);
      if (_current(generation)) {
        _emit(PushStatus(available: true, enabled: desired));
      }
    } catch (_) {
      if (_current(generation)) {
        _emit(
          PushStatus(
            available: _status.available,
            enabled: _status.enabled,
            detail: 'Could not connect notifications. Try again.',
          ),
        );
      }
    }
  }

  Future<void> _register(int generation, {required bool prompt}) async {
    await _ensureFirebase();
    if (!_current(generation)) {
      throw const AppFailure(kind: FailureKind.unauthorized);
    }
    final messaging = FirebaseMessaging.instance;
    final permission = prompt
        ? await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          )
        : await messaging.getNotificationSettings();
    if (permission.authorizationStatus != AuthorizationStatus.authorized &&
        permission.authorizationStatus != AuthorizationStatus.provisional) {
      throw const AppFailure(
        kind: FailureKind.validation,
        userMessage:
            'Allow notifications in your device settings, then try again.',
      );
    }
    if (!_current(generation)) {
      throw const AppFailure(kind: FailureKind.unauthorized);
    }
    await messaging.setAutoInitEnabled(true);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String? apns;
      for (var attempt = 0; attempt < 10 && _current(generation); attempt++) {
        apns = await messaging.getAPNSToken();
        if (apns != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      if (apns == null) {
        throw const AppFailure(
          kind: FailureKind.validation,
          userMessage: 'Notifications are not available on this device yet. Please try again later.',
        );
      }
    }
    final token = await messaging.getToken();
    final installationId = await _installationId();
    if (!_current(generation) || token == null) {
      throw const AppFailure(kind: FailureKind.network);
    }
    await api.request(
      'POST',
      '/devices',
      body: {
        'installationId': installationId,
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      },
    );
    if (!_current(generation)) {
      throw const AppFailure(kind: FailureKind.unauthorized);
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (!_status.available || _status.busy || _userId == null) return;
    final generation = _generation;
    final userId = _userId!;
    final previous = _status.enabled;
    _emit(PushStatus(available: true, enabled: previous, busy: true));
    try {
      if (enabled) {
        await _register(generation, prompt: true);
      } else {
        final installation = await _installationId();
        if (!_current(generation)) return;
        await api.request('DELETE', '/devices/installations/$installation');
      }
      if (!_current(generation)) return;
      await storage.write(key: _preference(userId), value: enabled.toString());
      if (!_current(generation)) return;
      if (!enabled && _firebase != null) {
        // Server revocation is authoritative even if local provider cleanup fails.
        try {
          await FirebaseMessaging.instance.setAutoInitEnabled(false);
          await FirebaseMessaging.instance.deleteToken();
        } catch (_) {
          /* Revoked on server. */
        }
      }
      if (_current(generation)) {
        _emit(PushStatus(available: true, enabled: enabled));
      }
    } catch (error) {
      if (_current(generation)) {
        _emit(
          PushStatus(
            available: true,
            enabled: previous,
            detail: error is AppFailure
                ? error.userMessage
                : 'Could not update notifications. Try again.',
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Future<ConversationSummary> resolveConversation(
    String conversationId,
  ) async => conversationFromJson(
    await api.request('GET', '/conversations/$conversationId'),
  );
  @override
  Future<void> close() async {
    _closed = true;
    _generation++;
    try {
      await _firebase;
    } catch (_) {
      /* Initialization may have failed. */
    }
    await _tokens?.cancel();
    await _interactions?.cancel();
    await _states.close();
    await _opens.close();
  }
}
