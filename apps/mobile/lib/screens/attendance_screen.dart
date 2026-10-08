import 'package:flutter/material.dart';
import '../services/error_notifier.dart';
import '../services/error_mapper.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> _attendances = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  Future<void> _loadAttendances() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final data = await ApiService.getList('/attendance');
      if (mounted) {
        setState(() {
          _attendances = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _clockIn() async {
    try {
      // Menggunakan dummy staff ID untuk keperluan demo (biasanya diambil dari auth)
      // Kita coba ambil dari API staff dulu untuk mendapatkan 1 ID yang valid
      final staffList = await ApiService.getList('/staff');
      if (staffList.isEmpty) {
        if (mounted) ErrorNotifier.showInfo('Tidak ada data pegawai.');
        return;
      }
      final staffId = staffList.first['id'];

      await ApiService.post('/attendance/clock-in', {
        'staffId': staffId,
        'notes': 'Clock In dari Web Admin',
      });
      if (mounted) {
        ErrorNotifier.showSuccess('Berhasil Clock In');
        _loadAttendances();
      }
    } catch (e, stack) {
      if (mounted) {
        final err = ErrorMapper.from(e, stack, module: 'attendance', action: 'clockIn');
        ErrorNotifier.show(err);
      }
    }
  }

  Future<void> _clockOut() async {
    try {
      final staffList = await ApiService.getList('/staff');
      if (staffList.isEmpty) return;
      final staffId = staffList.first['id'];

      await ApiService.post('/attendance/clock-out', {
        'staffId': staffId,
        'notes': 'Clock Out dari Web Admin',
      });
      if (mounted) {
        ErrorNotifier.showSuccess('Berhasil Clock Out');
        _loadAttendances();
      }
    } catch (e, stack) {
      if (mounted) {
        final err = ErrorMapper.from(e, stack, module: 'attendance', action: 'clockOut');
        ErrorNotifier.show(err);
      }
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('HH:mm:ss').format(dt);
    } catch (e) {
      return '-';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      return '-';
    }
  }

  Widget _buildStatusBadge(String status) {
    final isLate = status.toLowerCase() == 'late';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: (isLate ? AppTheme.danger : AppTheme.success).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isLate ? AppTheme.danger : AppTheme.success).withValues(alpha: 0.3)),
      ),
      child: Text(
        isLate ? 'Terlambat' : 'Tepat Waktu',
        style: TextStyle(
          color: isLate ? AppTheme.danger : AppTheme.success,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & Actions
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Absensi Karyawan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('Log kehadiran dan timesheet harian', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _clockIn,
                icon: const Icon(Icons.login),
                label: const Text('Clock In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _clockOut,
                icon: const Icon(Icons.logout),
                label: const Text('Clock Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),

        // Main Table Area
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceDark),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: AppTheme.danger)))
                    : _attendances.isEmpty
                        ? const Center(child: Text('Belum ada data absensi', style: TextStyle(color: AppTheme.textMuted)))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(AppTheme.surfaceDark.withValues(alpha: 0.5)),
                                  dataRowColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.hovered)) return AppTheme.surfaceDark.withValues(alpha: 0.3);
                                    return Colors.transparent;
                                  }),
                                  dividerThickness: 1,
                                  columns: const [
                                    DataColumn(label: Text('Tanggal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Nama Karyawan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Jam Masuk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Jam Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                  ],
                                  rows: _attendances.map((record) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(_formatDate(record['date']), style: const TextStyle(color: Colors.white70))),
                                        DataCell(Text(record['staffName'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                                        DataCell(Text(_formatTime(record['clockInTime']), style: const TextStyle(color: AppTheme.success))),
                                        DataCell(Text(_formatTime(record['clockOutTime']), style: const TextStyle(color: AppTheme.textMuted))),
                                        DataCell(_buildStatusBadge(record['status'] ?? 'on-time')),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
