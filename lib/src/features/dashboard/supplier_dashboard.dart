import 'package:flutter/material.dart';
import '../orders/orders_page.dart';
import '../profile/presentation/screens/chat_list_screen.dart';
import '../profile/presentation/screens/supplier_category_page.dart';
import '../profile/presentation/screens/supplier_payout_page.dart';
import '../banners/screens/manage_banners_screen.dart';
import '../profile/presentation/screens/supplier_profile_screen.dart';
import '../supplier/inventory/ui/add_product_page.dart';
import '../supplier/orders/supplier_orders_page.dart'; // Import the new page
import '../supplier/sales/sales_analytics_page.dart';
import '../../core/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import '../supplier/inventory/ui/my_products_page.dart';
import '../supplier/sales/sales_stats_service.dart';

class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({super.key});
  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddProductPage()),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  late final List<Widget> _pages = [
    const SupplierDashboardHome(),
    const SupplierCategoryPage(),
    const SizedBox(), // Placeholder for Add Product (handled by onTap)
    const SupplierOrdersPage(), // Updated to SupplierOrdersPage
    const MyProductsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4CA6A8),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled, size: 26),
            label: "Home",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view, size: 26),
            label: "Category",
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF4CA6A8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
            label: "",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long, size: 26),
            label: "Order",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined, size: 26),
            label: "My Products",
          ),
        ],
      ),
    );
  }
}

class SupplierDashboardHome extends StatelessWidget {
  const SupplierDashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildTopBar(context),
          const SizedBox(height: 20),
          _buildPromoBanner(),
          const SizedBox(height: 30),
          _buildSectionHeader(context, "Categories"),
          const SizedBox(height: 15),
          _buildCategoryList(context),
          const SizedBox(height: 30),
          _buildSectionHeader(context, "Performance Stats"),
          const SizedBox(height: 15),
          _buildPerformanceGrid(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupplierProfileScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.person_outline,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ),
        const SizedBox(width: 15),

        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                hintText: "Search analytics...",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),

        const SizedBox(width: 15),

        // Theme Toggle (Replaced Cart)
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return GestureDetector(
              onTap: () {
                themeProvider.toggleTheme();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return FutureBuilder<Map<String, dynamic>>(
      future: SalesStatsService().fetchSalesStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildBannerContainer(
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        // Default values if error or empty
        final growth = snapshot.data?['growth'] ?? 0.0;
        final revenue = snapshot.data?['totalRevenue'] ?? 0.0;

        return _buildBannerContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Supplier Growth",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "+$growth%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Total Revenue: ₹${revenue.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SalesAnalyticsPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4CA6A8),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: const Text("View Report"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBannerContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF63B4B7), Color(0xFF4CA6A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CA6A8).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const Text(
          "See All",
          style: TextStyle(
            color: Color(0xFF4CA6A8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(BuildContext context) {
    final List<Map<String, dynamic>> cats = [
      {
        'icon': Icons.inventory,
        'name': 'Inventory',
        'page': const MyProductsPage(),
      },
      {
        'icon': Icons.shopping_bag,
        'name': 'Orders',
        'page': const SupplierOrdersPage(),
      },
      {
        'icon': Icons.analytics,
        'name': 'Analytics',
        'page': const SalesAnalyticsPage(),
      },
      {
        'icon': Icons.campaign,
        'name': 'Banners',
        'page': const ManageBannersScreen(),
      },
      {
        'icon': Icons.account_balance_wallet,
        'name': 'Payouts',
        'page': const SupplierPayoutPage(),
      },
    ];

    return SizedBox(
      height: 95,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 25),
        itemBuilder: (context, index) {
          final label = cats[index]['label'];

          return InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () {
              //  NAVIGATION LOGIC
              if (label == "Banners") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageBannersScreen(),
                  ),
                );
              } else if (label == "Orders") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersPage()),
                );
              } else if (label == "Clients") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              } else if (label == "Payouts") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupplierPayoutPage()),
                );
              } else if (label == "Sales") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalesAnalyticsPage()),
                );
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cats[index]['icon'],
                    color: const Color(0xFF4CA6A8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformanceGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 0.80,
      children: [
        _statItem(context, "Revenue", "₹ 4.5L", "Supplements", "+12%"),
        _statItem(context, "Pending", "14 Units", "Medicine", "Alert"),
      ],
    );
  }

  Widget _statItem(
    BuildContext context,
    String title,
    String value,
    String sub,
    String badge,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 55,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.bar_chart, color: Colors.grey, size: 40),
          ),
          const SizedBox(height: 10),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF4CA6A8),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CA6A8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4CA6A8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
