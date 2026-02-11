import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/banner_model.dart';

class BannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  static const String _bannersCollection = 'banners';

  // Create a new banner
  Future<String> createBanner({
    required String title,
    required String subtitle,
    required File imageFile,
    required String supplierId,
    required String category,
    required DateTime startDate,
    required DateTime endDate,
    required bool active,
    String? supplierName,
  }) async {
    try {
      // Upload image to Firebase Storage
      final imageUrl = await _uploadBannerImage(imageFile, supplierId);

      // Create banner document
      final bannerData = {
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'supplierId': supplierId,
        'category': category,
        'active': active,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'supplierName': supplierName,
      };

      final docRef = await _firestore
          .collection(_bannersCollection)
          .add(bannerData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create banner: $e');
    }
  }

  // Upload banner image to Firebase Storage
  Future<String> _uploadBannerImage(File imageFile, String supplierId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${supplierId}.jpg';
      final ref = _storage.ref().child('banners/$supplierId/$fileName');
      
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Get active banners (real-time stream)
  Stream<List<BannerModel>> getActiveBannersStream() {
    final now = DateTime.now();
    
    return _firestore
        .collection(_bannersCollection)
        .where('active', isEqualTo: true)
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('endDate', descending: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BannerModel.fromFirestore(doc))
          .where((banner) => banner.isValid)
          .toList();
    });
  }

  // Get banners by supplier (for supplier dashboard)
  Stream<List<BannerModel>> getSupplierBannersStream(String supplierId) {
    return _firestore
        .collection(_bannersCollection)
        .where('supplierId', isEqualTo: supplierId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BannerModel.fromFirestore(doc))
          .toList();
    });
  }

  // Update banner
  Future<void> updateBanner(String bannerId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(_bannersCollection)
          .doc(bannerId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update banner: $e');
    }
  }

  // Toggle banner active status
  Future<void> toggleBannerStatus(String bannerId, bool active) async {
    try {
      await _firestore
          .collection(_bannersCollection)
          .doc(bannerId)
          .update({'active': active});
    } catch (e) {
      throw Exception('Failed to toggle banner status: $e');
    }
  }

  // Delete banner
  Future<void> deleteBanner(String bannerId, String imageUrl) async {
    try {
      // Delete image from storage
      if (imageUrl.isNotEmpty) {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }

      // Delete banner document
      await _firestore
          .collection(_bannersCollection)
          .doc(bannerId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete banner: $e');
    }
  }

  // Auto-disable expired banners (run periodically)
  Future<void> disableExpiredBanners() async {
    try {
      final now = DateTime.now();
      final expiredBanners = await _firestore
          .collection(_bannersCollection)
          .where('active', isEqualTo: true)
          .where('endDate', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      for (var doc in expiredBanners.docs) {
        batch.update(doc.reference, {'active': false});
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to disable expired banners: $e');
    }
  }

  // Get banners by category
  Stream<List<BannerModel>> getBannersByCategory(String category) {
    final now = DateTime.now();
    
    return _firestore
        .collection(_bannersCollection)
        .where('category', isEqualTo: category)
        .where('active', isEqualTo: true)
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('endDate', descending: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BannerModel.fromFirestore(doc))
          .where((banner) => banner.isValid)
          .toList();
    });
  }
}
