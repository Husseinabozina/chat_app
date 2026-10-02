import 'dart:typed_data';

enum PhotoSource { gallery, camera }

final class SelectedPhoto {
  const SelectedPhoto(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String mimeType;
}

abstract interface class MediaRepository {
  Future<SelectedPhoto?> pickPhoto(PhotoSource source);
  Future<String> uploadPhoto(
    SelectedPhoto photo, {
    required String purpose,
    String? conversationId,
  });
  Future<void> setAvatar(String mediaId);
  Future<String> downloadUrl(String reference);
}
