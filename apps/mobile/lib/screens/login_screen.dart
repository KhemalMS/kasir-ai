import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../utils/fullscreen.dart' if (dart.library.io) '../utils/fullscreen_stub.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _isFullscreen = isFullScreen();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleFullscreen() {
    toggleFullScreen();
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  void _showServerSettings() {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Pengaturan Server', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alamat server API:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'http://192.168.x.x:3001/api',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Contoh: http://192.168.1.24:3001/api\n'
              'Pastikan HP dan komputer server\nterhubung ke WiFi yang sama.',
              style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiConfig.setBaseUrl(controller.text.trim());
              if (mounted) {
                Navigator.pop(ctx);
                setState(() => _error = null);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Server diubah ke: ${controller.text.trim()}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Email dan kata sandi harus diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      await auth.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      final role = auth.userRole;
      debugPrint('🔑 Login role detected: $role (staff: ${auth.staff?['role']})');
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == 'dapur') {
        Navigator.pushReplacementNamed(context, '/kitchen');
      } else {
        Navigator.pushReplacementNamed(context, '/mulai-shift');
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Login error: $e');
      String errorMsg = 'Login gagal: $e';
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        errorMsg = 'Tidak dapat terhubung ke server. Pastikan server berjalan dan perangkat terhubung ke jaringan yang sama.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMsg = 'Koneksi timeout. Server tidak merespons.';
      }
      setState(() => _error = errorMsg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.point_of_sale,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'Kasir-AI',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textWhite,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Akses sistem POS cerdas untuk bisnis\nmulti-cabang Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Error
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Email field
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'EMAIL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.mail_outline, color: AppTheme.textMuted, size: 20),
                        hintText: 'kasir@kasir-ai.com',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'KATA SANDI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppTheme.textWhite),
                      onSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Login button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Masuk'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Server info (for debug)
                    Text(
                      'Server: ${ApiConfig.baseUrl}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Server settings button (top-left)
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                onPressed: _showServerSettings,
                tooltip: 'Pengaturan Server',
                icon: const Icon(
                  Icons.settings,
                  color: AppTheme.textMuted,
                  size: 24,
                ),
              ),
            ),
          ),
          if (kIsWeb)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: IconButton(
                  onPressed: _toggleFullscreen,
                  tooltip: _isFullscreen ? 'Keluar Layar Penuh' : 'Layar Penuh',
                  icon: Icon(
                    _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: AppTheme.textMuted,
                    size: 28,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
