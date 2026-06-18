import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/staff_provider.dart';
import '../services/api_service.dart';
import 'staff_form_screen.dart';
import 'staff_detail_screen.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<Map<String, dynamic>> _branches = [];
  bool _isLoadingBranches = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStaff();
      _loadBranches();
    });
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      final data = await ApiService.getList('/branches');
      setState(() {
        _branches = data.map((e) => e as Map<String, dynamic>).toList();
      });
    } catch (e) {
      debugPrint('Error loading branches: $e');
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark, // Matches mockup background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildFilterBar(),
              const SizedBox(height: 24),
              Expanded(
                child: _buildTableCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manajemen Pegawai',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.5),
                  builder: (context) => const StaffFormScreen(),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text('Tambah Pegawai Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(140, 48), // Override double.infinity from theme
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final provider = context.watch<StaffProvider>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark, // card background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Search Box
          Expanded(
            flex: 3,
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari karyawan berdasarkan nama, peran atau ID...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                filled: true,
                fillColor: AppTheme.bgDark,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => context.read<StaffProvider>().setSearchQuery(val),
            ),
          ),
          const SizedBox(width: 16),
          // Branch Dropdown
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: provider.branchFilter,
                  hint: Text('Semua Cabang', style: TextStyle(color: Colors.grey.shade400)),
                  dropdownColor: AppTheme.surfaceDark,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua Cabang')),
                    ..._branches.map((b) => DropdownMenuItem(
                      value: b['id'] as String,
                      child: Text(b['name'] ?? 'Unknown Branch'),
                    )),
                  ],
                  onChanged: (val) => context.read<StaffProvider>().setBranchFilter(val),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                _buildHeaderCell('', flex: 0, width: 40),
                _buildHeaderCell('KARYAWAN', flex: 3),
                _buildHeaderCell('PERAN', flex: 2),
                _buildHeaderCell('CABANG', flex: 2),
                _buildHeaderCell('STATUS', flex: 1),
                _buildHeaderCell('AKSI', flex: 1, alignment: Alignment.centerRight),
              ],
            ),
          ),
          // Table Body
          Expanded(
            child: Consumer<StaffProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null) {
                  return Center(child: Text(provider.error!, style: const TextStyle(color: AppTheme.danger)));
                }
                
                final staffList = provider.staffList;
                if (staffList.isEmpty) {
                  return Center(
                    child: Text('Tidak ada pegawai ditemukan', style: TextStyle(color: Colors.grey.shade500)),
                  );
                }

                return ListView.separated(
                  itemCount: staffList.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.05)),
                  itemBuilder: (context, index) {
                    final staff = staffList[index];
                    return _buildTableRow(staff);
                  },
                );
              },
            ),
          ),
          // Pagination Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: _buildPagination(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1, double? width, Alignment alignment = Alignment.centerLeft}) {
    Widget child = Container(
      alignment: alignment,
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textMutedLight,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex, child: child);
  }

  Widget _buildTableRow(Map<String, dynamic> staff) {
    final role = staff['role']?.toString().toLowerCase() ?? '';
    final isActive = staff['status'] == 'Aktif';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Radio/Checkbox Placeholder
          SizedBox(
            width: 40,
            child: Icon(Icons.radio_button_unchecked, color: Colors.grey.shade700, size: 20),
          ),
          
          // Karyawan
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.2),
                  child: Text(
                    (staff['name'] ?? '?').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff['name'] ?? '-',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      staff['email'] ?? '-',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Peran
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildRoleBadge(staff['role'] ?? 'Unknown'),
            ),
          ),
          
          // Cabang
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getBranchName(staff['branchId'] ?? ''),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          
          // Status
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(isActive),
            ),
          ),
          
          // Aksi
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message: 'Detail Pegawai',
                child: IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white54),
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.5),
                      builder: (context) => StaffDetailScreen(staffId: staff['id']),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'admin': color = Colors.orange; break;
      case 'manager':
      case 'manajer': color = Colors.purpleAccent; break;
      case 'kasir': color = AppTheme.primary; break;
      case 'dapur':
      case 'chef': color = Colors.pinkAccent; break;
      case 'kepala koki': color = Colors.orangeAccent; break;
      default: color = Colors.grey; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            role,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Text('Aktif', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Text('Tidak Aktif', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
      );
    }
  }

  String _getBranchName(String branchId) {
    if (branchId.isEmpty) return '-';
    try {
      return _branches.firstWhere((b) => b['id'] == branchId)['name'] ?? 'Unknown Branch';
    } catch (_) {
      return 'Unknown Branch';
    }
  }

  Widget _buildPagination() {
    final provider = context.watch<StaffProvider>();
    final start = ((provider.currentPage - 1) * provider.limit) + 1;
    var end = provider.currentPage * provider.limit;
    if (end > provider.totalItems) end = provider.totalItems;
    if (provider.totalItems == 0) end = 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Menampilkan $start-$end dari ${provider.totalItems} anggota staff',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
        Row(
          children: [
            TextButton(
              onPressed: provider.currentPage > 1 ? () => provider.setPage(provider.currentPage - 1) : null,
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Sebelumnya'),
            ),
            const SizedBox(width: 8),
            // Build page numbers
            ...List.generate(provider.totalPages, (index) {
              final page = index + 1;
              final isSelected = page == provider.currentPage;
              
              // Simple pagination rendering: show first few and last
              if (provider.totalPages > 5) {
                if (page > 3 && page < provider.totalPages) {
                  if (page == 4) return const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('...', style: TextStyle(color: Colors.white54)));
                  return const SizedBox.shrink();
                }
              }

              return InkWell(
                onTap: () => provider.setPage(page),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    page.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade400,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            TextButton(
              onPressed: provider.currentPage < provider.totalPages ? () => provider.setPage(provider.currentPage + 1) : null,
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Berikutnya'),
            ),
          ],
        )
      ],
    );
  }
}
