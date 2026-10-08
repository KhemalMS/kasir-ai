import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../widgets/dashboard_helpers.dart';


class BahanBakuTab extends StatefulWidget {
  const BahanBakuTab({super.key});
  @override State<BahanBakuTab> createState() => BahanBakuTabState();
}

class BahanBakuTabState extends State<BahanBakuTab> {
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
      if (mounted) {
        setState(() {
        _items = results[0]; _alerts = results[1]; _adjustLog = results[2];
        _allRecipes = results[3]; _products = results[4]; _isLoading = false;
      });
      }
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
    final borderColor = isDark ? AppTheme.surfaceDark : const Color(0xFFE2E8F0);
    final sidebarBg = isDark ? AppTheme.cardDark : Colors.white;

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
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;
    final borderColor = isDark ? AppTheme.surfaceDark : const Color(0xFFE2E8F0);

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
                    headingRowColor: WidgetStateProperty.all(isDark ? AppTheme.surfaceDark : const Color(0xFFF1F5F9)),
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
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;
    final borderColor = isDark ? AppTheme.surfaceDark : const Color(0xFFE2E8F0);

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
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;
    final borderColor = isDark ? AppTheme.surfaceDark : const Color(0xFFE2E8F0);

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
                  separatorBuilder: (_, _) => Divider(height: 1, color: borderColor),
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
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;


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
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
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
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        title: Row(children: [
          Expanded(child: Text(settings.t('adjust_stock'), style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark))),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20)),
        ]),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            initialValue: selectedItemId,
            dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
            decoration: InputDecoration(labelText: settings.t('select_item'), labelStyle: TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: isDark ? AppTheme.cardDark : const Color(0xFFF1F5F9)),
            style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark),
            items: _items.map<DropdownMenuItem<String>>((i) => DropdownMenuItem(value: i['id'], child: Text('${i['name']}'))).toList(),
            onChanged: (v) => setS(() => selectedItemId = v),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _dialogField(settings.t('qty'), qtyC, isDark, isNum: true)),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField<String>(
              initialValue: adjustType,
              dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
              decoration: InputDecoration(labelText: settings.t('type'), labelStyle: TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: isDark ? AppTheme.cardDark : const Color(0xFFF1F5F9)),
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
      final fieldBg = isDark ? AppTheme.cardDark : const Color(0xFFF1F5F9);
      final textStyle = TextStyle(color: isDark ? Colors.white : AppTheme.textDark);
      final labelStyle = TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight);
      final dropBg = isDark ? AppTheme.surfaceDark : Colors.white;

      return StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        title: Row(children: [
          Expanded(child: Text(productId != null ? settings.t('edit_recipe') : settings.t('add_recipe'),
            style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark))),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20)),
        ]),
        content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Product dropdown (only for new recipes)
          if (productId == null) ...[
            DropdownButtonFormField<String>(
              initialValue: selectedProduct,
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
              initialValue: selectedVariant,
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
                  initialValue: ing['inventoryId'],
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
        filled: true, fillColor: isDark ? AppTheme.cardDark : const Color(0xFFF1F5F9),
      ),
    );
  }
}