import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:med_shakthi/src/features/chat_support/data/repositories/chat_repository.dart';
import 'package:med_shakthi/src/core/providers/supabase_provider.dart';


final getOrCreateChatProvider =
    FutureProvider.family<String, ({String orderGroupId, String supplierId})>(
        (ref, args) async {
  final client = ref.watch(supabaseProvider);
  final repo = ChatRepository(client);

  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  // 1️⃣ Try existing chat
  final existing =
      await repo.getChatByOrderGroup(args.orderGroupId);

  if (existing != null) {
    return existing.chatId;
  }

  // 2️⃣ Create new chat
  final created = await repo.createChat(
    orderGroupId: args.orderGroupId,
    userId: user.id,
    supplierId: args.supplierId,
  );

  return created.chatId;
});
