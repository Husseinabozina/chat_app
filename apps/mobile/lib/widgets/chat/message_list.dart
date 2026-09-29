import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'message_bubble.dart';

class MessageList extends StatelessWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, chatSnapshot) {
        if (chatSnapshot.hasError) {
          return const Center(
            child: Text('Unable to load messages.'),
          );
        }

        if (!chatSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final chatDocuments = chatSnapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          itemCount: chatDocuments.length,
          itemBuilder: (context, index) {
            final document = chatDocuments[index];
            final data = document.data();

            return MessageBubble(
              key: ValueKey(document.id),
              imageUrl: data['userImage'] as String?,
              message: data['text'] as String? ?? '',
              isMine: currentUser.uid == data['userid'],
              username: data['username'] as String? ?? 'Unknown user',
            );
          },
        );
      },
    );
  }
}
