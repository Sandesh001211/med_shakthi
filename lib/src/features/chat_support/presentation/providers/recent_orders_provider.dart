import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_shakthi/src/features/chat_support/data/repositories/order_chat_repository.dart';
import 'package:med_shakthi/src/core/providers/supabase_provider.dart';

final recentOrdersProvider =
    FutureProvider.autoDispose((ref) async {
  final client = ref.watch(supabaseProvider);
  final repository = OrderChatRepository(client);

  return repository.fetchRecentOrdersForChat();
});
