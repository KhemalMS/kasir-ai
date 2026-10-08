
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../../../../utils/platform_helper_web.dart' if (dart.library.io) '../../../../utils/platform_helper_stub.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../widgets/dashboard_helpers.dart';
import '../../../../config/api_config.dart';
import 'products_tab_dialog.dart';

class ProductsTab extends StatefulWidget {
  final NumberFormat? formatter;
  const ProductsTab({super.key, this.formatter});
  @override State<ProductsTab> createState() => ProductsTabState();
}

class ProductsTabState extends State<ProductsTab> with SingleTickerProviderStateMixin {
  String _n(num value) => NumberFormat.compact(locale: 'id').format(value);
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
      if (mounted) {
        setState(() {
        _products = results[0];
        _categories = results[1];
        _isLoading = false;
      });
      }
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
    void calcSellingPrice() {
      final base = int.tryParse(basePriceCtrl.text) ?? 0;
      final mkp = double.tryParse(markupCtrl.text) ?? 0;
      final selling = (base * (1 + mkp / 100)).round();
      sellingPriceCtrl.text = '$selling';
    }

    // Reverse-calc markup from selling price
    void calcMarkup() {
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
      final bgColor = isDark ? AppTheme.cardDark : Colors.white;
      final textColor = isDark ? Colors.white : AppTheme.textDark;
      final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
      final fieldBg = isDark ? AppTheme.surfaceDark : const Color(0xFFF1F5F9);
      final borderCol = isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0);

      InputDecoration inputDeco(String label, {String? prefix, String? hint}) => InputDecoration(
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
                            errorBuilder: (_, _, _) => _uploadPlaceholder(mutedColor, settings)))
                      : _uploadPlaceholder(mutedColor, settings),
                ),
              ),
              const SizedBox(height: 16),

              // ── Nama Produk ──
              TextField(controller: nameCtrl, style: TextStyle(color: textColor),
                decoration: inputDeco('Nama Produk')),
              const SizedBox(height: 12),

              // ── Kode & Satuan (side by side) ──
              Row(children: [
                Expanded(child: TextField(controller: codeCtrl, style: TextStyle(color: textColor),
                  decoration: inputDeco('Kode Produk', hint: 'SKU / barcode'))),
                const SizedBox(width: 10),
                SizedBox(width: 130, child: TextField(controller: unitCtrl, style: TextStyle(color: textColor),
                  decoration: inputDeco('Satuan', hint: 'pcs, cup, porsi'))),
              ]),
              const SizedBox(height: 12),

              // ── Kategori & Aktif (side by side) ──
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  initialValue: categoryId, dropdownColor: bgColor,
                  style: TextStyle(color: textColor),
                  decoration: inputDeco(settings.t('category')),
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
                    activeThumbColor: AppTheme.success,
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
                  decoration: inputDeco('Harga Dasar', prefix: 'Rp '),
                  onChanged: (_) => setS(() => calcSellingPrice()),
                )),
                const SizedBox(width: 10),
                SizedBox(width: 100, child: TextField(controller: markupCtrl, style: TextStyle(color: textColor),
                  keyboardType: TextInputType.number,
                  decoration: inputDeco('Markup', hint: '%'),
                  onChanged: (_) => setS(() => calcSellingPrice()),
                )),
              ]),
              const SizedBox(height: 10),

              // Harga Jual & Pajak
              Row(children: [
                Expanded(child: TextField(controller: sellingPriceCtrl, style: TextStyle(color: textColor),
                  keyboardType: TextInputType.number,
                  decoration: inputDeco('Harga Jual', prefix: 'Rp '),
                  onChanged: (_) => setS(() => calcMarkup()),
                )),
                const SizedBox(width: 10),
                Column(children: [
                  Text('Termasuk Pajak', style: TextStyle(color: mutedColor, fontSize: 10)),
                  const SizedBox(height: 2),
                  Switch(
                    value: taxInclusive,
                    activeThumbColor: AppTheme.primary,
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
                      decoration: inputDeco('Nama variasi'),
                      onChanged: (val) => variants[idx]['name'] = val)),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: TextField(controller: vPriceCtrl,
                      style: TextStyle(color: textColor, fontSize: 13),
                      keyboardType: TextInputType.number,
                      decoration: inputDeco('+/- Harga', prefix: 'Rp '),
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
                  'imageUrl': ?imageUrl,
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
      backgroundColor: AppTheme.cardDark,
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
            color: AppTheme.cardDark,
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
      separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.surfaceDark),
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
                      errorBuilder: (_, _, _) => const Icon(Icons.fastfood, color: AppTheme.primary, size: 20),
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
                Text('Rp ${widget.formatter!.format(_n(p['price']))}',
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
      separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.surfaceDark),
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