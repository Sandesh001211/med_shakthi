import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupplierOrdersPage extends StatefulWidget {
  const SupplierOrdersPage({super.key});

  @override
  State<SupplierOrdersPage> createState() => _SupplierOrdersPageState();
}

class _SupplierOrdersPageState extends State<SupplierOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Orders"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Accepted"),
            Tab(text: "Dispatched"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SupplierOrderList(status: "Pending"),
          SupplierOrderList(status: "Accepted"),
          SupplierOrderList(status: "Dispatched"),
          SupplierOrderList(status: "Cancelled"), // Or Rejected
        ],
      ),
    );
  }
}

class SupplierOrderList extends StatefulWidget {
  final String status;
  const SupplierOrderList({super.key, required this.status});

  @override
  State<SupplierOrderList> createState() => _SupplierOrderListState();
}

class _SupplierOrderListState extends State<SupplierOrderList> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Get Supplier Code
      final supplierData = await _supabase
          .from('suppliers')
          .select('supplier_code')
          .eq('user_id', user.id)
          .maybeSingle();

      if (supplierData == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final String supplierCode = supplierData['supplier_code'];

      // 2. Fetch Order Details for this supplier
      // We need to join with 'products' to filter by supplier_code
      final response = await _supabase
          .from('order_details')
          .select(
            '*, products!inner(name, image_url, supplier_code), orders!inner(id, order_group_id, address_id, created_at, user_id)',
          )
          .eq('products.supplier_code', supplierCode)
          .eq('status', widget.status)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching supplier orders: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(
    String orderId,
    String newStatus, {
    String? reason,
  }) async {
    // Note: orderId here refers to the 'id' of the 'order_details' row, NOT the parent 'orders' table
    // because suppliers manage specific items, not the entire order group (usually).

    try {
      await _supabase
          .from('order_details')
          .update({
            'status': newStatus,
            if (reason != null)
              'cancellation_reason': reason, // Assuming column exists
          })
          .eq('id', orderId);

      _fetchOrders(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Order marked as $newStatus")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error updating status: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No ${widget.status} orders",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final product = order['products'];
        final parentOrder = order['orders'];
        final qty = order['quantity'];
        final price = order['price'];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product['image_url'] ?? '',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? 'Product',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Qty: $qty • ₹$price"),
                          Text(
                            "Order ID: #${parentOrder['order_group_id']?.toString().substring(0, 8) ?? 'N/A'}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (widget.status == "Pending")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () =>
                            _showRejectDialog(context, order['id']),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text("Reject"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _updateStatus(order['id'], "Accepted"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CA6A8),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Accept"),
                      ),
                    ],
                  ),
                if (widget.status == "Accepted")
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(order['id'], "Dispatched"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Dispatch Order"),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, String orderId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Order"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "Reason for rejection"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(
                orderId,
                "Cancelled",
                reason: reasonController.text,
              );
            },
            child: const Text("Reject", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
