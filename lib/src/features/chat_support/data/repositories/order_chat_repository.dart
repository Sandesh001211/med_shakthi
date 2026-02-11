import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:med_shakthi/src/features/chat_support/data/models/order_chat_candidate.dart';

class OrderChatRepository {
  final SupabaseClient _client;

  OrderChatRepository(this._client);

  /// Fetch orders from last 15 days and compute chat eligibility
  Future<List<OrderChatCandidate>> fetchRecentOrdersForChat() async {
    final user = _client.auth.currentSession?.user;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final sinceDate = DateTime.now().subtract(const Duration(days: 15));

    // ---- Fetch orders ----
    final orders = await _client
        .from('orders')
        .select()
        .eq('user_id', user.id)
        .gte('created_at', sinceDate.toIso8601String())
        .order('created_at', ascending: false);

    final List<OrderChatCandidate> results = [];

    for (final order in orders) {
      String? resolvedSupplierId;
      String? disableReason;

      // ---- Resolution step 1: supplier_id ----
      if (order['supplier_id'] != null) {
        resolvedSupplierId = order['supplier_id'];
      }

      // ---- Resolution step 2: supplier_code ----
      else if (order['supplier_code'] != null) {
        final supplier = await _client
            .from('suppliers')
            .select('id')
            .eq('supplier_code', order['supplier_code'])
            .maybeSingle();

        if (supplier != null) {
          resolvedSupplierId = supplier['id'];
        }
      }

      final canChat = resolvedSupplierId != null;

      if (!canChat) {
        disableReason = 'Supplier not yet assigned';
      }

      results.add(
        OrderChatCandidate(
          orderId: order['id'],
          orderGroupId: order['order_group_id'],
          createdAt: DateTime.parse(order['created_at']),
          supplierId: resolvedSupplierId,
          supplierCode: order['supplier_code'],
          canChat: canChat,
          disableReason: disableReason,
        ),
      );
    }

    return results;
  }
}
