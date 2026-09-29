import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/failures/app_failure.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

final class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.failure,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final AppFailure? failure;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

final class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._repository) : super(const ChatState()) {
    _subscription = _repository.watchMessages().listen(
      _onMessages,
      onError: _onStreamError,
    );
  }

  final ChatRepository _repository;
  late final StreamSubscription<List<ChatMessage>> _subscription;

  Future<void> sendMessage(String text) async {
    if (state.isSending || text.trim().isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        isSending: true,
        clearFailure: true,
      ),
    );

    try {
      await _repository.sendMessage(text);
      emit(
        state.copyWith(
          isSending: false,
          clearFailure: true,
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          isSending: false,
          failure: failure,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSending: false,
          failure: AppFailure(
            kind: FailureKind.unknown,
            debugMessage: error.toString(),
          ),
        ),
      );
    }
  }

  void clearFailure() {
    if (state.failure != null) {
      emit(state.copyWith(clearFailure: true));
    }
  }

  void _onMessages(List<ChatMessage> messages) {
    emit(
      state.copyWith(
        messages: messages,
        isLoading: false,
        clearFailure: true,
      ),
    );
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    final failure = error is AppFailure
        ? error
        : AppFailure(
            kind: FailureKind.unknown,
            debugMessage: error.toString(),
          );

    emit(
      state.copyWith(
        isLoading: false,
        failure: failure,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
