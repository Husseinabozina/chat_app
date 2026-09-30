import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class ApiSession {
  const ApiSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String userId;

  bool get needsRefresh => !expiresAt.isAfter(
    DateTime.now().toUtc().add(const Duration(seconds: 30)),
  );

  Map<String, Object> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toIso8601String(),
    'userId': userId,
  };

  static ApiSession fromJson(Map<String, dynamic> json) => ApiSession(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
    userId: json['userId'] as String,
  );
}

abstract interface class ApiSessionStore {
  Future<ApiSession?> read();

  Future<void> write(ApiSession session);

  Future<void> clear();
}

final class SecureApiSessionStore implements ApiSessionStore {
  const SecureApiSessionStore(this._storage);

  static const _key = 'chat_app_api_session_v1';
  final FlutterSecureStorage _storage;

  @override
  Future<ApiSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;

    try {
      return ApiSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      await clear();
      return null;
    } on TypeError {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(ApiSession session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
