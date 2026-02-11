import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:med_shakthi/src/features/chat_support/data/models/chat_summary.dart';
import 'package:med_shakthi/src/features/chat_support/data/repositories/chat_repository.dart';
import 'package:med_shakthi/src/features/chat_support/presentation/providers/supplier_id_provider.dart';



final supplierChatsProvider =
    StreamProvider.autoDispose<List<ChatSummary>>((ref) async* {
  final supplierId = await ref.watch(supplierIdProvider.future);

  if (supplierId == null) {
    yield [];
    return;
  }

  final repo = ref.watch(chatRepositoryProvider);

  yield* repo.streamSupplierChats(supplierId);
});
