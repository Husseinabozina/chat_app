import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat_message.dart';

final class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.username,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String text;
  final String senderId;
  final String username;
  final String? imageUrl;
  final DateTime createdAt;

  factory ChatMessageModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final timestamp = data['createdAt'];

    return ChatMessageModel(
      id: document.id,
      text: data['text'] is String ? data['text'] as String : '',
      senderId: data['userid'] is String ? data['userid'] as String : '',
      username: data['username'] is String
          ? data['username'] as String
          : 'Unknown user',
      imageUrl: data['userImage'] is String
          ? data['userImage'] as String
          : null,
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      text: text,
      senderId: senderId,
      username: username,
      imageUrl: imageUrl,
      createdAt: createdAt,
    );
  }
}
