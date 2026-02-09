import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:med_shakthi/src/core/providers/supabase_provider.dart';
import 'package:med_shakthi/src/features/chat_support/data/repositories/chat_repository.dart';
import 'package:med_shakthi/src/features/chat_support/data/models/chat_message.dart';

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final client = ref.watch(supabaseProvider);
  final repo = ChatRepository(client);
  return repo.streamMessages(chatId);
});
