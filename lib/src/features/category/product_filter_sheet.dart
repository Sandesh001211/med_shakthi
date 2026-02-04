import 'package:flutter/material.dart';
import 'b2b_product_filter.dart';

class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet({super.key});

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  final filter = B2BProductFilter();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Sort & Filter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 12),

              _sectionTitle('Sort By'),
              _radio('Price: Low → High', 'price_low'),
              _radio('Price: High → Low', 'price_high'),

              _divider(),

              _sectionTitle('Expiry'),
              _check('Expiry within 3 months', (v) => filter.expiry3Months = v),
              _check('Expiry within 6 months', (v) => filter.expiry6Months = v),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2b9c8f),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, filter),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1),
    );
  }

  Widget _radio(String label, String value) {
    return RadioListTile(
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 13)),
      value: value,
      groupValue: filter.sortBy,
      activeColor: const Color(0xff2b9c8f),
      onChanged: (v) => setState(() => filter.sortBy = v),
    );
  }

  Widget _check(String label, Function(bool) onChanged) {
    return CheckboxListTile(
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 13)),
      value: label.contains('3')
          ? filter.expiry3Months
          : filter.expiry6Months,
      activeColor: const Color(0xff2b9c8f),
      onChanged: (v) => setState(() => onChanged(v!)),
    );
  }
}
