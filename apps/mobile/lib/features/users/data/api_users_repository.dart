import '../../../core/network/rest_api_client.dart';
import '../../conversations/domain/entities/conversation.dart';
import '../domain/users_repository.dart';

final class ApiUsersRepository implements UsersRepository {
  const ApiUsersRepository(this._api);
  final RestApiClient _api;
  UserProfile _profile(Map<String, dynamic> value) => UserProfile(
    id: value['id'] as String,
    email: value['email'] as String?,
    username: value['username'] as String?,
    displayName: value['displayName'] as String?,
    bio: value['bio'] as String?,
    avatarUrl: value['avatarUrl'] as String?,
  );
  @override
  Future<UserProfile> getMe() async =>
      _profile(await _api.request('GET', '/users/me'));
  @override
  Future<UserProfile> getProfile(String userId) async =>
      _profile(await _api.request('GET', '/users/$userId'));
  @override
  Future<UserProfile> updateMe({
    required String username,
    required String displayName,
    required String bio,
  }) async => _profile(
    await _api.request(
      'PATCH',
      '/users/me',
      body: {
        'username': username.trim(),
        'displayName': displayName.trim(),
        'bio': bio.trim(),
      },
    ),
  );
  @override
  Future<CursorPage<UserProfile>> search(String query, {String? cursor}) async {
    final data = await _api.request(
      'GET',
      '/users',
      query: {'query': query.trim(), 'limit': '20', 'cursor': ?cursor},
    );
    return CursorPage(
      items: (data['items'] as List)
          .map((v) => _profile(v as Map<String, dynamic>))
          .toList(growable: false),
      hasMore: data['hasMore'] as bool,
      nextCursor: data['nextCursor'] as String?,
    );
  }
}
