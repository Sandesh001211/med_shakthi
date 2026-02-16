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
    _init(); // Load local immediate
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
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _syncWithRemote(data.session?.user);
      } else if (event == AuthChangeEvent.signedOut) {
        _clearStateOnLogout();
      }
    });
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

  /// 🔄 Real-time Sync with Supabase (Like CartData)
  void _syncWithRemote(User? user) {
    if (user == null) return;

    _wishlistStreamSubscription?.cancel();
    _wishlistStreamSubscription = _supabase
        .from('wishlist')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .listen(
          (List<Map<String, dynamic>> data) async {
            // Fetch full product details for these items to get images/names
            // Stream only gives us the wishlist row. We might need a separate fetch or join?
            // Supabase stream does NOT support joins directly.
            // We have two options:
            // 1. Fetch details for each item.
            // 2. Use the stream for IDs, then fetch details.

            // BETTER APPROACH for Stream + Join:
            // Supabase Flutter SDK streams don't support deep joins easily in one go.
            // However, we can just use the product_id to fetch details or trust local if we have it.
            // But to ensure Freshness, let's just use the FETCH approach (Polling) or Stream logic.

            // Actually, CartData uses .stream(). Does it get joined data?
            // CartData manually maps.
            // Logic: On stream update, we get list of wishlist items.
            // We can then enrich them.

            if (data.isEmpty) {
              _wishlist = [];
              notifyListeners();
              _saveToLocal();
              return;
            }

            final productIds = data.map((e) => e['product_id']).toList();

            try {
              // Bulk fetch product details
              final productsResponse = await _supabase
                  .from('products')
                  .select('*, suppliers(name, supplier_code, id)')
                  .filter('id', 'in', productIds);

              final List<dynamic> productsData =
                  productsResponse as List<dynamic>;
              final productMap = {for (var p in productsData) p['id']: p};

              _wishlist = data.map((wItem) {
                final pId = wItem['product_id'];
                final pData = productMap[pId]; // associated product

                // Merge/Map
                // We need to construct a map that WishlistItem.fromMap expects
                // It expects 'products' key for joined data
                final mapForModel = Map<String, dynamic>.from(wItem);
                if (pData != null) {
                  mapForModel['products'] = pData;
                }
                return WishlistItem.fromMap(mapForModel);
              }).toList();

              notifyListeners();
              _saveToLocal();
            } catch (e) {
              if (kDebugMode)
                print("Error fetching product details for wishlist: $e");
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
              onConflict: 'user_id, product_id', // Prevent duplicates
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
