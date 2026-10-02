import '../../conversations/domain/entities/conversation.dart';

final class PushStatus {
  const PushStatus({
    this.available = false,
    this.enabled = false,
    this.busy = false,
    this.detail,
  });
  final bool available;
  final bool enabled;
  final bool busy;
  final String? detail;
}

final class NotificationTarget {
  const NotificationTarget(this.userId, this.conversationId, this.messageId);
  final String userId;
  final String conversationId;
  final String messageId;
}

abstract interface class PushRepository {
  PushStatus get status;
  Stream<PushStatus> watchStatus();
  Stream<NotificationTarget> watchOpens();
  void bindUser(String? userId);
  Future<void> refresh();
  Future<void> setEnabled(bool enabled);
  Future<ConversationSummary> resolveConversation(String conversationId);
  Future<void> close();
}
