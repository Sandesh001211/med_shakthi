import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:med_shakthi/src/features/chat_support/data/repositories/chat_repository.dart';
import 'package:med_shakthi/src/core/providers/supabase_provider.dart';

/// Provides ChatRepository instance
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final SupabaseClient client = ref.watch(supabaseProvider);
  return ChatRepository(client);
});
