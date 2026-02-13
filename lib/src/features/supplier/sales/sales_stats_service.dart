import 'package:supabase_flutter/supabase_flutter.dart';

class SalesStatsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches sales stats for the current supplier
  Future<Map<String, dynamic>> fetchSalesStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // 1. Get Supplier Code
      final supplierData = await _supabase
          .from('suppliers')
          .select('supplier_code')
          .eq('user_id', user.id)
          .maybeSingle();

      if (supplierData == null) throw Exception("Supplier not found");
      final String supplierCode = supplierData['supplier_code'];

      // 2. Fetch Orders for this supplier
      // Note: In a real app, you'd likely filter by 'created_at' for "Monthly" stats.
      // Here we fetch all-time for simplicity, or you can add .gte('created_at', firstDayOfMonth)
      final List<dynamic> orderDetails = await _supabase
          .from('order_details')
          .select('price, quantity, status, products!inner(supplier_code)')
          .eq('products.supplier_code', supplierCode);

      double totalRevenue = 0;
      int totalOrders = 0;
      int pendingOrders = 0;

      for (var item in orderDetails) {
        final double price = (item['price'] as num).toDouble();
        final int qty = (item['quantity'] as num).toInt();
        totalRevenue += price * qty;
        totalOrders++; // Counting items as orders for now, or distinct order_ids if needed

        if (item['status'] == 'Pending') {
          pendingOrders++;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'growth': 12.5, // Mock growth for now
      };
    } catch (e) {
      // Return zeros on error
      return {
        'totalRevenue': 0.0,
        'totalOrders': 0,
        'pendingOrders': 0,
        'growth': 0.0,
      };
    }
  }
}
