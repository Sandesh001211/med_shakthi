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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // CRITICAL: Get supplier.id (not supplier_code!)
      // We need suppliers.id to match with order_details.supplier_id
      final supplierData = await _supabase
          .from('suppliers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (supplierData == null) {
        debugPrint("No supplier found for user");
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final String supplierId = supplierData['id'];

      // 2. Fetch Order Details for this supplier
      // Filter directly by supplier_id in order_details
      // AND filter by order status (status is in orders table, not order_details)
      final response = await _supabase
          .from('order_details')
          .select('''
            *,
            products!inner(name, image_url, supplier_code),
            orders!inner(
              id,
              order_group_id,
              shipping_address,
              created_at,
              user_id,
              status
            )
          ''')
          .eq('supplier_id', supplierId)
          .eq('orders.status', widget.status.toLowerCase())
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } on PostgrestException catch (e) {
      debugPrint("Supabase error fetching orders: ${e.message}");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(e.code, e.message);
        });
      }
    } catch (e) {
      debugPrint("Error fetching supplier orders: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Unable to load orders. Please check your internet connection.";
        });
      }
    }
  }

  Future<void> _updateStatus(
    String orderId,
    String newStatus, {
    String? reason,
  }) async {
    // orderId refers to the parent 'orders.id' (from parentOrder['id'])
    // Status is stored in the 'orders' table, not 'order_details'

    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus.toLowerCase()})
          .eq('id', orderId);

      _fetchOrders(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Order marked as $newStatus')));
      }
    } on PostgrestException catch (e) {
      debugPrint("Supabase error updating order: ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.code, e.message)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating order status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update order. Please try again."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getErrorMessage(String? code, String message) {
    switch (code) {
      case '42P01': // Undefined table
        return "Configuration error. Please contact support.";
      case '42703': // Undefined column
        return "Data structure error. Please contact support.";
      case 'PGRST116': // No rows returned
        return "Order not found.";
      case '23503': // Foreign key violation
        return "Cannot update order. Related data missing.";
      default:
        if (message.contains('JWT')) {
          return "Session expired. Please log in again.";
        } else if (message.contains('permission')) {
          return "You don't have permission to perform this action.";
        }
        return 'An error occurred: ${message.length > 50 ? message.substring(0, 50) : message}...';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _fetchOrders();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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
        final product = order['products'] as Map<String, dynamic>?;
        final parentOrder = order['orders'] as Map<String, dynamic>?;
        final qty = order['quantity'] ?? 0;
        final price = (order['price'] as num?)?.toDouble() ?? 0.0;

        // Null safety checks
        if (product == null || parentOrder == null) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Error: Missing order data",
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          );
        }

        final productName = product['name'] ?? 'Unknown Product';
        final imageUrl = product['image_url'] ?? '';
        final shippingAddress = parentOrder['shipping_address'] ?? 'No address';
        final orderId = parentOrder['id'] ?? 'Unknown';

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
                        imageUrl,
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
                            productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Qty: $qty • ₹$price"),
                          const SizedBox(height: 12),
                          Text(
                            "Order #${orderId.toString().substring(0, 8)}",
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  shippingAddress,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                            _showRejectDialog(context, parentOrder['id']),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text("Reject"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () =>
                            _updateStatus(parentOrder['id'], "Accepted"),
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
                      onPressed: () =>
                          _updateStatus(parentOrder['id'], "Dispatched"),
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
