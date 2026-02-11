import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';

class ChatMessageRepository {
  final SupabaseClient _client;

  ChatMessageRepository(this._client);

  /// Realtime stream of messages for a chat
  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map(
          (rows) => rows
              .map(
                (row) => ChatMessage(
                  id: row['id'],
                  chatId: row['chat_id'],
                  senderId: row['sender_id'],
                  senderRole: row['sender_role'],
                  content: row['content'],
                  createdAt: DateTime.parse(row['created_at']),
                ),
              )
              .toList(),
        );
  }

  /// Send a message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderRole,
    required String content,
  }) async {
    await _client.from('chat_messages').insert({
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'content': content,
    });

    // Update chat metadata
    await _client
        .from('chats')
        .update({'last_message_at': DateTime.now().toIso8601String()})
        .eq('id', chatId);
  }
}
