import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_shakthi/src/core/providers/supabase_provider.dart';

final supplierIdProvider = FutureProvider<String?>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = supabase.auth.currentUser;

  if (user == null) return null;

  final data = await supabase
      .from('suppliers')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle();

  return data?['id'] as String?;
});
