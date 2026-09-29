final class ChatMessage {
  const ChatMessage({
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
}
