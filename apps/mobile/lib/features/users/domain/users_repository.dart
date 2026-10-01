import '../../conversations/domain/entities/conversation.dart';

final class UserProfile {
  const UserProfile({
    required this.id,
    this.email,
    this.username,
    this.displayName,
    this.bio,
    this.avatarUrl,
  });
  final String id;
  final String? email;
  final String? username;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  String get label => displayName ?? username ?? 'Chat member';
  bool get isComplete =>
      (username?.isNotEmpty ?? false) && (displayName?.isNotEmpty ?? false);
}

abstract interface class UsersRepository {
  Future<UserProfile> getMe();
  Future<UserProfile> getProfile(String userId);
  Future<UserProfile> updateMe({
    required String username,
    required String displayName,
    required String bio,
  });
  Future<CursorPage<UserProfile>> search(String query, {String? cursor});
}
