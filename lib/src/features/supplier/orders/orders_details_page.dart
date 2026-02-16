import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = true;
  Map<String, dynamic>? order;

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    try {
      final response = await supabase
          .from('orders')
          .select('''
            *,
            order_details (*)
          ''')
          .eq('id', widget.orderId)
          .single();

      if (mounted) {
        setState(() {
          order = response;
          isLoading = false;
        });
      }
    } on PostgrestException catch (e) {
      debugPrint("Supabase error: ${e.message}");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading order: ${e.message}")),
        );
      }
    } catch (e) {
      debugPrint("Error fetching order details: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading order: $e")));
      }
    }
  }

  Future<void> updateOrderStatus(String newStatus) async {
    try {
      // Optimistic update
      setState(() {
        order!['status'] = newStatus;
      });

      await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', widget.orderId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Order marked as $newStatus")));
        Navigator.pop(context, true); // Return true to refresh parent list
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
      // Revert optimistic update
      fetchOrderDetails();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error updating status: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Order Details")),
        body: const Center(child: Text("Order not found")),
      );
    }

    final createdAt = DateTime.parse(order!['created_at']);
    final formattedDate = DateFormat('dd MMM yyyy').format(createdAt);
    final status = order!['status'] ?? 'Unknown';
    final items = order!['order_details'] as List<dynamic>;

    // Assumption: Buyer address is stored in shipping_address column in orders table
    // If not, we might need to fetch it from 'profiles' table if we have buyer_id
    // For now, using a safe fallback
    final address = order!['shipping_address'] ?? 'Address not available';
    final buyerName = order!['buyer_name'] ?? 'Unknown Buyer';
    final phone =
        order!['buyer_phone'] ??
        'Phone not available'; // Assuming this field exist

    return Scaffold(
      appBar: AppBar(title: const Text("Order Details"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shipping Address Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 20,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    address,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 📦 Order Summary
            _sectionTitle("Order Summary"),
            _infoRow(
              "Order ID",
              order!['order_number'] ?? widget.orderId.substring(0, 8),
            ),
            _infoRow("Order Date", formattedDate),
            _infoRow("Status", status),
            _infoRow(
              "Payment",
              "Credit (30 Days)",
            ), // Placeholder till we have payment info
            const SizedBox(height: 20),

            // 🏥 Pharmacy Details
            _sectionTitle("Pharmacy Details"),
            _infoRow("Pharmacy Name", buyerName),
            _infoRow("Contact", phone),
            const SizedBox(height: 20),

            // 💊 Items Ordered
            _sectionTitle("Items Ordered"),
            ...items.map((item) {
              // Use data directly from order_details (no products join needed)
              return _medicineItem(
                name: item['item_name'] ?? 'Unknown Product',
                batch: item['brand'] ?? 'N/A',
                expiry: 'N/A', // Not stored in order_details
                qty: "${item['quantity']} ${item['unit_size'] ?? 'units'}",
                price: "₹${item['price']}",
              );
            }),
            const SizedBox(height: 20),

            // 💰 Billing Summary
            _sectionTitle("Billing Summary"),
            _infoRow("Subtotal", "₹${order!['total_amount']}"),
            // Assuming tax is included or calculated. For simplest view, showing total.
            // _infoRow("GST (12%)", "₹147"),
            _infoRow("Total Amount", "₹${order!['total_amount']}"),
            const SizedBox(height: 30),

            // 🚚 Actions
            if (status == 'Pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        updateOrderStatus("Cancelled"), // Rejecting = Cancelled
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text("Reject"),
                  ),
                  ElevatedButton(
                    onPressed: () => updateOrderStatus("Accepted"),
                    child: const Text("Accept Order"),
                  ),
                ],
              )
            else if (status == 'Accepted')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => updateOrderStatus("Dispatched"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text("Mark as Dispatched"),
                ),
              )
            else if (status == 'Dispatched')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      () {}, // Maybe Mark Delivered is manual or by buyer?
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text("Order Dispatched"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- Widgets ----------

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicineItem({
    required String name,
    required String batch,
    required String expiry,
    required String qty,
    required String price,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Batch/SKU: $batch"),
            Text("Expiry: $expiry"),
            Text("Quantity: $qty"),
            Text("Price: $price"),
          ],
        ),
      ),
    );
  }
}
