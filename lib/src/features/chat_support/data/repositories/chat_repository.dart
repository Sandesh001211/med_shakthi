import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_summary.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final SupabaseClient _client;

  ChatRepository(this._client);

  // ===============================
  // Get existing chat by order
  // ===============================
  Future<ChatSummary?> getChatByOrderGroup(String orderGroupId) async {
    final row = await _client
        .from('chats')
        .select('id, order_id, supplier_id, last_message, last_message_at')
        .eq('order_id', orderGroupId)
        .maybeSingle();

    if (row == null) return null;

    return ChatSummary(
      chatId: row['id'],
      orderGroupId: row['order_id'],
      supplierId: row['supplier_id'],
      lastMessage: row['last_message'],
      lastMessageAt: row['last_message_at'] != null
          ? DateTime.parse(row['last_message_at'])
          : null,
    );
  }

  // ===============================
  // Create chat
  // ===============================
  Future<ChatSummary> createChat({
    required String orderGroupId,
    required String userId,
    required String supplierId,
  }) async {
    final row = await _client
        .from('chats')
        .insert({
          'order_id': orderGroupId,
          'user_id': userId,
          'supplier_id': supplierId,
        })
        .select('id, order_id, supplier_id, last_message, last_message_at')
        .single();

    return ChatSummary(
      chatId: row['id'],
      orderGroupId: row['order_id'],
      supplierId: row['supplier_id'],
      lastMessage: row['last_message'],
      lastMessageAt: row['last_message_at'] != null
          ? DateTime.parse(row['last_message_at'])
          : null,
    );
  }

  // ===============================
  // Fetch chat history for user
  // ===============================
  Future<List<ChatSummary>> fetchUserChats(String userId) async {
    final rows = await _client
        .from('chats')
        .select(
          'id, order_id, supplier_id, last_message, last_message_at',
        )
        .eq('user_id', userId)
        .order('last_message_at', ascending: false);

    return (rows as List)
        .map(
          (row) => ChatSummary(
            chatId: row['id'],
            orderGroupId: row['order_id'],
            supplierId: row['supplier_id'],
            lastMessage: row['last_message'],
            lastMessageAt: row['last_message_at'] != null
                ? DateTime.parse(row['last_message_at'])
                : null,
          ),
        )
        .toList();
  }

  // ===============================
  // Stream messages
  // ===============================
  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map(
          (rows) =>
              rows.map((r) => ChatMessage.fromRow(r)).toList(),
        );
  }

  // ===============================
  // Send message
  // ===============================
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String body,
    String? senderRole,
  }) async {
    final now = DateTime.now().toIso8601String();

    // 1️⃣ Insert message
    await _client.from('chat_messages').insert({
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'body': body,
      'created_at': now,
    });

    // 2️⃣ Update chat preview + ordering
    await _client.from('chats').update({
      'last_message': body,
      'last_message_at': now,
    }).eq('id', chatId);
  }
}
