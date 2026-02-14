import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class SalesStatsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Stream controller for real-time updates
  final _statsController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Subscription references
  RealtimeChannel? _ordersSubscription;
  RealtimeChannel? _productsSubscription;
  RealtimeChannel? _inventorySubscription;
  
  /// Stream of real-time stats updates
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;
  
  /// Subscribe to real-time database changes
  Future<void> subscribeToRealtimeUpdates(String supplierCode, String supplierId) async {
    try {
      // Subscribe to orders table changes
      _ordersSubscription = _supabase
          .channel('orders_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'supplier_code',
              value: supplierCode,
            ),
            callback: (payload) async {
              print('📦 Order change detected: ${payload.eventType}');
              // Fetch fresh stats and emit to stream
              final stats = await fetchSalesStats();
              _statsController.add(stats);
            },
          )
          .subscribe();
      
      // Subscribe to products table changes
      _productsSubscription = _supabase
          .channel('products_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'products',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'supplier_code',
              value: supplierCode,
            ),
            callback: (payload) async {
              print('📦 Product change detected: ${payload.eventType}');
              final stats = await fetchSalesStats();
              _statsController.add(stats);
            },
          )
          .subscribe();
      
      // Subscribe to inventory table changes
      _inventorySubscription = _supabase
          .channel('inventory_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'inventory',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'supplier_id',
              value: supplierId,
            ),
            callback: (payload) async {
              print('📦 Inventory change detected: ${payload.eventType}');
              final stats = await fetchSalesStats();
              _statsController.add(stats);
            },
          )
          .subscribe();
          
      print('✅ Real-time subscriptions active for supplier: $supplierCode');
    } catch (e) {
      print('❌ Error subscribing to real-time updates: $e');
    }
  }
  
  /// Unsubscribe from real-time updates
  Future<void> unsubscribe() async {
    await _ordersSubscription?.unsubscribe();
    await _productsSubscription?.unsubscribe();
    await _inventorySubscription?.unsubscribe();
    print('🔌 Unsubscribed from real-time updates');
  }
  
  /// Dispose resources
  void dispose() {
    _statsController.close();
    unsubscribe();
  }

  /// Fetches comprehensive supplier dashboard stats from Supabase
  Future<Map<String, dynamic>> fetchSalesStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return _getEmptyStats();
      }

      // 1. Get Supplier Information
      final supplierData = await _supabase
          .from('suppliers')
          .select('supplier_code, id, name')
          .eq('user_id', user.id)
          .maybeSingle();

      if (supplierData == null) {
        print('❌ Supplier not found for user: ${user.id}');
        return _getEmptyStats();
      }
      
      final String? supplierCode = supplierData['supplier_code'];
      final String? supplierId = supplierData['id'];
      
      if (supplierCode == null || supplierCode.isEmpty) {
        print('❌ Supplier code is null or empty');
        return _getEmptyStats();
      }
      
      if (supplierId == null || supplierId.isEmpty) {
        print('❌ Supplier ID is null or empty');
        return _getEmptyStats();
      }
      
      print('✅ Fetching stats for supplier: $supplierCode');
      
      // 2. Define Date Ranges
      final now = DateTime.now();
      final firstDayThisMonth = DateTime(now.year, now.month, 1);
      final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
      final today = DateTime(now.year, now.month, now.day);
      
      // 3. Fetch Products Count and Inventory
      final productsResponse = await _supabase
          .from('products')
          .select('id, name, price, image_url, category')
          .eq('supplier_code', supplierCode);
      
      final List<dynamic> productsList = productsResponse as List<dynamic>;
      final int totalProducts = productsList.length;
      
      print('📦 Found $totalProducts products');
      
      // 4. Fetch Inventory Data
      final inventoryResponse = await _supabase
          .from('inventory')
          .select('product_id, stock_quantity')
          .eq('supplier_id', supplierId);
      
      final List<dynamic> inventoryList = inventoryResponse as List<dynamic>;
      int lowStockCount = 0;
      int outOfStockCount = 0;
      int totalStock = 0;
      
      for (var inv in inventoryList) {
        final int stock = (inv['stock_quantity'] as num?)?.toInt() ?? 0;
        totalStock += stock;
        if (stock == 0) {
          outOfStockCount++;
        } else if (stock < 10) {
          lowStockCount++;
        }
      }
      
      // 5. Fetch Orders Data
      final ordersResponse = await _supabase
          .from('orders')
          .select('id, user_id, total_amount, status, created_at, product_id, quantity, price')
          .eq('supplier_code', supplierCode);

      final List<dynamic> ordersList = ordersResponse as List<dynamic>;

      double totalRevenue = 0;
      double thisMonthRevenue = 0;
      double lastMonthRevenue = 0;
      double todayRevenue = 0;
      int pendingOrders = 0;
      int confirmedOrders = 0;
      int shippedOrders = 0;
      int deliveredOrders = 0;
      int totalOrdersCount = ordersList.length;
      final Set<String> uniqueClients = {};
      final Map<String, int> productSales = {};

      for (var order in ordersList) {
        final double amount = (order['total_amount'] as num?)?.toDouble() ?? 
                             ((order['price'] as num?)?.toDouble() ?? 0.0) * 
                             ((order['quantity'] as num?)?.toInt() ?? 0);
        final String status = (order['status'] ?? 'pending').toString().toLowerCase();
        final DateTime createdAt = DateTime.parse(order['created_at']);
        final String userId = order['user_id'] ?? '';
        final String productId = order['product_id'] ?? '';
        
        totalRevenue += amount;
        if (userId.isNotEmpty) uniqueClients.add(userId);

        // Track product sales
        if (productId.isNotEmpty) {
          productSales[productId] = (productSales[productId] ?? 0) + 1;
        }

        // Status tracking
        switch (status) {
          case 'pending':
            pendingOrders++;
            break;
          case 'confirmed':
            confirmedOrders++;
            break;
          case 'shipped':
            shippedOrders++;
            break;
          case 'delivered':
            deliveredOrders++;
            break;
        }

        // Revenue by time period
        if (createdAt.isAfter(today)) {
          todayRevenue += amount;
        }
        
        if (createdAt.isAfter(firstDayThisMonth)) {
          thisMonthRevenue += amount;
        } else if (createdAt.isAfter(firstDayLastMonth) && createdAt.isBefore(firstDayThisMonth)) {
          lastMonthRevenue += amount;
        }
      }

      // 6. Calculate Growth Percentage
      double growth = 0;
      if (lastMonthRevenue > 0) {
        growth = ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100;
      } else if (thisMonthRevenue > 0) {
        growth = 100.0;
      }

      // 7. Calculate Average Order Value
      double avgOrderValue = totalOrdersCount > 0 ? totalRevenue / totalOrdersCount : 0;

      // 8. Monthly Payout (92% after platform fees)
      double monthlyPayout = thisMonthRevenue * 0.92;

      // 9. Find top selling products
      List<Map<String, dynamic>> topProducts = [];
      if (productSales.isNotEmpty) {
        final sortedProducts = productSales.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        for (var entry in sortedProducts.take(3)) {
          final product = productsList.firstWhere(
            (p) => p['id'] == entry.key,
            orElse: () => null,
          );
          if (product != null) {
            topProducts.add({
              'id': product['id'],
              'name': product['name'],
              'sales': entry.value,
              'image': product['image_url'],
              'price': product['price'],
            });
          }
        }
      }

      return {
        // Revenue Metrics
        'totalRevenue': totalRevenue,
        'thisMonthRevenue': thisMonthRevenue,
        'todayRevenue': todayRevenue,
        'growth': growth,
        'monthlyPayout': monthlyPayout,
        'avgOrderValue': avgOrderValue,
        
        // Order Metrics
        'totalOrders': totalOrdersCount,
        'pendingOrders': pendingOrders,
        'confirmedOrders': confirmedOrders,
        'shippedOrders': shippedOrders,
        'deliveredOrders': deliveredOrders,
        
        // Customer Metrics
        'totalClients': uniqueClients.length,
        
        // Product & Inventory Metrics
        'totalProducts': totalProducts,
        'totalStock': totalStock,
        'lowStockCount': lowStockCount,
        'outOfStockCount': outOfStockCount,
        'topProducts': topProducts,
        
        // Metadata
        'updatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print("Error in fetchSalesStats: $e");
      return _getEmptyStats();
    }
  }

  Map<String, dynamic> _getEmptyStats() {
    return {
      'totalRevenue': 0.0,
      'thisMonthRevenue': 0.0,
      'todayRevenue': 0.0,
      'growth': 0.0,
      'pendingOrders': 0,
      'confirmedOrders': 0,
      'shippedOrders': 0,
      'deliveredOrders': 0,
      'totalOrders': 0,
      'totalClients': 0,
      'monthlyPayout': 0.0,
      'avgOrderValue': 0.0,
      'totalProducts': 0,
      'totalStock': 0,
      'lowStockCount': 0,
      'outOfStockCount': 0,
      'topProducts': [],
    };
  }
}
