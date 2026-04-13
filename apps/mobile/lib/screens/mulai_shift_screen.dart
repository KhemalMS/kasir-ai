import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/shifts_service.dart';
import '../config/app_theme.dart';

class MulaiShiftScreen extends StatefulWidget {
  const MulaiShiftScreen({super.key});

  @override
  State<MulaiShiftScreen> createState() => _MulaiShiftScreenState();
}

class _MulaiShiftScreenState extends State<MulaiShiftScreen> {
  int _modalAwal = 0;
  bool _isLoading = false;
  final _formatter = NumberFormat('#,###', 'id_ID');

  String get _formattedModal => _formatter.format(_modalAwal);

  void _addAmount(int amount) {
    setState(() => _modalAwal += amount);
  }

  void _resetAmount() {
    setState(() => _modalAwal = 0);
  }

  void _onNumpadTap(String value) {
    setState(() {
      if (value == 'C') {
        _modalAwal = 0;
      } else if (value == '⌫') {
        final str = _modalAwal.toString();
        _modalAwal = str.length > 1 ? int.parse(str.substring(0, str.length - 1)) : 0;
      } else {
        final current = _modalAwal.toString();
        final next = current == '0' ? value : current + value;
        if (next.length <= 10) {
          _modalAwal = int.parse(next);
        }
      }
    });
  }

  Future<void> _handleStartShift() async {
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    try {
      final result = await ShiftsService.startShift(
        staffId: auth.staffId,
        branchId: auth.branchId,
        startingCash: _modalAwal,
      );
      // Save shift ID for orders and tutup shift
      auth.setShiftId(result['id']);
    } catch (e) {
      debugPrint('Shift start error: $e');
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/kasir');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0x0DFFFFFF)),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Mulai Shift',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.amber.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kasir Bertugas',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                auth.userName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Modal Awal Input
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Masukkan Modal Awal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1115),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Rp',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formattedModal,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textWhite,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Quick Add Pills
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _quickPill('+ Rp 100.000', () => _addAmount(100000)),
                            _quickPill('+ Rp 200.000', () => _addAmount(200000)),
                            _quickPill('+ Rp 500.000', () => _addAmount(500000)),
                            _quickPill('Reset', _resetAmount, isDanger: true),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Numpad
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.2,
                      children: [
                        for (final key in ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '⌫'])
                          _numpadButton(key),
                      ],
                    ),
                  ),

                  // Start Button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleStartShift,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 20),
                                  SizedBox(width: 8),
                                  Text('Mulai Shift'),
                                ],
                              ),
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

  Widget _quickPill(String label, VoidCallback onTap, {bool isDanger = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDanger
                ? AppTheme.danger.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDanger ? AppTheme.danger : AppTheme.textMuted,
          ),
        ),
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
          child: Text(
            key,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: key == 'C' ? AppTheme.danger : AppTheme.textWhite,
            ),
          ),
        ),
      ),
    );
  }
}
