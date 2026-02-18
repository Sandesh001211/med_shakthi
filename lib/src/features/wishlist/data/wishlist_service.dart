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
  List<WishlistItem> get wishlist {
    debugPrint(
      "WishlistService($hashCode): wishlist getter called. Count: ${_wishlist.length}",
    );
    return List.unmodifiable(_wishlist);
  }

  WishlistService({String? userId}) {
    debugPrint("WishlistService($hashCode): Created");
    _init();
    _listenToAuthChanges();
  }

  void _init() async {
    final user = _supabase.auth.currentUser;
    debugPrint("WishlistService: _init called. User: ${user?.id}");
    if (user != null) {
      // Authenticated: Fetch from cloud immediately
      _syncWithRemote(user);
    } else {
      // Guest: Load from local
      await _loadFromLocal();
    }
  }

  void _listenToAuthChanges() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      debugPrint("WishlistService: Auth event: $event");
      if (event == AuthChangeEvent.signedIn) {
        final user = data.session?.user;
        if (user != null) {
          debugPrint("WishlistService: User signed in: ${user.id}");
          // Merge local guest items to cloud before syncing
          await _mergeGuestWishlist(user);

          // Clear local list purely for UI perception before sync fills it
          _wishlist = [];
          notifyListeners();

          _syncWithRemote(user);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint("WishlistService: User signed out");
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

      debugPrint(
        "WishlistService: Merging ${guestItems.length} guest items to user ${user.id}",
      );

      // Upload each to Supabase
      for (final item in guestItems) {
        try {
          await _supabase
              .from('wishlist')
              .upsert(
                item.toMap(user.id),
                onConflict: 'user_id,product_id', // Unique constraint
              );
        } catch (e) {
          debugPrint("WishlistService: Values merge failed for ${item.id}: $e");
        }
      }

      // Clear guest list after successful merge attempt
      await prefs.remove('local_wishlist');
      // _wishlist.clear(); // Already handled in _listenToAuthChanges
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

  /// 🔄 Real-time Sync with Supabase (Single Source of Truth)
  void _syncWithRemote(User? user) async {
    if (user == null) return;

    debugPrint("WishlistService: Starting remote sync for user ${user.id}");

    // Cancel existing subscription
    _wishlistStreamSubscription?.cancel();

    // 1. Initial REST Fetch (Fallback)
    try {
      final initialData = await _supabase
          .from('wishlist')
          .select()
          .eq('user_id', user.id);

      if (initialData.isNotEmpty) {
        debugPrint(
          "WishlistService: Initial REST fetch found ${initialData.length} items",
        );
        _wishlist = (initialData as List)
            .map((e) => WishlistItem.fromMap(e))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("WishlistService: Initial fetch error: $e");
    }

    _wishlistStreamSubscription = _supabase
        .from('wishlist')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .handleError((error) {
          debugPrint(
            "WishlistService($hashCode): Stream error (handleError): $error",
          );
        })
        .listen(
          (List<Map<String, dynamic>> data) async {
            debugPrint(
              "WishlistService($hashCode): Stream event. Items: ${data.length}",
            );
            try {
              if (data.isEmpty) {
                debugPrint(
                  "WishlistService($hashCode): Stream data is EMPTY. Returning.",
                );
                return;
              }

              final productIds = data.map((e) => e['product_id']).toList();

              // 2. Background Refresh (Detailed Data)
              // Fetch latest product details including supplier info
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

              debugPrint(
                "WishlistService: Enhanced wishlist with product details",
              );
              notifyListeners();
            } catch (e, stack) {
              debugPrint(
                "WishlistService: CRITICAL Stream processing error: $e\n$stack",
              );
            }
          },
          onError: (error) {
            debugPrint("WishlistService: Stream onError: $error");
          },
        );
  }

  // Fallback manual fetch if needed
  Future<void> fetchWishlist() async {
    final user = _supabase.auth.currentUser;
    if (user != null) _syncWithRemote(user);
  }

  /// Add: Optimistic UI + Cloud Upsert
  Future<void> addToWishlist(WishlistItem item) async {
    if (isInWishlist(item.id)) {
      debugPrint("WishlistService: Item ${item.id} already in wishlist");
      return;
    }

    final user = _supabase.auth.currentUser;
    debugPrint("WishlistService: Adding item ${item.id}. User: ${user?.id}");

    // 1. Optimistic Update (UI)
    _wishlist.add(item);
    notifyListeners();

    if (user != null) {
      // Authenticated: Sync to Cloud
      try {
        debugPrint(
          "WishlistService: Upserting item ${item.id} for user ${user.id}",
        );
        await _supabase
            .from('wishlist')
            .upsert(item.toMap(user.id), onConflict: 'user_id,product_id');
        debugPrint("WishlistService: Upsert successful for ${item.id}");
      } catch (e) {
        debugPrint("WishlistService: Supabase add failed: $e");
        // If failed, the next stream update will correct the list
      }
    } else {
      // Guest: Save to Local
      _saveToLocal();
    }
  }

  /// Remove: Optimistic UI + Cloud Delete
  Future<void> removeFromWishlist(String productId) async {
    final user = _supabase.auth.currentUser;
    debugPrint("WishlistService: Removing item $productId. User: ${user?.id}");

    // 1. Optimistic Update (UI)
    _wishlist.removeWhere((item) => item.id == productId);
    notifyListeners();

    if (user != null) {
      // Authenticated: Sync to Cloud
      try {
        await _supabase
            .from('wishlist')
            .delete()
            .eq('user_id', user.id) // STRICT ISOLATION
            .eq('product_id', productId);
        debugPrint("WishlistService: Delete successful");
      } catch (e) {
        debugPrint("WishlistService: Supabase remove failed: $e");
      }
    } else {
      // Guest: Save to Local
      _saveToLocal();
    }
  }

  /// 💾 Local Storage: Save (GUEST ONLY)
  Future<void> _saveToLocal() async {
    final user = _supabase.auth.currentUser;
    // We strictly do NOT save local cache for logged-in users to prevent conflict
    if (user != null) return;

    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = _wishlist.map((item) {
      return jsonEncode(item.toMap('guest_user'));
    }).toList();
    await prefs.setStringList('local_wishlist', jsonList);
  }

  /// 💾 Local Storage: Load (GUEST ONLY)
  Future<void> _loadFromLocal() async {
    final user = _supabase.auth.currentUser;
    if (user != null) return; // Should use cloud for auth users

    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList('local_wishlist');

    if (jsonList != null) {
      _wishlist = jsonList.map((jsonStr) {
        return WishlistItem.fromMap(jsonDecode(jsonStr));
      }).toList();
      notifyListeners();
    }
  }

  Future<void> clearWishlist() async {
    debugPrint(
      "WishlistService($hashCode): clearWishlist called (DESTRUCTIVE)",
    );
    _wishlist.clear();
    notifyListeners();

    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('wishlist').delete().eq('user_id', user.id);
      } catch (_) {}
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_wishlist');
    }
  }
}
