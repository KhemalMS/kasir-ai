import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/app_theme.dart';
import 'config/api_config.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/login_screen.dart';
import 'screens/mulai_shift_screen.dart';
import 'screens/kasir_screen.dart';
import 'screens/tutup_shift_screen.dart';
import 'screens/kitchen_display_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'providers/staff_provider.dart';
import 'screens/staff_management_screen.dart';
import 'screens/staff_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/staff_form_screen.dart'; // Still needed for compilation if used, but maybe not in routes

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Tangkap error UI / Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FLUTTER ERROR] ${details.exceptionAsString()}');
  };

  // Tangkap error asinkron / Dart
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[DART ERROR] $error\n$stack');
    return true;
  };

  await initializeDateFormatting('id_ID', null);
  await ApiConfig.loadSavedUrl();
  
  // Auto-detect server if no manual URL saved
  final prefs = await SharedPreferences.getInstance();
  final hasManualUrl = prefs.getString('api_base_url') != null;
  if (!hasManualUrl) {
    await ApiConfig.autoDetect();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
      ],
      child: const KasirAIApp(),
    ),
  );
}

class KasirAIApp extends StatelessWidget {
  const KasirAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) => MaterialApp(
        title: 'Kasir-AI',
        debugShowCheckedModeBanner: kDebugMode,
        theme: settings.isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: const AuthWrapper(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/mulai-shift': (_) => const MulaiShiftScreen(),
          '/kasir': (_) => const KasirScreen(),
          '/tutup-shift': (_) => const TutupShiftScreen(),
          '/kitchen': (_) => const KitchenDisplayScreen(),
          '/admin': (_) => const AdminDashboardScreen(),
          '/staff': (_) => const StaffManagementScreen(),
          '/staff/detail': (ctx) {
            final args = ModalRoute.of(ctx)?.settings.arguments;
            if (args is! String) {
              return const Scaffold(body: Center(child: Text('Error: ID Staff tidak valid')));
            }
            return StaffDetailScreen(staffId: args);
          },
        },
      ),
    );
  }
}

/// Checks auth state and redirects accordingly
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuth();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.point_of_sale, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Kasir-AI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Point of Sale Cerdas',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      if (auth.userRole == 'admin') {
        return const AdminDashboardScreen();
      }
      if (auth.userRole == 'dapur') {
        return const KitchenDisplayScreen();
      }
      return const MulaiShiftScreen();
    }

    return const LoginScreen();
  }
}
