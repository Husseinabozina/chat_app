import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.isMine,
    required this.username,
    this.imageUrl,
    super.key,
  });

  final String message;
  final bool isMine;
  final String username;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final avatarImage = imageUrl == null || imageUrl!.isEmpty
        ? null
        : NetworkImage(imageUrl!);

    final bubble = Flexible(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.grey.shade300
              : Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
      ),
    );

    final avatar = CircleAvatar(
      radius: 18,
      backgroundImage: avatarImage,
      child: avatarImage == null
          ? Text(
              username.isEmpty ? '?' : username.substring(0, 1).toUpperCase(),
            )
          : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMine ? [bubble, avatar] : [avatar, bubble],
      ),
    );
  }
}
