import 'package:flutter/material.dart';
import 'b2b_product_filter.dart';

class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet({super.key});

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late final B2BProductFilter filter;
  final minPriceController = TextEditingController();
  final maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filter = B2BProductFilter();
  }

  @override
  void dispose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section('Sort By'),
                      _radio('Price: Low → High', 'price_low'),
                      _radio('Price: High → Low', 'price_high'),
                      _radio('Name: A → Z', 'name_az'),
                      _radio('Name: Z → A', 'name_za'),
                      _radio('Expiry: Soonest', 'expiry_soon'),

                      _divider(),
                      _section('Price Range'),
                      _priceRangeRow(),

                      _divider(),
                      _section('Expiry Date'),
                      _check(
                        'Within 1 Month',
                        filter.expiry1Month,
                        (v) => setState(() => filter.expiry1Month = v),
                      ),
                      _check(
                        'Within 3 Months',
                        filter.expiry3Months,
                        (v) => setState(() => filter.expiry3Months = v),
                      ),
                      _check(
                        'Within 6 Months',
                        filter.expiry6Months,
                        (v) => setState(() => filter.expiry6Months = v),
                      ),
                      _check(
                        'Within 12 Months',
                        filter.expiry12Months,
                        (v) => setState(() => filter.expiry12Months = v),
                      ),

                      _divider(),
                      _section('Stock Status'),
                      _check(
                        'Available Only',
                        filter.availableOnly,
                        (v) => setState(() => filter.availableOnly = v),
                      ),
                      _check(
                        'Low Stock (<10)',
                        filter.lowStock,
                        (v) => setState(() => filter.lowStock = v),
                      ),
                      _check(
                        'Out of Stock',
                        filter.outOfStock,
                        (v) => setState(() => filter.outOfStock = v),
                      ),

                      _divider(),
                      _section('Minimum Rating'),
                      Slider(
                        value: filter.minRating ?? 0,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        label: '${(filter.minRating ?? 0).toStringAsFixed(1)}+',
                        activeColor: const Color(0xff2b9c8f),
                        onChanged: (v) => setState(() => filter.minRating = v),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildApplyButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Filters',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1);

  Widget _radio(String label, String value) {
    return RadioListTile<String>(
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      groupValue: filter.sortBy,
      activeColor: const Color(0xff2b9c8f),
      onChanged: (v) => setState(() => filter.sortBy = v),
    );
  }

  Widget _check(String label, bool value, void Function(bool) onChanged) {
    return CheckboxListTile(
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      activeColor: const Color(0xff2b9c8f),
      onChanged: (bool? v) {
        if (v != null) {
          onChanged(v);
        }
      },
    );
  }

  Widget _priceRangeRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: minPriceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Min Price',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => filter.minPrice = double.tryParse(v),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: maxPriceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max Price',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => filter.maxPrice = double.tryParse(v),
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
