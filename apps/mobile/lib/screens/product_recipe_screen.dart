import 'package:flutter/material.dart';
import '../services/error_notifier.dart';
import '../services/error_mapper.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

class ProductRecipeScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const ProductRecipeScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductRecipeScreen> createState() => _ProductRecipeScreenState();
}

class _ProductRecipeScreenState extends State<ProductRecipeScreen> {
  bool _isLoading = true;
  List<dynamic> _ingredients = [];
  List<dynamic> _rawMaterials = [];
  
  String? _selectedMaterialId;
  final TextEditingController _qtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getList('/products/${widget.productId}/recipe'),
        ApiService.getList('/inventory'), // Fetch all raw materials
      ]);
      if (mounted) {
        setState(() {
          _ingredients = results[0];
          _rawMaterials = results[1];
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() => _isLoading = false);
        final err = ErrorMapper.from(e, stack, module: 'inventory', action: 'loadRecipe');
        ErrorNotifier.show(err);
      }
    }
  }

  Future<void> _saveRecipe() async {
    // API expects full array of {inventoryId, quantityUsed}
    final payload = {
      'ingredients': _ingredients.map((ing) => {
        'inventoryId': ing['inventoryId'],
        'quantityUsed': num.tryParse(ing['quantityUsed'].toString()) ?? 0,
      }).toList()
    };

    try {
      await ApiService.post('/products/${widget.productId}/recipe', payload);
      if (mounted) {
        ErrorNotifier.showSuccess('Resep berhasil disimpan');
        Navigator.pop(context, true); // Return true to refresh parent if needed
      }
    } catch (e, stack) {
      if (mounted) {
        final err = ErrorMapper.from(e, stack, module: 'inventory', action: 'saveRecipe');
        ErrorNotifier.show(err);
      }
    }
  }

  void _addIngredient() {
    if (_selectedMaterialId == null || _qtyCtrl.text.isEmpty) return;
    
    final material = _rawMaterials.firstWhere((m) => m['id'] == _selectedMaterialId);
    final qty = double.tryParse(_qtyCtrl.text) ?? 0.0;
    if (qty <= 0) return;

    setState(() {
      // Check if already exists
      final existingIndex = _ingredients.indexWhere((i) => i['inventoryId'] == _selectedMaterialId);
      if (existingIndex >= 0) {
        _ingredients[existingIndex]['quantityUsed'] = qty;
      } else {
        _ingredients.add({
          'inventoryId': material['id'],
          'inventoryName': material['name'],
          'inventoryUnit': material['unit'],
          'quantityUsed': qty,
        });
      }
      _selectedMaterialId = null;
      _qtyCtrl.clear();
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manajemen Resep', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.productName, style: const TextStyle(color: AppTheme.primary, fontSize: 13)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveRecipe,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Simpan Resep'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left panel: List of current ingredients
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.surfaceDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Bahan Baku Produk', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                          const Divider(height: 1, color: AppTheme.surfaceDark),
                          Expanded(
                            child: _ingredients.isEmpty
                                ? const Center(child: Text('Belum ada bahan baku (Resep Kosong)', style: TextStyle(color: AppTheme.textMuted)))
                                : ListView.separated(
                                    itemCount: _ingredients.length,
                                    separatorBuilder: (ctx, i) => const Divider(height: 1, color: AppTheme.surfaceDark),
                                    itemBuilder: (ctx, i) {
                                      final ing = _ingredients[i];
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                        leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.kitchen, color: AppTheme.primary, size: 20),
                                        ),
                                        title: Text(ing['inventoryName'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                        subtitle: Text('${ing['quantityUsed']} ${ing['inventoryUnit'] ?? ''}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                                          onPressed: () => _removeIngredient(i),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // Right panel: Add Ingredient Form
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.surfaceDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Tambah Bahan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 24),
                          
                          const Text('Pilih Bahan Baku', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedMaterialId,
                            dropdownColor: AppTheme.surfaceDark,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.bgDark,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: _rawMaterials.map((m) {
                              return DropdownMenuItem<String>(
                                value: m['id'].toString(),
                                child: Text('${m['name']} (${m['unit']})'),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedMaterialId = val),
                            hint: const Text('Pilih...', style: TextStyle(color: AppTheme.textMuted)),
                          ),
                          const SizedBox(height: 20),
                          
                          const Text('Kuantitas (Gramasi/Unit)', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _qtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.bgDark,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              hintText: 'Misal: 50',
                              hintStyle: const TextStyle(color: AppTheme.textMuted),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addIngredient,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.surfaceDark,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Tambahkan ke Resep', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
