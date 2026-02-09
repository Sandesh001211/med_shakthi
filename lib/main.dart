/*
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Riverpod
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Legacy Provider (aliased)
import 'package:provider/provider.dart' as legacy;

// Feature Imports
import 'package:med_shakthi/src/features/cart/data/cart_data.dart';
import 'package:med_shakthi/src/features/checkout/presentation/screens/AddressStore.dart';
import 'package:med_shakthi/src/features/auth/presentation/screens/login_page.dart';
import 'package:med_shakthi/src/features/dashboard/pharmacy_home_screen.dart';
import 'package:med_shakthi/src/features/dashboard/supplier_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(
    const ProviderScope(
      child: AppBootstrap(),
    ),
  );
}

/// ===============================================================
/// AppBootstrap
/// Combines legacy Provider + Riverpod
/// ===============================================================
class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return legacy.MultiProvider(
      providers: [
        legacy.ChangeNotifierProvider(create: (_) => CartData()),
        legacy.ChangeNotifierProvider(create: (_) => AddressStore()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Med Shakthi',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7F9),
      ),
      home: const AuthGate(),
    );
  }
}

/// ===============================================================
/// AUTH GATE
/// ===============================================================
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isSupplier = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('suppliers')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isSupplier = data != null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4C8077)),
        ),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4C8077)),
        ),
      );
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return const LoginPage();
    }

    return _isSupplier
        ? const SupplierDashboard()
        : const PharmacyHomeScreen();
  }
}
