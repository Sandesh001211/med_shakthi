import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:med_shakthi/src/features/chat_support/data/models/order_chat_candidate.dart';
import 'package:med_shakthi/src/features/chat_support/data/models/chat_summary.dart';
import 'chat_repository_provider.dart';
import 'package:med_shakthi/src/core/providers/supabase_provider.dart';

/// Get-or-create chat for a given order
final chatForOrderProvider =
    FutureProvider.family<ChatSummary, OrderChatCandidate>((ref, order) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  final supabase = ref.watch(supabaseProvider);

  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  // 1️⃣ Try existing chat
  final existingChat =
      await chatRepo.getChatByOrderGroup(order.orderGroupId);

  if (existingChat != null) {
    return ChatSummary(
     chatId: existingChat.chatId,
     orderGroupId: existingChat.orderGroupId,
     supplierId: existingChat.supplierId,
    lastMessage: existingChat.lastMessage,
    lastMessageAt: existingChat.lastMessageAt,
   );

  }

  // 2️⃣ Create chat if missing
  if (!order.canChat || order.supplierId == null) {
    throw Exception('Chat not allowed for this order');
  }

  final createdChat = await chatRepo.createChat(
    orderGroupId: order.orderGroupId,
    userId: user.id,
    supplierId: order.supplierId!,
  );

  return ChatSummary(
  chatId: createdChat.chatId,
  orderGroupId: createdChat.orderGroupId,
  supplierId: createdChat.supplierId,
  lastMessage: createdChat.lastMessage,
  lastMessageAt: createdChat.lastMessageAt,
  );
});
