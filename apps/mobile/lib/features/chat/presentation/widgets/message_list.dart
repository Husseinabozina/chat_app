import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';
import 'message_bubble.dart';

class MessageList extends StatelessWidget {
  const MessageList({
    required this.messages,
    required this.currentUserId,
    required this.isLoading,
    super.key,
  });

  final List<ChatMessage> messages;
  final String currentUserId;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return const Center(child: Text('No messages yet.'));
    }

    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];

        return MessageBubble(
          key: ValueKey(message.id),
          imageUrl: message.imageUrl,
          message: message.text,
          isMine: currentUserId == message.senderId,
          username: message.username,
        );
      },
    );
  }
}
