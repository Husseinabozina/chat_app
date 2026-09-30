import 'package:chat_app/features/conversations/data/models/realtime_event_dto.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a versioned message event into a domain event', () {
    final event = eventFromEnvelope('message.created', {
      'protocolVersion': 1,
      'eventId': 'event-1',
      'type': 'message.created',
      'occurredAt': '2026-09-30T12:00:00.000Z',
      'conversationId': 'conversation-1',
      'data': {
        'message': {
          'id': 'message-1',
          'clientMessageId': 'client-1',
          'conversationId': 'conversation-1',
          'senderId': 'user-1',
          'text': 'Hello',
          'replyToMessageId': null,
          'createdAt': '2026-09-30T12:00:00.000Z',
          'editedAt': null,
          'deletedAt': null,
        },
      },
    });

    expect(event, isA<MessageChanged>());
    expect((event as MessageChanged).message.clientMessageId, 'client-1');
    expect(event.message.text, 'Hello');
  });

  test('rejects a mismatched protocol version', () {
    expect(
      () => eventFromEnvelope('typing.started', {
        'protocolVersion': 2,
        'eventId': 'event-2',
        'type': 'typing.started',
        'occurredAt': '2026-09-30T12:00:00.000Z',
        'data': {},
      }),
      throwsFormatException,
    );
  });
}
