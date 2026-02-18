import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Get or Create Chat for Specific Order-Supplier-User Triad ---
  Future<String> getOrCreateChat({
    required String orderId,
    required String supplierId,
    required String userId,
  }) async {
    try {
      // 1. Check if chat exists
      final existingChat = await _supabase
          .from('chats')
          .select('id')
          .eq('order_id', orderId)
          .eq('supplier_id', supplierId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingChat != null) {
        return existingChat['id'] as String;
      }

      // 2. Create new chat if not exists
      final newChat = await _supabase
          .from('chats')
          .insert({
            'order_id': orderId,
            'supplier_id': supplierId,
            'user_id': userId,
            'order_group_id': orderId, // Treating order_id as the group id
            'last_message': 'Chat started',
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return newChat['id'] as String;
    } catch (e) {
      debugPrint('Error getting/creating chat: $e');
      rethrow;
    }
  }

  // --- Send Message ---
  Future<void> sendMessage({
    required String chatId,
    required String message,
    required String senderId,
    String messageType = 'text',
    String? filePath,
  }) async {
    try {
      // 1. Insert message linked to chat_id
      await _supabase.from('chat_messages').insert({
        'chat_id': chatId,
        'sender_id': senderId,
        'message': message,
        'message_type': messageType,
        'file_path': filePath,
      });

      // 2. Update last message in chats table
      await _supabase
          .from('chats')
          .update({
            'last_message': message,
            'last_message_at': DateTime.now().toIso8601String(),
            'last_message_sender': senderId, // Useful for unread logic
          })
          .eq('id', chatId);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // --- Stream Messages ---
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);
  }
}
