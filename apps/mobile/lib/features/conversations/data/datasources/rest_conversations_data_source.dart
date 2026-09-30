import 'package:uuid/uuid.dart';

import '../../../../core/network/rest_api_client.dart';
import '../../domain/entities/conversation.dart';
import '../models/conversation_dto.dart';

final class RestConversationsDataSource {
  const RestConversationsDataSource(this._api);

  final RestApiClient _api;

  Future<CursorPage<ConversationSummary>> listConversations({
    String? cursor,
    int limit = 20,
  }) async {
    final query = {'limit': '$limit'};
    if (cursor != null) query['cursor'] = cursor;
    final data = await _api.request('GET', '/conversations', query: query);
    return pageFromJson(data, conversationFromJson);
  }

  Future<ConversationSummary> openDirect(String userId) async {
    final data = await _api.request(
      'POST',
      '/conversations/direct',
      body: {'userId': userId},
    );
    return conversationFromJson(data);
  }

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

  Future<ConversationMessage> sendMessage(
    String conversationId,
    String text, {
    String? clientMessageId,
    String? replyToMessageId,
  }) async {
    final data = await _api.request(
      'POST',
      '/conversations/$conversationId/messages',
      body: {
        'clientMessageId': clientMessageId ?? const Uuid().v4(),
        'type': 'text',
        'text': text,
        'replyToMessageId': replyToMessageId,
        'attachments': <Object>[],
      },
    );
    return messageFromJson(data);
  }

  Future<ConversationMessage> editMessage(String messageId, String text) async {
    final data = await _api.request(
      'PATCH',
      '/messages/$messageId',
      body: {'text': text},
    );
    return messageFromJson(data);
  }

  Future<void> deleteMessage(String messageId) async {
    await _api.request('DELETE', '/messages/$messageId');
  }

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
    );
  }
}
