import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final int totalAmount;
  final List<Map<String, dynamic>> cartItems;
  final Function(String method, int paidAmount) onConfirmPayment;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.cartItems,
    required this.onConfirmPayment,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formatter = NumberFormat('#,###', 'id_ID');
  String _selectedMethod = 'Tunai';
  int _paidAmount = 0;
  bool _isProcessing = false;

  int get _change => _paidAmount - widget.totalAmount;
  bool get _canPay => _selectedMethod != 'Tunai'
      ? true
      : _paidAmount >= widget.totalAmount;

  void _onNumpadTap(String value) {
    setState(() {
      if (value == 'C') {
        _paidAmount = 0;
      } else if (value == '⌫') {
        final str = _paidAmount.toString();
        _paidAmount = str.length > 1 ? int.parse(str.substring(0, str.length - 1)) : 0;
      } else {
        final current = _paidAmount.toString();
        final next = current == '0' ? value : current + value;
        if (next.length <= 10) _paidAmount = int.parse(next);
      }
    });
  }

  void _setExactAmount() {
    setState(() => _paidAmount = widget.totalAmount);
  }

  void _addAmount(int amount) {
    setState(() => _paidAmount += amount);
  }

  Future<void> _handleConfirm() async {
    if (!_canPay || _isProcessing) return;
    setState(() => _isProcessing = true);

    final paid = _selectedMethod == 'Tunai' ? _paidAmount : widget.totalAmount;
    widget.onConfirmPayment(_selectedMethod, paid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
                      ),
                      const Text(
                        'Pembayaran',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textWhite),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Order summary
                  _buildOrderSummary(),
                  const SizedBox(height: 16),

                  // Payment method
                  _buildMethodSelector(),
                  const SizedBox(height: 16),

                  // Cash input (only for Tunai)
                  if (_selectedMethod == 'Tunai') ...[
                    _buildCashInput(),
                    const SizedBox(height: 16),
                  ],

                  // Change / result
                  _buildResult(),
                  const SizedBox(height: 20),

                  // Confirm
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _canPay && !_isProcessing ? _handleConfirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canPay ? AppTheme.success : Colors.grey.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isProcessing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedMethod == 'Tunai'
                                      ? 'Bayar Tunai'
                                      : 'Konfirmasi $_selectedMethod',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Pesanan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          ...widget.cartItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Center(child: Text('${item['quantity']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 13, color: AppTheme.textWhite))),
                Text('Rp ${_formatter.format((item['price'] as int) * (item['quantity'] as int))}', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              ],
            ),
          )),
          const Divider(color: Color(0x1AFFFFFF), height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textWhite)),
              Text('Rp ${_formatter.format(widget.totalAmount)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Metode Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              _methodChip(Icons.money, 'Tunai'),
              const SizedBox(width: 8),
              _methodChip(Icons.qr_code, 'QRIS'),
              const SizedBox(width: 8),
              _methodChip(Icons.credit_card, 'Kartu'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _methodChip(IconData icon, String label) {
    final isSelected = _selectedMethod == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedMethod = label;
          if (label != 'Tunai') _paidAmount = widget.totalAmount;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: isSelected ? AppTheme.primary : AppTheme.textMuted),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppTheme.primary : AppTheme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Uang Dibayarkan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 10),

          // Amount display
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1115),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(children: [
              const Text('Rp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
              const SizedBox(width: 8),
              Expanded(child: Text(_formatter.format(_paidAmount), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textWhite))),
            ]),
          ),
          const SizedBox(height: 10),

          // Quick amount pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickPill('Uang Pas', _setExactAmount),
              _quickPill('+ 5.000', () => _addAmount(5000)),
              _quickPill('+ 10.000', () => _addAmount(10000)),
              _quickPill('+ 20.000', () => _addAmount(20000)),
              _quickPill('+ 50.000', () => _addAmount(50000)),
              _quickPill('+ 100.000', () => _addAmount(100000)),
            ],
          ),
          const SizedBox(height: 12),

          // Numpad
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: [
              for (final key in ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '⌫'])
                _numpadButton(key),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    if (_selectedMethod != 'Tunai') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success, size: 22),
            const SizedBox(width: 10),
            Text(
              'Pembayaran via $_selectedMethod',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.success),
            ),
          ],
        ),
      );
    }

    final isEnough = _paidAmount >= widget.totalAmount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isEnough ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isEnough ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isEnough ? 'Kembalian' : 'Kurang',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isEnough ? AppTheme.success : AppTheme.danger),
          ),
          Text(
            'Rp ${_formatter.format(_change.abs())}',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isEnough ? AppTheme.success : AppTheme.danger),
          ),
        ],
      ),
    );
  }

  Widget _quickPill(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
      ),
    );
  }

  Widget _numpadButton(String key) {
    final isSpecial = key == 'C' || key == '⌫';
    return Material(
      color: isSpecial ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF0F1115),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _onNumpadTap(key),
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Text(key, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: key == 'C' ? AppTheme.danger : AppTheme.textWhite)),
        ),
      ),
    );
  }
}
