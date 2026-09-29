import 'dart:async';

import 'package:chat_app/core/failures/app_failure.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:chat_app/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ChatCubit exposes streamed messages', () async {
    final repository = _FakeChatRepository();
    final cubit = ChatCubit(repository);

    repository.messages.add([
      ChatMessage(
        id: 'message-1',
        text: 'Hello',
        senderId: 'user-1',
        username: 'Ahmed',
        createdAt: DateTime(2026),
      ),
    ]);

    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.messages.single.text, 'Hello');

    await cubit.close();
    await repository.close();
  });

  test('ChatCubit exposes send failures', () async {
    final repository = _FakeChatRepository(
      sendFailure: const AppFailure(kind: FailureKind.network),
    );
    final cubit = ChatCubit(repository);

    await cubit.sendMessage('Hello');

    expect(cubit.state.isSending, isFalse);
    expect(cubit.state.failure?.kind, FailureKind.network);

    await cubit.close();
    await repository.close();
  });
}

final class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository({
    this.sendFailure,
  });

  final AppFailure? sendFailure;
  final messages = StreamController<List<ChatMessage>>();

  @override
  Future<void> sendMessage(String text) async {
    final failure = sendFailure;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages() => messages.stream;

  Future<void> close() => messages.close();
}
