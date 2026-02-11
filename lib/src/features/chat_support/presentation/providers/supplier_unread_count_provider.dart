import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:med_shakthi/src/features/chat_support/data/repositories/chat_repository.dart';
import 'package:med_shakthi/src/features/chat_support/presentation/providers/supplier_id_provider.dart';



final supplierUnreadCountProvider =
    FutureProvider.family<int, String>((ref, chatId) async {
  final supplierId = await ref.watch(supplierIdProvider.future);

  if (supplierId == null) return 0;

  final repo = ref.watch(chatRepositoryProvider);

  return repo.getUnreadCountForSupplier(
    chatId: chatId,
    supplierId: supplierId,
  );
});
