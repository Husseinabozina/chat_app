import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/failures/app_failure.dart';
import '../../../core/network/rest_api_client.dart';
import '../domain/media_repository.dart';

final class ApiMediaRepository implements MediaRepository {
  ApiMediaRepository(this.api, this.httpClient);
  _UploadAttempt? _attempt;
  final RestApiClient api;
  final http.Client httpClient;
  @override
  Future<SelectedPhoto?> pickPhoto(PhotoSource source) async {
    final file = await ImagePicker().pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (file == null) return null;
    if (await file.length() > 6291456) {
      throw const AppFailure(
        kind: FailureKind.validation,
        userMessage: 'Choose an image under 6 MB.',
      );
    }
    final bytes = await file.readAsBytes();
    final mime = bytes.length > 3 && bytes[0] == 255 && bytes[1] == 216
        ? 'image/jpeg'
        : bytes.length > 8 &&
              bytes[0] == 137 &&
              bytes[1] == 80 &&
              bytes[2] == 78 &&
              bytes[3] == 71
        ? 'image/png'
        : bytes.length > 12 &&
              String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
              String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP'
        ? 'image/webp'
        : null;
    if (mime == null) {
      throw const AppFailure(
        kind: FailureKind.validation,
        userMessage: 'Choose a JPEG, PNG or WebP image.',
      );
    }
    return SelectedPhoto(bytes, mime);
  }

  @override
  Future<String> uploadPhoto(
    SelectedPhoto photo, {
    required String purpose,
    String? conversationId,
  }) async {
    final revision = api.sessionRevision;
    var attempt = _attempt;
    if (attempt == null ||
        !identical(attempt.photo, photo) ||
        attempt.purpose != purpose ||
        attempt.conversationId != conversationId ||
        attempt.revision != revision ||
        (!attempt.uploaded && attempt.expiresAt.isBefore(DateTime.now()))) {
      final grant = await api.request(
        'POST',
        '/media/uploads',
        body: {
          'purpose': purpose,
          'mimeType': photo.mimeType,
          'sizeBytes': photo.bytes.length,
          'conversationId': ?conversationId,
        },
      );
      attempt = _UploadAttempt(photo, purpose, conversationId, revision, grant);
      _attempt = attempt;
    }
    final ticket = attempt.grant;
    if (!attempt.uploaded) {
      final target = ticket['upload'] as Map<String, dynamic>;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(target['url'] as String),
      );
      request.fields.addAll(
        (target['fields'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as String),
        ),
      );
      // The signed form Content-Type field declares the image type; file is last.
      request.files.add(
        http.MultipartFile.fromBytes('file', photo.bytes, filename: 'image'),
      );
      try {
        final response = await httpClient
            .send(request)
            .timeout(const Duration(seconds: 60));
        await response.stream.drain<void>().timeout(
          const Duration(seconds: 15),
        );
        if (api.sessionRevision != revision) {
          throw const AppFailure(kind: FailureKind.unauthorized);
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw const AppFailure(kind: FailureKind.network);
        }
      } on http.ClientException {
        throw const AppFailure(kind: FailureKind.network);
      } on TimeoutException {
        throw const AppFailure(kind: FailureKind.network);
      }
      attempt.uploaded = true;
    }
    final id = ticket['mediaId'] as String;
    await api.request('POST', '/media/$id/complete');
    return id;
  }

  @override
  Future<void> setAvatar(String mediaId) async {
    await api.request('PATCH', '/media/$mediaId/avatar');
  }

  @override
  Future<String> downloadUrl(String reference) async {
    final id = reference.startsWith('/v1/media/')
        ? reference.split('/')[3]
        : reference;
    final data = await api.request('GET', '/media/$id/content');
    return data['url'] as String;
  }
}

final class _UploadAttempt {
  _UploadAttempt(
    this.photo,
    this.purpose,
    this.conversationId,
    this.revision,
    this.grant,
  );
  final SelectedPhoto photo;
  final String purpose;
  final String? conversationId;
  final int revision;
  final Map<String, dynamic> grant;
  final expiresAt = DateTime.now().add(const Duration(seconds: 280));
  bool uploaded = false;
}
