import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/screens/product_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final supabase = Supabase.instance.client;

  bool isScanned = false;
  bool isLoading = false;

  final MobileScannerController cameraController =
  MobileScannerController();

  final ImagePicker picker = ImagePicker();

  /// ✅ Fetch product from Supabase
  Future<void> _openProduct(String productId) async {
    setState(() {
      isLoading = true;
    });

    try {
      print("Scanned Product ID: $productId");

      final res = await supabase
          .from('products')
          .select()
          .eq('id', productId)
          .single();

      final product = Product(
        id: res['id'],
        name: res['name'],
        category: res['category'],
        price: (res['price'] as num).toDouble(),
        rating: (res['rating'] ?? 4.5).toDouble(),
        image: res['image_url'],
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProductPage(product: product),
          ),
        );
      }
    } catch (e) {
      print("ERROR: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product not found"),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          isScanned = false;
          isLoading = false;
        });
      }
    }
  }

  /// ✅ Pick QR from gallery
  Future<void> _pickFromGallery() async {
    final XFile? image =
    await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      isLoading = true;
    });

    final result = await cameraController.analyzeImage(image.path);

    if (result != null && result.barcodes.isNotEmpty) {
      final code = result.barcodes.first.rawValue;

      if (code != null) {
        _openProduct(code);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No QR found in image"),
        ),
      );

      setState(() {
        isLoading = false;
      });
    }
  }

  /// ✅ Scan from camera
  void _onDetect(BarcodeCapture capture) {
    if (isScanned) return;

    final barcode = capture.barcodes.first;

    final code = barcode.rawValue;

    if (code != null) {
      isScanned = true;

      print("QR RESULT: $code");

      _openProduct(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo),
            onPressed: _pickFromGallery,
          )
        ],
      ),

      body: Stack(
        children: [

          /// Camera Scanner
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),

          /// Loader
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),

          /// Scan Frame UI
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

        ],
      ),

      /// Gallery Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickFromGallery,
        icon: const Icon(Icons.image),
        label: const Text("Upload QR"),
      ),
    );
  }
}
