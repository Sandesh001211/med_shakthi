import 'package:flutter/material.dart';
import 'package:med_shakthi/src/features/category/category_products_page.dart';
import '../../profile/presentation/screens/qr_scanner_page.dart';

class StaticPharmacyBanners extends StatelessWidget {
  const StaticPharmacyBanners({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: PageView(
        controller: PageController(viewportFraction: 0.9),
        children: [
          _buildStaticBanner(
            context,
            title: "Flat 20% OFF",
            subtitle: "On all Medicines",
            buttonText: "Order Now",
            color: const Color(0xFF4CA6A8),
            icon: Icons.medication,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const CategoryProductsPage(categoryName: "Medicines"),
                ),
              );
            },
          ),
          _buildStaticBanner(
            context,
            title: "Upload Prescription",
            subtitle: "We'll do the rest",
            buttonText: "Upload Now",
            color: const Color(0xFF6366F1),
            icon: Icons.upload_file,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QRScannerPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStaticBanner(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String buttonText,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative Circle
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -40,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            buttonText,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    icon,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 60,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
