import '../entities/chat_message.dart';

abstract interface class ChatRepository {
  Stream<List<ChatMessage>> watchMessages();

  Future<void> sendMessage(String text);
}
