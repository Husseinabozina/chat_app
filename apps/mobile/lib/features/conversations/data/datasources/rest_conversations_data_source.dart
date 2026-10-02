import 'package:uuid/uuid.dart';

import '../../../../core/network/rest_api_client.dart';
import '../../domain/entities/conversation.dart';
import '../models/conversation_dto.dart';
import 'conversation_sources.dart';

final class RestConversationsDataSource implements ConversationsRestSource {
  const RestConversationsDataSource(this._api);

  final RestApiClient _api;

  @override
  Future<CursorPage<ConversationSummary>> listConversations({
    String? cursor,
    int limit = 20,
  }) async {
    final query = {'limit': '$limit'};
    if (cursor != null) query['cursor'] = cursor;
    final data = await _api.request('GET', '/conversations', query: query);
    return pageFromJson(data, conversationFromJson);
  }

  @override
  Future<List<ReadPointer>> getReadState(String conversationId) async {
    final data = await _api.request(
      'GET',
      '/conversations/$conversationId/read-state',
    );
    return (data['members'] as List<dynamic>)
        .map(asObject)
        .where(
          (member) =>
              member['lastReadMessageId'] != null &&
              member['lastReadAt'] != null,
        )
        .map(
          (member) => ReadPointer(
            conversationId: conversationId,
            userId: member['userId'] as String,
            lastReadMessageId: member['lastReadMessageId'] as String,
            lastReadAt: asDate(member['lastReadAt']),
            lastReadMessageCreatedAt: asNullableDate(
              member['lastReadMessageCreatedAt'],
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<ConversationSummary> openDirect(String userId) async {
    final data = await _api.request(
      'POST',
      '/conversations/direct',
      body: {'userId': userId},
    );
    return conversationFromJson(data);
  }

  @override
  Future<CursorPage<ConversationMessage>> listMessages(
    String conversationId, {
    String? before,
    int limit = 40,
  }) async {
    final query = {'limit': '$limit'};
    if (before != null) query['before'] = before;
    final data = await _api.request(
      'GET',
      '/conversations/$conversationId/messages',
      query: query,
    );
    return pageFromJson(data, messageFromJson);
  }

  @override
  Future<ConversationMessage> sendMessage(
    String conversationId,
    String text, {
    String? clientMessageId,
    String? replyToMessageId,
    String? imageMediaId,
  }) async {
    final data = await _api.request(
      'POST',
      '/conversations/$conversationId/messages',
      body: {
        'clientMessageId': clientMessageId ?? const Uuid().v4(),
        'type': imageMediaId == null ? 'text' : 'image',
        'imageMediaId': ?imageMediaId,
        'text': text,
        'replyToMessageId': replyToMessageId,
        'attachments': <Object>[],
      },
    );
    return messageFromJson(data);
  }

  @override
  Future<ConversationMessage> editMessage(String messageId, String text) async {
    final data = await _api.request(
      'PATCH',
      '/messages/$messageId',
      body: {'text': text},
    );
    return messageFromJson(data);
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await _api.request('DELETE', '/messages/$messageId');
  }

  @override
  Future<ReadPointer> markRead(
    String conversationId,
    String upToMessageId,
    String userId,
  ) async {
    final data = await _api.request(
      'POST',
      '/conversations/$conversationId/read',
      body: {'upToMessageId': upToMessageId},
    );
    return ReadPointer(
      conversationId: data['conversationId'] as String,
      userId: userId,
      lastReadMessageId: data['lastReadMessageId'] as String,
      lastReadAt: asDate(data['lastReadAt']),
      lastReadMessageCreatedAt: asNullableDate(
        data['lastReadMessageCreatedAt'],
      ),
    );
  }
}
