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

// Safe numeric conversion — API sometimes returns String values
num _n(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _formatter = NumberFormat('#,###', 'id_ID');
  int _selectedTab = 0;


  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDark;
    final bgColor = isDark ? AppTheme.bgDark : AppTheme.bgLight;
    final sidebarColor = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : AppTheme.textDark;


    final tabs = [
      {'icon': Icons.dashboard, 'label': settings.t('dashboard')},
      {'icon': Icons.inventory_2, 'label': settings.t('products')},
      {'icon': Icons.people, 'label': settings.t('staff')},
      {'icon': Icons.assessment, 'label': settings.t('reports')},
      {'icon': Icons.kitchen, 'label': settings.t('raw_materials')},
      {'icon': Icons.settings, 'label': settings.t('settings')},
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar
            Container(
              width: 220,
              decoration: BoxDecoration(
                color: sidebarColor,
                border: Border(right: BorderSide(color: borderColor)),
              ),
              child: Column(
                children: [
                  // Logo
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
                  // Nav items
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
                          onTap: () => setState(() => _selectedTab = i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Icon(tab['icon'] as IconData, size: 20,
                                  color: isActive ? AppTheme.primary : const Color(0xFF9CA3AF)),
                                const SizedBox(width: 12),
                                Text(tab['label'] as String,
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                    color: isActive ? Colors.white : const Color(0xFF9CA3AF),
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
                  // Logout
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
            // Content
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _DashboardTab(formatter: _formatter),
                  _ProdukTab(formatter: _formatter),
                  const _StaffTab(),
                  _LaporanTab(formatter: _formatter),
                  const _BahanBakuTab(),
                  const _PengaturanTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1: DASHBOARD
// ══════════════════════════════════════════════════════════════════
class _DashboardTab extends StatefulWidget {
  final NumberFormat formatter;
  const _DashboardTab({required this.formatter});
  @override State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Map<String, dynamic>? _daily;
  List<dynamic> _topProducts = [];
  List<dynamic> _revenueChart = [];
  List<dynamic> _hourlyChart = [];
  List<dynamic> _monthlyChart = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/reports/daily'),
        ApiService.getList('/reports/top-products?limit=5'),
        ApiService.getList('/reports/revenue-chart?days=7'),
        ApiService.getList('/reports/hourly'),
        ApiService.getList('/reports/monthly'),
      ]);
      if (mounted) setState(() {
        _daily = results[0] as Map<String, dynamic>;
        _topProducts = results[1] as List;
        _revenueChart = results[2] as List;
        _hourlyChart = results[3] as List;
        _monthlyChart = results[4] as List;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Ringkasan hari ini • ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 24),

          // Summary cards (2 cards: Pendapatan + Transaksi)
          Row(
            children: [
              _summaryCard('Total Pendapatan', 'Rp ${widget.formatter.format(_n(_daily?['totalRevenue']))}',
                Icons.account_balance_wallet, AppTheme.success),
              const SizedBox(width: 16),
              _summaryCard('Transaksi', '${_daily?['totalTransactions'] ?? 0}',
                Icons.receipt_long, AppTheme.primary),
            ],
          ),
          const SizedBox(height: 24),

          // Hourly revenue chart
          _sectionCard(
            title: 'Pendapatan Per Jam (Hari Ini)',
            icon: Icons.access_time,
            child: SizedBox(
              height: 200,
              child: _hourlyChart.isEmpty
                ? const Center(child: Text('Belum ada data', style: TextStyle(color: AppTheme.textMuted)))
                : _buildHourlyChart(),
            ),
          ),
          const SizedBox(height: 16),

          // Monthly revenue chart
          _sectionCard(
            title: 'Pendapatan Per Bulan (${DateTime.now().year})',
            icon: Icons.calendar_month,
            child: SizedBox(
              height: 200,
              child: _monthlyChart.isEmpty
                ? const Center(child: Text('Belum ada data', style: TextStyle(color: AppTheme.textMuted)))
                : _buildMonthlyChart(),
            ),
          ),
          const SizedBox(height: 16),

          // Revenue 7 days chart
          _sectionCard(
            title: 'Pendapatan 7 Hari Terakhir',
            icon: Icons.bar_chart,
            child: SizedBox(
              height: 180,
              child: _revenueChart.isEmpty
                ? const Center(child: Text('Belum ada data', style: TextStyle(color: AppTheme.textMuted)))
                : _buildDailyChart(),
            ),
          ),
          const SizedBox(height: 16),

          // Top products
          _sectionCard(
            title: 'Produk Terlaris',
            icon: Icons.emoji_events,
            child: _topProducts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Belum ada data', style: TextStyle(color: AppTheme.textMuted)),
                )
              : Column(
                  children: List.generate(_topProducts.length, (i) {
                    final p = _topProducts[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                        child: Text('${i + 1}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                      ),
                      title: Text(p['productName'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      subtitle: Text('${p['totalQuantity'] ?? 0} terjual', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      trailing: Text('Rp ${widget.formatter.format(_n(p['totalRevenue']))}',
                        style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600)),
                    );
                  }),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart() {
    final maxVal = _hourlyChart.fold<double>(0, (m, e) {
      final v = (e['totalRevenue'] ?? 0).toDouble();
      return v > m ? v : m;
    });
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _hourlyChart.map<Widget>((e) {
          final val = (e['totalRevenue'] ?? 0).toDouble();
          final ratio = maxVal > 0 ? val / maxVal : 0.0;
          final hour = e['hour'] as int? ?? 0;
          final hasValue = val > 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: (150 * ratio).clamp(3, 150).toDouble(),
                    decoration: BoxDecoration(
                      color: hasValue ? const Color(0xFF22C55E).withValues(alpha: 0.7) : const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(hour % 3 == 0 ? hour.toString().padLeft(2, '0') : '',
                    style: const TextStyle(fontSize: 8, color: AppTheme.textMuted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyChart() {
    final maxVal = _monthlyChart.fold<double>(0, (m, e) {
      final v = (e['totalRevenue'] ?? 0).toDouble();
      return v > m ? v : m;
    });
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _monthlyChart.map<Widget>((e) {
          final val = (e['totalRevenue'] ?? 0).toDouble();
          final ratio = maxVal > 0 ? val / maxVal : 0.0;
          final label = e['label']?.toString() ?? '';
          final hasValue = val > 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasValue) Text(widget.formatter.format(val.toInt()),
                    style: const TextStyle(fontSize: 8, color: AppTheme.textMuted)),
                  const SizedBox(height: 2),
                  Container(
                    height: (145 * ratio).clamp(3, 145).toDouble(),
                    decoration: BoxDecoration(
                      color: hasValue ? AppTheme.primary.withValues(alpha: 0.7) : const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDailyChart() {
    final maxVal = _revenueChart.fold<double>(0, (m, e) {
      final v = (e['totalRevenue'] ?? 0).toDouble();
      return v > m ? v : m;
    });
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _revenueChart.map<Widget>((e) {
        final val = (e['totalRevenue'] ?? 0).toDouble();
        final ratio = maxVal > 0 ? val / maxVal : 0.0;
        final date = e['date']?.toString() ?? '';
        final dayLabel = date.length >= 10 ? date.substring(8, 10) : '';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(widget.formatter.format(val.toInt()), style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                Container(
                  height: (140 * ratio).clamp(4, 140).toDouble(),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(dayLabel, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1F2937)),
          child,
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 2: PRODUK & KATEGORI
// ══════════════════════════════════════════════════════════════════
class _ProdukTab extends StatefulWidget {
  final NumberFormat formatter;
  const _ProdukTab({required this.formatter});
  @override State<_ProdukTab> createState() => _ProdukTabState();
}

class _ProdukTabState extends State<_ProdukTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getList('/products?includeInactive=true'),
        ApiService.getList('/categories'),
      ]);
      if (mounted) setState(() {
        _products = results[0];
        _categories = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showProductDialog([Map<String, dynamic>? product]) {
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final codeCtrl = TextEditingController(text: product?['code'] ?? '');
    final unitCtrl = TextEditingController(text: product?['unit'] ?? '');
    final basePriceCtrl = TextEditingController(text: '${product?['basePrice'] ?? product?['price'] ?? ''}');
    final markupCtrl = TextEditingController(text: '${product?['markup'] ?? '0'}');
    final sellingPriceCtrl = TextEditingController(text: '${product?['price'] ?? ''}');
    String? categoryId = product?['categoryId'];
    String? imageUrl = product?['imageUrl'];
    bool isUploading = false;
    bool isActive = product?['isActive'] ?? true;
    bool taxInclusive = product?['taxInclusive'] ?? false;

    // Auto-calc selling price from basePrice + markup
    void _calcSellingPrice() {
      final base = int.tryParse(basePriceCtrl.text) ?? 0;
      final mkp = double.tryParse(markupCtrl.text) ?? 0;
      final selling = (base * (1 + mkp / 100)).round();
      sellingPriceCtrl.text = '$selling';
    }

    // Reverse-calc markup from selling price
    void _calcMarkup() {
      final base = int.tryParse(basePriceCtrl.text) ?? 0;
      final selling = int.tryParse(sellingPriceCtrl.text) ?? 0;
      if (base > 0) {
        final mkp = ((selling - base) / base * 100);
        markupCtrl.text = mkp.toStringAsFixed(1);
      }
    }

    // Variants state
    List<Map<String, dynamic>> variants = [];


    if (product != null) {
      final existing = product['variants'] as List<dynamic>? ?? [];
      if (existing.isNotEmpty) {
        variants = existing.map((v) => <String, dynamic>{
          'id': v['id'], 'name': v['name'] ?? '', 'priceModifier': v['priceModifier'] ?? 0,
        }).toList();
      } else {
        ApiService.getList('/products/${product['id']}/variants').then((list) {
          variants = list.map((v) => <String, dynamic>{
            'id': v['id'], 'name': v['name'] ?? '', 'priceModifier': v['priceModifier'] ?? 0,
          }).toList();
        }).catchError((_) {});
      }
    }

    showDialog(context: context, builder: (ctx) {
      final settings = ctx.read<SettingsProvider>();
      final isDark = settings.isDark;
      final bgColor = isDark ? const Color(0xFF111827) : Colors.white;
      final textColor = isDark ? Colors.white : AppTheme.textDark;
      final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
      final fieldBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9);
      final borderCol = isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0);

      InputDecoration _inputDeco(String label, {String? prefix, String? hint}) => InputDecoration(
        labelText: label, labelStyle: TextStyle(color: mutedColor, fontSize: 13),
        hintText: hint, hintStyle: TextStyle(color: mutedColor.withValues(alpha: 0.5), fontSize: 12),
        prefixText: prefix, prefixStyle: TextStyle(color: mutedColor, fontSize: 13),
        isDense: true, filled: true, fillColor: fieldBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );

      return StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: bgColor,
        title: Row(children: [
          Expanded(child: Text(product == null ? settings.t('add_product') : settings.t('edit_product'),
            style: TextStyle(color: textColor))),
          IconButton(onPressed: () => Navigator.pop(ctx),
            icon: Icon(Icons.close, color: mutedColor, size: 20)),
        ]),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image Upload ──
              GestureDetector(
                onTap: () {
                  if (!kIsWeb) return;
                  webPickFile(
                    accept: 'image/*',
                    onPicked: (fileName, bytes) async {
                      setS(() => isUploading = true);
                      try {
                        final apiBase = ApiConfig.baseUrl.replaceAll('/api', '');
                        final uri = Uri.parse('$apiBase/api/upload');
                        final request = http.MultipartRequest('POST', uri);
                        final cookie = await ApiService.getSessionCookie();
                        if (cookie != null) {
                          final token = cookie.contains('=') ? cookie.split('=').sublist(1).join('=') : cookie;
                          request.headers['Authorization'] = 'Bearer $token';
                        }
                        request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: fileName,
                          contentType: MediaType('image', fileName.split('.').last)));
                        final resp = await request.send();
                        final body = await resp.stream.bytesToString();
                        final json = jsonDecode(body);
                        setS(() { imageUrl = json['imageUrl']; isUploading = false; });
                      } catch (e) {
                        setS(() => isUploading = false);
                        debugPrint('Upload error: $e');
                      }
                    },
                  );
                },
                child: Container(
                  height: 140, width: double.infinity,
                  decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol)),
                  child: isUploading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : imageUrl != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12),
                          child: Image.network('${ApiConfig.baseUrl.replaceAll('/api', '')}$imageUrl',
                            fit: BoxFit.cover, width: double.infinity, height: 140,
                            errorBuilder: (_, __, ___) => _uploadPlaceholder(mutedColor, settings)))
                      : _uploadPlaceholder(mutedColor, settings),
                ),
              ),
              const SizedBox(height: 16),

              // ── Nama Produk ──
              TextField(controller: nameCtrl, style: TextStyle(color: textColor),
                decoration: _inputDeco('Nama Produk')),
              const SizedBox(height: 12),

              // ── Kode & Satuan (side by side) ──
              Row(children: [
                Expanded(child: TextField(controller: codeCtrl, style: TextStyle(color: textColor),
                  decoration: _inputDeco('Kode Produk', hint: 'SKU / barcode'))),
                const SizedBox(width: 10),
                SizedBox(width: 130, child: TextField(controller: unitCtrl, style: TextStyle(color: textColor),
                  decoration: _inputDeco('Satuan', hint: 'pcs, cup, porsi'))),
              ]),
              const SizedBox(height: 12),

              // ── Kategori & Aktif (side by side) ──
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: categoryId, dropdownColor: bgColor,
                  style: TextStyle(color: textColor),
                  decoration: _inputDeco(settings.t('category')),
                  items: _categories.map<DropdownMenuItem<String>>((c) =>
                    DropdownMenuItem(value: c['id'], child: Text(c['name']))).toList(),
                  onChanged: (v) => categoryId = v,
                )),
                const SizedBox(width: 10),
                Column(children: [
                  Text('Status', style: TextStyle(color: mutedColor, fontSize: 11)),
                  const SizedBox(height: 4),
                  Switch(
                    value: isActive,
                    activeColor: AppTheme.success,
                    onChanged: (v) => setS(() => isActive = v),
                  ),
                  Text(isActive ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: isActive ? AppTheme.success : AppTheme.danger)),
                ]),
              ]),

              // ── Section: Harga ──
              const SizedBox(height: 20),
              Row(children: [
                Icon(Icons.attach_money, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('Harga', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
              ]),
              const SizedBox(height: 10),

              // Harga Dasar & Markup
              Row(children: [
                Expanded(child: TextField(controller: basePriceCtrl, style: TextStyle(color: textColor),
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Harga Dasar', prefix: 'Rp '),
                  onChanged: (_) => setS(() => _calcSellingPrice()),
                )),
                const SizedBox(width: 10),
                SizedBox(width: 100, child: TextField(controller: markupCtrl, style: TextStyle(color: textColor),
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Markup', hint: '%'),
                  onChanged: (_) => setS(() => _calcSellingPrice()),
                )),
              ]),
              const SizedBox(height: 10),

              // Harga Jual & Pajak
              Row(children: [
                Expanded(child: TextField(controller: sellingPriceCtrl, style: TextStyle(color: textColor),
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Harga Jual', prefix: 'Rp '),
                  onChanged: (_) => setS(() => _calcMarkup()),
                )),
                const SizedBox(width: 10),
                Column(children: [
                  Text('Termasuk Pajak', style: TextStyle(color: mutedColor, fontSize: 10)),
                  const SizedBox(height: 2),
                  Switch(
                    value: taxInclusive,
                    activeColor: AppTheme.primary,
                    onChanged: (v) => setS(() => taxInclusive = v),
                  ),
                ]),
              ]),

              // ── Section: Variasi ──
              const SizedBox(height: 20),
              Row(children: [
                Icon(Icons.style, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('Variasi Produk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor))),
                TextButton.icon(
                  onPressed: () => setS(() => variants.add(<String, dynamic>{'id': null, 'name': '', 'priceModifier': 0})),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                ),
              ]),
              if (variants.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Belum ada variasi. Klik "Tambah" untuk menambahkan.',
                    style: TextStyle(fontSize: 12, color: mutedColor, fontStyle: FontStyle.italic))),
              ...variants.asMap().entries.map((entry) {
                final idx = entry.key;
                final v = entry.value;
                final vNameCtrl = TextEditingController(text: v['name'] ?? '');
                final vPriceCtrl = TextEditingController(text: '${v['priceModifier'] ?? 0}');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(flex: 3, child: TextField(controller: vNameCtrl,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: _inputDeco('Nama variasi'),
                      onChanged: (val) => variants[idx]['name'] = val)),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: TextField(controller: vPriceCtrl,
                      style: TextStyle(color: textColor, fontSize: 13),
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco('+/- Harga', prefix: 'Rp '),
                      onChanged: (val) => variants[idx]['priceModifier'] = int.tryParse(val) ?? 0)),
                    IconButton(icon: const Icon(Icons.remove_circle, color: AppTheme.danger, size: 20),
                      onPressed: () => setS(() => variants.removeAt(idx))),
                  ]),
                );
              }),
            ],
          )),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              try {
                final data = {
                  'name': nameCtrl.text,
                  'code': codeCtrl.text.isEmpty ? null : codeCtrl.text,
                  'unit': unitCtrl.text.isEmpty ? null : unitCtrl.text,
                  'basePrice': int.tryParse(basePriceCtrl.text) ?? 0,
                  'markup': double.tryParse(markupCtrl.text) ?? 0,
                  'price': int.tryParse(sellingPriceCtrl.text) ?? 0,
                  'taxInclusive': taxInclusive,
                  'isActive': isActive,
                  'categoryId': categoryId,
                  if (imageUrl != null) 'imageUrl': imageUrl,
                };
                String productId;
                if (product == null) {
                  final result = await ApiService.post('/products', data);
                  productId = result['id'];
                } else {
                  await ApiService.put('/products/${product['id']}', data);
                  productId = product['id'];
                }

                // Save variants
                if (product != null) {
                  final existingIds = (product['variants'] as List<dynamic>? ?? []).map((v) => v['id']).toSet();
                  final currentIds = variants.where((v) => v['id'] != null).map((v) => v['id']).toSet();
                  for (final removedId in existingIds.difference(currentIds)) {
                    try { await ApiService.delete('/products/$productId/variants/$removedId'); } catch (_) {}
                  }
                }
                for (final v in variants) {
                  final vData = {'name': v['name'], 'priceModifier': v['priceModifier'] ?? 0};
                  if (v['id'] != null) {
                    await ApiService.put('/products/$productId/variants/${v['id']}', vData);
                  } else {
                    await ApiService.post('/products/$productId/variants', vData);
                  }
                }

                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(settings.t('save')),
          ),
        ],
      ));
    });
  }

  Widget _uploadPlaceholder(Color mutedColor, SettingsProvider settings) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.cloud_upload_outlined, size: 36, color: mutedColor),
      const SizedBox(height: 8),
      Text(settings.t('upload_product_image'), style: TextStyle(color: mutedColor, fontSize: 13)),
      const SizedBox(height: 4),
      Text('JPG, PNG, WEBP (max 5MB)', style: TextStyle(color: mutedColor.withValues(alpha: 0.5), fontSize: 11)),
    ]);
  }

  void _showCategoryDialog([Map<String, dynamic>? cat]) {
    final nameCtrl = TextEditingController(text: cat?['name'] ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF111827),
      title: Row(
        children: [
          Text(cat == null ? 'Tambah Kategori' : 'Edit Kategori',
            style: const TextStyle(color: Colors.white)),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20)),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: TextField(controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Nama Kategori')),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            final data = {'name': nameCtrl.text};
            if (cat == null) {
              await ApiService.post('/categories', data);
            } else {
              await ApiService.put('/categories/${cat['id']}', data);
            }
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          },
          child: const Text('Simpan'),
        ),
      ],
    ));
  }

  Future<void> _deleteProduct(String id) async {
    await ApiService.delete('/products/$id');
    _load();
  }

  Future<void> _deleteCategory(String id) async {
    await ApiService.delete('/categories/$id');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              const Text('Produk & Kategori', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _tabCtrl.index == 0 ? _showProductDialog() : _showCategoryDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabCtrl,
            indicator: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.textMuted,
            dividerHeight: 0,
            tabs: const [Tab(text: 'Produk'), Tab(text: 'Kategori')],
            onTap: (_) => setState(() {}),
          ),
        ),
        // Search (for products tab)
        if (_tabCtrl.index == 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Content
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _tabCtrl.index == 0 ? _buildProductList() : _buildCategoryList(),
        ),
      ],
    );
  }

  Widget _buildProductList() {
    final filtered = _search.isEmpty ? _products
      : _products.where((p) => (p['name'] ?? '').toString().toLowerCase().contains(_search)).toList();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF1F2937)),
      itemBuilder: (ctx, i) {
        final p = filtered[i];
        final catName = _categories.firstWhere((c) => c['id'] == p['categoryId'], orElse: () => {'name': '-'})['name'];
        final isInactive = p['isActive'] == false;
        return Opacity(
          opacity: isInactive ? 0.5 : 1.0,
          child: ListTile(
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: p['imageUrl'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      '${ApiConfig.baseUrl.replaceAll('/api', '')}${p['imageUrl']}',
                      fit: BoxFit.cover, width: 42, height: 42,
                      errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, color: AppTheme.primary, size: 20),
                    ),
                  )
                : const Icon(Icons.fastfood, color: AppTheme.primary, size: 20),
            ),
            title: Row(children: [
              Expanded(child: Text(p['name'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
              if (isInactive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Nonaktif', style: TextStyle(fontSize: 9, color: AppTheme.danger, fontWeight: FontWeight.w600)),
                ),
            ]),
            subtitle: Text(
              '${p['code'] != null && p['code'].toString().isNotEmpty ? '${p['code']}  •  ' : ''}${catName ?? '-'}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Rp ${widget.formatter.format(_n(p['price']))}',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.edit, size: 18, color: AppTheme.textMuted),
                  onPressed: () => _showProductDialog(p)),
                IconButton(icon: const Icon(Icons.delete, size: 18, color: AppTheme.danger),
                  onPressed: () => _deleteProduct(p['id'])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF1F2937)),
      itemBuilder: (ctx, i) {
        final c = _categories[i];
        final count = _products.where((p) => p['categoryId'] == c['id']).length;
        return ListTile(
          leading: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: const Color(0xFFFF6B35).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.category, color: Color(0xFFFF6B35), size: 20),
          ),
          title: Text(c['name'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          subtitle: Text('$count produk', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 18, color: AppTheme.textMuted),
                onPressed: () => _showCategoryDialog(c)),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: AppTheme.danger),
                onPressed: () => _deleteCategory(c['id'])),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 3: STAFF
// ══════════════════════════════════════════════════════════════════
class _StaffTab extends StatefulWidget {
  const _StaffTab();
  @override State<_StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<_StaffTab> {
  List<dynamic> _staffList = [];
  List<String> _roles = ['Admin', 'Kasir', 'Dapur'];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _staffList = await ApiService.getList('/staff');
      // Collect unique roles from staff and merge with defaults
      final staffRoles = _staffList
        .map((s) => s['role']?.toString() ?? '')
        .where((r) => r.isNotEmpty)
        .toSet();
      final merged = {..._roles, ...staffRoles}.toList()..sort();
      _roles = merged;
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showStaffDialog([Map<String, dynamic>? staff]) {
    final nameCtrl = TextEditingController(text: staff?['name'] ?? '');
    final emailCtrl  = TextEditingController(text: staff?['email'] ?? '');
    String role = staff?['role'] ?? (_roles.isNotEmpty ? _roles.first : 'Kasir');

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF111827),
      title: Row(
        children: [
          Text(staff == null ? 'Tambah Staff' : 'Edit Staff',
            style: const TextStyle(color: Colors.white)),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Nama')),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _roles.contains(role) ? role : (_roles.isNotEmpty ? _roles.first : null),
              dropdownColor: const Color(0xFF111827),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Role'),
              items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => role = v ?? role,
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            final data = {
              'name': nameCtrl.text,
              'email': emailCtrl.text,
              'role': role,
              'branchId': context.read<AuthProvider>().branchId,
            };
            if (staff == null) {
              await ApiService.post('/staff', data);
            } else {
              await ApiService.put('/staff/${staff['id']}', data);
            }
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          },
          child: const Text('Simpan'),
        ),
      ],
    ));
  }

  void _showRolesDialog() {
    showDialog(context: context, builder: (ctx) {
      final roleCtrl = TextEditingController();
      return StatefulBuilder(builder: (ctx2, setDialogState) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Row(
          children: [
            const Text('Kelola Role', style: TextStyle(color: Colors.white)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20)),
          ],
        ),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(controller: roleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Nama role baru...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      )),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final name = roleCtrl.text.trim();
                      if (name.isNotEmpty && !_roles.contains(name)) {
                        setState(() => _roles.add(name));
                        setDialogState(() {});
                        roleCtrl.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 42)),
                    child: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(_roles.length, (i) {
                final r = _roles[i];
                final usedBy = _staffList.where((s) => s['role'] == r).length;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: _roleColor(r).withValues(alpha: 0.15),
                    child: Text(r.isNotEmpty ? r[0] : '?', style: TextStyle(fontSize: 12, color: _roleColor(r), fontWeight: FontWeight.w700)),
                  ),
                  title: Text(r, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text('$usedBy staff', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  trailing: usedBy == 0
                    ? IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: AppTheme.danger),
                        onPressed: () {
                          setState(() => _roles.remove(r));
                          setDialogState(() {});
                        },
                      )
                    : null,
                );
              }),
            ],
          ),
        ),
      ));
    });
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Admin': return AppTheme.primary;
      case 'Kasir': return AppTheme.success;
      case 'Dapur': return const Color(0xFFFF6B35);
      default: return AppTheme.warning;
    }
  }

  Future<void> _confirmDeleteStaff(Map<String, dynamic> staff) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Row(
          children: [
            const Text('Hapus Akun', style: TextStyle(color: Colors.white)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(ctx, false),
              icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20)),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus staf ${staff['name']}?',
          style: const TextStyle(color: AppTheme.textMuted)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteStaff(staff['id']);
    }
  }

  Future<void> _deleteStaff(String id) async {
    await ApiService.delete('/staff/$id');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              const Text('Manajemen Staff', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _showRolesDialog,
                icon: const Icon(Icons.badge, size: 16),
                label: const Text('Kelola Role'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  minimumSize: const Size(0, 40),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showStaffDialog(),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Tambah Staff'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _staffList.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF1F2937)),
                itemBuilder: (ctx, i) {
                  final s = _staffList[i];
                  final role = s['role'] ?? 'Kasir';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _roleColor(role).withValues(alpha: 0.15),
                      child: Text((s['name']?.toString().isNotEmpty == true ? s['name'].toString() : 'S')[0].toUpperCase(),
                        style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.w700)),
                    ),
                    title: Text(s['name'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    subtitle: Text(s['email'] ?? '-', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _roleColor(role).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _roleColor(role).withValues(alpha: 0.3)),
                          ),
                          child: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _roleColor(role))),
                        ),
                        const SizedBox(width: 8),
                        IconButton(icon: const Icon(Icons.edit, size: 18, color: AppTheme.textMuted),
                          onPressed: () => _showStaffDialog(s)),
                        IconButton(icon: const Icon(Icons.delete, size: 18, color: AppTheme.danger),
                          onPressed: () => _confirmDeleteStaff(s)),
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 4: LAPORAN
// ══════════════════════════════════════════════════════════════════
class _LaporanTab extends StatefulWidget {
  final NumberFormat formatter;
  const _LaporanTab({required this.formatter});
  @override State<_LaporanTab> createState() => _LaporanTabState();
}

class _LaporanTabState extends State<_LaporanTab> {
  int _selectedReport = 0;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;

  // Data holders
  List<dynamic> _dailySales = [];
  List<dynamic> _hourlySales = [];
  List<dynamic> _hourlyProductSales = [];
  List<dynamic> _shiftReport = [];
  List<dynamic> _expenseReport = [];
  Map<String, dynamic>? _profitLoss;
  List<dynamic> _inventoryReport = [];
  List<dynamic> _orderHistory = [];

  final _reportNames = const [
    'Penjualan Harian',
    'Penjualan Per Jam',
    'Penjualan Per Jam/Produk',
    'Laporan Shift',
    'Pengeluaran',
    'Laba / Rugi',
    'Stok Bahan Baku',
    'Riwayat Transaksi',
  ];

  final _reportIcons = const [
    Icons.calendar_today,
    Icons.access_time,
    Icons.grid_view,
    Icons.point_of_sale,
    Icons.money_off,
    Icons.balance,
    Icons.inventory_2,
    Icons.receipt_long,
  ];

  @override
  void initState() { super.initState(); _loadReport(); }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final s = _fmt(_startDate);
      final e = _fmt(_endDate);
      switch (_selectedReport) {
        case 0:
          _dailySales = await ApiService.getList('/reports/daily-sales?start=$s&end=$e');
          break;
        case 1:
          _hourlySales = await ApiService.getList('/reports/hourly-sales?date=$s');
          break;
        case 2:
          _hourlyProductSales = await ApiService.getList('/reports/hourly-product-sales?date=$s');
          break;
        case 3:
          _shiftReport = await ApiService.getList('/reports/shift-report?start=$s&end=$e');
          break;
        case 4:
          _expenseReport = await ApiService.getList('/reports/expense-report?start=$s&end=$e');
          break;
        case 5:
          _profitLoss = await ApiService.get('/reports/profit-loss?start=$s&end=$e');
          break;
        case 6:
          _inventoryReport = await ApiService.getList('/reports/inventory-report');
          break;
        case 7:
          final s = _fmt(_startDate);
          final e2 = _fmt(_endDate.add(const Duration(days: 1)));
          _orderHistory = await ApiService.getList('/orders?startDate=$s&endDate=$e2');
          break;
      }
    } catch (err) {
      debugPrint('Report load error: $err');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
      _loadReport();
    }
  }

  void _exportCsv() {
    String csv = '';
    switch (_selectedReport) {
      case 0:
        csv = 'Tanggal,Transaksi,Pendapatan\n';
        for (final r in _dailySales) {
          csv += '${r['date']},${r['totalTransactions']},${r['totalRevenue']}\n';
        }
        break;
      case 1:
        csv = 'Jam,Transaksi,Pendapatan\n';
        for (final r in _hourlySales) {
          csv += '${r['label']},${r['totalTransactions']},${r['totalRevenue']}\n';
        }
        break;
      case 2:
        csv = 'Jam,Produk,Qty,Pendapatan\n';
        for (final r in _hourlyProductSales) {
          csv += '${r['label']},${r['productName']},${r['totalQuantity']},${r['totalRevenue']}\n';
        }
        break;
      case 3:
        csv = 'Kasir,Uang Awal,Uang Akhir,Selisih,Status,Mulai\n';
        for (final r in _shiftReport) {
          csv += '${r['staffName']},${r['startingCash']},${r['endingCash'] ?? '-'},${r['cashDifference'] ?? '-'},${r['status']},${r['startedAt']}\n';
        }
        break;
      case 4:
        csv = 'Tanggal,Kategori,Jumlah,Deskripsi,Staff\n';
        for (final r in _expenseReport) {
          csv += '${r['createdAt']},${r['category']},${r['amount']},${r['description'] ?? '-'},${r['staffName']}\n';
        }
        break;
      case 5:
        csv = 'Keterangan,Jumlah\n';
        csv += 'Pendapatan,${_profitLoss?['totalRevenue'] ?? 0}\n';
        csv += 'Pengeluaran,${_profitLoss?['totalExpenses'] ?? 0}\n';
        csv += 'Laba/Rugi,${_profitLoss?['profit'] ?? 0}\n';
        break;
      case 6:
        csv = 'Nama,SKU,Stok,Unit,Threshold,Status\n';
        for (final r in _inventoryReport) {
          csv += '${r['name']},${r['sku']},${r['quantity']},${r['unit']},${r['reorderThreshold']},${r['isCritical'] == true ? 'Kritis' : 'Aman'}\n';
        }
        break;
    }

    if (!kIsWeb) return;
    try {
      final csvBytes = Uint8List.fromList(csv.codeUnits);
      webDownloadFile(
        bytes: csvBytes,
        fileName: '${_reportNames[_selectedReport].replaceAll(' ', '_').replaceAll('/', '_')}_${_fmt(_startDate)}.csv',
        mimeType: 'text/csv;charset=utf-8',
      );
    } catch (e) {
      debugPrint('CSV export error: $e');
    }
  }

  void _exportPdf() async {
    final pdf = pw.Document();
    final reportName = _reportNames[_selectedReport];
    List<String> columns = [];
    List<List<String>> rows = [];

    switch (_selectedReport) {
      case 0:
        columns = ['Tanggal', 'Transaksi', 'Pendapatan'];
        rows = _dailySales.map((r) => [
          r['date']?.toString() ?? '-',
          '${r['totalTransactions'] ?? 0}',
          'Rp ${widget.formatter.format(_n(r['totalRevenue']))}',
        ]).toList();
        break;
      case 1:
        columns = ['Jam', 'Transaksi', 'Pendapatan'];
        rows = _hourlySales.map((r) => [
          r['label']?.toString() ?? '-',
          '${r['totalTransactions'] ?? 0}',
          'Rp ${widget.formatter.format(_n(r['totalRevenue']))}',
        ]).toList();
        break;
      case 2:
        columns = ['Jam', 'Produk', 'Qty', 'Pendapatan'];
        rows = _hourlyProductSales.map((r) => [
          r['label']?.toString() ?? '-',
          r['productName']?.toString() ?? '-',
          '${r['totalQuantity'] ?? 0}',
          'Rp ${widget.formatter.format(_n(r['totalRevenue']))}',
        ]).toList();
        break;
      case 3:
        columns = ['Kasir', 'Uang Awal', 'Uang Akhir', 'Selisih', 'Status'];
        rows = _shiftReport.map((r) => [
          r['staffName']?.toString() ?? '-',
          'Rp ${widget.formatter.format(_n(r['startingCash']))}',
          r['endingCash'] != null ? 'Rp ${widget.formatter.format(_n(r['endingCash']))}' : '-',
          r['cashDifference'] != null ? 'Rp ${widget.formatter.format(_n(r['cashDifference']))}' : '-',
          r['status']?.toString() ?? '-',
        ]).toList();
        break;
      case 4:
        columns = ['Tanggal', 'Kategori', 'Jumlah', 'Deskripsi', 'Staff'];
        rows = _expenseReport.map((r) => [
          r['createdAt']?.toString() ?? '-',
          r['category']?.toString() ?? '-',
          'Rp ${widget.formatter.format(_n(r['amount']))}',
          r['description']?.toString() ?? '-',
          r['staffName']?.toString() ?? '-',
        ]).toList();
        break;
      case 5:
        columns = ['Keterangan', 'Jumlah'];
        rows = [
          ['Pendapatan', 'Rp ${widget.formatter.format(_n(_profitLoss?['totalRevenue']))}'],
          ['Pengeluaran', 'Rp ${widget.formatter.format(_n(_profitLoss?['totalExpenses']))}'],
          ['Laba/Rugi', 'Rp ${widget.formatter.format(_n(_profitLoss?['profit']))}'],
        ];
        break;
      case 6:
        columns = ['Nama', 'SKU', 'Stok', 'Unit', 'Threshold', 'Status'];
        rows = _inventoryReport.map((r) => [
          r['name']?.toString() ?? '-',
          r['sku']?.toString() ?? '-',
          '${r['quantity'] ?? 0}',
          r['unit']?.toString() ?? '-',
          '${r['reorderThreshold'] ?? 0}',
          r['isCritical'] == true ? 'Kritis' : 'Aman',
        ]).toList();
        break;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(reportName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Periode: ${_fmt(_startDate)} s/d ${_fmt(_endDate)}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headers: columns,
            data: rows,
          ),
          pw.SizedBox(height: 12),
          pw.Text('Total: ${rows.length} baris', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        ],
      ),
    );

    if (!kIsWeb) return;
    try {
      final pdfBytes = await pdf.save();
      webDownloadFile(
        bytes: pdfBytes,
        fileName: '${reportName.replaceAll(' ', '_').replaceAll('/', '_')}_${_fmt(_startDate)}.pdf',
        mimeType: 'application/pdf',
      );
    } catch (e) {
      debugPrint('PDF export error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              const Text('Laporan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.success,
                  minimumSize: const Size(0, 40),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('Export PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  minimumSize: const Size(0, 40),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Report type selector
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _reportNames.length,
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(_reportIcons[i], size: 16,
                  color: _selectedReport == i ? Colors.white : AppTheme.textMuted),
                label: Text(_reportNames[i], style: const TextStyle(fontSize: 12)),
                selected: _selectedReport == i,
                selectedColor: AppTheme.primary,
                backgroundColor: const Color(0xFF1F2937),
                labelStyle: TextStyle(
                  color: _selectedReport == i ? Colors.white : AppTheme.textMuted,
                ),
                onSelected: (_) {
                  setState(() => _selectedReport = i);
                  _loadReport();
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Date filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range, size: 18, color: AppTheme.primary),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _pickDate(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(DateFormat('dd MMM yyyy', 'id_ID').format(_startDate),
                      style: const TextStyle(fontSize: 13, color: Colors.white)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('—', style: TextStyle(color: AppTheme.textMuted)),
                ),
                InkWell(
                  onTap: () => _pickDate(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(DateFormat('dd MMM yyyy', 'id_ID').format(_endDate),
                      style: const TextStyle(fontSize: 13, color: Colors.white)),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _loadReport,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 34)),
                  child: const Text('Tampilkan', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Report content
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildCurrentReport(),
              ),
        ),
      ],
    );
  }

  Widget _buildCurrentReport() {
    switch (_selectedReport) {
      case 0: return _buildDailySalesReport();
      case 1: return _buildHourlySalesReport();
      case 2: return _buildHourlyProductReport();
      case 3: return _buildShiftReport();
      case 4: return _buildExpenseReport();
      case 5: return _buildProfitLossReport();
      case 6: return _buildInventoryReport();
      case 7: return _buildOrderHistoryReport();
      default: return const SizedBox();
    }
  }

  // ─── Report Builders ──────────────────────────

  Widget _buildDailySalesReport() {
    if (_dailySales.isEmpty) return _emptyState('Tidak ada data penjualan');
    return _buildTable(
      columns: const ['Tanggal', 'Transaksi', 'Pendapatan'],
      rows: _dailySales.map((r) => [
        r['date']?.toString() ?? '-',
        '${r['totalTransactions'] ?? 0}',
        'Rp ${widget.formatter.format(_n(r['totalRevenue']))}',
      ]).toList(),
    );
  }

  Widget _buildHourlySalesReport() {
    if (_hourlySales.isEmpty) return _emptyState('Tidak ada data');
    return _buildTable(
      columns: const ['Jam', 'Transaksi', 'Pendapatan'],
      rows: _hourlySales.map((r) => [
        r['label']?.toString() ?? '-',
        '${r['totalTransactions'] ?? 0}',
        'Rp ${widget.formatter.format(_n(r['totalRevenue']))}',
      ]).toList(),
    );
  }

  Widget _buildHourlyProductReport() {
    if (_hourlyProductSales.isEmpty) return _emptyState('Tidak ada data');
    return _buildTable(
      columns: const ['Jam', 'Produk', 'Qty', 'Pendapatan'],
      rows: _hourlyProductSales.map((r) => [
        r['label']?.toString() ?? '-',
        r['productName']?.toString() ?? '-',
        '${r['totalQuantity'] ?? 0}',
        'Rp ${widget.formatter.format(_n(r['totalRevenue']))}',
      ]).toList(),
    );
  }

  Widget _buildShiftReport() {
    if (_shiftReport.isEmpty) return _emptyState('Tidak ada data shift');
    return _buildTable(
      columns: const ['Kasir', 'Uang Awal', 'Uang Akhir', 'Selisih', 'Status'],
      rows: _shiftReport.map((r) => [
        r['staffName']?.toString() ?? '-',
        'Rp ${widget.formatter.format(_n(r['startingCash']))}',
        r['endingCash'] != null ? 'Rp ${widget.formatter.format(_n(r['endingCash']))}' : '-',
        r['cashDifference'] != null ? 'Rp ${widget.formatter.format(_n(r['cashDifference']))}' : '-',
        r['status']?.toString() ?? '-',
      ]).toList(),
    );
  }

  Widget _buildExpenseReport() {
    if (_expenseReport.isEmpty) return _emptyState('Tidak ada pengeluaran');
    return _buildTable(
      columns: const ['Tanggal', 'Kategori', 'Jumlah', 'Deskripsi', 'Staff'],
      rows: _expenseReport.map((r) {
        String dateStr = '-';
        if (r['createdAt'] != null) {
          try { dateStr = DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(r['createdAt'].toString())); } catch (_) {}
        }
        return [
          dateStr,
          r['category']?.toString() ?? '-',
          'Rp ${widget.formatter.format(_n(r['amount']))}',
          r['description']?.toString() ?? '-',
          r['staffName']?.toString() ?? '-',
        ];
      }).toList(),
    );
  }

  Widget _buildProfitLossReport() {
    if (_profitLoss == null) return _emptyState('Tidak ada data');
    final revenue = _profitLoss!['totalRevenue'] ?? 0;
    final expenses = _profitLoss!['totalExpenses'] ?? 0;
    final profit = _profitLoss!['profit'] ?? 0;
    final isProfit = profit >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.balance, size: 48, color: AppTheme.primary),
          const SizedBox(height: 16),
          Text('Laporan Laba / Rugi', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('${_fmt(_startDate)} s/d ${_fmt(_endDate)}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 24),
          _plRow('Total Pendapatan', revenue, AppTheme.success),
          const Divider(color: Color(0xFF1F2937)),
          _plRow('Total Pengeluaran', expenses, AppTheme.danger),
          const Divider(color: Color(0xFF1F2937), thickness: 2),
          const SizedBox(height: 8),
          _plRow(isProfit ? 'LABA BERSIH' : 'RUGI BERSIH', profit, isProfit ? AppTheme.success : AppTheme.danger, isBold: true),
        ],
      ),
    );
  }

  Widget _plRow(String label, dynamic value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? color : Colors.white,
          )),
          const Spacer(),
          Text('Rp ${widget.formatter.format(_n(value))}', style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          )),
        ],
      ),
    );
  }

  Widget _buildInventoryReport() {
    if (_inventoryReport.isEmpty) return _emptyState('Tidak ada data stok');
    return _buildTable(
      columns: const ['Nama', 'SKU', 'Stok', 'Unit', 'Threshold', 'Status'],
      rows: _inventoryReport.map((r) => [
        r['name']?.toString() ?? '-',
        r['sku']?.toString() ?? '-',
        '${r['quantity'] ?? 0}',
        r['unit']?.toString() ?? '-',
        '${r['reorderThreshold'] ?? 0}',
        r['isCritical'] == true ? '⚠️ Kritis' : '✅ Aman',
      ]).toList(),
    );
  }
  // ─── Order History Report ──────────────────────
  Widget _buildOrderHistoryReport() {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDark;
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    if (_orderHistory.isEmpty) return _emptyState('Tidak ada transaksi');

    final totalRevenue = _orderHistory.fold<int>(0, (sum, o) => sum + (_n(o['totalAmount']).toInt()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total: ${_orderHistory.length} transaksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
              Text('Rp ${widget.formatter.format(totalRevenue)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
            ])),
            Icon(Icons.receipt_long, size: 36, color: AppTheme.primary.withValues(alpha: 0.4)),
          ]),
        ),
        // Order list
        Expanded(
          child: ListView.builder(
            itemCount: _orderHistory.length,
            itemBuilder: (ctx, i) {
              final order = _orderHistory[i];
              final createdAt = DateTime.tryParse(order['createdAt'] ?? '');
              final timeStr = createdAt != null
                  ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                  : '-';
              final total = _n(order['totalAmount']).toInt();
              final orderType = order['orderType'] ?? 'dine_in';
              final typeLabel = orderType == 'take_away' ? 'Take Away' : 'Dine In';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text('${i + 1}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))),
                  ),
                  title: Row(children: [
                    Expanded(child: Text(order['orderNumber'] ?? '-', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: orderType == 'take_away' ? AppTheme.warning.withValues(alpha: 0.15) : AppTheme.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: orderType == 'take_away' ? AppTheme.warning : AppTheme.success)),
                    ),
                  ]),
                  subtitle: Text('$timeStr  •  Rp ${widget.formatter.format(total)}', style: TextStyle(fontSize: 12, color: mutedColor)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                    onPressed: () => _confirmDeleteOrder(order['id'], order['orderNumber']),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteOrder(String orderId, String? orderNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Hapus Transaksi?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Transaksi ${orderNumber ?? orderId} akan dihapus permanen.\nData tidak dapat dikembalikan.',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.delete('/orders/$orderId');
        _loadReport(); // Refresh
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transaksi $orderNumber berhasil dihapus'), backgroundColor: AppTheme.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: AppTheme.danger),
          );
        }
      }
    }
  }

  // ─── Shared Widgets ──────────────────────────

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTable({required List<String> columns, required List<List<String>> rows}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0D1117),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: columns.map((c) => Expanded(
                child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              )).toList(),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1F2937)),
          // Rows
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF1F2937)),
              itemBuilder: (ctx, i) {
                final row = rows[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: i.isEven ? Colors.transparent : const Color(0xFF0D1117).withValues(alpha: 0.3),
                  child: Row(
                    children: row.map((cell) => Expanded(
                      child: Text(cell, style: const TextStyle(fontSize: 12, color: Colors.white),
                        overflow: TextOverflow.ellipsis),
                    )).toList(),
                  ),
                );
              },
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0D1117),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Text('Total: ${rows.length} baris', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



// ══════════════════════════════════════════════════════════════════
// ══════════════════════════════════════════════════════════════════
// TAB 5: BAHAN BAKU (RAW MATERIALS)
// ══════════════════════════════════════════════════════════════════
class _BahanBakuTab extends StatefulWidget {
  const _BahanBakuTab();
  @override State<_BahanBakuTab> createState() => _BahanBakuTabState();
}

class _BahanBakuTabState extends State<_BahanBakuTab> {
  int _subMenu = 0;
  List<dynamic> _items = [];
  List<dynamic> _alerts = [];
  List<dynamic> _adjustLog = [];
  List<dynamic> _allRecipes = [];
  List<dynamic> _products = [];
  bool _isLoading = true;

  final _subMenus = const [
    {'icon': Icons.inventory, 'label': 'Daftar Bahan'},
    {'icon': Icons.restaurant_menu, 'label': 'Racikan'},
    {'icon': Icons.swap_vert, 'label': 'Penyesuaian Stok'},
    {'icon': Icons.warning_amber, 'label': 'Peringatan'},
  ];

  @override
  void initState() { super.initState(); _loadAll(); }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getList('/inventory'),
        ApiService.getList('/inventory/alerts'),
        ApiService.getList('/inventory/adjustments/log'),
        ApiService.getList('/inventory/recipes/all'),
        ApiService.getList('/products'),
      ]);
      if (mounted) setState(() {
        _items = results[0]; _alerts = results[1]; _adjustLog = results[2];
        _allRecipes = results[3]; _products = results[4]; _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('BahanBaku load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDark;
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final sidebarBg = isDark ? const Color(0xFF0D1117) : Colors.white;

    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));

    return Row(
      children: [
        Container(
          width: 200, color: sidebarBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(settings.t('raw_materials'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
              ),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 8),
              ...List.generate(_subMenus.length, (i) {
                final m = _subMenus[i];
                final sel = _subMenu == i;
                return InkWell(
                  onTap: () => setState(() => _subMenu = i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: sel ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3)) : null,
                    ),
                    child: Row(children: [
                      Icon(m['icon'] as IconData, size: 18, color: sel ? AppTheme.primary : mutedColor),
                      const SizedBox(width: 12),
                      Expanded(child: Text(settings.t(m['label'] as String), style: TextStyle(
                        fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? (isDark ? Colors.white : AppTheme.primary) : mutedColor,
                      ))),
                      if (i == 3 && _alerts.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(10)),
                          child: Text('${_alerts.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                  ),
                );
              }),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: borderColor),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: [_buildDaftarBahan(), _buildRacikan(), _buildPenyesuaian(), _buildPeringatan()][_subMenu],
          ),
        ),
      ],
    );
  }

  // ─── 1. DAFTAR BAHAN ──────────────────────────
  Widget _buildDaftarBahan() {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDark;
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(settings.t('Daftar Bahan'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 4),
            Text(settings.t('manage_raw_desc'), style: TextStyle(fontSize: 13, color: mutedColor)),
          ])),
          ElevatedButton.icon(
            onPressed: () => _showItemDialog(),
            icon: const Icon(Icons.add, size: 16),
            label: Text(settings.t('add_item')),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, minimumSize: const Size(0, 40)),
          ),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
            child: _items.isEmpty
              ? Center(child: Text(settings.t('no_stock_data'), style: TextStyle(color: mutedColor)))
              : ListView(children: [
                  DataTable(
                    headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9)),
                    columns: [
                      DataColumn(label: Text(settings.t('name'), style: TextStyle(color: textColor, fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('SKU', style: TextStyle(color: textColor, fontWeight: FontWeight.w600))),
                      DataColumn(label: Text(settings.t('stock'), style: TextStyle(color: textColor, fontWeight: FontWeight.w600))),
                      DataColumn(label: Text(settings.t('unit'), style: TextStyle(color: textColor, fontWeight: FontWeight.w600))),
                      DataColumn(label: Text(settings.t('threshold'), style: TextStyle(color: textColor, fontWeight: FontWeight.w600))),
                      DataColumn(label: Text(settings.t('status'), style: TextStyle(color: textColor, fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('', style: TextStyle(color: textColor))),
                    ],
                    rows: _items.map<DataRow>((item) {
                      final qty = double.tryParse('${item['quantity']}') ?? 0;
                      final thr = double.tryParse('${item['reorderThreshold']}') ?? 10;
                      final isLow = qty <= thr;
                      return DataRow(cells: [
                        DataCell(Text('${item['name']}', style: TextStyle(color: textColor))),
                        DataCell(Text('${item['sku'] ?? '-'}', style: TextStyle(color: mutedColor, fontSize: 12))),
                        DataCell(Text('${item['quantity']}', style: TextStyle(color: isLow ? AppTheme.danger : textColor, fontWeight: FontWeight.w600))),
                        DataCell(Text('${item['unit']}', style: TextStyle(color: mutedColor))),
                        DataCell(Text('${item['reorderThreshold']}', style: TextStyle(color: mutedColor))),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isLow ? AppTheme.danger : AppTheme.success).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(isLow ? settings.t('critical') : settings.t('safe'),
                            style: TextStyle(fontSize: 11, color: isLow ? AppTheme.danger : AppTheme.success, fontWeight: FontWeight.w600)),
                        )),
                        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: Icon(Icons.edit, size: 16, color: mutedColor), onPressed: () => _showItemDialog(item)),
                          IconButton(icon: const Icon(Icons.delete, size: 16, color: AppTheme.danger), onPressed: () => _deleteItem(item['id'])),
                        ])),
                      ]);
                    }).toList(),
                  ),
                ]),
          ),
        ),
      ],
    );
  }

  // ─── 2. RACIKAN ───────────────────────────────
  Widget _buildRacikan() {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDark;
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    // Group recipes by product + variant
    final Map<String, List<dynamic>> grouped = {};
    for (final r in _allRecipes) {
      final pid = r['productId'] ?? '';
      final vid = r['variantId'] ?? '';
      final key = '${pid}_$vid';
      grouped.putIfAbsent(key, () => []).add(r);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(settings.t('Racikan'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 4),
            Text(settings.t('recipe_desc'), style: TextStyle(fontSize: 13, color: mutedColor)),
          ])),
          ElevatedButton.icon(
            onPressed: () => _showRecipeDialog(),
            icon: const Icon(Icons.add, size: 16),
            label: Text(settings.t('add_recipe')),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, minimumSize: const Size(0, 40)),
          ),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: grouped.isEmpty
            ? Center(child: Text(settings.t('no_recipe'), style: TextStyle(color: mutedColor)))
            : ListView(
                children: grouped.entries.map((e) {
                  final productName = e.value.first['productName'] ?? '-';
                  final variantName = e.value.first['variantName'];
                  final variantId = e.value.first['variantId'];
                  final displayName = variantName != null && variantName.toString().isNotEmpty
                      ? '$productName — $variantName'
                      : productName;
                  final productId = e.value.first['productId'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(displayName, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                      subtitle: Row(children: [
                        Text('${e.value.length} ${settings.t('ingredients')}', style: TextStyle(fontSize: 12, color: mutedColor)),
                        if (variantName != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text('Variasi', style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ]),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: Icon(Icons.edit, size: 16, color: mutedColor), onPressed: () => _showRecipeDialog(productId, e.value, variantId)),
                        const Icon(Icons.expand_more),
                      ]),
                      children: e.value.map<Widget>((ing) => ListTile(
                        dense: true,
                        leading: Icon(Icons.fiber_manual_record, size: 8, color: mutedColor),
                        title: Text('${ing['inventoryName'] ?? '-'}', style: TextStyle(color: textColor, fontSize: 13)),
                        trailing: Text('${ing['quantityUsed']} ${ing['inventoryUnit'] ?? ''}', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      )).toList(),
                    ),
                  );
                }).toList(),
              ),
        ),
      ],
    );
  }

  // ─── 3. PENYESUAIAN STOK ──────────────────────
  Widget _buildPenyesuaian() {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDark;
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(settings.t('Penyesuaian Stok'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 4),
            Text(settings.t('adjust_desc'), style: TextStyle(fontSize: 13, color: mutedColor)),
          ])),
          ElevatedButton.icon(
            onPressed: () => _showAdjustDialog(),
            icon: const Icon(Icons.swap_vert, size: 16),
            label: Text(settings.t('adjust_stock')),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, minimumSize: const Size(0, 40)),
          ),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
            child: _adjustLog.isEmpty
              ? Center(child: Text(settings.t('no_data_available'), style: TextStyle(color: mutedColor)))
              : ListView.separated(
                  padding: const EdgeInsets.all(0),
                  itemCount: _adjustLog.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                  itemBuilder: (_, i) {
                    final log = _adjustLog[i];
                    final type = log['type'] ?? '';
                    final isIn = type == 'IN';
                    final isOrder = type == 'ORDER';
                    final color = isIn ? AppTheme.success : (isOrder ? AppTheme.primary : AppTheme.danger);
                    final icon = isIn ? Icons.arrow_downward : (isOrder ? Icons.shopping_cart : Icons.arrow_upward);
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, size: 18, color: color)),
                      title: Text('${log['inventoryName'] ?? '-'}', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                      subtitle: Text('${log['reason'] ?? type} • ${log['createdAt'] ?? ''}', style: TextStyle(color: mutedColor, fontSize: 11)),
                      trailing: Text('${isIn ? '+' : '-'}${log['quantity']}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }

  // ─── 4. PERINGATAN ────────────────────────────
  Widget _buildPeringatan() {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDark;
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(settings.t('Peringatan'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
        const SizedBox(height: 4),
        Text(settings.t('alert_desc'), style: TextStyle(fontSize: 13, color: mutedColor)),
        const SizedBox(height: 16),
        Expanded(
          child: _alerts.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle, size: 48, color: AppTheme.success.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(settings.t('all_stock_safe'), style: TextStyle(color: mutedColor, fontSize: 14)),
              ]))
            : ListView.builder(
                itemCount: _alerts.length,
                itemBuilder: (_, i) {
                  final a = _alerts[i];
                  final qty = double.tryParse('${a['quantity']}') ?? 0;
                  final thr = double.tryParse('${a['reorderThreshold']}') ?? 10;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3))),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0x20FF4444), child: Icon(Icons.warning_amber, color: AppTheme.danger, size: 20)),
                      title: Text('${a['name']}', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                      subtitle: Text('${settings.t('stock')}: $qty ${a['unit']} • Threshold: $thr', style: TextStyle(color: mutedColor, fontSize: 12)),
                      trailing: ElevatedButton(
                        onPressed: () { _subMenu = 0; setState(() {}); },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, minimumSize: const Size(0, 32), textStyle: const TextStyle(fontSize: 12)),
                        child: Text(settings.t('adjust_stock')),
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  // ─── Dialogs ──────────────────────────────────
  void _showItemDialog([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final nameC = TextEditingController(text: item?['name'] ?? '');
    final skuC = TextEditingController(text: item?['sku'] ?? '');
    final qtyC = TextEditingController(text: '${item?['quantity'] ?? '0'}');
    final unitC = TextEditingController(text: item?['unit'] ?? 'gram');
    final thrC = TextEditingController(text: '${item?['reorderThreshold'] ?? '10'}');

    showDialog(context: context, builder: (_) {
      final settings = context.read<SettingsProvider>();
      final isDark = settings.isDark;
      return AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        title: Row(children: [
          Expanded(child: Text(isEdit ? settings.t('edit_item') : settings.t('add_item'),
            style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark))),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20)),
        ]),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField(settings.t('name'), nameC, isDark),
          const SizedBox(height: 8),
          _dialogField('SKU', skuC, isDark),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _dialogField(settings.t('stock'), qtyC, isDark, isNum: true)),
            const SizedBox(width: 8),
            Expanded(child: _dialogField(settings.t('unit'), unitC, isDark)),
          ]),
          const SizedBox(height: 8),
          _dialogField(settings.t('threshold'), thrC, isDark, isNum: true),
        ])),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final data = {
                'name': nameC.text, 'sku': skuC.text,
                'quantity': qtyC.text, 'unit': unitC.text,
                'reorderThreshold': thrC.text,
                'branchId': 'default',
              };
              if (isEdit) {
                await ApiService.put('/inventory/${item['id']}', data);
              } else {
                await ApiService.post('/inventory', data);
              }
              if (mounted) Navigator.pop(context);
              _loadAll();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(settings.t('save')),
          ),
        ],
      );
    });
  }

  void _showAdjustDialog() {
    String? selectedItemId;
    final qtyC = TextEditingController();
    String adjustType = 'IN';
    final reasonC = TextEditingController();

    showDialog(context: context, builder: (_) {
      final settings = context.read<SettingsProvider>();
      final isDark = settings.isDark;
      return StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        title: Row(children: [
          Expanded(child: Text(settings.t('adjust_stock'), style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark))),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20)),
        ]),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: selectedItemId,
            dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
            decoration: InputDecoration(labelText: settings.t('select_item'), labelStyle: TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9)),
            style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark),
            items: _items.map<DropdownMenuItem<String>>((i) => DropdownMenuItem(value: i['id'], child: Text('${i['name']}'))).toList(),
            onChanged: (v) => setS(() => selectedItemId = v),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _dialogField(settings.t('qty'), qtyC, isDark, isNum: true)),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField<String>(
              value: adjustType,
              dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
              decoration: InputDecoration(labelText: settings.t('type'), labelStyle: TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9)),
              style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark),
              items: const [
                DropdownMenuItem(value: 'IN', child: Text('Stok Masuk (IN)')),
                DropdownMenuItem(value: 'OUT', child: Text('Stok Keluar (OUT)')),
                DropdownMenuItem(value: 'ADJUSTMENT', child: Text('Set Manual')),
              ],
              onChanged: (v) => setS(() => adjustType = v ?? 'IN'),
            )),
          ]),
          const SizedBox(height: 8),
          _dialogField(settings.t('reason'), reasonC, isDark),
        ])),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (selectedItemId == null || qtyC.text.isEmpty) return;
              await ApiService.post('/inventory/$selectedItemId/adjust', {
                'quantity': qtyC.text, 'type': adjustType, 'reason': reasonC.text,
              });
              if (mounted) Navigator.pop(context);
              _loadAll();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(settings.t('save')),
          ),
        ],
      ));
    });
  }

  void _showRecipeDialog([String? productId, List<dynamic>? existing, String? existingVariantId]) {
    String? selectedProduct = productId;
    String? selectedVariant = existingVariantId;
    List<Map<String, dynamic>> ingredients = existing?.map((e) => <String, dynamic>{
      'inventoryId': e['inventoryId'] as String, 'quantityUsed': e['quantityUsed'].toString(),
    }).toList() ?? [];

    // Get variants for selected product
    List<dynamic> productVariants = [];
    if (selectedProduct != null) {
      final prod = _products.cast<Map<String, dynamic>?>().firstWhere((p) => p?['id'] == selectedProduct, orElse: () => null);
      productVariants = (prod?['variants'] as List<dynamic>?) ?? [];
    }

    showDialog(context: context, builder: (_) {
      final settings = context.read<SettingsProvider>();
      final isDark = settings.isDark;
      final fieldBg = isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9);
      final textStyle = TextStyle(color: isDark ? Colors.white : AppTheme.textDark);
      final labelStyle = TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight);
      final dropBg = isDark ? const Color(0xFF1F2937) : Colors.white;

      return StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        title: Row(children: [
          Expanded(child: Text(productId != null ? settings.t('edit_recipe') : settings.t('add_recipe'),
            style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark))),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20)),
        ]),
        content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Product dropdown (only for new recipes)
          if (productId == null) ...[
            DropdownButtonFormField<String>(
              value: selectedProduct,
              dropdownColor: dropBg,
              decoration: InputDecoration(labelText: settings.t('select_product'), labelStyle: labelStyle,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: fieldBg),
              style: textStyle,
              items: _products.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'], child: Text('${p['name']}'))).toList(),
              onChanged: (v) {
                setS(() {
                  selectedProduct = v;
                  selectedVariant = null;
                  // Update variants list
                  final prod = _products.cast<Map<String, dynamic>?>().firstWhere((p) => p?['id'] == v, orElse: () => null);
                  productVariants = (prod?['variants'] as List<dynamic>?) ?? [];
                });
              },
            ),
            const SizedBox(height: 12),
          ],
          // Variant dropdown (optional)
          if (productVariants.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              value: selectedVariant,
              dropdownColor: dropBg,
              decoration: InputDecoration(
                labelText: 'Variasi (opsional)',
                labelStyle: labelStyle,
                hintText: 'Semua variasi (dasar)',
                hintStyle: TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true, fillColor: fieldBg,
              ),
              style: textStyle,
              items: [
                DropdownMenuItem<String>(value: null, child: Text('Semua variasi (dasar)', style: TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight, fontSize: 13))),
                ...productVariants.map<DropdownMenuItem<String>>((v) =>
                  DropdownMenuItem(value: v['id'], child: Text('${v['name']}'))),
              ],
              onChanged: (v) => setS(() => selectedVariant = v),
            ),
            const SizedBox(height: 12),
          ],
          // Ingredients list
          ...ingredients.asMap().entries.map((entry) {
            final idx = entry.key;
            final ing = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: ing['inventoryId'],
                  dropdownColor: dropBg,
                  decoration: InputDecoration(labelText: settings.t('ingredient'), isDense: true, labelStyle: labelStyle,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: fieldBg),
                  style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark, fontSize: 13),
                  items: _items.map<DropdownMenuItem<String>>((i) => DropdownMenuItem(value: i['id'], child: Text('${i['name']} (${i['unit']})'))).toList(),
                  onChanged: (v) => setS(() => ingredients[idx]['inventoryId'] = v ?? ''),
                )),
                const SizedBox(width: 8),
                SizedBox(width: 80, child: TextFormField(
                  initialValue: ing['quantityUsed'],
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark, fontSize: 13),
                  decoration: InputDecoration(labelText: settings.t('qty'), isDense: true, labelStyle: labelStyle,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: fieldBg),
                  onChanged: (v) => ingredients[idx]['quantityUsed'] = v,
                )),
                IconButton(icon: const Icon(Icons.remove_circle, color: AppTheme.danger, size: 20),
                  onPressed: () => setS(() => ingredients.removeAt(idx))),
              ]),
            );
          }),
          TextButton.icon(
            onPressed: () => setS(() => ingredients.add({'inventoryId': _items.isNotEmpty ? _items.first['id'] : '', 'quantityUsed': '1'})),
            icon: const Icon(Icons.add, size: 16), label: Text(settings.t('add_ingredient')),
          ),
        ]))),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (selectedProduct == null) return;
              await ApiService.post('/inventory/recipes/$selectedProduct', <String, dynamic>{
                'variantId': selectedVariant,
                'ingredients': ingredients.map((e) => <String, dynamic>{
                  'inventoryId': e['inventoryId'], 'quantityUsed': double.tryParse(e['quantityUsed'] ?? '0') ?? 0,
                }).toList(),
              });
              if (mounted) Navigator.pop(context);
              _loadAll();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(settings.t('save')),
          ),
        ],
      ));
    });
  }

  Future<void> _deleteItem(String id) async {
    await ApiService.delete('/inventory/$id');
    _loadAll();
  }

  Widget _dialogField(String label, TextEditingController c, bool isDark, {bool isNum = false}) {
    return TextFormField(
      controller: c,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark),
      decoration: InputDecoration(
        labelText: label, isDense: true,
        labelStyle: TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true, fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 6: PENGATURAN

// ══════════════════════════════════════════════════════════════════
class _PengaturanTab extends StatefulWidget {
  const _PengaturanTab();
  @override State<_PengaturanTab> createState() => _PengaturanTabState();
}

class _PengaturanTabState extends State<_PengaturanTab> {
  int _selectedMenu = 0;
  List<dynamic> _taxes = [];
  bool _isLoading = true;
  // Settings state (managed by SettingsProvider except print)

  // Print state
  String _printerName = 'Default Printer';
  String _paperSize = '80mm';
  bool _autoPrint = false;
  String _headerText = 'Nama Toko';
  String _footerText = 'Terima kasih!';
  bool _showLogo = true;
  String _logoPath = '';

  // Receipt fields visibility
  bool _showReceiptNo = true;
  bool _showOrderNo = true;
  bool _showTableNo = true;
  bool _showUser = true;
  bool _showItemCount = true;
  bool _showTotal = true;
  bool _showTax = true;
  bool _showChange = true;

  // Font & layout
  String _fontFamily = 'Monospace';
  String _fontSize = '12';
  String _marginTop = '5';
  String _marginBottom = '5';
  String _marginLeft = '5';
  String _marginRight = '5';
  bool _autoCashDrawer = false;

  // Kitchen ticket state
  int _receiptTabIndex = 0; // 0 = Customer, 1 = Kitchen
  bool _kitchenShowTable = true;
  bool _kitchenShowTime = true;
  bool _kitchenShowNotes = true;
  String _kitchenFontSize = '16';

  final _menuItems = const [
    {'icon': Icons.tune, 'label': 'Umum'},
    {'icon': Icons.storefront, 'label': 'Produk'},
    {'icon': Icons.print, 'label': 'Print'},
    {'icon': Icons.storage, 'label': 'Database'},
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getList('/settings/taxes'),
      ]);
      if (mounted) setState(() {
        _taxes = results[0];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Settings error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTaxDialog([Map<String, dynamic>? tax]) {
    final nameCtrl = TextEditingController(text: tax?['name'] ?? '');
    final rateCtrl = TextEditingController(text: tax?['rate']?.toString() ?? '');
    bool isActive = tax?['isActive'] ?? true;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF111827),
      title: Row(
        children: [
          Expanded(child: Text(tax == null ? 'Tambah Pajak' : 'Edit Pajak',
            style: const TextStyle(color: Colors.white))),
          IconButton(icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
            onPressed: () => Navigator.pop(ctx)),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Nama Pajak')),
            const SizedBox(height: 12),
            TextField(controller: rateCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Persentase (%)')),
            const SizedBox(height: 12),
            StatefulBuilder(builder: (ctx2, setSt) => SwitchListTile(
              title: const Text('Aktif', style: TextStyle(color: Colors.white)),
              value: isActive,
              activeColor: AppTheme.success,
              onChanged: (v) => setSt(() => isActive = v),
            )),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            final data = {'name': nameCtrl.text, 'rate': double.tryParse(rateCtrl.text) ?? 0, 'isActive': isActive};
            if (tax == null) {
              await ApiService.post('/settings/taxes', data);
            } else {
              await ApiService.put('/settings/taxes/${tax['id']}', data);
            }
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          },
          child: const Text('Simpan'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));

    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDark;
    final sidebarBg = isDark ? const Color(0xFF0D1117) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;

    return Row(
      children: [
        // Sidebar
        Container(
          width: 200,
          color: sidebarBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(settings.t('settings'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
              ),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 8),
              ...List.generate(_menuItems.length, (i) {
                final item = _menuItems[i];
                final selected = _selectedMenu == i;
                return InkWell(
                  onTap: () => setState(() => _selectedMenu = i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: selected ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3)) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(item['icon'] as IconData, size: 18,
                          color: selected ? AppTheme.primary : mutedColor),
                        const SizedBox(width: 12),
                        Text(item['label'] as String, style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? (isDark ? Colors.white : AppTheme.primary) : mutedColor,
                        )),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: borderColor),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedMenu) {
      case 0: return _buildUmum();
      case 1: return _buildProduk();
      case 2: return _buildPrint();
      case 3: return _buildDatabase();
      default: return const SizedBox();
    }
  }

  // ─── 1. UMUM ──────────────────────────

  Widget _buildUmum() {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDark;
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;

    return ListView(
      children: [
        Text(settings.t('general'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
        const SizedBox(height: 4),
        Text(settings.t('appearance_settings'), style: TextStyle(fontSize: 13, color: mutedColor)),
        const SizedBox(height: 24),

        _settingsCard(
          title: settings.t('language'),
          icon: Icons.language,
          child: _dropdownTile(settings.t('select_language'), settings.language, ['Indonesia', 'English'],
            (v) => settings.setLanguage(v)),
        ),
        const SizedBox(height: 16),

        _settingsCard(
          title: settings.t('color_theme'),
          icon: Icons.palette,
          child: _dropdownTile(settings.t('display_theme'), settings.theme,
            ['Gelap', 'Terang'],
            (v) => settings.setTheme(v)),
        ),
      ],
    );
  }

  // ─── 2. PRODUK (Perpajakan) ───────────

  Widget _buildProduk() {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDark;
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;

    return ListView(
      children: [
        Text(settings.t('product'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
        const SizedBox(height: 4),
        Text(settings.t('tax_settings'), style: TextStyle(fontSize: 13, color: mutedColor)),
        const SizedBox(height: 24),

        _settingsCard(
          title: settings.t('tax_list'),
          icon: Icons.receipt,
          trailing: IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.primary),
            onPressed: () => _showTaxDialog(),
          ),
          child: Column(
            children: _taxes.isEmpty
              ? [Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(settings.t('no_tax'), style: TextStyle(color: mutedColor)),
                )]
              : _taxes.map((t) => ListTile(
                  title: Text(t['name'] ?? '-', style: TextStyle(color: textColor, fontSize: 14)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${t['rate'] ?? 0}%', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (t['isActive'] == true ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(t['isActive'] == true ? settings.t('active') : settings.t('inactive'),
                          style: TextStyle(fontSize: 11, color: t['isActive'] == true ? AppTheme.success : AppTheme.danger)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(icon: Icon(Icons.edit, size: 16, color: mutedColor),
                        onPressed: () => _showTaxDialog(t)),
                    ],
                  ),
                )).toList(),
          ),
        ),
      ],
    );
  }

  // ─── 3. PRINT ─────────────────────────

  Widget _buildPrint() {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDark;
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    final tabBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final activeTabBg = AppTheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(settings.t('print'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
        const SizedBox(height: 4),
        Text(settings.t('printer_receipt_settings'), style: TextStyle(fontSize: 13, color: mutedColor)),
        const SizedBox(height: 20),

        // ── Tab Bar ──
        Container(
          decoration: BoxDecoration(
            color: tabBg,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _receiptTab(0, Icons.receipt_long, settings.t('customer_receipt'), activeTabBg, textColor, mutedColor, isDark),
              const SizedBox(width: 4),
              _receiptTab(1, Icons.restaurant, settings.t('kitchen_ticket'), activeTabBg, textColor, mutedColor, isDark),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Content ──
        Expanded(
          child: _receiptTabIndex == 0
              ? _buildCustomerReceiptSettings(settings, isDark, textColor, mutedColor)
              : _buildKitchenTicketSettings(settings, isDark, textColor, mutedColor),
        ),
      ],
    );
  }

  Widget _receiptTab(int index, IconData icon, String label, Color activeTabBg, Color textColor, Color mutedColor, bool isDark) {
    final isActive = _receiptTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _receiptTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeTabBg : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive ? [BoxShadow(color: activeTabBg.withValues(alpha: 0.3), blurRadius: 8)] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isActive ? Colors.white : mutedColor),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : mutedColor,
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ── STRUK PEMBELI (Customer Receipt) ──
  Widget _buildCustomerReceiptSettings(SettingsProvider settings, bool isDark, Color textColor, Color mutedColor) {
    return ListView(
      children: [
        // Printer Settings
        _settingsCard(
          title: settings.t('printer_settings'),
          icon: Icons.print,
          child: Column(
            children: [
              _textFieldTile(settings.t('printer_name'), _printerName, (v) => setState(() => _printerName = v)),
              _dropdownTile(settings.t('paper_size'), _paperSize, ['58mm', '80mm'],
                (v) => setState(() => _paperSize = v)),
              _switchTile(settings.t('auto_print'), _autoPrint,
                (v) => setState(() => _autoPrint = v)),
              _switchTile(settings.t('auto_cash_drawer'), _autoCashDrawer,
                (v) => setState(() => _autoCashDrawer = v)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _printTestPage,
                    icon: const Icon(Icons.print, size: 16),
                    label: Text(settings.t('print_test_page')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Logo Upload
        _settingsCard(
          title: settings.t('business_logo'),
          icon: Icons.image,
          child: Column(
            children: [
              _switchTile(settings.t('show_logo'), _showLogo, (v) => setState(() => _showLogo = v)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1)),
                      ),
                      child: _logoPath.isEmpty
                        ? Icon(Icons.store, size: 32, color: mutedColor)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.network(_logoPath, fit: BoxFit.cover),
                          ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickLogo,
                          icon: const Icon(Icons.upload, size: 16),
                          label: Text(settings.t('upload_logo')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            minimumSize: const Size(0, 36),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('PNG, JPG (max 1MB)', style: TextStyle(fontSize: 11, color: mutedColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Receipt Customization (Header/Footer)
        _settingsCard(
          title: settings.t('receipt_customization'),
          icon: Icons.receipt_long,
          child: Column(
            children: [
              _textFieldTile(settings.t('receipt_header'), _headerText, (v) => setState(() => _headerText = v)),
              _textFieldTile(settings.t('receipt_footer'), _footerText, (v) => setState(() => _footerText = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Receipt Fields Visibility
        _settingsCard(
          title: settings.t('receipt_fields'),
          icon: Icons.checklist,
          child: Column(
            children: [
              _switchTile(settings.t('receipt_no'), _showReceiptNo, (v) => setState(() => _showReceiptNo = v)),
              _switchTile(settings.t('order_no'), _showOrderNo, (v) => setState(() => _showOrderNo = v)),
              _switchTile(settings.t('table_no'), _showTableNo, (v) => setState(() => _showTableNo = v)),
              _switchTile(settings.t('cashier_user'), _showUser, (v) => setState(() => _showUser = v)),
              _switchTile(settings.t('item_count'), _showItemCount, (v) => setState(() => _showItemCount = v)),
              _switchTile(settings.t('total_amount'), _showTotal, (v) => setState(() => _showTotal = v)),
              _switchTile(settings.t('tax_info'), _showTax, (v) => setState(() => _showTax = v)),
              _switchTile(settings.t('change_amount'), _showChange, (v) => setState(() => _showChange = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Font & Layout
        _settingsCard(
          title: settings.t('font_layout'),
          icon: Icons.text_fields,
          child: Column(
            children: [
              _dropdownTile(settings.t('font_type'), _fontFamily,
                ['Monospace', 'Sans-Serif', 'Serif'],
                (v) => setState(() => _fontFamily = v)),
              _dropdownTile(settings.t('font_size_label'), _fontSize,
                ['8', '9', '10', '11', '12', '14', '16'],
                (v) => setState(() => _fontSize = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Margins
        _settingsCard(
          title: settings.t('margins'),
          icon: Icons.space_bar,
          child: Column(
            children: [
              _textFieldTile(settings.t('margin_top'), _marginTop, (v) => setState(() => _marginTop = v)),
              _textFieldTile(settings.t('margin_bottom'), _marginBottom, (v) => setState(() => _marginBottom = v)),
              _textFieldTile(settings.t('margin_left'), _marginLeft, (v) => setState(() => _marginLeft = v)),
              _textFieldTile(settings.t('margin_right'), _marginRight, (v) => setState(() => _marginRight = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Customer Receipt Preview
        _settingsCard(
          title: 'Preview',
          icon: Icons.visibility,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    if (_showLogo && _logoPath.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Image.network(_logoPath, height: 50),
                      ),
                    Text(_headerText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black, fontFamily: 'monospace')),
                    const Text('Jl. Contoh No. 123', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const Text('Telp: 021-1234567', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const Divider(color: Colors.black38),
                    if (_showReceiptNo) _customerPreviewRow(settings.t('receipt_no'), '#RCP-001'),
                    if (_showOrderNo) _customerPreviewRow(settings.t('order_no'), '#ORD-001'),
                    if (_showTableNo) _customerPreviewRow(settings.t('table_no'), '5'),
                    if (_showUser) _customerPreviewRow(settings.t('cashier_user'), 'Admin'),
                    const Divider(color: Colors.black38),
                    _customerItemRow('Kopi Latte', '2 x 18.000', '36.000'),
                    _customerItemRow('Croissant', '1 x 25.000', '25.000'),
                    _customerItemRow('Es Teh Manis', '3 x 8.000', '24.000'),
                    const Divider(color: Colors.black38),
                    if (_showItemCount) _customerPreviewRow(settings.t('item_count'), '6'),
                    if (_showTotal) _customerPreviewBoldRow('TOTAL', 'Rp 85.000'),
                    if (_showTax) _customerPreviewRow('${settings.t('tax_info')} (10%)', 'Rp 8.500'),
                    if (_showTotal) _customerPreviewBoldRow('Grand Total', 'Rp 93.500'),
                    _customerPreviewRow('Bayar (Tunai)', 'Rp 100.000'),
                    if (_showChange) _customerPreviewBoldRow(settings.t('change_amount'), 'Rp 6.500'),
                    const Divider(color: Colors.black38),
                    Text(_footerText, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
                    const Text('Powered by Kasir-AI', style: TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _printTestPage,
                    icon: const Icon(Icons.print, size: 16),
                    label: Text(settings.t('print_test_page')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _customerPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace')),
          Text(value, style: const TextStyle(fontSize: 11, color: Colors.black, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _customerPreviewBoldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black, fontFamily: 'monospace')),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _customerItemRow(String name, String qty, String total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black, fontFamily: 'monospace')),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('  $qty', style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
              Text('Rp $total', style: const TextStyle(fontSize: 10, color: Colors.black, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }

  // ── STRUK DAPUR (Kitchen Ticket) ──
  Widget _buildKitchenTicketSettings(SettingsProvider settings, bool isDark, Color textColor, Color mutedColor) {
    return ListView(
      children: [
        // Kitchen Display Settings
        _settingsCard(
          title: settings.t('kitchen_display'),
          icon: Icons.restaurant,
          child: Column(
            children: [
              _switchTile(settings.t('show_table_number'), _kitchenShowTable,
                (v) => setState(() => _kitchenShowTable = v)),
              _switchTile(settings.t('show_order_time'), _kitchenShowTime,
                (v) => setState(() => _kitchenShowTime = v)),
              _switchTile(settings.t('show_special_notes'), _kitchenShowNotes,
                (v) => setState(() => _kitchenShowNotes = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Kitchen Font Settings
        _settingsCard(
          title: settings.t('kitchen_font'),
          icon: Icons.text_fields,
          child: Column(
            children: [
              _dropdownTile(settings.t('font_size_label'), _kitchenFontSize,
                ['14', '16', '18', '20', '24'],
                (v) => setState(() => _kitchenFontSize = v)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  settings.t('kitchen_font_hint'),
                  style: TextStyle(fontSize: 11, color: mutedColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Kitchen Ticket Preview & Test Print
        _settingsCard(
          title: settings.t('kitchen_preview'),
          icon: Icons.visibility,
          child: Column(
            children: [
              // Preview
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('🍳 DAPUR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black, fontFamily: 'monospace')),
                    const Divider(color: Colors.black54),
                    if (_kitchenShowTable)
                      _kitchenPreviewRow('Meja', '5'),
                    if (_kitchenShowTime)
                      _kitchenPreviewRow('Waktu', '22:45'),
                    const Divider(color: Colors.black54),
                    // Items with per-product notes
                    Text('2x  Kopi Latte', style: TextStyle(fontSize: double.parse(_kitchenFontSize), fontWeight: FontWeight.w700, color: Colors.black)),
                    if (_kitchenShowNotes)
                      const Padding(
                        padding: EdgeInsets.only(left: 24, bottom: 4),
                        child: Row(children: [
                          Icon(Icons.edit_note, size: 12, color: Colors.orange),
                          SizedBox(width: 4),
                          Text('Tanpa gula', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54)),
                        ]),
                      ),
                    const SizedBox(height: 2),
                    Text('1x  Croissant', style: TextStyle(fontSize: double.parse(_kitchenFontSize), fontWeight: FontWeight.w700, color: Colors.black)),
                    const SizedBox(height: 2),
                    Text('3x  Es Teh Manis', style: TextStyle(fontSize: double.parse(_kitchenFontSize), fontWeight: FontWeight.w700, color: Colors.black)),
                    if (_kitchenShowNotes)
                      const Padding(
                        padding: EdgeInsets.only(left: 24, bottom: 4),
                        child: Row(children: [
                          Icon(Icons.edit_note, size: 12, color: Colors.orange),
                          SizedBox(width: 4),
                          Text('Es dipisah', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54)),
                        ]),
                      ),
                  ],
                ),
              ),
              // Test Print button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _printKitchenTestPage,
                    icon: const Icon(Icons.print, size: 16),
                    label: Text(settings.t('print_kitchen_test')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _kitchenPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace')),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  void _pickLogo() {
    if (!kIsWeb) return;
    try {
      webPickFile(
        accept: 'image/*',
        onPicked: (_, __) {},
        onPickedDataUrl: (dataUrl) {
          setState(() => _logoPath = dataUrl);
        },
      );
    } catch (e) {
      debugPrint('Logo pick error: $e');
    }
  }

  void _printTestPage() {
    final settings = context.read<SettingsProvider>();
    final mt = _marginTop, mb = _marginBottom, ml = _marginLeft, mr = _marginRight;
    final font = _fontFamily == 'Monospace' ? 'monospace' : _fontFamily == 'Serif' ? 'serif' : 'sans-serif';
    final fSize = _fontSize;

    final fields = <String>[];
    if (_showReceiptNo) fields.add('<tr><td>${settings.t('receipt_no')}</td><td style="text-align:right">#TEST-001</td></tr>');
    if (_showOrderNo) fields.add('<tr><td>${settings.t('order_no')}</td><td style="text-align:right">#ORD-001</td></tr>');
    if (_showTableNo) fields.add('<tr><td>${settings.t('table_no')}</td><td style="text-align:right">5</td></tr>');
    if (_showUser) fields.add('<tr><td>${settings.t('cashier_user')}</td><td style="text-align:right">Admin</td></tr>');

    final items = '''
      <tr style="border-top:1px dashed #000;border-bottom:1px dashed #000">
        <td><b>Item</b></td><td style="text-align:center"><b>Qty</b></td><td style="text-align:right"><b>Harga</b></td>
      </tr>
      <tr><td>Kopi Latte</td><td style="text-align:center">2</td><td style="text-align:right">36.000</td></tr>
      <tr><td>Croissant</td><td style="text-align:center">1</td><td style="text-align:right">25.000</td></tr>
      <tr><td>Es Teh Manis</td><td style="text-align:center">3</td><td style="text-align:right">24.000</td></tr>
    ''';

    final totals = <String>[];
    if (_showItemCount) totals.add('<tr><td>${settings.t('item_count')}</td><td style="text-align:right">6</td></tr>');
    if (_showTotal) totals.add('<tr style="border-top:1px dashed #000"><td><b>Total</b></td><td style="text-align:right"><b>Rp 85.000</b></td></tr>');
    if (_showTax) totals.add('<tr><td>${settings.t('tax_info')} (10%)</td><td style="text-align:right">Rp 8.500</td></tr>');
    if (_showTotal) totals.add('<tr style="border-top:1px solid #000"><td><b>Grand Total</b></td><td style="text-align:right"><b>Rp 93.500</b></td></tr>');
    if (_showChange) totals.add('<tr><td>${settings.t('change_amount')}</td><td style="text-align:right">Rp 6.500</td></tr>');

    final logoHtml = (_showLogo && _logoPath.isNotEmpty)
      ? '<img src="$_logoPath" style="max-width:80px;max-height:80px;margin-bottom:8px" />'
      : '';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head><title>Test Print</title>
<style>
  @page { margin: ${mt}mm ${mr}mm ${mb}mm ${ml}mm; }
  body { font-family: $font; font-size: ${fSize}px; color: #000; width: ${_paperSize == '58mm' ? '48mm' : '72mm'}; margin: 0 auto; }
  table { width: 100%; border-collapse: collapse; }
  td { padding: 2px 0; vertical-align: top; }
  .center { text-align: center; }
  .header { font-size: ${int.parse(fSize) + 4}px; font-weight: bold; }
  hr { border: none; border-top: 1px dashed #000; margin: 6px 0; }
</style>
</head>
<body>
  <div class="center">
    $logoHtml
    <div class="header">${_headerText}</div>
    <div style="margin-bottom:8px;font-size:${int.parse(fSize) - 1}px">Test Receipt</div>
  </div>
  <table>${fields.join('')}</table>
  <table>$items</table>
  <table>${totals.join('')}</table>
  <hr/>
  <div class="center" style="font-size:${int.parse(fSize) - 1}px;margin-top:8px">${_footerText}</div>
  <div class="center" style="font-size:${int.parse(fSize) - 2}px;margin-top:4px;color:#888">── TEST PAGE ──</div>
</body>
</html>
''';

    printReceiptHtml(htmlContent);
  }

  void _printKitchenTestPage() {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final fSize = _kitchenFontSize;
    final noteSize = '${int.parse(fSize) - 2}';

    final infoRows = <String>[];
    if (_kitchenShowTable) infoRows.add('<tr><td>Meja</td><td style="text-align:right;font-weight:bold">5</td></tr>');
    if (_kitchenShowTime) infoRows.add('<tr><td>Waktu</td><td style="text-align:right;font-weight:bold">$timeStr</td></tr>');

    final note1 = _kitchenShowNotes ? '<div class="note">📝 Tanpa gula</div>' : '';
    final note2 = _kitchenShowNotes ? '<div class="note">📝 Es dipisah</div>' : '';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head><title>Kitchen Ticket</title>
<style>
  @page { margin: 2mm; size: ${_paperSize == '58mm' ? '58mm' : '80mm'} auto; }
  body { font-family: monospace; font-size: ${fSize}px; color: #000; width: ${_paperSize == '58mm' ? '48mm' : '72mm'}; margin: 0 auto; }
  table { width: 100%; border-collapse: collapse; }
  td { padding: 2px 0; vertical-align: top; }
  .center { text-align: center; }
  .header { font-size: ${int.parse(fSize) + 8}px; font-weight: 900; letter-spacing: 2px; }
  hr { border: none; border-top: 1px dashed #000; margin: 6px 0; }
  .item { font-size: ${fSize}px; font-weight: bold; padding: 3px 0; margin: 0; }
  .note { font-size: ${noteSize}px; font-style: italic; color: #555; padding-left: 16px; margin-bottom: 4px; }
</style>
</head>
<body>
  <div class="center"><div class="header">🍳 DAPUR</div></div>
  <hr/>
  <table>${infoRows.join('')}</table>
  <hr/>
  <div class="item">2x  Kopi Latte</div>
  $note1
  <div class="item">1x  Croissant</div>
  <div class="item">3x  Es Teh Manis</div>
  $note2
  <hr/>
  <div class="center" style="font-size:${int.parse(fSize) - 2}px;color:#888;margin-top:4px">── KITCHEN TEST ──</div>
</body>
</html>
''';

    printReceiptHtml(htmlContent);
  }

  // ─── 4. DATABASE ──────────────────────

  Widget _buildDatabase() {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDark;
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;

    return ListView(
      children: [
        Text(settings.t('database'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
        const SizedBox(height: 4),
        Text(settings.t('manage_backup'), style: TextStyle(fontSize: 13, color: mutedColor)),
        const SizedBox(height: 24),

        _settingsCard(
          title: settings.t('backup_database'),
          icon: Icons.cloud_download,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: mutedColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      settings.t('backup_desc'),
                      style: TextStyle(fontSize: 12, color: mutedColor),
                    )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(settings.t('backup_started')), backgroundColor: AppTheme.primary),
                      );
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(settings.t('download_backup')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _settingsCard(
          title: settings.t('restore_database'),
          icon: Icons.cloud_upload,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, size: 16, color: Color(0xFFFF6B35)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      settings.t('restore_desc'),
                      style: TextStyle(fontSize: 12, color: mutedColor),
                    )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(settings.t('restore_coming')), backgroundColor: const Color(0xFFFF6B35)),
                      );
                    },
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(settings.t('upload_backup')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B35),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Shared Widgets ───────────────────

  Widget _settingsCard({required String title, required IconData icon, required Widget child, Widget? trailing}) {
    final isDark = context.watch<SettingsProvider>().isDark;
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : AppTheme.textDark;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(children: [
              Icon(icon, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor))),
              if (trailing != null) trailing,
            ]),
          ),
          Divider(height: 1, color: borderColor),
          child,
        ],
      ),
    );
  }

  Widget _dropdownTile(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    final isDark = context.watch<SettingsProvider>().isDark;
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final dropdownBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    return ListTile(
      title: Text(label, style: TextStyle(color: textColor, fontSize: 14)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: dropdownBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          underline: const SizedBox(),
          style: TextStyle(color: AppTheme.primary, fontSize: 13),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    final isDark = context.watch<SettingsProvider>().isDark;
    final textColor = isDark ? Colors.white : AppTheme.textDark;

    return SwitchListTile(
      title: Text(label, style: TextStyle(color: textColor, fontSize: 14)),
      value: value,
      activeColor: AppTheme.success,
      onChanged: onChanged,
    );
  }

  Widget _textFieldTile(String label, String value, ValueChanged<String> onChanged) {
    final isDark = context.watch<SettingsProvider>().isDark;
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final fieldBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    return ListTile(
      title: Text(label, style: TextStyle(color: textColor, fontSize: 14)),
      trailing: SizedBox(
        width: 200,
        child: TextField(
          controller: TextEditingController(text: value),
          style: TextStyle(color: textColor, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: fieldBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
