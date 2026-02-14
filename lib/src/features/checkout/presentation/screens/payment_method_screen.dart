// ignore_for_file: deprecated_member_use, no_leading_underscores_for_local_identifiers
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:med_shakthi/src/core/utils/custom_snackbar.dart';
import 'order_success_screen.dart';
import 'package:med_shakthi/src/features/checkout/presentation/screens/payment_method_store.dart';
import 'package:med_shakthi/src/features/checkout/presentation/widgets/add_payment_method_sheet.dart';
import '../../../cart/data/cart_data.dart';
import '../../../cart/data/cart_item.dart';
import 'package:med_shakthi/src/features/checkout/data/models/payment_method_model.dart';
import 'package:uuid/uuid.dart';
import 'package:med_shakthi/src/features/checkout/data/models/address_model.dart';

class PaymentMethodScreen extends StatefulWidget {
  final bool isCheckout;
  final AddressModel? deliveryAddress;
  const PaymentMethodScreen({
    super.key,
    this.isCheckout = true,
    this.deliveryAddress,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final supabase = Supabase.instance.client;
  bool _placingOrder = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<PaymentMethodStore>().fetchPaymentMethods();
    });
  }

  void _showAddMethodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddPaymentMethodSheet(),
    );
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartData>();
    final user = supabase.auth.currentUser;
    final paymentStore = context.read<PaymentMethodStore>();

    if (user == null) {
      showCustomSnackBar(context, "User not logged in", isError: true);
      return;
    }

    if (cart.items.isEmpty) {
      showCustomSnackBar(context, "Cart is empty", isError: true);
      return;
    }

    // Allow proceeding without selecting a saved method? Maybe default to COD?
    // Requirement says "Replacing static ... with dynamic".
    // For now, require a selection if the list is not empty, OR just assume "Cash on Delivery" or similar if nothing selected.
    // Let's enforce selection if store has methods, or provide a default "Cash / Pay on Arrival" option.

    // For simplicity, let's assume they MUST select one of their saved methods.
    if (paymentStore.selectedMethodId == null &&
        paymentStore.paymentMethods.isNotEmpty) {
      showCustomSnackBar(
        context,
        "Please select a payment method",
        isError: true,
      );
      return;
    }

    setState(() => _placingOrder = true);

    try {
      final orderGroupId = const Uuid().v4();
      final subTotal = cart.subTotal;
      const shipping = 10;
      final total = subTotal + shipping;

      final orderItemsJson = cart.items.map((CartItem item) {
        return {
          "product_id": item.id,
          "item_name": item.title ?? item.name,
          "brand": item.brand ?? "",
          "unit_size": item.size ?? "",
          "image_url": item.imagePath ?? item.imageUrl ?? "",
          "price": item.price,
          "quantity": item.quantity,
        };
      }).toList();

      // Format delivery address
      final String deliveryAddressText = widget.deliveryAddress != null
          ? widget.deliveryAddress!.fullAddress
          : 'No address provided';

      final List<Map<String, dynamic>> rows = cart.items.map((CartItem item) {
        return {
          "user_id": user.id,
          "order_group_id": orderGroupId,
          "product_id": item.id,
          "item_name": item.title ?? item.name,
          "brand": item.brand,
          "unit_size": item.size,
          "image_url": item.imagePath ?? item.imageUrl,
          "price": item.price,
          "quantity": item.quantity,
          "total_amount": total,
          "status": "pending",
          "payment_status": "pending",
          // Store selected payment method ID/Info
          "payment_method_id": paymentStore.selectedMethodId,
          "shipping": shipping,
          "shipping_address": deliveryAddressText,
          "order_items": orderItemsJson,
        };
      }).toList();

      // Insert into orders table and get back the inserted rows with IDs
      final insertedOrders = await supabase
          .from("orders")
          .insert(rows)
          .select();

      // Now insert into order_details table using the order IDs from inserted orders
      final List<Map<String, dynamic>> orderDetailRows = [];
      for (int i = 0; i < insertedOrders.length; i++) {
        final orderId = insertedOrders[i]['id'];
        final item = cart.items[i];

        orderDetailRows.add({
          "order_id": orderId,
          "product_id": item.id,
          "item_name": item.title ?? item.name,
          "brand": item.brand ?? "",
          "unit_size": item.size ?? "",
          "image_url": item.imagePath ?? item.imageUrl ?? "",
          "price": item.price,
          "quantity": item.quantity,
        });
      }

      // Insert into order_details table
      await supabase.from("order_details").insert(orderDetailRows);

      if (!mounted) return;
      showCustomSnackBar(context, "Order Placed Successfully");

      cart.clearCart();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
      );
    } catch (e) {
      showCustomSnackBar(context, "Order failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  IconData _getIconForType(String type, Map<String, dynamic> details) {
    if (type == 'upi') {
      final provider = details['provider'];
      if (provider == 'google_pay') {
        return Icons.g_mobiledata;
      }
      if (provider == 'phonepe') {
        return Icons.payments;
      }
      if (provider == 'paytm') {
        return Icons.account_balance_wallet;
      }
      return Icons.qr_code_2;
    }
    switch (type) {
      case 'bank_transfer':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      case 'paypal':
        return Icons.paypal; // Or Icons.payment if paypal not available
      default:
        return Icons.payment;
    }
  }

  String _getSubtitle(PaymentMethodModel method) {
    switch (method.type) {
      case 'upi':
        return "${(method.details['provider'] as String?)?.replaceAll('_', ' ').toUpperCase() ?? 'UPI'}: ${method.details['upi_id'] ?? ''}";
      case 'card':
        if (method.details['card_number_masked'] != null) {
          return "${method.details['card_type'] ?? 'Card'} ending ${method.details['card_number_masked'].toString().split('-').last}";
        }
        return "Card ending **${method.details['card_last4'] ?? ''}";
      case 'bank_transfer':
        return "Acc: ${method.details['account_no'] ?? ''}";
      case 'paypal':
        return "Email: ${method.details['email'] ?? ''}";
      default:
        return method.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartData>();
    final store = context.watch<PaymentMethodStore>();

    const shipping = 10;
    final subTotal = cart.subTotal;
    final total = subTotal + shipping;

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("Payment Method")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Delivery Address Summary
              if (widget.deliveryAddress != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.teal.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.teal,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delivery Address',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.deliveryAddress!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.deliveryAddress!.fullAddress,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      if (widget.deliveryAddress!.remarks != null &&
                          widget.deliveryAddress!.remarks!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Note: ${widget.deliveryAddress!.remarks}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Your Payment Methods",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _showAddMethodSheet,
                    icon: const Icon(Icons.add),
                    label: const Text("Add New"),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (store.loading)
                const Center(child: CircularProgressIndicator())
              else if (store.paymentMethods.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.payment_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "No payment methods saved",
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: _showAddMethodSheet,
                        child: const Text("Add One Now"),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: store.paymentMethods.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final method = store.paymentMethods[i];
                    final isSelected = store.selectedMethodId == method.id;

                    return Dismissible(
                      key: Key(method.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        store.deletePaymentMethod(method.id);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.teal
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: RadioListTile<String>(
                          value: method.id,
                          groupValue: store.selectedMethodId,
                          activeColor: Colors.teal,
                          onChanged: (val) {
                            if (val != null) store.selectMethod(val);
                          },
                          secondary: Icon(
                            _getIconForType(method.type, method.details),
                            color: isSelected ? Colors.teal : Colors.grey,
                          ),
                          title: Text(
                            method.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getSubtitle(method),
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (method.type == 'card' &&
                                  method.details.containsKey('expiry'))
                                Text(
                                  "Expires: ${method.details['expiry']}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              if (widget.isCheckout) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                const Text(
                  "Billing Summary",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal"),
                    Text("₹${subTotal.toStringAsFixed(2)}"),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text("Shipping & Tax"), Text("₹$shipping")],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "₹${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _placingOrder ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _placingOrder
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "PLACE ORDER",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
