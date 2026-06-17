import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isEditingName = false;
  bool _isLoadingName = false;
  bool _isLoadingPass = false;
  bool _isUploadingPhoto = false;

  String _branchName = 'Memuat...';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl.text = auth.userName;
    _loadBranchName(auth.staff?['branchId']);
  }

  Future<void> _loadBranchName(String? branchId) async {
    if (branchId == null) {
      if (mounted) setState(() => _branchName = 'Semua Cabang');
      return;
    }
    try {
      final branches = await ApiService.getList('/branches');
      final branch = branches.firstWhere((b) => b['id'] == branchId, orElse: () => null);
      if (mounted) {
        setState(() {
          _branchName = branch != null ? branch['name'] : branchId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _branchName = branchId;
        });
      }
    }
  }

  Future<void> _uploadPhoto() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload foto profil belum diimplementasi (Tugas API mendatang)')));
  }

  Future<void> _updateName() async {
    final auth = context.read<AuthProvider>();
    if (_nameCtrl.text.trim().isEmpty) return;
    
    setState(() => _isLoadingName = true);
    try {
      await auth.updateName(_nameCtrl.text.trim());
      setState(() => _isEditingName = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama berhasil diperbarui')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingName = false);
    }
  }

  Future<void> _changePassword() async {
    final auth = context.read<AuthProvider>();
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password baru tidak cocok!'), backgroundColor: Colors.red));
      return;
    }
    
    setState(() => _isLoadingPass = true);
    try {
      await auth.changePassword(_oldPassCtrl.text, _newPassCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingPass = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final staff = auth.staff;
    
    final initial = auth.userName.isNotEmpty ? auth.userName.substring(0, 1).toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Profil Akun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Identity Panel
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.primary.withOpacity(0.2),
                            backgroundImage: staff?['imageUrl'] != null ? NetworkImage(staff!['imageUrl']) : null,
                            child: staff?['imageUrl'] == null
                                ? Text(initial, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primary))
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _uploadPhoto,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(auth.userName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(user?['email'] ?? '-', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Text(
                          auth.userRole.toUpperCase(),
                          style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Edit Name Panel
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue, size: 24),
                          SizedBox(width: 8),
                          Text('Informasi Dasar', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 32),
                      const Text('Nama Lengkap', style: TextStyle(color: Colors.white54, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameCtrl,
                              enabled: _isEditingName,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: _isEditingName ? AppTheme.surfaceDark : AppTheme.surfaceDark.withOpacity(0.5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (!_isEditingName)
                            ElevatedButton(
                              onPressed: () => setState(() => _isEditingName = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.surfaceDark,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 20),
                            )
                          else
                            ElevatedButton(
                              onPressed: _isLoadingName ? null : _updateName,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoadingName
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.check, color: Colors.white, size: 20),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Cabang Tugas', style: TextStyle(color: Colors.white54, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: _branchName),
                        enabled: false,
                        style: const TextStyle(color: Colors.white54),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.surfaceDark.withOpacity(0.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Change Password Panel
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock, color: Colors.orange, size: 24),
                          SizedBox(width: 8),
                          Text('Keamanan & Sandi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 32),
                      const Text('Password Lama', style: TextStyle(color: Colors.white54, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _oldPassCtrl,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Password Baru', style: TextStyle(color: Colors.white54, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _newPassCtrl,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Konfirmasi Password Baru', style: TextStyle(color: Colors.white54, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmPassCtrl,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoadingPass ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoadingPass
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Simpan Password Baru', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
