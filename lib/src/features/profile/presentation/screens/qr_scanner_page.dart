import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:med_shakthi/src/features/products/data/models/product_model.dart';
import 'package:med_shakthi/src/features/products/presentation/screens/product_page.dart';
import 'package:med_shakthi/src/features/search/presentation/screens/global_search_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool isScanned = false;
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Product QR/Barcode"),
        centerTitle: true,
      ),
      body: MobileScanner(
        onDetect: (barcodeCapture) {
          if (isScanned) return;

          final List<Barcode> barcodes = barcodeCapture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final String code = barcodes.first.rawValue!;
            _handleScan(code);
          }
        },
      ),
    );
  }

  Future<void> _handleScan(String code) async {
    setState(() => isScanned = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Searching..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Check for direct match on barcode, SKU, or ID
      final response = await supabase
          .from('products')
          .select()
          .or(
            'barcode.eq.$code, sku.eq.$code, id.eq.$code',
          ) // removed id.eq.$code if id is int? No, usually uuid string in supabase
          .limit(2); // Get up to 2 to check for uniqueness

      if (!mounted) return;

      final List<dynamic> matches = response as List<dynamic>;

      if (matches.length == 1) {
        // Exact match found - Go to Product Page
        final productData = matches.first;
        final productModel = Product(
          id: productData['id']?.toString() ?? '',
          name: productData['name'] ?? 'Unknown Product',
          price:
              double.tryParse(productData['price']?.toString() ?? '0') ?? 0.0,
          image: productData['image_url'] ?? '',
          category: productData['category'] ?? 'General',
          rating: 0.0,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProductPage(product: productModel)),
        );
      } else {
        // No match or multiple matches - Go to Search Page with code pre-filled
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GlobalSearchPage(initialSearchQuery: code),
          ),
        );
      }
    } catch (e) {
      debugPrint("Scan Error: $e");
      if (mounted) {
        // On error, fallback to search page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GlobalSearchPage(initialSearchQuery: code),
          ),
        );
      }
    }
  }
}
