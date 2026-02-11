import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:med_shakthi/src/core/providers/supabase_provider.dart';
import 'package:med_shakthi/src/features/chat_support/data/repositories/chat_repository.dart';

/// Usage example:
/// await ref.read(sendMessageProvider).sendMessage(
///   chatId: chatId,
///   senderId: user.id,
///   senderRole: 'user',
///   body: message,
/// );
final sendMessageProvider = Provider((ref) {
  final client = ref.watch(supabaseProvider);
  return ChatRepository(client);
});
