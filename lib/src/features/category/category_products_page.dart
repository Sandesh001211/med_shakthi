import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_filter_sheet.dart';
import 'b2b_product_filter.dart';

class CategoryProductsPage extends StatefulWidget {
  final String categoryName;

  const CategoryProductsPage({
    super.key,
    required this.categoryName,
  });

  @override
  State<CategoryProductsPage> createState() =>
      _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> visibleProducts = [];

  bool loading = true;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() => loading = true);

    final response = await supabase
        .from('products')
        .select()
        .eq('category', widget.categoryName)
        .order('created_at', ascending: false);

    products = List<Map<String, dynamic>>.from(response);
    visibleProducts = products;

    setState(() => loading = false);
  }

  void applySearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      visibleProducts = products.where((p) {
        return p['name'].toString().toLowerCase().contains(q) ||
            p['brand'].toString().toLowerCase().contains(q) ||
            p['generic_name'].toString().toLowerCase().contains(q);
      }).toList();
    });
  }

  void applyFilter(B2BProductFilter filter) {
    List<Map<String, dynamic>> result = [...products];

    if (filter.sortBy == 'price_low') {
      result.sort((a, b) =>
          (a['price'] as num).compareTo(b['price'] as num));
    } else if (filter.sortBy == 'price_high') {
      result.sort((a, b) =>
          (b['price'] as num).compareTo(a['price'] as num));
    }

    if (filter.expiryBefore != null) {
      result = result.where((p) {
        final expiry =
        DateTime.tryParse(p['expiry_date']?.toString() ?? '');
        return expiry != null &&
            expiry.isBefore(filter.expiryBefore!);
      }).toList();
    }

    setState(() => visibleProducts = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () async {
              final filter =
              await showModalBottomSheet<B2BProductFilter>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const ProductFilterSheet(),
              );
              if (filter != null) {
                applyFilter(filter);
              }
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: applySearch,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: visibleProducts.isEmpty
                ? const Center(
              child: Text('No products found'),
            )
                : ListView.builder(
              itemCount: visibleProducts.length,
              itemBuilder: (context, index) {
                final p = visibleProducts[index];
                return ListTile(
                  leading: p['image_url'] != null
                      ? Image.network(
                    p['image_url'],
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  )
                      : const Icon(Icons.medical_services),
                  title: Text(p['name']),
                  subtitle: Text(
                    '${p['brand']} • ₹${p['price']}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
