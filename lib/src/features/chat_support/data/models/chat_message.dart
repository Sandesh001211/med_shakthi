/// Represents a single chat message
class ChatMessage {
  final String id;
  final String chatId;

  final String senderId;
  final String? senderRole; // 'user' | 'supplier' (optional for now)

  final String body;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderRole,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromRow(Map<String, dynamic> row) {
    return ChatMessage(
      id: row['id'],
      chatId: row['chat_id'],
      senderId: row['sender_id'],
      senderRole: row['sender_role'], // safe even if null
      body: row['body'],
      createdAt: DateTime.parse(row['created_at']),
    );
  }
}
