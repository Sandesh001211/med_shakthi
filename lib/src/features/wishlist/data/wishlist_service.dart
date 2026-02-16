import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/wishlist_item_model.dart';

class WishlistService extends ChangeNotifier {
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _wishlistStreamSubscription;
  final SupabaseClient _supabase = Supabase.instance.client;

  List<WishlistItem> _wishlist = [];
  List<WishlistItem> get wishlist => List.unmodifiable(_wishlist);

  WishlistService({String? userId}) {
    _init(); // Load local immediately
    _listenToAuthChanges();
  }

  void _init() async {
    await _loadFromLocal();
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _syncWithRemote(user);
    }
  }

  void _listenToAuthChanges() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        final user = data.session?.user;
        if (user != null) {
          await _mergeGuestWishlist(user);
          _syncWithRemote(user);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _clearStateOnLogout();
      }
    });
  }

  /// 🔄 Merge Guest Items to User Account
  Future<void> _mergeGuestWishlist(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? guestList = prefs.getStringList('local_wishlist');

    if (guestList != null && guestList.isNotEmpty) {
      final List<WishlistItem> guestItems = guestList.map((jsonStr) {
        return WishlistItem.fromMap(jsonDecode(jsonStr));
      }).toList();

      if (kDebugMode) {
        print("Merging ${guestItems.length} guest items to user ${user.id}");
      }

      // Upload each to Supabase
      for (final item in guestItems) {
        try {
          await _supabase
              .from('wishlist')
              .upsert(item.toMap(user.id), onConflict: 'user_id, product_id');
        } catch (e) {
          if (kDebugMode) print("Values merge failed for ${item.id}: $e");
        }
      }

      // Clear guest list after successful merge attempt
      await prefs.remove('local_wishlist');
    }
  }

  void _clearStateOnLogout() {
    _wishlistStreamSubscription?.cancel();
    _wishlistStreamSubscription = null;
    _wishlist = [];
    notifyListeners();
    _loadFromLocal(); // Load guest wishlist if any
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _wishlistStreamSubscription?.cancel();
    super.dispose();
  }

  bool isInWishlist(String productId) {
    return _wishlist.any((item) => item.id == productId);
  }

  /// 🔄 Real-time Sync with Supabase
  void _syncWithRemote(User? user) {
    if (user == null) return;

    // Cancel existing subscription to avoid duplicates
    _wishlistStreamSubscription?.cancel();

    _wishlistStreamSubscription = _supabase
        .from('wishlist')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id) // Strict user filter like Cart
        .listen(
          (List<Map<String, dynamic>> data) async {
            if (kDebugMode) {
              print("Wishlist Stream Event: ${data.length} items");
            }

            // 1. Immediate Update (Snapshot)
            // Use the data directly from the wishlist table so user sees *something*
            // even if product fetch fails.
            _wishlist = data.map((e) => WishlistItem.fromMap(e)).toList();
            notifyListeners();
            _saveToLocal();

            if (data.isEmpty) return;

            final productIds = data.map((e) => e['product_id']).toList();

            try {
              // 2. Background Refresh (Detailed Data)
              // Fetch latest product details (price, image, supplier)
              final productsResponse = await _supabase
                  .from('products')
                  .select('*, suppliers(name, supplier_code, id)')
                  .filter('id', 'in', productIds);

              final List<dynamic> productsData =
                  productsResponse as List<dynamic>;
              final productMap = {for (var p in productsData) p['id']: p};

              // Re-map with enhanced product data
              _wishlist = data.map((wItem) {
                final pId = wItem['product_id'];
                final pData = productMap[pId];

                final mapForModel = Map<String, dynamic>.from(wItem);
                if (pData != null) {
                  mapForModel['products'] = pData;
                }
                return WishlistItem.fromMap(mapForModel);
              }).toList();

              if (kDebugMode) {
                print("Wishlist enhanced with product data");
              }

              notifyListeners();
              _saveToLocal();
            } catch (e) {
              // If product fetch fails, we just log it.
              // We DO NOT clear the list - we keep the snapshot from step 1.
              if (kDebugMode) {
                print("Error enhancing wishlist with product details: $e");
              }
            }
          },
          onError: (error) {
            if (kDebugMode) print("Wishlist stream error: $error");
          },
        );
  }

  // Fallback manual fetch if needed
  Future<void> fetchWishlist() async {
    final user = _supabase.auth.currentUser;
    if (user != null) _syncWithRemote(user);
  }

  /// Add: Optimistic Local + Remote
  Future<void> addToWishlist(WishlistItem item) async {
    if (isInWishlist(item.id)) return;

    // Optimistic Update
    _wishlist.add(item);
    notifyListeners();
    _saveToLocal();

    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase
            .from('wishlist')
            .upsert(
              item.toMap(user.id),
              onConflict:
                  'user_id, product_id', // Ensures uniqueness based on user and product
            );
      } catch (e) {
        if (kDebugMode) print('Supabase add failed: $e');
        // Rollback? Usually not needed if stream corrects it.
      }
    }
  }

  /// Remove: Optimistic Local + Remote
  Future<void> removeFromWishlist(String productId) async {
    _wishlist.removeWhere((item) => item.id == productId);
    notifyListeners();
    _saveToLocal();

    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase
            .from('wishlist')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', productId);
      } catch (e) {
        if (kDebugMode) print('Supabase remove failed: $e');
      }
    }
  }

  /// 💾 Local Storage: Save
  Future<void> _saveToLocal() async {
    final user = _supabase.auth.currentUser;
    final String key = user != null ? 'wishlist_${user.id}' : 'local_wishlist';
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = _wishlist.map((item) {
      return jsonEncode(item.toMap(user?.id ?? 'local_user'));
    }).toList();
    await prefs.setStringList(key, jsonList);
  }

  /// 💾 Local Storage: Load
  Future<void> _loadFromLocal() async {
    final user = _supabase.auth.currentUser;
    final String key = user != null ? 'wishlist_${user.id}' : 'local_wishlist';
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(key);

    if (jsonList != null && _wishlist.isEmpty) {
      // Only load if empty to verify cache
      // Actually, we should allow overwrite if local is source of truth initially
      _wishlist = jsonList.map((jsonStr) {
        return WishlistItem.fromMap(jsonDecode(jsonStr));
      }).toList();
      notifyListeners();
    }
  }

  Future<void> clearWishlist() async {
    // This legacy method might just clear local?
    // If we stream, we should delete from server?
    // For now, let's keep it local clear + server delete if logged in
    _wishlist.clear();
    notifyListeners();

    final user = _supabase.auth.currentUser;
    if (user != null) {
      // DANGER: Do we really want to wipe server wishlist?
      // Usually 'Clear Wishlist' means wipe it.
      try {
        await _supabase.from('wishlist').delete().eq('user_id', user.id);
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      await prefs.remove('wishlist_${user.id}');
    } else {
      await prefs.remove('local_wishlist');
    }
  }
}
