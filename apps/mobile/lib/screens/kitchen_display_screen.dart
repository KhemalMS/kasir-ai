import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';

class KitchenDisplayScreen extends StatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  State<KitchenDisplayScreen> createState() => _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends State<KitchenDisplayScreen> {
  List<dynamic> _tickets = [];
  bool _isLoading = true;
  String _filter = 'Semua';
  Timer? _refreshTimer;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  final _filters = ['Semua', 'Sukses', 'Disiapkan', 'Selesai'];

  @override
  void initState() {
    super.initState();
    _loadTickets();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadTickets());
    // Clock update every second (for elapsed time)
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    try {
      final statusParam = _filter == 'Semua' ? '' : '?status=$_filter';
      final tickets = await ApiService.getList('/kitchen/tickets$statusParam');
      if (mounted) setState(() { _tickets = tickets; _isLoading = false; });
    } catch (e) {
      debugPrint('Kitchen load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    try {
      await ApiService.put('/kitchen/tickets/$orderId/status', {'status': status});
      _loadTickets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Sukses': return const Color(0xFFFF6B35);
      case 'Disiapkan': return const Color(0xFF3B82F6);
      case 'Selesai': return AppTheme.success;
      default: return AppTheme.textMuted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Sukses': return Icons.notifications_active;
      case 'Disiapkan': return Icons.restaurant;
      case 'Selesai': return Icons.check_circle;
      default: return Icons.receipt;
    }
  }

  String _elapsed(String? createdAt) {
    if (createdAt == null) return '-';
    try {
      final created = DateTime.parse(createdAt).toLocal();
      final diff = _now.difference(created);
      if (diff.inMinutes < 1) return '${diff.inSeconds < 0 ? 0 : diff.inSeconds}d';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      return '${diff.inHours}j ${diff.inMinutes % 60}m';
    } catch (_) {
      return '-';
    }
  }

  Color _elapsedColor(String? createdAt) {
    if (createdAt == null) return AppTheme.textMuted;
    try {
      final diff = _now.difference(DateTime.parse(createdAt).toLocal());
      if (diff.inMinutes >= 15) return AppTheme.danger;
      if (diff.inMinutes >= 8) return const Color(0xFFFF9800);
      return AppTheme.success;
    } catch (_) {
      return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter for display
    final filtered = _filter == 'Semua'
        ? _tickets.where((t) => t['status'] != 'Batal').toList()
        : _tickets;

    // Counts
    final newCount = _tickets.where((t) => t['status'] == 'Sukses').length;
    final prepCount = _tickets.where((t) => t['status'] == 'Disiapkan').length;
    final doneCount = _tickets.where((t) => t['status'] == 'Selesai').length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF111827),
                border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.restaurant_menu, color: Color(0xFFFF6B35), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kitchen Display', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('Tampilan Dapur', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                  const Spacer(),
                  // Live counts
                  _countBadge('Baru', newCount, const Color(0xFFFF6B35)),
                  const SizedBox(width: 8),
                  _countBadge('Proses', prepCount, const Color(0xFF3B82F6)),
                  const SizedBox(width: 8),
                  _countBadge('Selesai', doneCount, AppTheme.success),
                  const SizedBox(width: 12),
                  // Refresh
                  IconButton(
                    onPressed: _loadTickets,
                    icon: const Icon(Icons.refresh, color: Color(0xFF9CA3AF)),
                    tooltip: 'Refresh',
                  ),
                  // Back
                  IconButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    icon: const Icon(Icons.logout, color: AppTheme.danger, size: 20),
                    tooltip: 'Keluar',
                  ),
                ],
              ),
            ),

            // Filter tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF111827),
              child: Row(
                children: _filters.map((f) {
                  final isActive = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _filter = f);
                        _loadTickets();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFFF6B35).withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? const Color(0xFFFF6B35).withValues(alpha: 0.5) : const Color(0xFF374151),
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? const Color(0xFFFF6B35) : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.restaurant, size: 80, color: const Color(0xFF1F2937)),
                              const SizedBox(height: 16),
                              const Text('Belum ada pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                              const SizedBox(height: 4),
                              const Text('Pesanan baru akan muncul di sini', style: TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTickets,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 340,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: MediaQuery.of(context).size.width > 1200 ? 0.85 : 0.75,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) => _ticketCard(filtered[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _ticketCard(Map<String, dynamic> ticket) {
    final items = (ticket['items'] as List?) ?? [];
    final status = ticket['status'] ?? 'Sukses';
    final orderNum = ticket['orderNumber'] ?? '-';
    final orderType = ticket['orderType'] ?? '';
    final tableNum = ticket['tableNumber'];
    final createdAt = ticket['createdAt']?.toString();
    final elapsed = _elapsed(createdAt);
    final elColor = _elapsedColor(createdAt);
    final sColor = _statusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: sColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(status), size: 18, color: sColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#$orderNum', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      if (orderType.isNotEmpty || tableNum != null)
                        Text(
                          '${orderType}${tableNum != null ? ' • Meja $tableNum' : ''}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                    ],
                  ),
                ),
                // Elapsed time
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: elColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer, size: 12, color: elColor),
                      const SizedBox(width: 3),
                      Text(elapsed, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: elColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                final item = items[i];
                final product = item['product'] ?? {};
                final qty = item['quantity'] ?? 1;
                final notes = item['notes'];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: sColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: Text('$qty', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: sColor)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? '-',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                          if (notes != null && notes.toString().isNotEmpty)
                            Text(
                              '📝 $notes',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFFF9800)),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1F2937))),
            ),
            child: _actionButton(status, ticket['id']),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String status, String orderId) {
    if (status == 'Sukses') {
      return SizedBox(
        width: double.infinity,
        height: 40,
        child: ElevatedButton.icon(
          onPressed: () => _updateStatus(orderId, 'Disiapkan'),
          icon: const Icon(Icons.restaurant, size: 18),
          label: const Text('Mulai Siapkan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }
    if (status == 'Disiapkan') {
      return SizedBox(
        width: double.infinity,
        height: 40,
        child: ElevatedButton.icon(
          onPressed: () => _updateStatus(orderId, 'Selesai'),
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text('Selesai Disiapkan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppTheme.success),
          const SizedBox(width: 6),
          const Text('Sudah Selesai', style: TextStyle(fontSize: 13, color: AppTheme.success, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
