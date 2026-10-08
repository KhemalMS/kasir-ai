import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../widgets/dashboard_helpers.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../utils/web_print.dart' if (dart.library.io) '../../../../utils/web_print_stub.dart';
import '../../../../utils/platform_helper_web.dart' if (dart.library.io) '../../../../utils/platform_helper_stub.dart';


class PengaturanTab extends StatefulWidget {
  const PengaturanTab({super.key});
  @override State<PengaturanTab> createState() => PengaturanTabState();
}

class PengaturanTabState extends State<PengaturanTab> {
  int _selectedMenu = 0;
  List<dynamic> _taxes = [];
  bool _isLoading = true;

  int _receiptTabIndex = 0; // 0 = Customer, 1 = Kitchen

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
      if (mounted) {
        setState(() {
        _taxes = results[0];
        _isLoading = false;
      });
      }
    } catch (e) {
      debugPrint('Settings error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Simpan semua pengaturan printer ke SharedPreferences melalui SettingsProvider
  Future<void> _savePrinterSettings() async {
    final settings = context.read<SettingsProvider>();
    await settings.savePrinterSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan printer tersimpan'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showTaxDialog([Map<String, dynamic>? tax]) {
    final nameCtrl = TextEditingController(text: tax?['name'] ?? '');
    final rateCtrl = TextEditingController(text: tax?['rate']?.toString() ?? '');
    bool isActive = tax?['isActive'] ?? true;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardDark,
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
              activeThumbColor: AppTheme.success,
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
    final sidebarBg = isDark ? AppTheme.cardDark : Colors.white;
    final borderColor = isDark ? AppTheme.surfaceDark : const Color(0xFFE2E8F0);
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

        sectionCard(
          title: settings.t('language'),
          icon: Icons.language,
          child: _dropdownTile(settings.t('select_language'), settings.language, ['Indonesia', 'English'],
            (v) => settings.setLanguage(v)),
        ),
        const SizedBox(height: 16),

        sectionCard(
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

        sectionCard(
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
    final tabBg = isDark ? AppTheme.surfaceDark : const Color(0xFFE2E8F0);
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
        sectionCard(
          title: settings.t('printer_settings'),
          icon: Icons.print,
          child: Column(
            children: [
              _textFieldTile(settings.t('printer_name'), settings.printerName,
                (v) => settings.printerName = v),
              _dropdownTile(settings.t('paper_size'), settings.paperSize, ['58mm', '80mm'],
                (v) => settings.paperSize = v),
              _switchTile(settings.t('auto_print'), settings.autoPrint,
                (v) => settings.autoPrint = v),
              _switchTile(settings.t('auto_cash_drawer'), settings.autoCashDrawer,
                (v) => setState(() => settings.autoCashDrawer = v)),
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
        sectionCard(
          title: settings.t('business_logo'),
          icon: Icons.image,
          child: Column(
            children: [
              _switchTile(settings.t('show_logo'), settings.showLogo,
                (v) => setState(() => settings.showLogo = v)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.surfaceDark : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1)),
                      ),
                      child: settings.logoPath.isEmpty
                        ? Icon(Icons.store, size: 32, color: mutedColor)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.network(settings.logoPath, fit: BoxFit.cover),
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
        sectionCard(
          title: settings.t('receipt_customization'),
          icon: Icons.receipt_long,
          child: Column(
            children: [
              _textFieldTile(settings.t('receipt_header'), settings.headerText,
                (v) => setState(() => settings.headerText = v)),
              _textFieldTile(settings.t('receipt_footer'), settings.footerText,
                (v) => setState(() => settings.footerText = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Receipt Fields Visibility
        sectionCard(
          title: settings.t('receipt_fields'),
          icon: Icons.checklist,
          child: Column(
            children: [
              _switchTile(settings.t('receipt_no'), settings.showReceiptNo, (v) => setState(() => settings.showReceiptNo = v)),
              _switchTile(settings.t('order_no'), settings.showOrderNo, (v) => setState(() => settings.showOrderNo = v)),
              _switchTile(settings.t('table_no'), settings.showTableNo, (v) => setState(() => settings.showTableNo = v)),
              _switchTile(settings.t('cashier_user'), settings.showUser, (v) => setState(() => settings.showUser = v)),
              _switchTile(settings.t('item_count'), settings.showItemCount, (v) => setState(() => settings.showItemCount = v)),
              _switchTile(settings.t('total_amount'), settings.showTotal, (v) => setState(() => settings.showTotal = v)),
              _switchTile(settings.t('tax_info'), settings.showTax, (v) => setState(() => settings.showTax = v)),
              _switchTile(settings.t('change_amount'), settings.showChange, (v) => setState(() => settings.showChange = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Font & Layout
        sectionCard(
          title: settings.t('font_layout'),
          icon: Icons.text_fields,
          child: Column(
            children: [
              _dropdownTile(settings.t('font_type'), settings.fontFamily,
                ['Monospace', 'Sans-Serif', 'Serif'],
                (v) => setState(() => settings.fontFamily = v)),
              _dropdownTile(settings.t('font_size_label'), settings.fontSize,
                ['8', '9', '10', '11', '12', '14', '16'],
                (v) => setState(() => settings.fontSize = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Margins
        sectionCard(
          title: settings.t('margins'),
          icon: Icons.space_bar,
          child: Column(
            children: [
              _textFieldTile(settings.t('margin_top'), settings.marginTop, (v) => setState(() => settings.marginTop = v)),
              _textFieldTile(settings.t('margin_bottom'), settings.marginBottom, (v) => setState(() => settings.marginBottom = v)),
              _textFieldTile(settings.t('margin_left'), settings.marginLeft, (v) => setState(() => settings.marginLeft = v)),
              _textFieldTile(settings.t('margin_right'), settings.marginRight, (v) => setState(() => settings.marginRight = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Customer Receipt Preview
        sectionCard(
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
                    if (settings.showLogo && settings.logoPath.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Image.network(settings.logoPath, height: 50),
                      ),
                    Text(settings.headerText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black, fontFamily: 'monospace')),
                    Text(settings.storeAddress.isNotEmpty ? settings.storeAddress : 'Jl. Contoh No. 123',
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(settings.storePhone.isNotEmpty ? 'Telp: ${settings.storePhone}' : 'Telp: 021-1234567',
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    const Divider(color: Colors.black38),
                    if (settings.showReceiptNo) _customerPreviewRow(settings.t('receipt_no'), '#RCP-001'),
                    if (settings.showOrderNo) _customerPreviewRow(settings.t('order_no'), '#ORD-001'),
                    if (settings.showTableNo) _customerPreviewRow(settings.t('table_no'), '5'),
                    if (settings.showUser) _customerPreviewRow(settings.t('cashier_user'), 'Admin'),
                    const Divider(color: Colors.black38),
                    _customerItemRow('Kopi Latte', '2 x 18.000', '36.000'),
                    _customerItemRow('Croissant', '1 x 25.000', '25.000'),
                    _customerItemRow('Es Teh Manis', '3 x 8.000', '24.000'),
                    const Divider(color: Colors.black38),
                    if (settings.showItemCount) _customerPreviewRow(settings.t('item_count'), '6'),
                    if (settings.showTotal) _customerPreviewBoldRow('TOTAL', 'Rp 85.000'),
                    if (settings.showTax) _customerPreviewRow('${settings.t('tax_info')} (10%)', 'Rp 8.500'),
                    if (settings.showTotal) _customerPreviewBoldRow('Grand Total', 'Rp 93.500'),
                    _customerPreviewRow('Bayar (Tunai)', 'Rp 100.000'),
                    if (settings.showChange) _customerPreviewBoldRow(settings.t('change_amount'), 'Rp 6.500'),
                    const Divider(color: Colors.black38),
                    Text(settings.footerText, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
                    const Text('Powered by Kasir-AI', style: TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
              // Tombol Simpan Pengaturan Print
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _savePrinterSettings,
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Simpan Pengaturan Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
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
        sectionCard(
          title: settings.t('kitchen_display'),
          icon: Icons.restaurant,
          child: Column(
            children: [
              _switchTile(settings.t('show_table_number'), settings.kitchenShowTable,
                (v) => setState(() => settings.kitchenShowTable = v)),
              _switchTile(settings.t('show_order_time'), settings.kitchenShowTime,
                (v) => setState(() => settings.kitchenShowTime = v)),
              _switchTile(settings.t('show_special_notes'), settings.kitchenShowNotes,
                (v) => setState(() => settings.kitchenShowNotes = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Kitchen Font Settings
        sectionCard(
          title: settings.t('kitchen_font'),
          icon: Icons.text_fields,
          child: Column(
            children: [
              _dropdownTile(settings.t('font_size_label'), settings.kitchenFontSize,
                ['14', '16', '18', '20', '24'],
                (v) => setState(() => settings.kitchenFontSize = v)),
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
        sectionCard(
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
                    if (settings.kitchenShowTable)
                      _kitchenPreviewRow('Meja', '5'),
                    if (settings.kitchenShowTime)
                      _kitchenPreviewRow('Waktu', '22:45'),
                    const Divider(color: Colors.black54),
                    // Items with per-product notes
                    Text('2x  Kopi Latte', style: TextStyle(fontSize: double.parse(settings.kitchenFontSize), fontWeight: FontWeight.w700, color: Colors.black)),
                    if (settings.kitchenShowNotes)
                      const Padding(
                        padding: EdgeInsets.only(left: 24, bottom: 4),
                        child: Row(children: [
                          Icon(Icons.edit_note, size: 12, color: Colors.orange),
                          SizedBox(width: 4),
                          Text('Tanpa gula', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54)),
                        ]),
                      ),
                    const SizedBox(height: 2),
                    Text('1x  Croissant', style: TextStyle(fontSize: double.parse(settings.kitchenFontSize), fontWeight: FontWeight.w700, color: Colors.black)),
                    const SizedBox(height: 2),
                    Text('3x  Es Teh Manis', style: TextStyle(fontSize: double.parse(settings.kitchenFontSize), fontWeight: FontWeight.w700, color: Colors.black)),
                    if (settings.kitchenShowNotes)
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
    final settings = context.read<SettingsProvider>();
    try {
      webPickFile(
        accept: 'image/*',
        onPicked: (_, _) {},
        onPickedDataUrl: (dataUrl) {
          setState(() => settings.logoPath = dataUrl);
        },
      );
    } catch (e) {
      debugPrint('Logo pick error: $e');
    }
  }

  void _printTestPage() {
    final settings = context.read<SettingsProvider>();
    final mt = settings.marginTop, mb = settings.marginBottom,
          ml = settings.marginLeft, mr = settings.marginRight;
    final font = settings.fontFamily == 'Monospace' ? 'monospace'
        : settings.fontFamily == 'Serif' ? 'serif' : 'sans-serif';
    final fSize = settings.fontSize;

    final fields = <String>[];
    if (settings.showReceiptNo) fields.add('<tr><td>${settings.t('receipt_no')}</td><td style="text-align:right">#TEST-001</td></tr>');
    if (settings.showOrderNo) fields.add('<tr><td>${settings.t('order_no')}</td><td style="text-align:right">#ORD-001</td></tr>');
    if (settings.showTableNo) fields.add('<tr><td>${settings.t('table_no')}</td><td style="text-align:right">5</td></tr>');
    if (settings.showUser) fields.add('<tr><td>${settings.t('cashier_user')}</td><td style="text-align:right">Admin</td></tr>');

    const items = '''
      <tr style="border-top:1px dashed #000;border-bottom:1px dashed #000">
        <td><b>Item</b></td><td style="text-align:center"><b>Qty</b></td><td style="text-align:right"><b>Harga</b></td>
      </tr>
      <tr><td>Kopi Latte</td><td style="text-align:center">2</td><td style="text-align:right">36.000</td></tr>
      <tr><td>Croissant</td><td style="text-align:center">1</td><td style="text-align:right">25.000</td></tr>
      <tr><td>Es Teh Manis</td><td style="text-align:center">3</td><td style="text-align:right">24.000</td></tr>
    ''';

    final totals = <String>[];
    if (settings.showItemCount) totals.add('<tr><td>${settings.t('item_count')}</td><td style="text-align:right">6</td></tr>');
    if (settings.showTotal) totals.add('<tr style="border-top:1px dashed #000"><td><b>Total</b></td><td style="text-align:right"><b>Rp 85.000</b></td></tr>');
    if (settings.showTax) totals.add('<tr><td>${settings.t('tax_info')} (10%)</td><td style="text-align:right">Rp 8.500</td></tr>');
    if (settings.showTotal) totals.add('<tr style="border-top:1px solid #000"><td><b>Grand Total</b></td><td style="text-align:right"><b>Rp 93.500</b></td></tr>');
    if (settings.showChange) totals.add('<tr><td>${settings.t('change_amount')}</td><td style="text-align:right">Rp 6.500</td></tr>');

    final logoHtml = (settings.showLogo && settings.logoPath.isNotEmpty)
      ? '<img src="${settings.logoPath}" style="max-width:80px;max-height:80px;margin-bottom:8px" />'
      : '';

    final storeAddr = settings.storeAddress.isNotEmpty ? settings.storeAddress : 'Jl. Contoh No. 123';
    final storePhone = settings.storePhone.isNotEmpty ? 'Telp: ${settings.storePhone}' : 'Telp: 021-1234567';
    final storeName = settings.storeName.isNotEmpty ? settings.storeName : settings.headerText;

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head><title>Test Print</title>
<style>
  @page { margin: ${mt}mm ${mr}mm ${mb}mm ${ml}mm; }
  body { font-family: $font; font-size: ${fSize}px; color: #000; width: ${settings.paperSize == '58mm' ? '48mm' : '72mm'}; margin: 0 auto; }
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
    <div class="header">$storeName</div>
    <div style="margin-bottom:4px;font-size:${int.parse(fSize) - 1}px">$storeAddr</div>
    <div style="margin-bottom:8px;font-size:${int.parse(fSize) - 1}px">$storePhone</div>
  </div>
  <table>${fields.join('')}</table>
  <table>$items</table>
  <table>${totals.join('')}</table>
  <hr/>
  <div class="center" style="font-size:${int.parse(fSize) - 1}px;margin-top:8px">${settings.footerText}</div>
  <div class="center" style="font-size:${int.parse(fSize) - 2}px;margin-top:4px;color:#888">── TEST PAGE ──</div>
</body>
</html>
''';

    printReceiptHtml(htmlContent);
  }

  void _printKitchenTestPage() {
    final settings = context.read<SettingsProvider>();
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final fSize = settings.kitchenFontSize;
    final noteSize = '${int.parse(fSize) - 2}';

    final infoRows = <String>[];
    if (settings.kitchenShowTable) infoRows.add('<tr><td>Meja</td><td style="text-align:right;font-weight:bold">5</td></tr>');
    if (settings.kitchenShowTime) infoRows.add('<tr><td>Waktu</td><td style="text-align:right;font-weight:bold">$timeStr</td></tr>');

    final note1 = settings.kitchenShowNotes ? '<div class="note">📝 Tanpa gula</div>' : '';
    final note2 = settings.kitchenShowNotes ? '<div class="note">📝 Es dipisah</div>' : '';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head><title>Kitchen Ticket</title>
<style>
  @page { margin: 2mm; size: ${settings.paperSize == '58mm' ? '58mm' : '80mm'} auto; }
  body { font-family: monospace; font-size: ${fSize}px; color: #000; width: ${settings.paperSize == '58mm' ? '48mm' : '72mm'}; margin: 0 auto; }
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

        sectionCard(
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

        sectionCard(
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

  Widget sectionCard({required String title, required IconData icon, required Widget child, Widget? trailing}) {
    final isDark = context.watch<SettingsProvider>().isDark;
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;
    final borderColor = isDark ? AppTheme.surfaceDark : const Color(0xFFE2E8F0);
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
              ?trailing,
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
    final dropdownBg = isDark ? AppTheme.surfaceDark : const Color(0xFFE2E8F0);

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
          dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
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
      activeThumbColor: AppTheme.success,
      onChanged: onChanged,
    );
  }

  Widget _textFieldTile(String label, String value, ValueChanged<String> onChanged) {
    final isDark = context.watch<SettingsProvider>().isDark;
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final fieldBg = isDark ? AppTheme.surfaceDark : const Color(0xFFE2E8F0);

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