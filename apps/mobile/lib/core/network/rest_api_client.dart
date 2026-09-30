import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../failures/app_failure.dart';
import 'api_session.dart';

final class RestApiClient {
  factory RestApiClient({
    required Uri baseUrl,
    required http.Client httpClient,
    required ApiSessionStore sessionStore,
  }) => RestApiClient._(baseUrl, httpClient, sessionStore);

  RestApiClient._(this._baseUrl, this._httpClient, this._sessionStore);

  final Uri _baseUrl;
  final http.Client _httpClient;
  final ApiSessionStore _sessionStore;
  Future<ApiSession>? _refreshing;

  Future<ApiSession?> currentSession() => _sessionStore.read();

  Future<void> saveSession(ApiSession session) => _sessionStore.write(session);

  Future<void> clearSession() => _sessionStore.clear();

  Future<ApiSession> refreshSession() => _refresh();

  Future<String> accessToken() async {
    final session = await _sessionStore.read();
    if (session == null) throw _unauthorized();
    if (session.needsRefresh) return (await _refresh()).accessToken;
    return session.accessToken;
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, Object?>? body,
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    var token = authenticated ? await accessToken() : null;
    var response = await _send(method, path, body, query, token);

    if (authenticated && response.statusCode == 401) {
      token = (await _refresh()).accessToken;
      response = await _send(method, path, body, query, token);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _failure(response);
    }

    if (response.body.isEmpty) return const {};
    return _decodeObject(response.body);
  }

  Future<ApiSession> _refresh() async {
    final pending = _refreshing ??= _performRefresh();
    try {
      return await pending;
    } finally {
      if (identical(_refreshing, pending)) _refreshing = null;
    }
  }

  Future<ApiSession> _performRefresh() async {
    final previous = await _sessionStore.read();
    if (previous == null) throw _unauthorized();

    try {
      final response = await _send(
        'POST',
        '/auth/refresh',
        {'refreshToken': previous.refreshToken},
        null,
        null,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) await _sessionStore.clear();
        throw _failure(response);
      }

      final data = _decodeObject(response.body);
      final session = sessionFromAuthResponse(data);
      await _sessionStore.write(session);
      return session;
    } on AppFailure {
      rethrow;
    } on http.ClientException catch (error) {
      throw AppFailure(kind: FailureKind.network, debugMessage: error.message);
    } on TimeoutException catch (error) {
      throw AppFailure(kind: FailureKind.network, debugMessage: '$error');
    }
  }

  Future<http.Response> _send(
    String method,
    String path,
    Map<String, Object?>? body,
    Map<String, String>? query,
    String? token,
  ) async {
    final uri = _baseUrl.replace(
      path: '${_baseUrl.path.replaceFirst(RegExp(r'/$'), '')}$path',
      queryParameters: query,
    );
    final request = http.Request(method, uri);
    request.headers['accept'] = 'application/json';
    if (token != null) request.headers['authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    try {
      return await http.Response.fromStream(await _httpClient.send(request));
    } on http.ClientException catch (error) {
      throw AppFailure(kind: FailureKind.network, debugMessage: error.message);
    } on TimeoutException catch (error) {
      throw AppFailure(kind: FailureKind.network, debugMessage: '$error');
    }
  }
}

ApiSession sessionFromAuthResponse(Map<String, dynamic> data) {
  try {
    final user = data['user'] as Map<String, dynamic>;
    final expiresIn = data['expiresIn'] as num;
    return ApiSession(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      expiresAt: DateTime.now().toUtc().add(
        Duration(seconds: expiresIn.toInt()),
      ),
      userId: user['id'] as String,
    );
  } on TypeError {
    throw const AppFailure(
      kind: FailureKind.unknown,
      debugMessage: 'Invalid authentication response.',
    );
  }
}

Map<String, dynamic> _decodeObject(String text) {
  try {
    return jsonDecode(text) as Map<String, dynamic>;
  } on FormatException {
    throw const AppFailure(
      kind: FailureKind.unknown,
      debugMessage: 'Invalid JSON response.',
    );
  } on TypeError {
    throw const AppFailure(
      kind: FailureKind.unknown,
      debugMessage: 'Expected JSON object.',
    );
  }
}

AppFailure _failure(http.Response response) {
  String? code;
  try {
    final body = _decodeObject(response.body);
    final error = body['error'] as Map<String, dynamic>?;
    code = error?['code'] as String?;
  } on AppFailure {
    // HTTP status remains authoritative when an error body is malformed.
  }

  final kind = switch (response.statusCode) {
    400 => FailureKind.validation,
    401 || 403 => FailureKind.unauthorized,
    404 => FailureKind.validation,
    409 => FailureKind.conflict,
    429 => FailureKind.network,
    >= 500 => FailureKind.network,
    _ => FailureKind.unknown,
  };
  return AppFailure(
    kind: kind,
    debugMessage: code ?? 'HTTP ${response.statusCode}',
  );
}

AppFailure _unauthorized() => const AppFailure(
  kind: FailureKind.unauthorized,
  debugMessage: 'No backend session.',
);
