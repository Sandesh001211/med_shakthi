import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:med_shakthi/src/features/chat_support/data/repositories/chat_repository.dart';
import 'package:med_shakthi/src/features/chat_support/data/models/chat_summary.dart';
import 'package:med_shakthi/src/core/providers/supabase_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return ChatRepository(client);
});

final userChatsProvider = FutureProvider.autoDispose<List<ChatSummary>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null) return [];

  final repo = ref.watch(chatRepositoryProvider);
  return repo.fetchUserChats(user.id);
});
