import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:med_shakthi/src/features/chat_support/data/repositories/chat_repository.dart';
import 'package:med_shakthi/src/core/providers/supabase_provider.dart';

final chatHistoryProvider =
    FutureProvider.autoDispose((ref) async {
  final client = ref.watch(supabaseProvider);
  final user = client.auth.currentUser;

  if (user == null) {
    throw Exception('User not authenticated');
  }

  final repo = ChatRepository(client);
  return repo.fetchUserChats(user.id);
});
