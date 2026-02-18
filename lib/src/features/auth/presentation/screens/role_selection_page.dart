/*
import 'package:flutter/material.dart';
import 'package:med_shakthi/src/features/auth/presentation/screens/signup_page.dart';
import 'package:med_shakthi/src/features/auth/presentation/screens/supplier_signup_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Role'),
        backgroundColor: const Color(0xFF6AA39B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Text(
              'Are you a?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 40),

            _roleCard(
              context: context,
              title: 'Pharmacy / User',
              icon: Icons.local_pharmacy,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SignupPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            _roleCard(
              context: context,
              title: 'Supplier',
              icon: Icons.local_shipping,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SupplierSignupPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF6AA39B)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:med_shakthi/src/core/theme/theme_provider.dart';
import 'package:med_shakthi/src/features/auth/presentation/screens/signup_page.dart';
import 'package:med_shakthi/src/features/auth/presentation/screens/supplier_signup_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Choose Your Role"),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Text(
              "Select your role to continue",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "This will determine your dashboard and available features",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 40),

            _roleCard(
              context: context,
              title: "Pharmacy / User",
              subtitle: "Order medicines & manage purchases",
              icon: Icons.local_pharmacy,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SignupPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            _roleCard(
              context: context,
              title: "Supplier",
              subtitle: "Manage products & fulfill orders",
              icon: Icons.local_shipping,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SupplierSignupPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4C8077).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 30,
                color: const Color(0xFF4C8077),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
