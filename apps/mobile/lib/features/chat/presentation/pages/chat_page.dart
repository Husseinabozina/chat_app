import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/failures/app_failure.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../cubit/chat_cubit.dart';
import '../widgets/message_composer.dart';
import '../widgets/message_list.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({
    required this.authRepository,
    required this.chatRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final ChatRepository chatRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatCubit(chatRepository),
      child: _ChatView(authRepository: authRepository),
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView({required this.authRepository});

  final AuthRepository authRepository;

  Future<void> _signOut(BuildContext context) async {
    try {
      await authRepository.signOut();
    } on AppFailure {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = authRepository.currentUser?.id ?? '';

    return BlocListener<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure && current.failure != null,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_failureMessage(failure))));
        context.read<ChatCubit>().clearFailure();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Chat'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'logout') {
                  _signOut(context);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: MessageList(
                    messages: state.messages,
                    currentUserId: currentUserId,
                    isLoading: state.isLoading,
                  ),
                ),
                MessageComposer(
                  isSending: state.isSending,
                  onSend: context.read<ChatCubit>().sendMessage,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _failureMessage(AppFailure failure) {
    return switch (failure.kind) {
      FailureKind.unauthorized =>
        'Your session is no longer valid. Please sign in again.',
      FailureKind.validation =>
        'That message could not be sent. Please check it and retry.',
      FailureKind.conflict =>
        'That action conflicts with the current conversation state.',
      FailureKind.network =>
        'The network is unavailable. Please check your connection and retry.',
      FailureKind.unknown => 'Something went wrong. Please try again.',
    };
  }
}
