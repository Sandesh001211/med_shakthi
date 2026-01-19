import 'package:flutter/material.dart';
import 'package:med_shakthi/src/features/products/presentation/screens/add_product.dart';
import 'package:med_shakthi/src/features/auth/presentation/screens/login_page.dart';
import 'package:med_shakthi/src/features/supplier/orders/supplier_orders_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupplierDashboardPage extends StatefulWidget {
  const SupplierDashboardPage({super.key});

  @override
  State<SupplierDashboardPage> createState() => _SupplierDashboardPageState();
}

class _SupplierDashboardPageState extends State<SupplierDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),

                  _buildStatsGrid(),
                  const SizedBox(height: 32),

                  _buildSectionTitle("Quick Actions"),
                  const SizedBox(height: 16),
                  _buildQuickActions(),

                  const SizedBox(height: 32),
                  _buildSectionTitle("Orders Placed"),
                  const SizedBox(height: 16),
                  _buildRealtimeOrders(),

                  const SizedBox(height: 32),
                  _buildSectionTitle("Sales Insights"),
                  const SizedBox(height: 16),
                  _buildSalesInsightsCard(),

                  const SizedBox(height: 32),
                  _buildSectionTitle("Inventory Alerts"),
                  const SizedBox(height: 16),
                  _buildInventoryAlertsList(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductPage()),
          );
        },
        backgroundColor: const Color(0xFF4F8F87),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Product", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ---------------- APP BAR ----------------
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: const FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          "Supplier Dashboard",
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
        ),
      ],
    );
  }

  // ---------------- SECTIONS ----------------
  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text("Hello, MedShakthi Supplier",
            style: TextStyle(color: Colors.grey)),
        SizedBox(height: 4),
        Text("Manage your items efficiently",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: const [
        _StatCard("Total Products", "128", Icons.inventory_2_outlined, Colors.blue),
        _StatCard("Active Orders", "14", Icons.shopping_cart_outlined, Colors.orange),
        _StatCard("Revenue", "₹45.2k", Icons.wallet, Colors.green),
        _StatCard("Low Stock", "8", Icons.warning, Colors.red),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (title == "Orders Placed")
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupplierOrdersPage()),
              );
            },
            child: const Text("View All"),
          ),
      ],
    );
  }

  // ---------------- QUICK ACTIONS ----------------
  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildActionButton("Inventory", Icons.list_alt, Colors.purple),
        const SizedBox(width: 12),
        _buildActionButton("Add New", Icons.add_box, Colors.teal),
        const SizedBox(width: 12),
        _buildActionButton("Shipments", Icons.local_shipping, Colors.indigo),
        const SizedBox(width: 12),
        _buildActionButton("Settings", Icons.settings, Colors.blueGrey),
      ],
    );
  }

  // ---------------- REALTIME ORDERS ----------------
  Widget _buildRealtimeOrders() {
    final supabase = Supabase.instance.client;
    final supplierId = supabase.auth.currentUser!.id;

    return StreamBuilder<List<Map<String, dynamic>>>(
  stream: Supabase.instance.client
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('supplier_id', Supabase.instance.client.auth.currentUser!.id)
      .order('created_at', ascending: false),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }

    final orders = snapshot.data!;
    return Text("Orders: ${orders.length}");
  },
);

  }

  // ---------------- OTHERS ----------------
  Widget _buildActionButton(String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesInsightsCard() => Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF4F8F87),
          borderRadius: BorderRadius.circular(20),
        ),
      );

  Widget _buildInventoryAlertsList() => const Text("Inventory alerts here");
}

// ---------------- STAT CARD ----------------
class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
