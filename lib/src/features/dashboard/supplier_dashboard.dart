import 'package:flutter/material.dart';

import '../cart/presentation/screens/cart_page.dart';
import '../orders/orders_page.dart';
import '../profile/presentation/screens/chat_list_screen.dart';
import '../profile/presentation/screens/supplier_category_page.dart';
import '../profile/presentation/screens/supplier_payout_page.dart';
import '../profile/presentation/screens/supplier_profile_screen.dart';
import '../profile/presentation/screens/supplier_wishlist_page.dart';
import '../chat_support/chat_support_entry.dart';
import 'package:med_shakthi/src/features/chat_support/chat_support_entry.dart';

class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({super.key});
  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  late final List<Widget> _pages = [
    const SupplierDashboardHome(),
    ChatSupportEntryPage(
      isSupplierView: true, // 👈 IMPORTANT
    ),
    const OrdersPage(),
    const SupplierProfileScreen(),
  ];

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Drawer coming soon')),
            );
          },
        ),
        title: const Text(
          'Supplier Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ],
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chat Requests", // 👈 renamed
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _promoBanner(),
          const SizedBox(height: 25),
          _sectionTitle("Quick Actions"),
          const SizedBox(height: 15),
          _quickActions(),
          const SizedBox(height: 30),
          _sectionTitle("Performance"),
          const SizedBox(height: 15),
          _performanceGrid(),
        ],
      ),
    );
  }

  Widget _promoBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF63B4B7), Color(0xFF4CA6A8)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Supplier Growth",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Your monthly performance is improving",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D2D2D),
      ),
    );
  }

  Widget _quickActions() {
    final items = [
      {"icon": Icons.receipt_long, "label": "Orders"},
      {"icon": Icons.chat, "label": "Chats"},
      {"icon": Icons.account_balance_wallet, "label": "Payouts"},
      {"icon": Icons.analytics, "label": "Reports"},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((e) {
        return Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(e['icon'] as IconData, color: const Color(0xFF4CA6A8)),
            ),
            const SizedBox(height: 8),
            Text(
              e['label'] as String,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _performanceGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 0.85,
      children: const [
        _StatCard(title: "Revenue", value: "₹ 4.5L"),
        _StatCard(title: "Pending Orders", value: "14"),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bar_chart, color: Colors.grey),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CA6A8),
            ),
          ),
        ],
      ),
    );
  }
}
