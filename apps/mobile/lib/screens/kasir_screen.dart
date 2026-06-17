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
  final List<Map<String, dynamic>> _cart = [];
  String? _selectedCategoryId;
  String _orderType = 'Makan di Tempat';
  String _tableNumber = '';
  final _tableNumberController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
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
          // Sort categories A-Z
          cats.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
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
    var filtered = _products;
    if (_selectedCategoryId != null) {
      filtered = filtered.where((p) => p['categoryId'] == _selectedCategoryId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((p) => (p['name']?.toString().toLowerCase() ?? '').contains(q)).toList();
    }
    return filtered;
  }

  int get _subtotal => _cart.fold(0, (sum, item) =>
      sum + ((item['price'] as int) * (item['quantity'] as int)));
  
  int get _taxAmount => (_subtotal * 0.10).round(); // 10% tax

  int get _totalAmount => _subtotal + _taxAmount;

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
      backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
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
          'imageUrl': product['imageUrl'],
        });
      }
    });
  }

  void _showChangeVariantSheet(int cartIdx, Map<String, dynamic> product, List<dynamic> variants) {
    final settings = context.read<SettingsProvider>();
    final isDark = settings.isDark;
    final textColor = isDark ? AppTheme.textWhite : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    final basePrice = (product['price'] as num?)?.toInt() ?? 0;
    final currentVariantId = _cart[cartIdx]['variantId'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                  Expanded(child: Text('Ubah Variasi — ${product['name']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor))),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, color: mutedColor, size: 20)),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(child: SingleChildScrollView(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Base product
                  _variantOption(ctx, cartIdx, product, null, null, basePrice, basePrice, currentVariantId, textColor, mutedColor, isDark),
                  // Variants
                  ...variants.map((v) {
                    final mod = (v['priceModifier'] as num?)?.toInt() ?? 0;
                    return _variantOption(ctx, cartIdx, product, v['id'], v['name'], basePrice + mod, mod, currentVariantId, textColor, mutedColor, isDark);
                  }),
                ],
              ))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _variantOption(BuildContext ctx, int cartIdx, Map<String, dynamic> product, String? variantId, String? variantName, int totalPrice, int mod, String? currentVariantId, Color textColor, Color mutedColor, bool isDark) {
    final isSelected = currentVariantId == variantId;
    final modStr = mod > 0 && variantId != null ? ' (+Rp ${_formatter.format(mod)})' : mod < 0 && variantId != null ? ' (-Rp ${_formatter.format(mod.abs())})' : '';
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        if (!isSelected) {
          setState(() {
            final qty = _cart[cartIdx]['quantity'] as int;
            final notes = _cart[cartIdx]['notes'] as String;
            // Remove old
            _cart.removeAt(cartIdx);
            // Add new or merge
            final cartKey = '${product['id']}_${variantId ?? 'base'}';
            final existingIdx = _cart.indexWhere((i) => i['_cartKey'] == cartKey);
            if (existingIdx >= 0) {
              _cart[existingIdx]['quantity'] = (_cart[existingIdx]['quantity'] as int) + qty;
              if (notes.isNotEmpty) {
                final exNotes = _cart[existingIdx]['notes'] as String;
                _cart[existingIdx]['notes'] = exNotes.isEmpty ? notes : '$exNotes | $notes';
              }
            } else {
              _cart.insert(cartIdx >= _cart.length ? _cart.length : cartIdx, {
                '_cartKey': cartKey,
                'productId': product['id'],
                'variantId': variantId,
                'variantName': variantName,
                'name': product['name'],
                'price': totalPrice,
                'quantity': qty,
                'notes': notes,
                'imageUrl': product['imageUrl'],
              });
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.primary : (isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(variantName ?? 'Original', style: TextStyle(color: isSelected ? AppTheme.primary : textColor, fontWeight: FontWeight.w600)),
                if (modStr.isNotEmpty) Text(modStr, style: TextStyle(color: mutedColor, fontSize: 11)),
              ],
            )),
            Text('Rp ${_formatter.format(totalPrice)}', style: TextStyle(color: isSelected ? AppTheme.primary : textColor, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
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
        taxAmount: _taxAmount,
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
    final auth = context.watch<AuthProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.point_of_sale, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Kasir-AI',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
          ),
          
          const Spacer(),

          // Center Search Bar
          SizedBox(
            width: 320,
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(fontSize: 14, color: textColor),
              decoration: InputDecoration(
                hintText: 'Cari menu...',
                hintStyle: TextStyle(color: mutedColor, fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 18, color: mutedColor),
                filled: true,
                fillColor: subtleBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Order type selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: subtleBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _orderType,
              dropdownColor: cardColor,
              underline: const SizedBox(),
              isDense: true,
              style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w600),
              icon: Icon(Icons.arrow_drop_down, color: mutedColor),
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
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _tableNumberController,
                onChanged: (v) => _tableNumber = v,
                style: TextStyle(fontSize: 13, color: textColor),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Meja',
                  hintStyle: TextStyle(color: mutedColor, fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),

          const SizedBox(width: 16),

          // Profile Dropdown Menu
          PopupMenuButton<String>(
            color: cardColor,
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: subtleBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primary.withOpacity(0.2),
                    child: Text(
                      auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(auth.userName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor)),
                      Text(auth.userRole, style: TextStyle(fontSize: 10, color: mutedColor)),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 16, color: mutedColor),
                ],
              ),
            ),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.userName, style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                    Text(auth.user?['email'] ?? '', style: TextStyle(fontSize: 11, color: mutedColor)),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: borderColor),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 18, color: mutedColor),
                    const SizedBox(width: 10),
                    Text('Profil Saya', style: TextStyle(color: textColor, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, size: 18, color: mutedColor),
                    const SizedBox(width: 10),
                    Text('Riwayat Transaksi', style: TextStyle(color: textColor, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 18, color: AppTheme.danger),
                    const SizedBox(width: 10),
                    const Text('Akhiri Shift', style: TextStyle(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            onSelected: (val) {
              if (val == 'logout') Navigator.pushReplacementNamed(context, '/tutup-shift');
              if (val == 'history') _showHistoryDrawer(cardColor, textColor, mutedColor, borderColor, subtleBg, isDark);
              if (val == 'profile') Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(Color cardColor, Color textColor, Color mutedColor, Color subtleBg, bool isDark) {
    return Container(
      height: 56,
      color: cardColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _categoryPill('Semua', null, Icons.grid_view, textColor, mutedColor, subtleBg),
          ..._categories.map((c) {
            IconData icon = Icons.label;
            final n = c['name']?.toString().toLowerCase() ?? '';
            if (n.contains('makan')) icon = Icons.restaurant;
            else if (n.contains('minum')) icon = Icons.local_cafe;
            else if (n.contains('snack') || n.contains('camilan')) icon = Icons.cookie;
            return _categoryPill(c['name'], c['id'], icon, textColor, mutedColor, subtleBg);
          }),
        ],
      ),
    );
  }

  Widget _categoryPill(String name, String? id, IconData icon, Color textColor, Color mutedColor, Color subtleBg) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategoryId = id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : subtleBg,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Row(
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : mutedColor),
              const SizedBox(width: 6),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : textColor,
                ),
              ),
            ],
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
          color: isDark ? AppTheme.surfaceDark : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.transparent : borderColor),
          boxShadow: isDark ? null : [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image (Square-ish top)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : AppTheme.primary.withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: product['imageUrl'] != null && product['imageUrl'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        '${ApiConfig.baseUrl.replaceAll('/api', '')}${product['imageUrl']}',
                        fit: BoxFit.cover, width: double.infinity,
                        errorBuilder: (_, _, _) => const Center(child: Icon(Icons.fastfood, size: 36, color: AppTheme.primary)),
                      ),
                    )
                  : const Center(child: Icon(Icons.fastfood, size: 36, color: AppTheme.primary)),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatter.format(product['price'] ?? 0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  if ((product['variants'] as List<dynamic>? ?? []).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${(product['variants'] as List).length} variasi',
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : AppTheme.textMutedLight, fontWeight: FontWeight.w500),
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
    final auth = context.watch<AuthProvider>();
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(left: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          // Cart header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PESANAN SAAT INI',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)} • ${auth.userName}',
                        style: TextStyle(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (_cart.isNotEmpty)
                  IconButton(
                    onPressed: _clearCart,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                    ),
                    tooltip: 'Kosongkan Keranjang',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Cart items
          Expanded(
            child: _cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 64, color: mutedColor.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('Belum ada pesanan', style: TextStyle(color: mutedColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Silakan pilih menu terlebih dahulu', style: TextStyle(color: mutedColor, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cart.length,
                    separatorBuilder: (ctx, i) => Divider(height: 24, color: borderColor),
                    itemBuilder: (ctx, i) => _cartItem(i, textColor, mutedColor, subtleBg, isDark),
                  ),
          ),

          // Total & Checkout
          if (_cart.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                border: Border(top: BorderSide(color: borderColor)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal', style: TextStyle(fontSize: 14, color: mutedColor)),
                      Text('Rp ${_formatter.format(_subtotal)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pajak (10%)', style: TextStyle(fontSize: 14, color: mutedColor)),
                      Text('Rp ${_formatter.format(_taxAmount)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Bayar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                      Text(
                        'Rp ${_formatter.format(_totalAmount)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _showPaymentDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('BAYAR SEKARANG', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
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

  Widget _cartItem(int idx, Color textColor, Color mutedColor, Color subtleBg, bool isDark) {
    final item = _cart[idx];
    final hasNote = (item['notes'] as String?)?.isNotEmpty == true;
    final imgUrl = item['imageUrl'] as String?;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: imgUrl != null && imgUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    '${ApiConfig.baseUrl.replaceAll('/api', '')}$imgUrl',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.fastfood, color: AppTheme.primary, size: 24),
                  ),
                )
              : const Icon(Icons.fastfood, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(width: 12),
        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
              const SizedBox(height: 2),
              Text('Rp ${_formatter.format(item['price'])}', style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              
              if (item['variantName'] != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    // Try to load product to show variants
                    final prodId = item['productId'];
                    final p = _products.firstWhere((p) => p['id'] == prodId, orElse: () => null);
                    if (p != null) {
                      final variants = p['variants'] as List<dynamic>? ?? [];
                      if (variants.isNotEmpty) {
                        _showChangeVariantSheet(idx, p, variants);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: subtleBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item['variantName'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 10, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Note and quantity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _showNoteDialog(idx, textColor, subtleBg),
                    child: Row(
                      children: [
                        Icon(hasNote ? Icons.edit_note : Icons.add_comment_outlined, size: 16, color: hasNote ? AppTheme.warning : mutedColor),
                        const SizedBox(width: 4),
                        Text(hasNote ? 'Edit catatan' : 'Tambah catatan', style: TextStyle(fontSize: 12, color: hasNote ? AppTheme.warning : mutedColor)),
                      ],
                    ),
                  ),
                  
                  // Quantity
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _updateQuantity(idx, -1),
                          icon: Icon(item['quantity'] > 1 ? Icons.remove : Icons.delete_outline, size: 14, color: item['quantity'] > 1 ? textColor : AppTheme.danger),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                        Container(
                          width: 24,
                          alignment: Alignment.center,
                          child: Text('${item['quantity']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                        ),
                        IconButton(
                          onPressed: () => _updateQuantity(idx, 1),
                          icon: const Icon(Icons.add, size: 14, color: AppTheme.primary),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (hasNote) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
                  ),
                  width: double.infinity,
                  child: Text(
                    '"${item['notes']}"',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.warning),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showNoteDialog(int idx, Color textColor, Color subtleBg) {
    final settings = context.read<SettingsProvider>();
    final isDark = settings.isDark;
    final ctrl = TextEditingController(text: _cart[idx]['notes'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
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
              color: isDark ? AppTheme.cardDark : Colors.white,
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
                          separatorBuilder: (_, _) => Divider(height: 1, color: borderColor),
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
          color: isDark ? AppTheme.cardDark : const Color(0xFFF8FAFC),
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
          backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
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
