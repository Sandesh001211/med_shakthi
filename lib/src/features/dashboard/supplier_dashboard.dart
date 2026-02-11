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
    const SupplierWishlistPage(),
    const OrdersPage(),
    const SupplierProfileScreen(),
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
          _buildSectionHeader("Categories"),
          const SizedBox(height: 15),
          _buildCategoryList(context),
          const SizedBox(height: 30),
          _buildSectionHeader("Performance Stats"),
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
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            );
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

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Text("See All", style: TextStyle(color: Color(0xFF4CA6A8), fontWeight: FontWeight.w600)),
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformanceGrid(BuildContext context) {
    return const SizedBox.shrink();
  }
}
