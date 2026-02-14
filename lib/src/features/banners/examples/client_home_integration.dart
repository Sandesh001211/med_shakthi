import 'package:flutter/material.dart';
import 'package:med_shakthi/src/features/banners/widgets/banner_carousel.dart';

/// Example integration of the Banner Carousel in the Client Home Screen
///
/// This demonstrates how to integrate the banner system into your existing
/// home screen or dashboard.

class ClientHomeScreenExample extends StatelessWidget {
  const ClientHomeScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              _buildTopBar(context),
              const SizedBox(height: 20),

              // Banner Carousel - Auto-sliding with real-time updates
              BannerCarousel(
                onBannerTap: (category) {
                  // Navigate to category products
                  Navigator.pushNamed(
                    context,
                    '/products',
                    arguments: {'category': category},
                  );
                },
              ),
              const SizedBox(height: 32),

              // Categories Section
              _buildCategoriesSection(context),
              const SizedBox(height: 32),

              // Featured Products Section
              _buildFeaturedProductsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Profile Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.person_outline, color: Colors.white),
          ),
          const SizedBox(width: 12),

          // Search Bar
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Colors.white54),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search medicine',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Theme Toggle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.nightlight_round, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'See All',
                  style: TextStyle(color: Color(0xFF00D9C0), fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryCard(
                'Medicines',
                Icons.medication,
                const Color(0xFF3B82F6),
              ),
              _buildCategoryCard(
                'Devices',
                Icons.medical_services,
                const Color(0xFFA855F7),
              ),
              _buildCategoryCard(
                'Health',
                Icons.favorite,
                const Color(0xFFEF4444),
              ),
              _buildCategoryCard(
                'Vitamins',
                Icons.eco,
                const Color(0xFFEAB308),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String name, IconData icon, Color color) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProductsSection(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bestseller Products',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'See All',
                  style: TextStyle(color: Color(0xFF00D9C0), fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Add your product grid here
      ],
    );
  }
}
