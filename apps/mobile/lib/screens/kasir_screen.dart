import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/products_service.dart';
import '../services/categories_service.dart';
import '../services/orders_service.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import 'payment_screen.dart';
import 'receipt_screen.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  final _formatter = NumberFormat('#,###', 'id_ID');
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  List<Map<String, dynamic>> _cart = [];
  String? _selectedCategoryId;
  String _orderType = 'Makan di Tempat';
  String _tableNumber = '';
  final _tableNumberController = TextEditingController();
  bool _isLoadingProducts = true;
  String? _loadError;
  List<dynamic> _shiftOrders = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadShiftOrders();
  }

  Future<void> _loadShiftOrders() async {
    final auth = context.read<AuthProvider>();
    final shiftId = auth.currentShiftId;
    if (shiftId == null || shiftId.isEmpty) return;
    setState(() => _isLoadingHistory = true);
    try {
      final orders = await OrdersService.getByShift(shiftId);
      if (mounted) setState(() { _shiftOrders = orders; _isLoadingHistory = false; });
    } catch (e) {
      debugPrint('History load error: $e');
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _loadData() async {
    setState(() { _isLoadingProducts = true; _loadError = null; });
    try {
      debugPrint('🔄 Loading categories...');
      final cats = await CategoriesService.getAll();
      debugPrint('✅ Categories: ${cats.length}');
      
      debugPrint('🔄 Loading products...');
      final prods = await ProductsService.getAll();
      debugPrint('✅ Products: ${prods.length}');
      
      if (mounted) {
        setState(() {
          _categories = cats;
          _products = prods;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load error: $e');
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _loadError = e.toString();
        });
      }
    }
  }

  List<dynamic> get _filteredProducts {
    if (_selectedCategoryId == null) return _products;
    return _products.where((p) => p['categoryId'] == _selectedCategoryId).toList();
  }

  int get _subtotal => _cart.fold(0, (sum, item) =>
      sum + ((item['price'] as int) * (item['quantity'] as int)));

  int get _totalAmount => _subtotal;

  void _addToCart(Map<String, dynamic> product) {
    final variants = product['variants'] as List<dynamic>? ?? [];
    if (variants.isNotEmpty) {
      _showVariantPicker(product, variants);
    } else {
      _addItemToCart(product, null, null, product['price'] as int);
    }
  }

  void _showVariantPicker(Map<String, dynamic> product, List<dynamic> variants) {
    final settings = context.read<SettingsProvider>();
    final isDark = settings.isDark;
    final textColor = isDark ? AppTheme.textWhite : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    final basePrice = (product['price'] as num?)?.toInt() ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
        child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.style, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Pilih Variasi — ${product['name']}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor))),
                IconButton(onPressed: () => Navigator.pop(ctx),
                  icon: Icon(Icons.close, color: mutedColor, size: 20)),
              ],
            ),
            const SizedBox(height: 12),
            // Scrollable variant list
            Flexible(child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Base product (no variant)
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _addItemToCart(product, null, null, basePrice);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Original', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                        Text('Rp ${_formatter.format(basePrice)}',
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                // Variants
                ...variants.map((v) {
                  final mod = (v['priceModifier'] as num?)?.toInt() ?? 0;
                  final totalPrice = basePrice + mod;
                  final modStr = mod > 0 ? ' (+Rp ${_formatter.format(mod)})' : mod < 0 ? ' (-Rp ${_formatter.format(mod.abs())})' : '';
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _addItemToCart(product, v['id'], v['name'], totalPrice);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v['name'] ?? '-', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                              if (modStr.isNotEmpty)
                                Text(modStr, style: TextStyle(color: mutedColor, fontSize: 11)),
                            ],
                          )),
                          Text('Rp ${_formatter.format(totalPrice)}',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ))),
          ],
        ),
      )),
    );
  }

  void _addItemToCart(Map<String, dynamic> product, String? variantId, String? variantName, int price) {
    setState(() {
      // Use composite key: productId + variantId
      final cartKey = '${product['id']}_${variantId ?? 'base'}';
      final idx = _cart.indexWhere((i) => i['_cartKey'] == cartKey);
      if (idx >= 0) {
        _cart[idx]['quantity'] = (_cart[idx]['quantity'] as int) + 1;
      } else {
        _cart.add({
          '_cartKey': cartKey,
          'productId': product['id'],
          'variantId': variantId,
          'variantName': variantName,
          'name': product['name'],
          'price': price,
          'quantity': 1,
          'notes': '',
        });
      }
    });
  }

  void _updateQuantity(int idx, int delta) {
    setState(() {
      final newQty = (_cart[idx]['quantity'] as int) + delta;
      if (newQty <= 0) {
        _cart.removeAt(idx);
      } else {
        _cart[idx]['quantity'] = newQty;
      }
    });
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  Future<void> _handleCheckout(String paymentMethod, int paidAmount) async {
    final auth = context.read<AuthProvider>();
    final orderNum = 'ORD${DateTime.now().millisecondsSinceEpoch}';
    final cartCopy = List<Map<String, dynamic>>.from(_cart);

    try {
      await OrdersService.create(
        orderNumber: orderNum,
        staffId: auth.staffId,
        branchId: auth.branchId,
        shiftId: auth.currentShiftId,
        orderType: _orderType,
        tableNumber: _tableNumber.isEmpty ? null : _tableNumber,
        subtotal: _subtotal,
        taxAmount: 0,
        serviceAmount: 0,
        totalAmount: _totalAmount,
        items: _cart.map((item) => <String, dynamic>{
          'productId': item['productId'],
          'variantId': item['variantId'],
          'quantity': item['quantity'],
          'price': item['price'],
          'notes': (item['notes'] as String?)?.isNotEmpty == true ? item['notes'] : null,
        }).toList(),
        paymentMethods: [
          {'method': paymentMethod, 'amount': _totalAmount},
        ],
      );

      final total = _totalAmount;
      if (mounted) {
        setState(() {
          _cart.clear();
          _tableNumber = '';
          _tableNumberController.clear();
        });

        // Refresh transaction history
        _loadShiftOrders();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(
              orderNumber: orderNum,
              paymentMethod: paymentMethod,
              totalAmount: total,
              paidAmount: paidAmount,
              changeAmount: paymentMethod == 'Tunai' ? paidAmount - total : 0,
              items: cartCopy,
              cashierName: auth.userName,
              orderType: _orderType,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDark;
    final isWide = MediaQuery.of(context).size.width > 800;

    // Theme-aware colors
    final bgColor = isDark ? AppTheme.bgDark : AppTheme.bgLight;
    final cardColor = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final textColor = isDark ? AppTheme.textWhite : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0);
    final subtleBg = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: isWide
            ? _buildWideLayout(cardColor, textColor, mutedColor, borderColor, subtleBg, isDark)
            : _buildNarrowLayout(cardColor, textColor, mutedColor, borderColor, subtleBg, isDark),
      ),
    );
  }

  // ── Wide Layout (tablet/web) ──────────────────────────────────
  Widget _buildWideLayout(Color cardColor, Color textColor, Color mutedColor, Color borderColor, Color subtleBg, bool isDark) {
    return Row(
      children: [
        // Left: Products
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildTopBar(cardColor, textColor, mutedColor, borderColor, subtleBg, isDark),
              _buildCategoryTabs(cardColor, textColor, mutedColor, subtleBg, isDark),
              Expanded(child: _buildProductGrid(textColor, mutedColor, isDark, cardColor, borderColor)),
            ],
          ),
        ),
        // Right: Cart
        SizedBox(
          width: 380,
          child: _buildCartPanel(cardColor, textColor, mutedColor, borderColor, subtleBg, isDark),
        ),
      ],
    );
  }

  // ── Narrow Layout (phone) ─────────────────────────────────────
  Widget _buildNarrowLayout(Color cardColor, Color textColor, Color mutedColor, Color borderColor, Color subtleBg, bool isDark) {
    return Column(
      children: [
        _buildTopBar(cardColor, textColor, mutedColor, borderColor, subtleBg, isDark),
        _buildCategoryTabs(cardColor, textColor, mutedColor, subtleBg, isDark),
        Expanded(child: _buildProductGrid(textColor, mutedColor, isDark, cardColor, borderColor)),
        if (_cart.isNotEmpty) _buildCartBottomBar(cardColor, textColor, mutedColor, borderColor, subtleBg, isDark),
      ],
    );
  }

  Widget _buildTopBar(Color cardColor, Color textColor, Color mutedColor, Color borderColor, Color subtleBg, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.point_of_sale, color: AppTheme.primary, size: 24),
          const SizedBox(width: 10),
          Text(
            'Kasir POS',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
          ),
          const Spacer(),
          // Order type selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: subtleBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _orderType,
              dropdownColor: cardColor,
              underline: const SizedBox(),
              isDense: true,
              style: TextStyle(fontSize: 13, color: textColor),
              items: const [
                DropdownMenuItem(value: 'Makan di Tempat', child: Text('Dine In')),
                DropdownMenuItem(value: 'Bungkus', child: Text('Take Away')),
              ],
              onChanged: (v) => setState(() => _orderType = v!),
            ),
          ),
          if (_orderType == 'Makan di Tempat')
            Container(
              width: 72,
              height: 36,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: subtleBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _tableNumberController,
                onChanged: (v) => _tableNumber = v,
                style: TextStyle(fontSize: 13, color: textColor),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Meja',
                  hintStyle: TextStyle(color: mutedColor, fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Transaction history button
          Stack(
            children: [
              IconButton(
                onPressed: () => _showHistoryDrawer(cardColor, textColor, mutedColor, borderColor, subtleBg, isDark),
                icon: const Icon(Icons.receipt_long, color: AppTheme.primary, size: 22),
                tooltip: 'Riwayat Transaksi',
              ),
              if (_shiftOrders.isNotEmpty)
                Positioned(
                  right: 4, top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                    child: Text('${_shiftOrders.length}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          // End shift button
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/tutup-shift'),
            icon: const Icon(Icons.logout, color: AppTheme.danger, size: 20),
            tooltip: 'Akhiri Shift',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(Color cardColor, Color textColor, Color mutedColor, Color subtleBg, bool isDark) {
    return Container(
      height: 48,
      color: cardColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _categoryChip('Semua', null, textColor, mutedColor, subtleBg),
          ..._categories.map((c) => _categoryChip(c['name'], c['id'], textColor, mutedColor, subtleBg)),
        ],
      ),
    );
  }

  Widget _categoryChip(String name, String? id, Color textColor, Color mutedColor, Color subtleBg) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategoryId = id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : subtleBg,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : mutedColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(Color textColor, Color mutedColor, bool isDark, Color cardColor, Color borderColor) {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
            const SizedBox(height: 12),
            Text('Gagal memuat produk', style: TextStyle(color: textColor, fontSize: 16)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_loadError!, style: TextStyle(color: mutedColor, fontSize: 12), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final products = _filteredProducts;
    if (products.isEmpty) {
      return Center(
        child: Text('Belum ada produk', style: TextStyle(color: mutedColor)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: products.length,
      itemBuilder: (ctx, i) => _productCard(products[i], textColor, cardColor, borderColor, isDark),
    );
  }

  Widget _productCard(Map<String, dynamic> product, Color textColor, Color cardColor, Color borderColor, bool isDark) {
    return GestureDetector(
      onTap: () => _addToCart(product),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isDark ? null : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: isDark ? 0.08 : 0.06),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: product['imageUrl'] != null && product['imageUrl'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        '${ApiConfig.baseUrl.replaceAll('/api', '')}${product['imageUrl']}',
                        fit: BoxFit.cover, width: double.infinity,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.fastfood, size: 36, color: AppTheme.primary)),
                      ),
                    )
                  : const Center(child: Icon(Icons.fastfood, size: 36, color: AppTheme.primary)),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatter.format(product['price'] ?? 0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  if ((product['variants'] as List<dynamic>? ?? []).isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${(product['variants'] as List).length} variasi',
                      style: TextStyle(fontSize: 10, color: AppTheme.primary.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cart Panel (for wide layout) ──────────────────────────────
  Widget _buildCartPanel(Color cardColor, Color textColor, Color mutedColor, Color borderColor, Color subtleBg, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(left: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          // Cart header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Keranjang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                ),
                const Spacer(),
                if (_cart.isNotEmpty)
                  GestureDetector(
                    onTap: _clearCart,
                    child: const Text('Hapus Semua', style: TextStyle(fontSize: 12, color: AppTheme.danger)),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          // Cart items
          Expanded(
            child: _cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 48, color: mutedColor.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text('Keranjang kosong', style: TextStyle(color: mutedColor)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (ctx, i) => _cartItem(i, textColor, mutedColor, subtleBg),
                  ),
          ),

          // Total & Checkout
          if (_cart.isNotEmpty) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: mutedColor)),
                      Text(
                        'Rp ${_formatter.format(_totalAmount)}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _showPaymentDialog(),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment, size: 20),
                          SizedBox(width: 8),
                          Text('Bayar'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cartItem(int idx, Color textColor, Color mutedColor, Color subtleBg) {
    final item = _cart[idx];
    final hasNote = (item['notes'] as String?)?.isNotEmpty == true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    if (item['variantName'] != null)
                      Text(
                        item['variantName'],
                        style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500),
                      ),
                    Text(
                      'Rp ${_formatter.format(item['price'])}',
                      style: TextStyle(fontSize: 12, color: mutedColor),
                    ),
                  ],
                ),
              ),
              // Note button
              GestureDetector(
                onTap: () => _showNoteDialog(idx, textColor, subtleBg),
                child: Container(
                  width: 30, height: 30,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: hasNote ? AppTheme.warning.withValues(alpha: 0.15) : subtleBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    hasNote ? Icons.edit_note : Icons.note_add_outlined,
                    size: 16,
                    color: hasNote ? AppTheme.warning : mutedColor,
                  ),
                ),
              ),
              // Quantity controls
              Container(
                decoration: BoxDecoration(
                  color: subtleBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _updateQuantity(idx, -1),
                      icon: Icon(Icons.remove, size: 16, color: mutedColor),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${item['quantity']}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _updateQuantity(idx, 1),
                      icon: const Icon(Icons.add, size: 16, color: AppTheme.primary),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rp ${_formatter.format((item['price'] as int) * (item['quantity'] as int))}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
              ),
            ],
          ),
          // Show note if exists
          if (hasNote)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, size: 13, color: AppTheme.warning),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item['notes'],
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.warning),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showNoteDialog(int idx, Color textColor, Color subtleBg) {
    final settings = context.read<SettingsProvider>();
    final isDark = settings.isDark;
    final ctrl = TextEditingController(text: _cart[idx]['notes'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.edit_note, color: AppTheme.warning, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Catatan — ${_cart[idx]['name']}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _cart[idx]['notes'] = '');
                Navigator.pop(ctx);
              },
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(Icons.close, size: 16, color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: textColor),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Contoh: Tanpa gula, Level pedas 5, Es dipisah...',
            hintStyle: TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight, fontSize: 13),
            filled: true,
            fillColor: subtleBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() => _cart[idx]['notes'] = ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ── Mobile bottom bar ─────────────────────────────────────────
  Widget _buildCartBottomBar(Color cardColor, Color textColor, Color mutedColor, Color borderColor, Color subtleBg, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_cart.length} item', style: TextStyle(fontSize: 12, color: mutedColor)),
              Text(
                'Rp ${_formatter.format(_totalAmount)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
              ),
            ],
          ),
          const Spacer(),
          if (_orderType == 'Makan di Tempat') ...[
            Container(
              width: 80,
              height: 48,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: subtleBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                onChanged: (v) => _tableNumber = v,
                style: TextStyle(fontSize: 14, color: textColor),
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'No. Meja',
                  hintStyle: TextStyle(color: mutedColor, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
          ElevatedButton(
            onPressed: _showPaymentDialog,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const Text('Bayar'),
          ),
        ],
      ),
    );
  }

  // ── Navigate to Payment Screen ────────────────────────────────
  void _showPaymentDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          totalAmount: _totalAmount,
          cartItems: List<Map<String, dynamic>>.from(_cart),
          onConfirmPayment: (method, paidAmount) {
            Navigator.pop(context);
            _handleCheckout(method, paidAmount);
          },
        ),
      ),
    );
  }

  // ── Transaction History Drawer ─────────────────────────────────
  void _showHistoryDrawer(Color cardColor, Color textColor, Color mutedColor, Color borderColor, Color subtleBg, bool isDark) {
    // Reload before showing
    _loadShiftOrders();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          final totalRevenue = _shiftOrders.fold<int>(0, (sum, o) => sum + ((o['totalAmount'] as num?)?.toInt() ?? 0));
          final totalTx = _shiftOrders.length;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1117) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: mutedColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Riwayat Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                            Text('Shift berjalan', style: TextStyle(fontSize: 12, color: mutedColor)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await _loadShiftOrders();
                          setS(() {});
                        },
                        icon: Icon(Icons.refresh, color: mutedColor, size: 20),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close, color: mutedColor, size: 20),
                      ),
                    ],
                  ),
                ),
                // Summary cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _summaryCard('Total Transaksi', '$totalTx', Icons.shopping_cart, AppTheme.primary, isDark),
                      const SizedBox(width: 12),
                      _summaryCard('Total Pendapatan', 'Rp ${_formatter.format(totalRevenue)}', Icons.account_balance_wallet, AppTheme.success, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: borderColor),
                // Orders list
                Expanded(
                  child: _isLoadingHistory
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : _shiftOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long, size: 48, color: mutedColor.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text('Belum ada transaksi', style: TextStyle(color: mutedColor, fontSize: 14)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(0),
                          itemCount: _shiftOrders.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                          itemBuilder: (_, i) {
                            final order = _shiftOrders[i];
                            final createdAt = order['createdAt']?.toString() ?? '';
                            String timeStr = '';
                            try {
                              final dt = DateTime.parse(createdAt).toLocal();
                              timeStr = DateFormat('HH:mm').format(dt);
                            } catch (_) {
                              timeStr = createdAt.length > 16 ? createdAt.substring(11, 16) : createdAt;
                            }
                            final total = (order['totalAmount'] as num?)?.toInt() ?? 0;
                            final orderNum = order['orderNumber'] ?? '-';
                            final orderType = order['orderType'] ?? '';
                            final status = order['status'] ?? '';
                            final tableNum = order['tableNumber'];

                            return InkWell(
                              onTap: () => _showOrderDetail(order, textColor, mutedColor, isDark, borderColor),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                child: Row(
                                  children: [
                                    // Icon
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(orderNum, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time, size: 12, color: mutedColor),
                                              const SizedBox(width: 4),
                                              Text(timeStr, style: TextStyle(fontSize: 11, color: mutedColor)),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(orderType, style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                              ),
                                              if (tableNum != null && tableNum.toString().isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Text('Meja $tableNum', style: TextStyle(fontSize: 10, color: mutedColor)),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Total
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Rp ${_formatter.format(total)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppTheme.success.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(status, style: const TextStyle(fontSize: 10, color: AppTheme.success, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.chevron_right, size: 18, color: mutedColor),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color), overflow: TextOverflow.ellipsis),
                  Text(title, style: TextStyle(fontSize: 10, color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetail(Map<String, dynamic> order, Color textColor, Color mutedColor, bool isDark, Color borderColor) async {
    // Fetch full order with items
    try {
      final detail = await OrdersService.getById(order['id']);
      if (!mounted) return;

      final items = detail['items'] as List<dynamic>? ?? [];
      final orderPayments = detail['payments'] as List<dynamic>? ?? [];
      final total = (order['totalAmount'] as num?)?.toInt() ?? 0;
      final orderNum = order['orderNumber'] ?? '-';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.receipt, color: AppTheme.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text(orderNum, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor))),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: Icon(Icons.close, color: mutedColor, size: 20),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Items
                  Text('Item Pesanan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 8),
                  ...items.map((item) {
                    final qty = (item['quantity'] as num?)?.toInt() ?? 0;
                    final price = (item['priceAtOrder'] as num?)?.toInt() ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Center(child: Text('$qty', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item['productName'] ?? item['productId'] ?? '-', style: TextStyle(fontSize: 13, color: textColor))),
                          Text('Rp ${_formatter.format(price * qty)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 12),
                  // Payment info
                  if (orderPayments.isNotEmpty) ...[
                    Text('Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 6),
                    ...orderPayments.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p['method'] ?? '-', style: TextStyle(fontSize: 13, color: mutedColor)),
                          Text('Rp ${_formatter.format((p['amount'] as num?)?.toInt() ?? 0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 8),
                  ],
                  // Total
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                        Text('Rp ${_formatter.format(total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Order detail error: $e');
    }
  }
}
