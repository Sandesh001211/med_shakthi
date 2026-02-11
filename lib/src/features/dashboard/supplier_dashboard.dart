import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 🔁 converted to package imports
import 'package:med_shakthi/src/features/cart/presentation/screens/cart_page.dart';
import 'package:med_shakthi/src/features/orders/orders_page.dart';
import 'package:med_shakthi/src/features/profile/presentation/screens/supplier_category_page.dart';
import 'package:med_shakthi/src/features/profile/presentation/screens/supplier_payout_page.dart';
import 'package:med_shakthi/src/features/profile/presentation/screens/supplier_profile_screen.dart';
import 'package:med_shakthi/src/features/profile/presentation/screens/supplier_wishlist_page.dart';
import 'package:med_shakthi/src/features/supplier/inventory/ui/add_product_page.dart';
import 'package:med_shakthi/src/features/auth/presentation/screens/login_page.dart';

// ✅ NEW supplier chat entry point
import 'package:med_shakthi/src/features/chat_support/supplier_chat_support_entry.dart';

import '../orders/orders_page.dart';
import '../profile/presentation/screens/chat_list_screen.dart';
import '../profile/presentation/screens/supplier_category_page.dart';
import '../profile/presentation/screens/supplier_profile_screen.dart';
import '../profile/presentation/screens/supplier_payout_page.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../supplier/inventory/ui/add_product_page.dart';
import '../supplier/inventory/ui/my_products_page.dart';
import '../supplier/sales/sales_analytics_page.dart';

class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({super.key});
  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  int _selectedIndex = 0;
  final SupabaseClient supabase = Supabase.instance.client;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  late final List<Widget> _pages = [
    const SupplierDashboardHome(),
    const SupplierCategoryPage(),
    const SizedBox(), // Placeholder for center "Add" button which navigates instead of switching tabs
    const OrdersPage(),
    const MyProductsPage(),
  ];

  Future<void> _handleLogout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ✅ DRAWER
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: const Text('Supplier Shop'),
                accountEmail: Text(supabase.auth.currentUser?.email ?? ''),
                currentAccountPicture: const CircleAvatar(
                  child: Icon(Icons.store),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SupplierProfileScreen(),
                    ),
                  );
                },
              ),

              // 🔁 Messages → Supplier chat entry point
              ListTile(
                leading: const Icon(Icons.message_outlined),
                title: const Text('Messages'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SupplierChatSupportEntry(),
                    ),
                  );
                },
              ),

              const Spacer(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _handleLogout,
              ),
            ],
          ),
        ),
      ),

      //  FAB ADDED - Shows on ALL tabs!
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductPage()),
          );
        },
        backgroundColor: const Color(0xFF4CA6A8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Product", style: TextStyle(color: Colors.white)),
      ),

      body: SafeArea(child: _pages[_selectedIndex]),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4CA6A8),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Category"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: "Wishlist"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Order"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      // Removed FloatingActionButton as requested
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF4CA6A8),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          currentIndex: _selectedIndex == 2
              ? 0
              : _selectedIndex, // Prevent selecting "Add Product" visually if needed, but here we treat it as a tab
          onTap: (index) {
            if (index == 2) {
              // Center Tab - Add Product
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProductPage()),
              );
            } else {
              _onItemTapped(index);
            }
          },
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
          _buildPromoBanner(context),
          const SizedBox(height: 30),
          _buildSectionHeader("Categories", context: context),
          const SizedBox(height: 15),
          _buildCategoryList(context),
          const SizedBox(height: 30),
          _buildSectionHeader("Performance Stats", context: context),
          const SizedBox(height: 15),
          _buildPerformanceGrid(context),
          const SizedBox(height: 100),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Row(
      children: [
        Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.menu, color: Theme.of(context).iconTheme.color),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SupplierProfileScreen(),
              ),
            );
          },
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.person_outline,
              color: Theme.of(context).iconTheme.color,
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 15),

        Expanded(
          child: GestureDetector(
            onTap: () {
              // Navigate to search page or show search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search functionality coming soon'),
                ),
              );
            },
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Theme.of(
                      context,
                    ).iconTheme.color?.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Search products, orders...",
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),

        // Theme Toggle (Replaced Cart)
        GestureDetector(
          onTap: () {
            themeProvider.toggleTheme();
          },
          child: Stack(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).cardColor,
                child: Icon(Icons.shopping_cart_outlined, color: Theme.of(context).iconTheme.color),
              ),
              Positioned(
                right: 0,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: const Color(0xFF4CA6A8),
                  child: const Text("3", style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ),
            ],
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
        ),
      ],
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
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
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text("Supplier Growth", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text("Monthly payout is ready", style: TextStyle(color: Colors.white70)),
      ]),
    );
  }

  Widget _buildSectionHeader(String title, {BuildContext? context}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Text("See All", style: TextStyle(color: Color(0xFF4CA6A8), fontWeight: FontWeight.w600)),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context != null
                ? Theme.of(context).textTheme.bodyLarge?.color
                : const Color(0xFF2D2D2D),
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
      {"icon": Icons.inventory_2, "label": "Orders"},
      {"icon": Icons.analytics, "label": "Sales"},
      {"icon": Icons.people, "label": "Clients"},
      {"icon": Icons.account_balance_wallet, "label": "Payouts"},
    ];

    return SizedBox(
      height: 95,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 25),
        itemBuilder: (context, index) {
          final label = cats[index]['label'] as String;
          final icon = cats[index]['icon'] as IconData;

          return InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () {
              if (label == "Clients") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SupplierChatSupportEntry()),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF4CA6A8)),
                ),
                const SizedBox(height: 8),
                Text(label),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
    return const SizedBox.shrink();
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.bar_chart, color: Colors.grey, size: 40),
          ),
          const SizedBox(height: 10),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
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
