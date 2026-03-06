import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/wishlist_service.dart';
import '../../data/models/wishlist_item_model.dart';
import '../../../cart/data/cart_data.dart';
import '../../../cart/data/cart_item.dart';
import '../../../products/presentation/screens/product_page.dart';
import '../../../products/data/models/product_model.dart';
import 'package:med_shakthi/src/core/utils/smart_product_image.dart';
import 'package:med_shakthi/src/core/utils/custom_snackbar.dart';

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

class _WishlistCard extends StatefulWidget {
  final WishlistItem item;
  final int index;

  const _WishlistCard({required this.item, required this.index});

  @override
  State<_WishlistCard> createState() => _WishlistCardState();
}

class _WishlistCardState extends State<_WishlistCard> {
  bool _addingToCart = false;

  /// Checks live stock + is_active before adding to cart.
  Future<void> _addToCart() async {
    if (_addingToCart) return;
    setState(() => _addingToCart = true);

    try {
      final supabase = Supabase.instance.client;
      final pRes = await supabase
          .from('products')
          .select('stock_quantity, is_active, price')
          .eq('id', widget.item.id)
          .maybeSingle();

      if (!mounted) return;

      if (pRes == null) {
        showCustomSnackBar(
          context,
          'Product is no longer available.',
          isError: true,
        );
        return;
      }

      final isActive = pRes['is_active'] == true;
      final stock = pRes['stock_quantity'] as int? ?? 0;
      final livePrice =
          (pRes['price'] as num?)?.toDouble() ?? widget.item.price;

      if (!isActive) {
        showCustomSnackBar(
          context,
          '${widget.item.name} is currently unavailable.',
          isError: true,
        );
        return;
      }

      if (stock <= 0) {
        showCustomSnackBar(
          context,
          '${widget.item.name} is out of stock.',
          isError: true,
        );
        return;
      }

      // All checks passed — add to cart with live price
      context.read<CartData>().addItem(
        CartItem(
          id: widget.item.id,
          name: widget.item.name,
          title: widget.item.name,
          brand: 'General',
          size: 'Standard',
          price: livePrice,
          imagePath: widget.item.image,
          imageUrl: widget.item.image,
          quantity: 1,
        ),
      );

      if (mounted) showCustomSnackBar(context, 'Added to cart!');
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, 'Could not add to cart: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
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
                id: widget.item.id,
                name: widget.item.name,
                price: widget.item.price,
                image: widget.item.image,
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
                        imageUrl: widget.item.image,
                        category: widget.item.name,
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
                          widget.item.name,
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
                          "₹${widget.item.price.toStringAsFixed(2)}",
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
                            widget.item.id,
                          );
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        tooltip: "Remove",
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 32,
                        width: 64,
                        child: ElevatedButton(
                          onPressed: _addingToCart ? null : _addToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C8077),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _addingToCart
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Add",
                                  style: TextStyle(fontSize: 12),
                                ),
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
