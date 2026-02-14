// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../screens/payment_method_store.dart';
import '../utils/payment_utils.dart';

class AddPaymentMethodSheet extends StatefulWidget {
  const AddPaymentMethodSheet({super.key});

  @override
  State<AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<AddPaymentMethodSheet> {
  String _selectedType = "upi";
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, dynamic>> _paymentOptions = [
    {
      'id': 'upi',
      'name': 'UPI',
      'icon': Icons.qr_code_2,
      'color': Colors.orange,
    },
    {
      'id': 'card',
      'name': 'Card',
      'icon': Icons.credit_card,
      'color': Colors.teal,
    },
    {
      'id': 'bank_transfer',
      'name': 'Net Banking',
      'icon': Icons.account_balance,
      'color': Colors.brown,
    },
    {
      'id': 'paypal',
      'name': 'PayPal',
      'icon': Icons.paypal,
      'color': Colors.blueAccent,
    },
  ];

  final List<String> _popularBanks = [
    "HDFC Bank",
    "SBI",
    "ICICI Bank",
    "Axis Bank",
    "Kotak Mahindra",
    "PNB",
    "Bank of Baroda",
    "Union Bank",
  ];

  String? _selectedBank;
  String? _cardType;

  // Controllers
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _confirmAccountNoController = TextEditingController();
  final _ifscController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _accountNoController.dispose();
    _confirmAccountNoController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String type) {
    _formKey.currentState?.reset();
    setState(() {
      _selectedType = type;
      _clearForm();
      if (type == 'card') _nameController.text = "My Card";
      if (type == 'upi') _nameController.text = "My UPI";
    });
  }

  void _clearForm() {
    _nameController.clear();
    _idController.clear();
    _cardNumberController.clear();
    _cardHolderController.clear();
    _expiryController.clear();
    _cvvController.clear();
    _accountNoController.clear();
    _confirmAccountNoController.clear();
    _ifscController.clear();
    _selectedBank = null;
    _cardType = null;
  }

  String? _validateIFSC(String? value) {
    if (value == null || value.isEmpty) return "IFSC required";
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value.toUpperCase())) {
      return "Invalid IFSC (e.g. HDFC0001234)";
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) return "Required";

    final parts = value.split('/');
    if (parts.length != 2 || parts[0].length != 2 || parts[1].length != 2) {
      return "Use MM/YY format";
    }

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) return "Invalid date";
    if (month < 1 || month > 12) return "Invalid month";

    // Check expiry
    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear) return "Card expired";
    if (year == currentYear && month < currentMonth) return "Card expired";

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.teal, width: 2),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    );

    InputDecoration getDecor(
      String label,
      IconData icon, {
      String? hint,
      Widget? suffix,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
        suffixIcon: suffix,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Add Payment Method",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Type Selector
            SizedBox(
              height: 85,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _paymentOptions.length,
                separatorBuilder: (context, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final option = _paymentOptions[index];
                  final isSelected = _selectedType == option['id'];
                  final color = option['color'] as Color;
                  return GestureDetector(
                    onTap: () => _onTypeChanged(option['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 75,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey[400]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            option['icon'],
                            color: isSelected ? color : Colors.grey[600],
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            option['name'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected ? color : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Alias Field
                    TextFormField(
                      key: const ValueKey('alias_field'),
                      controller: _nameController,
                      decoration: getDecor(
                        "Alias",
                        Icons.label_outline,
                        hint: "e.g. My HDFC Card",
                      ),
                      validator: (v) => v!.trim().isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),

                    // UPI
                    if (_selectedType == 'upi') ...[
                      TextFormField(
                        key: const ValueKey('upi_id_field'),
                        controller: _idController,
                        decoration: getDecor(
                          "UPI ID",
                          Icons.qr_code_2,
                          hint: "username@oksbi",
                        ),
                        validator: UpiUtils.validateUpiId,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Supported: @oksbi, @ybl, @paytm, @apl, @axl, etc.",
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),

                      // Card
                    ] else if (_selectedType == 'card') ...[
                      TextFormField(
                        key: const ValueKey('card_number_field'),
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CardNumberInputFormatter(),
                        ],
                        onChanged: (val) => setState(
                          () => _cardType = CardUtils.detectCardType(val),
                        ),
                        decoration: getDecor(
                          "Card Number",
                          Icons.credit_card,
                          hint: "1234 5678 9012 3456",
                          suffix: _cardType != null
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Chip(
                                    label: Text(
                                      _cardType!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: Colors.teal.withOpacity(
                                      0.1,
                                    ),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                              : null,
                        ),
                        validator: CardUtils.validateCardNum,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        key: const ValueKey('card_holder_field'),
                        controller: _cardHolderController,
                        decoration: getDecor(
                          "Cardholder Name",
                          Icons.person_outline,
                          hint: "As on card",
                        ),
                        validator: (v) => v!.trim().isEmpty ? "Required" : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              key: const ValueKey('card_expiry_field'),
                              controller: _expiryController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                ExpiryDateInputFormatter(),
                              ],
                              decoration: getDecor(
                                "Expiry",
                                Icons.calendar_today,
                                hint: "MM/YY",
                              ),
                              validator: _validateExpiry,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              key: const ValueKey('card_cvv_field'),
                              controller: _cvvController,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              decoration: getDecor(
                                "CVV",
                                Icons.lock_outline,
                                hint: "123",
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Required";
                                // Amex uses 4-digit CVV, others use 3-digit
                                if (_cardType == 'Amex') {
                                  return v.length != 4
                                      ? "Amex requires 4 digits"
                                      : null;
                                } else {
                                  return v.length != 3
                                      ? "CVV must be 3 digits"
                                      : null;
                                }
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                          ),
                        ],
                      ),

                      // Net Banking
                    ] else if (_selectedType == 'bank_transfer') ...[
                      DropdownButtonFormField<String>(
                        key: const ValueKey('bank_dropdown'),
                        value: _selectedBank,
                        decoration: getDecor(
                          "Select Bank",
                          Icons.account_balance,
                        ),
                        items: _popularBanks
                            .map(
                              (b) => DropdownMenuItem(value: b, child: Text(b)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedBank = v;
                          _nameController.text = v ?? "";
                        }),
                        validator: (v) => v == null ? "Select bank" : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        key: const ValueKey('bank_acc_field'),
                        controller: _accountNoController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: getDecor(
                          "Account Number",
                          Icons.password,
                          hint: "Hidden for security",
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? "Required" : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        key: const ValueKey('bank_confirm_field'),
                        controller: _confirmAccountNoController,
                        keyboardType: TextInputType.number,
                        decoration: getDecor(
                          "Confirm Account",
                          Icons.check_circle_outline,
                          hint: "Re-enter number",
                        ),
                        validator: (v) {
                          if (v != _accountNoController.text) {
                            return "Numbers don't match";
                          }
                          if (v == null || v.isEmpty) {
                            return "Required";
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        key: const ValueKey('bank_ifsc_field'),
                        controller: _ifscController,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [LengthLimitingTextInputFormatter(11)],
                        decoration: getDecor(
                          "IFSC Code",
                          Icons.code,
                          hint: "HDFC0001234",
                        ),
                        validator: _validateIFSC,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),

                      // PayPal
                    ] else if (_selectedType == 'paypal') ...[
                      TextFormField(
                        key: const ValueKey('paypal_email_field'),
                        controller: _idController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: getDecor(
                          "PayPal Email",
                          Icons.email_outlined,
                          hint: "you@example.com",
                        ),
                        validator: (v) =>
                            (v == null || !v.contains('@') || !v.contains('.'))
                            ? "Invalid email"
                            : null,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final details = <String, dynamic>{};

                    if (_selectedType == 'upi') {
                      details['upi_id'] = _idController.text.toLowerCase();
                      details['provider'] = 'upi';
                    } else if (_selectedType == 'paypal') {
                      details['email'] = _idController.text;
                    } else if (_selectedType == 'bank_transfer') {
                      details['bank_name'] = _selectedBank;
                      details['account_no'] = _confirmAccountNoController.text;
                      details['ifsc'] = _ifscController.text.toUpperCase();
                    } else if (_selectedType == 'card') {
                      String cleaned = CardUtils.getCleanedNumber(
                        _cardNumberController.text,
                      );
                      String last4 = cleaned.length >= 4
                          ? cleaned.substring(cleaned.length - 4)
                          : "XXXX";
                      details['card_number_masked'] = "•••• •••• •••• $last4";
                      details['card_holder'] = _cardHolderController.text;
                      details['expiry'] = _expiryController.text;
                      details['card_type'] = _cardType ?? 'Card';
                    }

                    final success = await context
                        .read<PaymentMethodStore>()
                        .addPaymentMethod(
                          _nameController.text,
                          _selectedType,
                          details,
                        );

                    if (!mounted) return;
                    if (success) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to save method")),
                      );
                    }
                  }
                },
                child: const Text(
                  "SAVE METHOD",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
