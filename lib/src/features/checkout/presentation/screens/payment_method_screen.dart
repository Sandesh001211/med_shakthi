// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:med_shakthi/src/core/utils/custom_snackbar.dart';
import 'order_success_screen.dart';

// import '../../../cart/cart_data.dart';
import '../../../cart/data/cart_data.dart';
import '../../../cart/data/cart_item.dart';
// import '../../../models/cart_item.dart';
import 'package:uuid/uuid.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final supabase = Supabase.instance.client;

  String selectedMethod = "MasterCard";
  bool _loading = false;
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _fetchingMethods = true;

  @override
  void initState() {
    super.initState();
    _fetchPaymentMethods();
  }

  Future<void> _fetchPaymentMethods() async {
    // Simulate API call to fetch payment methods
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _paymentMethods = [
          {"title": "MasterCard", "icon": Icons.credit_card},
          {"title": "PayPal", "icon": Icons.account_balance_wallet},
          {"title": "Visa", "icon": Icons.credit_score},
          {"title": "Apple Pay", "icon": Icons.apple},
        ];
        _fetchingMethods = false;
      });
    }
  }

  Widget paymentTile(String title, IconData icon) {
    const primaryColor = Color(0xFF5A9CA0);
    final isSelected = selectedMethod == title;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: RadioListTile<String>(
        value: title,
        groupValue: selectedMethod,
        onChanged: (value) {
          setState(() {
            selectedMethod = value!;
          });
        },
        activeColor: primaryColor,
        secondary: Icon(
          icon,
          size: 28,
          color: isSelected ? primaryColor : null,
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartData>();
    final user = supabase.auth.currentUser;

    if (user == null) {
      showCustomSnackBar(context, "User not logged in", isError: true);
      return;
    }

    if (cart.items.isEmpty) {
      showCustomSnackBar(context, "Cart is empty", isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      //  Order group id (same for all cart items)
      final orderGroupId = const Uuid().v4(); // string uuid

      //  Totals
      final subTotal = cart.subTotal;
      const shipping = 10;
      final total = subTotal + shipping;

      //  Full JSON order items (whole cart)
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

      //  Insert rows: 1 row per cart item
      final List<Map<String, dynamic>> rows = cart.items.map((CartItem item) {
        return {
          "user_id": user.id,

          // optional (if you have)
          "supplier_id": null,
          "supplier_code": null,

          //  group ID must be uuid (NOT NULL)
          "order_group_id": orderGroupId,

          //  required product data
          "product_id": item.id, // MUST be uuid string
          "item_name": item.title ?? item.name,
          "brand": item.brand,
          "unit_size": item.size,
          "image_url": item.imagePath ?? item.imageUrl,

          //  required order values
          "price": item.price,
          "quantity": item.quantity,
          "total_amount": total, // same total for whole order group
          //  status check constraint values
          "status": "pending",
          "payment_status": "pending",

          // optional
          "shipping": shipping,
          "order_items": orderItemsJson, // json column
        };
      }).toList();

      //  INSERT all at once
      await supabase.from("orders").insert(rows);
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartData>();

    const shipping = 10;
    final subTotal = cart.subTotal;
    final total = subTotal + shipping;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).appBarTheme.foregroundColor,
        ),
        title: Text(
          "Payment Method",
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_fetchingMethods)
                const Center(child: CircularProgressIndicator())
              else ...[
                ..._paymentMethods.map((method) {
                  return paymentTile(method["title"], method["icon"]);
                }).toList(),

                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: Icon(
                      Icons.add,
                      color: Theme.of(context).primaryColor,
                    ),
                    label: Text(
                      "Add New Card",
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Text(
                "Coupon Code / Voucher",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Enter your code here",
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A9CA0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    child: const Text("Apply"),
                  ),
                ],
              ),

              const Divider(height: 30),

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

              const Divider(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A9CA0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Next", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
