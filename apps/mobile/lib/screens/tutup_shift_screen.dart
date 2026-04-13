import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/shifts_service.dart';
import '../config/app_theme.dart';

class TutupShiftScreen extends StatefulWidget {
  const TutupShiftScreen({super.key});

  @override
  State<TutupShiftScreen> createState() => _TutupShiftScreenState();
}

class _TutupShiftScreenState extends State<TutupShiftScreen> {
  final _formatter = NumberFormat('#,###', 'id_ID');
  int _endingCash = 0;
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isClosed = false;
  
  // Shift data from API
  Map<String, dynamic>? _currentShift;
  Map<String, dynamic>? _closedResult;
  int _startingCash = 0;
  int _totalCashSales = 0;
  int _totalQrisSales = 0;
  int _totalCardSales = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadShiftData());
  }

  Future<void> _loadShiftData() async {
    final auth = context.read<AuthProvider>();
    try {
      final shift = await ShiftsService.getCurrentShift(auth.staffId);
      if (shift != null) {
        _currentShift = shift;
        _startingCash = (shift['startingCash'] as num?)?.toInt() ?? 0;
        _totalCashSales = (shift['totalCashSales'] as num?)?.toInt() ?? 0;
        _totalQrisSales = (shift['totalQrisSales'] as num?)?.toInt() ?? 0;
        _totalCardSales = (shift['totalCardSales'] as num?)?.toInt() ?? 0;
        
        if (_currentShift != null) {
          try {
            final summary = await ShiftsService.getShiftSummary(_currentShift!['id']);
            _totalCashSales = (summary['totalCashSales'] as num?)?.toInt() ?? _totalCashSales;
            _totalQrisSales = (summary['totalQrisSales'] as num?)?.toInt() ?? _totalQrisSales;
            _totalCardSales = (summary['totalCardSales'] as num?)?.toInt() ?? _totalCardSales;
          } catch (e) {
            debugPrint('Summary fetch error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading shift: $e');
    }
    if (mounted) setState(() => _isLoadingData = false);
  }

  int get _expectedCash => _startingCash + _totalCashSales;
  int get _totalNonCash => _totalQrisSales + _totalCardSales;
  int get _totalAllSales => _totalCashSales + _totalNonCash;
  int get _cashDifference => _endingCash - _expectedCash;

  void _onNumpadTap(String value) {
    setState(() {
      if (value == 'C') {
        _endingCash = 0;
      } else if (value == '⌫') {
        final str = _endingCash.toString();
        _endingCash = str.length > 1 ? int.parse(str.substring(0, str.length - 1)) : 0;
      } else {
        final current = _endingCash.toString();
        final next = current == '0' ? value : current + value;
        if (next.length <= 10) _endingCash = int.parse(next);
      }
    });
  }

  Future<void> _handleCloseShift() async {
    setState(() => _isLoading = true);

    try {
      if (_currentShift != null) {
        final result = await ShiftsService.closeShift(
          id: _currentShift!['id'],
          endingCash: _endingCash,
        );
        if (mounted) {
          setState(() {
            _closedResult = result;
            _totalCashSales = (result['totalCashSales'] as num?)?.toInt() ?? 0;
            _totalQrisSales = (result['totalQrisSales'] as num?)?.toInt() ?? 0;
            _totalCardSales = (result['totalCardSales'] as num?)?.toInt() ?? 0;
            _isClosed = true;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error closing shift: $e');
    }

    await _signOutAndExit();
  }

  Future<void> _signOutAndExit() async {
    try {
      await context.read<AuthProvider>().signOut();
    } catch (_) {}
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
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
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _isClosed ? _buildClosedView() : _buildOpenView(),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildOpenView() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.stop_circle, color: AppTheme.danger, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tutup Shift', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textWhite)),
              SizedBox(height: 2),
              Text('Hitung uang dan akhiri shift', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            ])),
            IconButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/kasir'),
              icon: const Icon(Icons.arrow_back, color: AppTheme.textMuted),
              tooltip: 'Kembali ke Kasir',
            ),
          ]),
        ),
        const SizedBox(height: 14),
        _buildShiftSummary(),
        const SizedBox(height: 14),
        _buildSalesBreakdown(),
        const SizedBox(height: 14),
        _buildCashInput(),
        const SizedBox(height: 14),
        _buildCashDifference(),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleCloseShift,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.stop_circle, size: 20), SizedBox(width: 8),
                    Text('Tutup Shift & Keluar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ]),
          ),
        ),
      ],
    );
  }

  Widget _buildClosedView() {
    final expectedCash = ((_closedResult?['expectedCash'] as num?)?.toInt()) ?? _expectedCash;
    final cashDiff = ((_closedResult?['cashDifference'] as num?)?.toInt()) ?? _cashDifference;
    final diffColor = cashDiff == 0 ? AppTheme.success : (cashDiff > 0 ? const Color(0xFF2196F3) : AppTheme.danger);

    return Column(
      children: [
        // Success header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
          ),
          child: const Column(children: [
            Icon(Icons.check_circle, color: AppTheme.success, size: 48),
            SizedBox(height: 12),
            Text('Shift Berhasil Ditutup', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.success)),
          ]),
        ),
        const SizedBox(height: 14),

        // Final summary
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardDark, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ringkasan Akhir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
            const SizedBox(height: 14),
            _infoRow(Icons.account_balance_wallet, 'Modal Awal', _startingCash, AppTheme.primary),
            const SizedBox(height: 10),
            _salesRow(Icons.money, 'Penjualan Tunai', _totalCashSales, const Color(0xFF4CAF50)),
            const SizedBox(height: 10),
            _salesRow(Icons.qr_code, 'Penjualan QRIS', _totalQrisSales, const Color(0xFF2196F3)),
            const SizedBox(height: 10),
            _salesRow(Icons.credit_card, 'Penjualan Kartu', _totalCardSales, const Color(0xFFFF9800)),
            const Divider(color: Color(0x1AFFFFFF), height: 24),
            _infoRow(Icons.calculate, 'Uang Seharusnya', expectedCash, AppTheme.textWhite),
            const SizedBox(height: 10),
            _infoRow(Icons.savings, 'Uang di Laci', _endingCash, AppTheme.textWhite),
            const SizedBox(height: 10),
            _infoRow(
              cashDiff == 0 ? Icons.check_circle : Icons.warning,
              cashDiff == 0 ? 'Selisih ✅' : (cashDiff > 0 ? 'Kelebihan' : 'Kurang'),
              cashDiff.abs(), diffColor,
            ),
          ]),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _signOutAndExit,
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.logout, size: 20), SizedBox(width: 8),
              Text('Keluar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildShiftSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Shift', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 14),
          _infoRow(Icons.account_balance_wallet, 'Modal Awal', _startingCash, AppTheme.primary),
          const SizedBox(height: 10),
          _infoRow(Icons.trending_up, 'Total Penjualan', _totalAllSales, AppTheme.success),
        ],
      ),
    );
  }

  Widget _buildSalesBreakdown() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rincian Penjualan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 14),
          _salesRow(Icons.money, 'Tunai', _totalCashSales, const Color(0xFF4CAF50)),
          const SizedBox(height: 10),
          _salesRow(Icons.qr_code, 'QRIS', _totalQrisSales, const Color(0xFF2196F3)),
          const SizedBox(height: 10),
          _salesRow(Icons.credit_card, 'Kartu Debit/Kredit', _totalCardSales, const Color(0xFFFF9800)),
          const Divider(color: Color(0x1AFFFFFF), height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Non-Tunai', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
              Text('Rp ${_formatter.format(_totalNonCash)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textWhite)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashInput() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hitung Uang di Laci', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 10),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1115), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(children: [
              const Text('Rp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
              const SizedBox(width: 8),
              Expanded(child: Text(_formatter.format(_endingCash), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textWhite))),
            ]),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _quickPill('= Seharusnya', () => setState(() => _endingCash = _expectedCash)),
              _quickPill('+ 50.000', () => setState(() => _endingCash += 50000)),
              _quickPill('+ 100.000', () => setState(() => _endingCash += 100000)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.4,
            children: [
              for (final key in ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '⌫'])
                _numpadButton(key),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashDifference() {
    final isMatch = _cashDifference == 0 && _endingCash > 0;
    final isOver = _cashDifference > 0;
    final color = isMatch ? AppTheme.success : (isOver ? const Color(0xFF2196F3) : AppTheme.danger);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Uang Seharusnya', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            Text('Rp ${_formatter.format(_expectedCash)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textWhite)),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(isMatch ? 'Cocok ✅' : (isOver ? 'Kelebihan' : 'Selisih (Kurang)'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            Text(isMatch ? 'Rp 0' : 'Rp ${_formatter.format(_cashDifference.abs())}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          ]),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, int value, Color color) {
    return Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted))),
      Text('Rp ${_formatter.format(value)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  Widget _salesRow(IconData icon, String label, int amount, Color color) {
    return Row(children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textWhite))),
      Text('Rp ${_formatter.format(amount)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  Widget _quickPill(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115), borderRadius: BorderRadius.circular(20),
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
