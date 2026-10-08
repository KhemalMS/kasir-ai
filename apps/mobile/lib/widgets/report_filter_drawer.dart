import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/error_notifier.dart';
import '../models/app_error.dart';
import '../services/error_mapper.dart';

// ─── Model Filter State ────────────────────────────────────────────────────
class ReportFilterState {
  final DateTime startDate;
  final DateTime endDate;
  final String? branchId;
  final String? branchName;      // untuk display label
  final String? staffId;
  final String? staffName;       // untuk display label
  final String? paymentMethod;
  final String? search;
  final String sortBy;           // 'createdAt' | 'totalAmount' | 'orderNumber'
  final String sortOrder;        // 'asc' | 'desc'
  final int page;
  final int limit;

  const ReportFilterState({
    required this.startDate,
    required this.endDate,
    this.branchId,
    this.branchName,
    this.staffId,
    this.staffName,
    this.paymentMethod,
    this.search,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.page = 1,
    this.limit = 20,
  });

  ReportFilterState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    String? branchName,
    String? staffId,
    String? staffName,
    String? paymentMethod,
    String? search,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
    bool clearBranch = false,
    bool clearStaff = false,
    bool clearPayment = false,
  }) {
    return ReportFilterState(
      startDate:     startDate     ?? this.startDate,
      endDate:       endDate       ?? this.endDate,
      branchId:      clearBranch  ? null : (branchId      ?? this.branchId),
      branchName:    clearBranch  ? null : (branchName    ?? this.branchName),
      staffId:       clearStaff   ? null : (staffId       ?? this.staffId),
      staffName:     clearStaff   ? null : (staffName     ?? this.staffName),
      paymentMethod: clearPayment ? null : (paymentMethod ?? this.paymentMethod),
      search:        search        ?? this.search,
      sortBy:        sortBy        ?? this.sortBy,
      sortOrder:     sortOrder     ?? this.sortOrder,
      page:          page          ?? 1, // reset ke 1 saat filter berubah
      limit:         limit         ?? this.limit,
    );
  }

  String buildQueryString() {
    final s = DateFormat('yyyy-MM-dd').format(startDate);
    final e = DateFormat('yyyy-MM-dd').format(endDate);
    final buf = StringBuffer('start=$s&end=$e&page=$page&limit=$limit&sortBy=$sortBy&sortOrder=$sortOrder');
    if (branchId      != null) buf.write('&branchId=$branchId');
    if (staffId       != null) buf.write('&staffId=$staffId');
    if (paymentMethod != null) buf.write('&paymentMethod=${Uri.encodeComponent(paymentMethod!)}');
    if (search        != null && search!.isNotEmpty) buf.write('&search=${Uri.encodeComponent(search!)}');
    return buf.toString();
  }
}

// ─── Quick Preset Helper ────────────────────────────────────────────────────
DateTimeRange _presetToday() {
  final now = DateTime.now();
  return DateTimeRange(start: DateTime(now.year, now.month, now.day), end: now);
}

DateTimeRange _presetYesterday() {
  final y = DateTime.now().subtract(const Duration(days: 1));
  return DateTimeRange(start: DateTime(y.year, y.month, y.day), end: DateTime(y.year, y.month, y.day, 23, 59, 59));
}

DateTimeRange _preset7Days() {
  return DateTimeRange(start: DateTime.now().subtract(const Duration(days: 6)), end: DateTime.now());
}

DateTimeRange _preset30Days() {
  return DateTimeRange(start: DateTime.now().subtract(const Duration(days: 29)), end: DateTime.now());
}

DateTimeRange _presetThisMonth() {
  final now = DateTime.now();
  return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
}

DateTimeRange _presetLastMonth() {
  final now = DateTime.now();
  final first = DateTime(now.year, now.month - 1, 1);
  final last  = DateTime(now.year, now.month, 0, 23, 59, 59);
  return DateTimeRange(start: first, end: last);
}

// ─── ReportFilterDrawer ─────────────────────────────────────────────────────
class ReportFilterDrawer extends StatefulWidget {
  final ReportFilterState initialFilter;
  final void Function(ReportFilterState) onApply;

  const ReportFilterDrawer({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<ReportFilterDrawer> createState() => _ReportFilterDrawerState();
}

class _ReportFilterDrawerState extends State<ReportFilterDrawer> {
  late ReportFilterState _filter;
  List<Map<String, dynamic>> _branchesList = [];
  List<Map<String, dynamic>> _staffList = [];
  List<String> _paymentMethods = [];
  bool _optionsLoaded = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _searchController.text = _filter.search ?? '';
    _loadOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    if (_optionsLoaded) return;
    try {
      final res = await ApiService.get('/reports/filter-options');
      if (mounted) {
        setState(() {
          _branchesList    = List<Map<String, dynamic>>.from(res['branches'] ?? []);
          _staffList       = List<Map<String, dynamic>>.from(res['staff'] ?? []);
          _paymentMethods  = List<String>.from(res['paymentMethods'] ?? []);
          _optionsLoaded   = true;
        });
      }
    } catch (e, stack) {
      ErrorNotifier.show(ErrorMapper.from(e, stack, module: 'report', action: 'fetchFilterOptions'));
    }
  }

  void _applyPreset(DateTimeRange range) {
    setState(() => _filter = _filter.copyWith(startDate: range.start, endDate: range.end));
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _filter.startDate, end: _filter.endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.primary, surface: AppTheme.cardDark)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _filter = _filter.copyWith(startDate: picked.start, endDate: picked.end));
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(text, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
  );

  Widget _presetBtn(String label, DateTimeRange range) {
    final isActive = _filter.startDate == range.start && _filter.endDate == range.end;
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      child: GestureDetector(
        onTap: () => _applyPreset(range),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isActive ? AppTheme.primary : Colors.transparent),
          ),
          child: Text(label, style: TextStyle(color: isActive ? Colors.white : AppTheme.textMuted, fontSize: 12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 320,
      backgroundColor: AppTheme.cardDark,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.surfaceDark,
            child: Row(
              children: [
                const Icon(Icons.tune, color: AppTheme.primary),
                const SizedBox(width: 10),
                const Text('Filter & Sortir', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    final def = ReportFilterState(
                      startDate: DateTime.now().subtract(const Duration(days: 29)),
                      endDate:   DateTime.now(),
                    );
                    setState(() { _filter = def; _searchController.clear(); });
                  },
                  child: const Text('Reset', style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Pencarian ────────────────────────────────
                  _sectionTitle('PENCARIAN (No. Invoice)'),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Cari nomor invoice...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 18),
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _filter = _filter.copyWith(search: v)),
                  ),

                  // ─── Quick Presets ────────────────────────────
                  _sectionTitle('PERIODE CEPAT'),
                  Wrap(children: [
                    _presetBtn('Hari Ini',    _presetToday()),
                    _presetBtn('Kemarin',     _presetYesterday()),
                    _presetBtn('7 Hari',      _preset7Days()),
                    _presetBtn('30 Hari',     _preset30Days()),
                    _presetBtn('Bulan Ini',   _presetThisMonth()),
                    _presetBtn('Bulan Lalu',  _presetLastMonth()),
                  ]),
                  const SizedBox(height: 8),

                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: Text('${DateFormat('dd MMM').format(_filter.startDate)}  →  ${DateFormat('dd MMM yyyy').format(_filter.endDate)}', style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: AppTheme.surfaceDark)),
                    onPressed: _pickCustomDateRange,
                  ),

                  // ─── Filter Cabang ─────────────────────────────
                  _sectionTitle('CABANG'),
                  DropdownButtonFormField<String>(
                    value: _filter.branchId,
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true, fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    hint: const Text('Semua Cabang', style: TextStyle(color: AppTheme.textMuted)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua Cabang', style: TextStyle(color: AppTheme.textMuted))),
                      ..._branchesList.map((b) => DropdownMenuItem(
                        value: b['id'] as String,
                        child: Text(b['name'] as String, style: const TextStyle(color: Colors.white)),
                      )),
                    ],
                    onChanged: (val) => setState(() => _filter = val == null
                      ? _filter.copyWith(clearBranch: true)
                      : _filter.copyWith(branchId: val, branchName: _branchesList.firstWhere((b) => b['id'] == val)['name'] as String)),
                  ),

                  // ─── Filter Kasir ─────────────────────────────
                  _sectionTitle('KASIR'),
                  DropdownButtonFormField<String>(
                    value: _filter.staffId,
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true, fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    hint: const Text('Semua Kasir', style: TextStyle(color: AppTheme.textMuted)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua Kasir', style: TextStyle(color: AppTheme.textMuted))),
                      ..._staffList.map((s) => DropdownMenuItem(
                        value: s['id'] as String,
                        child: Text(s['name'] as String, style: const TextStyle(color: Colors.white)),
                      )),
                    ],
                    onChanged: (val) => setState(() => _filter = val == null
                      ? _filter.copyWith(clearStaff: true)
                      : _filter.copyWith(staffId: val, staffName: _staffList.firstWhere((s) => s['id'] == val)['name'] as String)),
                  ),

                  // ─── Filter Metode Pembayaran ─────────────────
                  _sectionTitle('METODE PEMBAYARAN'),
                  DropdownButtonFormField<String>(
                    value: _filter.paymentMethod,
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true, fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    hint: const Text('Semua Metode', style: TextStyle(color: AppTheme.textMuted)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua Metode', style: TextStyle(color: AppTheme.textMuted))),
                      ..._paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: Colors.white)))),
                    ],
                    onChanged: (val) => setState(() => _filter = val == null
                      ? _filter.copyWith(clearPayment: true)
                      : _filter.copyWith(paymentMethod: val)),
                  ),

                  // ─── Sortir ───────────────────────────────────
                  _sectionTitle('URUTKAN BERDASARKAN'),
                  DropdownButtonFormField<String>(
                    value: _filter.sortBy,
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true, fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'createdAt',   child: Text('Tanggal Transaksi')),
                      DropdownMenuItem(value: 'totalAmount', child: Text('Nilai Transaksi')),
                      DropdownMenuItem(value: 'orderNumber', child: Text('Nomor Invoice')),
                    ],
                    onChanged: (val) => setState(() => _filter = _filter.copyWith(sortBy: val)),
                  ),
                  const SizedBox(height: 8),

                  SegmentedButton<String>(
                    selected: {_filter.sortOrder},
                    onSelectionChanged: (s) => setState(() => _filter = _filter.copyWith(sortOrder: s.first)),
                    style: ButtonStyle(backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                      return states.contains(WidgetState.selected) ? AppTheme.primary : AppTheme.surfaceDark;
                    })),
                    segments: const [
                      ButtonSegment(value: 'desc', label: Text('Terbaru'), icon: Icon(Icons.arrow_downward, size: 14)),
                      ButtonSegment(value: 'asc',  label: Text('Terlama'),  icon: Icon(Icons.arrow_upward,   size: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Tombol Terapkan ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  widget.onApply(_filter);
                  Navigator.of(context).pop();
                },
                child: const Text('Terapkan Filter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
