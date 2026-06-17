import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/staff_provider.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'package:image_picker/image_picker.dart';
// Web-only import
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class StaffFormScreen extends StatefulWidget {
  final Map<String, dynamic>? staff; // Null if creating
  const StaffFormScreen({super.key, this.staff});

  @override
  State<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends State<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _branches = [];
  bool _isLoadingBranches = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankAccountNumberCtrl = TextEditingController();
  final _bankAccountNameCtrl = TextEditingController();
  final _emergencyContactNameCtrl = TextEditingController();
  final _emergencyContactPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // State vars
  String? _gender = 'Laki-laki';
  String? _role;
  String? _branchId;
  String? _status = 'Aktif';
  String? _employmentType = 'Tetap';
  DateTime? _birthDate;
  String? _imageUrl;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();

    if (widget.staff != null) {
      final s = widget.staff!;
      _nameCtrl.text = s['name'] ?? '';
      _phoneCtrl.text = s['phone'] ?? '';
      _emailCtrl.text = s['email'] ?? '';
      _addressCtrl.text = s['address'] ?? '';
      _pinCtrl.text = s['pinCode'] ?? '';
      _bankNameCtrl.text = s['bankName'] ?? '';
      _bankAccountNumberCtrl.text = s['bankAccountNumber'] ?? '';
      _bankAccountNameCtrl.text = s['bankAccountName'] ?? '';
      _emergencyContactNameCtrl.text = s['emergencyContactName'] ?? '';
      _emergencyContactPhoneCtrl.text = s['emergencyContactPhone'] ?? '';
      _notesCtrl.text = s['notes'] ?? '';

      _gender = s['gender'] ?? 'Laki-laki';
      _role = s['role'];
      _branchId = s['branchId'];
      _status = s['status'] ?? 'Aktif';
      _employmentType = s['employmentType'] ?? 'Tetap';
      _imageUrl = s['imageUrl'];

      if (s['birthDate'] != null) _birthDate = DateTime.tryParse(s['birthDate']);
    }
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      final data = await ApiService.getList('/branches');
      setState(() {
        _branches = data.map((e) => e as Map<String, dynamic>).toList();
        if (_branchId == null && _branches.length == 1) {
          _branchId = _branches[0]['id'];
        }
      });
    } catch (e) {
      debugPrint('Error loading branches: $e');
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _pinCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountNumberCtrl.dispose();
    _bankAccountNameCtrl.dispose();
    _emergencyContactNameCtrl.dispose();
    _emergencyContactPhoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0D9488),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppTheme.bgDark,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Peran')));
      return;
    }
    if (_branchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Cabang')));
      return;
    }

    final data = {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'pinCode': _pinCtrl.text.trim().isNotEmpty ? _pinCtrl.text.trim() : null,
      'gender': _gender,
      'role': _role,
      'branchId': _branchId,
      'status': _status,
      'employmentType': _employmentType,
      'birthDate': _birthDate?.toIso8601String().split('T')[0],
      'imageUrl': _imageUrl,
      'bankName': _bankNameCtrl.text.trim().isNotEmpty ? _bankNameCtrl.text.trim() : null,
      'bankAccountNumber': _bankAccountNumberCtrl.text.trim().isNotEmpty ? _bankAccountNumberCtrl.text.trim() : null,
      'bankAccountName': _bankAccountNameCtrl.text.trim().isNotEmpty ? _bankAccountNameCtrl.text.trim() : null,
      'emergencyContactName': _emergencyContactNameCtrl.text.trim().isNotEmpty ? _emergencyContactNameCtrl.text.trim() : null,
      'emergencyContactPhone': _emergencyContactPhoneCtrl.text.trim().isNotEmpty ? _emergencyContactPhoneCtrl.text.trim() : null,
      'notes': _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    };

    try {
      final provider = context.read<StaffProvider>();
      if (widget.staff == null) {
        final res = await provider.createStaff(data);
        if (mounted) {
          Navigator.pop(context);
          if (res['tempPassword'] != null) {
            _showPasswordDialog(res['tempPassword']);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pegawai berhasil ditambahkan')));
          }
        }
      } else {
        await provider.updateStaff(widget.staff!['id'], data);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pegawai berhasil diperbarui')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger));
      }
    }
  }

  void _showPasswordDialog(String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Akun Berhasil Dibuat', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Berikan password sementara ini kepada pegawai:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.bgDark,
              width: double.infinity,
              child: SelectableText(
                password,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.greenAccent),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Mereka akan diminta mengganti password saat login pertama kali.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF0D9488))),
          )
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    if (kIsWeb) {
      await _pickAndUploadImageWeb();
    } else {
      await _pickAndUploadImageNative();
    }
  }

  // ── Web implementation: uses native FormData + XHR ───────────────────────
  Future<void> _pickAndUploadImageWeb() async {
    final completer = Completer<void>();

    final uploadInput = html.FileUploadInputElement()
      ..accept = 'image/png,image/jpeg,image/webp'
      ..style.display = 'none';
    html.document.body?.append(uploadInput);

    uploadInput.onChange.listen((_) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) {
        uploadInput.remove();
        if (!completer.isCompleted) completer.complete();
        return;
      }
      final file = files.first;
      setState(() => _isUploadingAvatar = true);
      try {
        // Use FormData + XHR — the native browser way to upload files.
        // This avoids the ByteBuffer→Uint8List cast issue with FileReader.
        final formData = html.FormData();
        formData.appendBlob('image', file, file.name);

        final xhrCompleter = Completer<Map<String, dynamic>>();
        final xhr = html.HttpRequest();
        final url = '${ApiConfig.baseUrl}/upload/avatar';

        xhr.open('POST', url, async: true);
        xhr.withCredentials = true;

        // Set Bearer token for authentication
        final token = ApiService.sessionBearerToken;
        if (token != null && token.isNotEmpty) {
          xhr.setRequestHeader('Authorization', 'Bearer $token');
        }

        xhr.onLoad.listen((_) {
          try {
            final data = jsonDecode(xhr.responseText ?? '{}') as Map<String, dynamic>;
            if (!xhrCompleter.isCompleted) xhrCompleter.complete(data);
          } catch (e) {
            if (!xhrCompleter.isCompleted) xhrCompleter.completeError('Parse error: $e');
          }
        });
        xhr.onError.listen((_) {
          if (!xhrCompleter.isCompleted) xhrCompleter.completeError('Network error');
        });
        xhr.send(formData);

        final response = await xhrCompleter.future;

        if (response['success'] == true && response['imageUrl'] != null) {
          if (mounted) setState(() => _imageUrl = response['imageUrl'] as String);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Avatar berhasil diunggah!')),
            );
          }
        } else {
          throw Exception('Upload gagal: ${response['error'] ?? 'Unknown error'}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error upload: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        uploadInput.remove();
        if (mounted) setState(() => _isUploadingAvatar = false);
        if (!completer.isCompleted) completer.complete();
      }
    });

    uploadInput.click();
    await completer.future;
  }

  // ── Native (Android/iOS) implementation: uses image_picker ───────────────
  Future<void> _pickAndUploadImageNative() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() => _isUploadingAvatar = true);
      final bytes = await pickedFile.readAsBytes();
      final response = await ApiService.uploadMultipart(
        '/upload/avatar',
        'image',
        bytes.toList(),
        pickedFile.name,
      );
      if (response['success'] == true && response['imageUrl'] != null) {
        if (mounted) setState(() => _imageUrl = response['imageUrl'] as String);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar berhasil diunggah')),
          );
        }
      } else {
        throw Exception('Upload gagal: ${response['error']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error upload: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // --- UI Builders ---

  InputDecoration _customInputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _buildToggleButtons({
    required List<String> options,
    required String selected,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = opt == selected;
          return GestureDetector(
            onTap: () => onChanged(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    opt,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.staff != null;
    final isLoading = context.watch<StaffProvider>().isLoading || _isLoadingBranches;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 880,
          maxHeight: screenHeight * 0.90,
        ),
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
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // HEADER — always visible
                        _buildHeader(isEdit),
                        // BODY — scrollable
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  _buildAvatar(),
                                  const SizedBox(height: 24),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isWide = constraints.maxWidth > 560;
                                      if (isWide) {
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: _buildLeftColumn()),
                                            const SizedBox(width: 32),
                                            Expanded(child: _buildRightColumn()),
                                          ],
                                        );
                                      } else {
                                        return Column(
                                          children: [
                                            _buildLeftColumn(),
                                            const SizedBox(height: 24),
                                            _buildRightColumn(),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // FOOTER — always visible at bottom
                        _buildFooter(isEdit),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEdit) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 16, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Data Pegawai' : 'Tambah Pegawai Baru',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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

  Widget _buildAvatar() {
    return Row(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.5), width: 2),
            image: _imageUrl != null && _imageUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(_imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: (_imageUrl == null || _imageUrl!.isEmpty)
              ? Icon(Icons.person, color: Colors.white.withOpacity(0.4), size: 40)
              : null,
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Foto Profil',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isUploadingAvatar ? null : _pickAndUploadImage,
                icon: _isUploadingAvatar 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.upload_file, size: 16),
                label: Text(_isUploadingAvatar ? 'Mengunggah...' : (_imageUrl == null || _imageUrl!.isEmpty ? 'Pilih Foto' : 'Ganti Foto')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceDark,
                  foregroundColor: Colors.white,

                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isEdit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Batal', style: TextStyle(fontSize: 16, color: Colors.white70)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isEdit ? 'Simpan Perubahan' : 'Tambah Pegawai',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Identitas & Kontak',
          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _nameCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _customInputDeco('Nama Lengkap *'),
          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          enabled: widget.staff == null,
          decoration: _customInputDeco('Email *'),
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v!.isEmpty) return 'Wajib diisi';
            if (!v.contains('@')) return 'Email tidak valid';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _customInputDeco('No. HP / WhatsApp *'),
          keyboardType: TextInputType.phone,
          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _addressCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _customInputDeco('Alamat Lengkap'),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        // Date picker
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white.withOpacity(0.4)),
                const SizedBox(width: 10),
                Text(
                  _birthDate != null
                      ? '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}'
                      : 'Tanggal Lahir',
                  style: TextStyle(
                    color: _birthDate != null ? Colors.white : Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text('Jenis Kelamin', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        _buildToggleButtons(
          options: ['Laki-laki', 'Perempuan'],
          selected: _gender ?? 'Laki-laki',
          onChanged: (val) => setState(() => _gender = val),
        ),
        
        const SizedBox(height: 24),
        const Text(
          'Kontak Darurat',
          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emergencyContactNameCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _customInputDeco('Nama Kontak Darurat'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emergencyContactPhoneCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _customInputDeco('No. HP Kontak Darurat'),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Pekerjaan',
          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _role,
          dropdownColor: AppTheme.surfaceDark,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _customInputDeco('Peran *'),
          items: ['Admin', 'Kasir', 'Barista', 'Chef', 'Pelayan', 'Manajer']
              .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setState(() => _role = v),
          validator: (v) => v == null ? 'Wajib dipilih' : null,
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _branchId,
          dropdownColor: AppTheme.surfaceDark,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _customInputDeco('Cabang *'),
          items: _branches.map((b) => DropdownMenuItem(
            value: b['id'] as String,
            child: Text(b['name'] ?? ''),
          )).toList(),
          onChanged: (v) => setState(() => _branchId = v),
          validator: (v) => v == null ? 'Wajib dipilih' : null,
        ),
        const SizedBox(height: 16),

        const Text('Tipe Kontrak', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        _buildToggleButtons(
          options: ['Tetap', 'Paruh Waktu', 'Magang'],
          selected: _employmentType ?? 'Tetap',
          onChanged: (val) => setState(() => _employmentType = val),
        ),
        const SizedBox(height: 16),

        const Text('Status', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        _buildToggleButtons(
          options: ['Aktif', 'Tidak Aktif'],
          selected: _status ?? 'Aktif',
          onChanged: (val) => setState(() => _status = val),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _notesCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _customInputDeco('Catatan Internal (Opsional)'),
          maxLines: 2,
        ),
        
        const SizedBox(height: 24),
        const Text(
          'Informasi Bank (Opsional)',
          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bankNameCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _customInputDeco('Nama Bank (Misal: BCA, BNI)'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bankAccountNumberCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _customInputDeco('Nomor Rekening'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bankAccountNameCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _customInputDeco('Nama Pemilik Rekening'),
        ),
      ],
    );
  }
}
