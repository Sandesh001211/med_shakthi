import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Removed unused import: supabase_flutter.dart
import '../../data/wishlist_service.dart';
import '../../data/models/wishlist_item_model.dart';
import '../../../cart/data/cart_data.dart';
import '../../../cart/data/cart_item.dart';
import '../../../products/presentation/screens/product_page.dart';
import '../../../products/data/models/product_model.dart';
import 'package:med_shakthi/src/core/utils/smart_product_image.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<WishlistService>(
        builder: (context, wishlistService, child) {
          final items = wishlistService.wishlist;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Your wishlist is empty",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text("Save items you want to buy later!"),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<WishlistService>().fetchWishlist(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C8077),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Refresh Wishlist"),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Modern App Bar
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                elevation: 0,
                centerTitle: true,
                title: const Text(
                  "My Wishlist",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                // No leading back button as this is a primary tab
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = items[index];
                    return _WishlistCard(item: item, index: index);
                  }, childCount: items.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final WishlistItem item;
  final int index;

  const _WishlistCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final product = Product(
                id: item.id,
                name: item.name,
                price: item.price,
                image: item.image,
                category: "General",
                rating: 0.0,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductPage(product: product),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 80,
                      width: 80,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[50],
                      child: SmartProductImage(
                        imageUrl: item.image,
                        category: item.name,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${item.price.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4C8077),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          context.read<WishlistService>().removeFromWishlist(
                            item.id,
                          );
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        tooltip: "Remove",
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () {
                          final cartItem = CartItem(
                            id: item.id,
                            name: item.name,
                            title: item.name,
                            brand: "General",
                            size: "Standard",
                            price: item.price,
                            imagePath: item.image,
                            imageUrl: item.image,
                          );
                          context.read<CartData>().addItem(cartItem);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Added to Cart"),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4C8077),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Add",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
