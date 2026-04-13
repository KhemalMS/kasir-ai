import 'package:flutter/material.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await ApiConfig.loadSavedUrl();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
        debugShowCheckedModeBanner: false,
        theme: settings.isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: const AuthWrapper(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/mulai-shift': (_) => const MulaiShiftScreen(),
          '/kasir': (_) => const KasirScreen(),
          '/tutup-shift': (_) => const TutupShiftScreen(),
          '/kitchen': (_) => const KitchenDisplayScreen(),
          '/admin': (_) => const AdminDashboardScreen(),
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

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();

    if (auth.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                settings.t('loading'),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],
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
