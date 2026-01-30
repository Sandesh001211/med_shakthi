import 'package:flutter/foundation.dart';
import 'models/wishlist_item_model.dart';

class WishlistService extends ChangeNotifier {
  final String userId;

  WishlistService({required this.userId});

  final List<WishlistItem> _wishlist = [];

  List<WishlistItem> get wishlist => List.unmodifiable(_wishlist);

  bool isInWishlist(String productId) {
    return _wishlist.any((item) => item.id == productId);
  }

  void addToWishlist(WishlistItem item) {
    if (!isInWishlist(item.id)) {
      _wishlist.add(item);
      notifyListeners();
    }
  }

  void removeFromWishlist(String productId) {
    _wishlist.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  void clearWishlist() {
    _wishlist.clear();
    notifyListeners();
  }
}
