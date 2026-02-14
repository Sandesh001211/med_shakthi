import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/payment_method_model.dart';
import 'package:uuid/uuid.dart';

class PaymentMethodStore extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  List<PaymentMethodModel> _paymentMethods = [];
  bool _loading = false;
  String? _selectedMethodId;

  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  bool get loading => _loading;
  String? get selectedMethodId => _selectedMethodId;

  void selectMethod(String id) {
    _selectedMethodId = id;
    notifyListeners();
  }

  Future<void> fetchPaymentMethods() async {
    _loading = true;
    notifyListeners();

    try {
      // Fetch system available payment methods
      // For now, we can simulated fetching from a 'payment_modes' table or just static definition
      // But the requirement says "dynamic, backend-driven".
      // Let's assume there is a 'payment_modes' table that defines what methods are available globally
      // AND a 'user_payment_methods' table where user saves their specific details (like specific UPI ID).

      // Wait, the requirement says "Payment methods are persistent, user-isolated".
      // So we likely need a table 'user_payment_methods'.

      final user = supabase.auth.currentUser;
      if (user == null) {
        _paymentMethods = [];
        _loading = false;
        notifyListeners();
        return;
      }

      final response = await supabase
          .from('user_payment_methods')
          .select()
          .eq('user_id', user.id);

      _paymentMethods = (response as List)
          .map((e) => PaymentMethodModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint("Error fetching payment methods: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addPaymentMethod(
    String name,
    String type,
    Map<String, dynamic> details,
  ) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final newMethod = PaymentMethodModel(
        id: const Uuid().v4(),
        name: name,
        type: type,
        details: details,
      );

      await supabase.from('user_payment_methods').insert({
        ...newMethod.toJson(),
        'user_id': user.id,
      });

      await fetchPaymentMethods();
      return true;
    } catch (e) {
      debugPrint("Error adding payment method: $e");
      return false;
    }
  }

  Future<bool> deletePaymentMethod(String id) async {
    try {
      await supabase.from('user_payment_methods').delete().eq('id', id);
      await fetchPaymentMethods();
      return true;
    } catch (e) {
      debugPrint("Error deleting payment method: $e");
      return false;
    }
  }
}
