import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/staff_provider.dart';
import '../services/api_service.dart';
import 'staff_form_screen.dart';

class StaffDetailScreen extends StatefulWidget {
  final String staffId;
  const StaffDetailScreen({super.key, required this.staffId});

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  Map<String, dynamic>? _staff;
  List<Map<String, dynamic>> _shifts = [];
  List<Map<String, dynamic>> _salaries = [];
  String _branchName = 'Loading...';
  bool _isLoading = true;
  bool _showPin = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final staffResponse = await ApiService.get('/staff/${widget.staffId}');
      _staff = staffResponse;
      
      // Load branch name
      if (_staff!['branchId'] != null) {
        final branchResp = await ApiService.get('/branches/${_staff!['branchId']}');
        _branchName = branchResp['name'] ?? 'Unknown Branch';
      }

      // Load histories
      final shiftData = await ApiService.getList('/staff/${widget.staffId}/shifts');
      _shifts = shiftData.map((e) => e as Map<String, dynamic>).toList();

      final salaryData = await ApiService.getList('/staff/${widget.staffId}/salary');
      _salaries = salaryData.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error loading staff details: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int? _calculateAge(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return null;
    try {
      final dob = DateTime.parse(birthDate);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  String _calculateTenure(String? joinDate) {
    if (joinDate == null || joinDate.isEmpty) return '-';
    try {
      final jd = DateTime.parse(joinDate);
      final diff = DateTime.now().difference(jd);
      final years = (diff.inDays / 365).floor();
      final months = ((diff.inDays % 365) / 30).floor();
      if (years > 0) return '$years tahun $months bulan';
      if (months > 0) return '$months bulan';
      return '${diff.inDays} hari';
    } catch (_) {
      return '-';
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 16, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detail Pegawai',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(width: 40, height: 3, color: const Color(0xFF0D9488)),
            ],
          ),
          const Spacer(),

          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_staff == null) {
      return Dialog(
        backgroundColor: AppTheme.surfaceDark,
        child: const Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Data tidak ditemukan', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return DefaultTabController(
      length: 3,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 880,
            maxHeight: screenHeight * 0.90,
          ),
          child: SizedBox(
            width: 880,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withOpacity(0.97),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _buildHeader(),
                      const TabBar(
                        isScrollable: true,
                        tabs: [
                          Tab(text: 'Profil & Pekerjaan'),
                          Tab(text: 'Riwayat Shift'),
                          Tab(text: 'Keuangan'),
                        ],
                      ),
                      _buildHeroHeader(),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildMergedProfileTab(),
                            _buildShiftsTab(),
                            _buildFinanceTab(),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final roleColor = AppTheme.primary; // Or custom logic based on role
    final isActive = _staff!['status'] == 'Aktif';

    return Container(
      width: double.infinity,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(24.0),
      child: Stack(
        children: [
          Center(
            child: Column(
              children: [
                Hero(
                  tag: 'avatar_',
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: roleColor.withOpacity(0.1),
                    backgroundImage: _staff!['imageUrl'] != null && _staff!['imageUrl'].toString().isNotEmpty
                        ? NetworkImage(_staff!['imageUrl'])
                        : null,
                    child: _staff!['imageUrl'] == null || _staff!['imageUrl'].toString().isEmpty
                        ? Text(
                            (_staff!['name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: roleColor),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _staff!['name'] ?? '-',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: roleColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        _staff!['role'] ?? 'Staff',
                        style: TextStyle(fontSize: 14, color: roleColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isActive ? AppTheme.success.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(isActive ? Icons.check_circle : Icons.block, 
                              size: 14, color: isActive ? AppTheme.success : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(fontSize: 14, color: isActive ? AppTheme.success : Colors.grey, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit Data Pegawai'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                await showDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.5),
                  builder: (context) => StaffFormScreen(staff: _staff),
                );
                _loadData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF0D9488)),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMergedProfileTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildIdentitasPribadiCard()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDataPekerjaanCard()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildKontakDaruratCard()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildKeamananDanCatatanCard()),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildIdentitasPribadiCard(),
              const SizedBox(height: 16),
              _buildDataPekerjaanCard(),
              const SizedBox(height: 16),
              _buildKontakDaruratCard(),
              const SizedBox(height: 16),
              _buildKeamananDanCatatanCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildIdentitasPribadiCard() {
    final age = _calculateAge(_staff!['birthDate']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Identitas Pribadi', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Email', _staff!['email'] ?? '-', icon: Icons.email),
                _buildInfoRow('No. HP', _staff!['phone'] ?? '-', icon: Icons.phone),
                _buildInfoRow('Jenis Kelamin', _staff!['gender'] ?? '-', icon: Icons.person),
                _buildInfoRow('Tanggal Lahir', ' ', icon: Icons.cake),
                _buildInfoRow('Alamat', _staff!['address'] ?? '-', icon: Icons.home),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKontakDaruratCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kontak Darurat', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Nama', _staff!['emergencyContactName'] ?? '-', icon: Icons.health_and_safety),
                _buildInfoRow('No. HP', _staff!['emergencyContactPhone'] ?? '-', icon: Icons.phone_android),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataPekerjaanCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Data Pekerjaan', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Cabang', _branchName, icon: Icons.storefront),
                _buildInfoRow('Tipe Kontrak', _staff!['employmentType'] ?? '-', icon: Icons.work),
                _buildInfoRow('Tgl Bergabung', _staff!['joinDate'] ?? '-', icon: Icons.event_available),
                _buildInfoRow('Masa Kerja', _calculateTenure(_staff!['joinDate']), icon: Icons.timer),
                
                const Divider(height: 32),
                Row(
                  children: [
                    const Icon(Icons.password, size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 120,
                      child: Text('PIN Absensi', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(
                      child: Text(
                        _showPin ? (_staff!['pinCode'] ?? 'Belum diatur') : '******',
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showPin = !_showPin),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeamananDanCatatanCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_staff!['notes'] != null && _staff!['notes'].toString().isNotEmpty) ...[
          const Text('Catatan Internal', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_staff!['notes'], style: TextStyle(color: Colors.white70, height: 1.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(child: _buildAccountSecuritySection()),
      ],
    );
  }

  Widget _buildAccountSecuritySection() {
    final isActive = _staff!['status'] == 'Aktif';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Keamanan & Manajemen Akun', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.password, size: 18),
                  label: const Text('Reset PIN Absensi'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    foregroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.lock_reset, size: 18),
                  label: const Text('Reset Password Akses'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    foregroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: Icon(isActive ? Icons.block : Icons.check_circle, size: 18),
                  label: Text(isActive ? 'Nonaktifkan Pegawai' : 'Aktifkan Pegawai'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: isActive ? AppTheme.danger.withOpacity(0.2) : AppTheme.success.withOpacity(0.2),
                    foregroundColor: isActive ? AppTheme.danger : AppTheme.success,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShiftsTab() {
    if (_shifts.isEmpty) {
      return const Center(child: Text('Belum ada riwayat shift'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _shifts.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final s = _shifts[index];
        final start = DateTime.tryParse(s['startedAt'] ?? '');
        final end = s['endedAt'] != null ? DateTime.tryParse(s['endedAt']) : null;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: end != null ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
            child: Icon(end != null ? Icons.check : Icons.timer, 
                color: end != null ? AppTheme.success : AppTheme.warning),
          ),
          title: Text(start?.toString().split(' ')[0] ?? '-'),
          subtitle: Text('${start?.hour}:${start?.minute} - ${end != null ? '${end.hour}:${end.minute}' : 'Berlangsung'}'),
          trailing: Text('Rp ${s['expectedCash'] ?? 0}'),
        );
      },
    );
  }

  Widget _buildFinanceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Nama Bank', _staff!['bankName'] ?? '-', icon: Icons.account_balance),
                _buildInfoRow('No. Rekening', _staff!['bankAccountNumber'] ?? '-', icon: Icons.numbers),
                _buildInfoRow('Atas Nama', _staff!['bankAccountName'] ?? '-', icon: Icons.person),
              ],
            ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Riwayat Gaji', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Catat Gaji'),
              onPressed: () {
                // TODO: Show add salary dialog
              },
            )
          ],
        ),
        if (_salaries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('Belum ada riwayat gaji')),
          )
        else
          ..._salaries.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.payments, color: AppTheme.success),
                  title: Text('Rp ${s['amount']}'),
                  subtitle: Text('${s['salaryType']} • ${s['effectiveDate']}'),
                  trailing: s['notes'] != null ? Tooltip(message: s['notes'], child: const Icon(Icons.info_outline)) : null,
                ),
              )).toList(),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isActive = _staff!['status'] == 'Aktif';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.password),
            label: const Text('Reset PIN'),
            onPressed: () {
              // TODO: Show reset PIN dialog
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.lock_reset),
            label: const Text('Reset Pass'),
            onPressed: () {
              // TODO: Show reset Password dialog
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? AppTheme.danger : AppTheme.success,
              foregroundColor: Colors.white,
            ),
            icon: Icon(isActive ? Icons.block : Icons.check_circle),
            label: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
            onPressed: () async {
              final newStatus = isActive ? 'Tidak Aktif' : 'Aktif';
              await context.read<StaffProvider>().updateStaff(_staff!['id'], {'status': newStatus});
              _loadData(); // reload
            },
          ),
        ],
      ),
    );
  }
}
