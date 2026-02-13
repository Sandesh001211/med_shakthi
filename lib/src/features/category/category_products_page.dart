import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_filter_sheet.dart';
import 'b2b_product_filter.dart';
import 'package:med_shakthi/src/core/utils/smart_product_image.dart';
import 'package:med_shakthi/src/features/products/data/models/product_model.dart';
import 'package:med_shakthi/src/features/products/presentation/screens/product_page.dart';

class CategoryProductsPage extends StatefulWidget {
  final String categoryName;

  const CategoryProductsPage({super.key, required this.categoryName});

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
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

  Future<void> fetchProducts({B2BProductFilter? filter}) async {
    setState(() => loading = true);

    try {
      dynamic query = supabase
          .from('products')
          .select()
          .ilike('category', '%${widget.categoryName}%');

      if (filter != null) {
        // Price range filters - YOUR price column (numeric)
        if (filter.minPrice != null && filter.minPrice! > 0) {
          query = query.gte('price', filter.minPrice!);
        }
        if (filter.maxPrice != null && filter.maxPrice! > 0) {
          query = query.lte('price', filter.maxPrice!);
        }

        // Expiry filter - YOUR expiry_date column (date)
        if (filter.expiryBefore != null) {
          query = query.lt(
            'expiry_date',
            filter.expiryBefore!.toIso8601String(),
          );
        }

        // Sorting - YOUR columns only
        if (filter.sortBy != null && filter.sortBy!.isNotEmpty) {
          if (filter.sortBy == 'price_low') {
            query = query.order('price', ascending: true);
          } else if (filter.sortBy == 'price_high') {
            query = query.order('price', ascending: false);
          } else if (filter.sortBy == 'name_az') {
            query = query.order('name', ascending: true);
          } else if (filter.sortBy == 'name_za') {
            query = query.order('name', ascending: false);
          } else if (filter.sortBy == 'expiry_soon') {
            query = query.order('expiry_date', ascending: true);
          } else {
            query = query.order('created_at', ascending: false);
          }
        }
      }

      final response = await query.limit(100);

      if (mounted) {
        products = List<Map<String, dynamic>>.from(response);
        visibleProducts = List<Map<String, dynamic>>.from(products);
        setState(() => loading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to fetch products: $e')));
        setState(() => loading = false);
      }
    }
  }

  String _formatExpiry(String? expiryDate) {
    if (expiryDate == null) return 'N/A';
    try {
      final date = DateTime.parse(expiryDate);
      return '${date.day}/${date.month}';
    } catch (e) {
      return 'N/A';
    }
  }

  void applySearch(String query) {
    if (products.isEmpty || query.isEmpty) {
      setState(() {
        visibleProducts = List<Map<String, dynamic>>.from(products);
      });
      return;
    }

    final q = query.toLowerCase();
    final filtered = products.where((p) {
      final name = p['name']?.toString().toLowerCase() ?? '';
      final brand = p['brand']?.toString().toLowerCase() ?? '';
      final generic = p['generic_name']?.toString().toLowerCase() ?? '';
      final sku = p['sku']?.toString().toLowerCase() ?? '';
      return name.contains(q) ||
          brand.contains(q) ||
          generic.contains(q) ||
          sku.contains(q);
    }).toList();

    setState(() {
      visibleProducts = filtered;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black87),
            onPressed: () async {
              final newFilter = await showModalBottomSheet<B2BProductFilter>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const ProductFilterSheet(),
              );
              if (newFilter != null) {
                await fetchProducts(filter: newFilter);
              }
            },
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff2b9c8f)),
            )
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: searchController,
                    onChanged: applySearch,
                    decoration: InputDecoration(
                      hintText: 'Search products by name, brand, SKU...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xff2b9c8f),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                // Products list
                Expanded(
                  child: visibleProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                searchController.text.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Text(
                                  searchController.text.isNotEmpty
                                      ? 'No products found matching your search'
                                      : 'No products available in this category',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (searchController.text.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () {
                                    searchController.clear();
                                    applySearch('');
                                  },
                                  icon: const Icon(Icons.clear, size: 18),
                                  label: const Text('Clear search'),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: visibleProducts.length,
                          itemBuilder: (context, index) {
                            final product = visibleProducts[index];
                            final price =
                                double.tryParse(
                                  product['price']?.toString() ?? '0',
                                ) ??
                                0.0;

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                onTap: () {
                                  final productModel = Product(
                                    id: product['id']?.toString() ?? '',
                                    name: product['name'] ?? 'Unknown Product',
                                    price: price,
                                    image: product['image_url'] ?? '',
                                    category:
                                        product['category'] ??
                                        widget.categoryName,
                                    rating: 0.0,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProductPage(product: productModel),
                                    ),
                                  );
                                },
                                leading: SmartProductImage(
                                  imageUrl: product['image_url'],
                                  category:
                                      product['category'] ??
                                      widget.categoryName,
                                  width: 56,
                                  height: 56,
                                ),
                                title: Text(
                                  product['name'] ?? 'Unknown Product',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // YOUR BRAND column
                                    Text(
                                      product['brand'] ?? 'Generic',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(0xFF757575),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // YOUR PRICE column
                                    Text(
                                      '₹${price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff2b9c8f),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // YOUR EXPIRY_DATE + SUB_CATEGORY columns
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'Expires: ${_formatExpiry(product['expiry_date'])}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange[700],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (product['sub_category'] != null &&
                                            product['sub_category']
                                                .toString()
                                                .isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              product['sub_category']
                                                  .toString(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue[700],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: const Color(0xFF757575),
                                ),
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
