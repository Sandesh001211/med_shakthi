import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../../../cart/data/cart_data.dart';
import '../../../cart/data/cart_item.dart';

class SupplierWishlistPage extends StatefulWidget {
  const SupplierWishlistPage({super.key});

  @override
  State<SupplierWishlistPage> createState() => _SupplierWishlistPageState();
}

class _SupplierWishlistPageState extends State<SupplierWishlistPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _wishlistFuture = _fetchWishlist();
  }

  // 🔹 FETCH WISHLIST FROM DB
  Future<List<Map<String, dynamic>>> _fetchWishlist() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      // 🔹 Get supplier id from suppliers table
      final supplierRes = await supabase
          .from('suppliers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (supplierRes == null) {
        debugPrint(" Supplier not found for user");
        return [];
      }

      final supplierId = supplierRes['id'];

      // 🔹 Fetch wishlist
      final res = await supabase
          .from('supplier_wishlist')
          .select()
          .eq('supplier_id', supplierId)
          .order('created_at', ascending: false);

      debugPrint(" Wishlist data: $res");

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint(" Wishlist fetch error: $e");
      return [];
    }
  }

  // 🔹 REMOVE ITEM
  Future<void> _removeWishlist(String id) async {
    await supabase.from('supplier_wishlist').delete().eq('id', id);

    setState(() {
      _wishlistFuture = _fetchWishlist();
    });
  }

  // 🔹 ADD TO CART
  void _addToCart(BuildContext context, Map<String, dynamic> item) {
    final cart = context.read<CartData>();

    cart.addItem(
      CartItem(
        id: item['product_id'],
        name: item['product_name'],
        price: (item['price'] as num).toDouble(),
        imagePath: item['image_url'],
        quantity: 1,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added to cart")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "Wishlist",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _wishlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _emptyState();
          }

          final wishlist = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wishlist.length,
            itemBuilder: (context, index) {
              return _wishlistCard(context, wishlist[index]);
            },
          );
        },
      ),
    );
  }

  // 🔹 EMPTY STATE
  Widget _emptyState() {
    return const Center(
      child: Text(
        "No items in wishlist",
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  // 🔹 WISHLIST CARD
  Widget _wishlistCard(BuildContext context, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // IMAGE
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: item['image_url'] != null && item['image_url'] != ''
                ? Image.network(item['image_url'], fit: BoxFit.contain)
                : const Icon(Icons.medical_services,
                size: 36, color: Color(0xFF4CA6A8)),
          ),

          const SizedBox(width: 14),

          // INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'] ?? '',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  "Category: ${item['category'] ?? '-'}",
                  style:
                  const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${item['price']}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CA6A8),
                  ),
                ),
              ],
            ),
          ),

          // ACTIONS
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                color: const Color(0xFF4CA6A8),
                onPressed: () => _addToCart(context, item),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.redAccent,
                onPressed: () => _removeWishlist(item['id']),
              ),
            ],
          )
        ],
      ),
    );
  }
}
