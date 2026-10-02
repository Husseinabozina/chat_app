import '../core/preferences/app_preferences.dart';
import '../features/auth/domain/repositories/backend_account_repository.dart';
import '../features/conversations/domain/repositories/conversations_repository.dart';
import '../features/media/domain/media_repository.dart';
import '../features/push/domain/push_repository.dart';
import '../features/users/domain/users_repository.dart';

/// Infrastructure is composed at the entrypoint; widgets consume domain ports.
final class BackendAppServices {
  const BackendAppServices({
    required this.account,
    required this.conversations,
    required this.users,
    required this.pause,
    required this.resume,
    required this.preferences,
    this.media,
    this.push,
  });
  final BackendAccountRepository account;
  final ConversationsRepository conversations;
  final UsersRepository users;
  final void Function() pause;
  final Future<void> Function() resume;
  final AppPreferences preferences;
  final MediaRepository? media;
  final PushRepository? push;
}
