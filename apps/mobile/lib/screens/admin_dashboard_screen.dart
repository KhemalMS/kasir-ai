import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../utils/platform_helper_web.dart' if (dart.library.io) '../utils/platform_helper_stub.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../utils/web_print.dart' if (dart.library.io) '../utils/web_print_stub.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';
import 'staff_management_screen.dart';

import 'admin_dashboard/tabs/dashboard_tab.dart';
import 'admin_dashboard/tabs/products_tab.dart';
import 'admin_dashboard/tabs/bahan_baku_tab.dart';
import 'admin_dashboard/tabs/pengaturan_tab.dart';
import 'sales_report_screen.dart';
import 'advanced_analytics_screen.dart';

// Safe numeric conversion — API sometimes returns String values
num _n(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0;

  // Opsi C: Lazy loading
  final _visitedTabs = <int>{0};

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDark;
    final bgColor = isDark ? AppTheme.bgDark : AppTheme.bgLight;
    final sidebarColor = isDark ? AppTheme.cardDark : Colors.white;
    final borderColor = isDark ? AppTheme.surfaceDark : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : AppTheme.textDark;

    final tabs = [
      {'icon': Icons.dashboard, 'label': settings.t('dashboard')},
      {'icon': Icons.inventory_2, 'label': settings.t('products')},
      {'icon': Icons.people, 'label': settings.t('staff')},
      {'icon': Icons.assessment, 'label': settings.t('reports')},
      {'icon': Icons.kitchen, 'label': settings.t('raw_materials')},
      {'icon': Icons.insights, 'label': 'Analitik'},
      {'icon': Icons.settings, 'label': settings.t('settings')},
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 220,
              decoration: BoxDecoration(
                color: sidebarColor,
                border: Border(right: BorderSide(color: borderColor)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.point_of_sale, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text('Kasir-AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 8),
                  ...List.generate(tabs.length, (i) {
                    final tab = tabs[i];
                    final isActive = _selectedTab == i;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: Material(
                        color: isActive ? AppTheme.primary.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() {
                            _selectedTab = i;
                            _visitedTabs.add(i);
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Icon(tab['icon'] as IconData, size: 20,
                                  color: isActive ? AppTheme.primary : AppTheme.textMuted),
                                const SizedBox(width: 12),
                                Text(tab['label'] as String,
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                    color: isActive ? Colors.white : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.person, size: 20, color: Colors.blue),
                              SizedBox(width: 12),
                              Text('Profil Akun', style: TextStyle(fontSize: 14, color: Colors.blue)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          await context.read<AuthProvider>().signOut();
                          if (mounted) Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 20, color: AppTheme.danger),
                              SizedBox(width: 12),
                              Text('Keluar', style: TextStyle(fontSize: 14, color: AppTheme.danger)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  DashboardTab(),
                  _visitedTabs.contains(1) ? ProductsTab() : const SizedBox.shrink(),
                  _visitedTabs.contains(2) ? const StaffManagementScreen() : const SizedBox.shrink(),
                  _visitedTabs.contains(3) ? SalesReportScreen() : const SizedBox.shrink(),
                  _visitedTabs.contains(4) ? const BahanBakuTab() : const SizedBox.shrink(),
                  _visitedTabs.contains(5) ? const AdvancedAnalyticsScreen() : const SizedBox.shrink(),
                  _visitedTabs.contains(6) ? const PengaturanTab() : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
