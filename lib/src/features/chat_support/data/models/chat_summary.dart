/// Lightweight representation of a chat used in list views
class ChatSummary {
  final String chatId;
  final String orderGroupId;
  final String supplierId;

  final String? lastMessage;
  final DateTime? lastMessageAt;

  ChatSummary({
    required this.chatId,
    required this.orderGroupId,
    required this.supplierId,
    this.lastMessage,
    this.lastMessageAt,
  });
}
