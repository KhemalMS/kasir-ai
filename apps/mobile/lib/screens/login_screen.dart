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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  bool _isFullscreen = false;
  bool _showConnecting = true;

  late AnimationController _animController;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _isFullscreen = isFullScreen();
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final curvedLogo = CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic));
    _logoFade = Tween<double>(begin: 0, end: 1).animate(curvedLogo);
    _logoSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(curvedLogo);

    final curvedForm = CurvedAnimation(parent: _animController, curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic));
    _formFade = Tween<double>(begin: 0, end: 1).animate(curvedForm);
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(curvedForm);

    final curvedBtn = CurvedAnimation(parent: _animController, curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic));
    _btnFade = Tween<double>(begin: 0, end: 1).animate(curvedBtn);

    _animController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showConnecting = false);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
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
      builder: (ctx) {
        bool isDetecting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text('Pengaturan Server', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.wifi_find, size: 18),
                    label: isDetecting
                        ? const Row(mainAxisSize: MainAxisSize.min, children: [
                            SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            SizedBox(width: 8),
                            Text('Mencari server...'),
                          ])
                        : const Text('🔍 Auto-Deteksi'),
                    onPressed: isDetecting ? null : () async {
                      setStateDialog(() => isDetecting = true);
                      await ApiConfig.autoDetect();
                      setStateDialog(() {
                        isDetecting = false;
                        controller.text = ApiConfig.baseUrl;
                      });
                      if (mounted) {
                        if (ApiConfig.baseUrl.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Server tidak ditemukan'), backgroundColor: Colors.red),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Server otomatis terdeteksi!'), backgroundColor: Colors.green),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Atau masukkan alamat manual:',
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
                      fillColor: AppTheme.bgDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Server otomatis terdeteksi saat buka aplikasi.\nGunakan tombol di atas jika perlu deteksi ulang.',
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
            );
          }
        );
      },
    ).then((_) => controller.dispose());
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
      String errorMsg = 'Login gagal. Periksa email dan kata sandi Anda.';
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        errorMsg = 'Tidak dapat terhubung ke server. Pastikan server berjalan dan perangkat terhubung ke jaringan yang sama.';
      } else if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        errorMsg = 'Server tidak merespons dalam 12 detik. Periksa koneksi internet atau hubungi admin.';
      } else if (e.toString().contains('401') || e.toString().contains('Invalid') || e.toString().contains('credentials')) {
        errorMsg = 'Email atau kata sandi salah. Silakan coba lagi.';
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
                    // Animated Logo & Title
                    SlideTransition(
                      position: _logoSlide,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Column(
                          children: [
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
                          ],
                        ),
                      ),
                    ),

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

                    // Animated Form Fields
                    SlideTransition(
                      position: _formSlide,
                      child: FadeTransition(
                        opacity: _formFade,
                        child: Column(
                          children: [
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
                          ],
                        ),
                      ),
                    ),

                    // Animated Login button
                    FadeTransition(
                      opacity: _btnFade,
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              disabledBackgroundColor: AppTheme.primary.withOpacity(0.8),
                            ),
                            child: _isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Sedang masuk...', style: TextStyle(color: Colors.white)),
                                    ],
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
                          // Server info
                          if (_showConnecting)
                            Text(
                              'Menghubungi server: ${ApiConfig.baseUrl}',
                              style: const TextStyle(fontSize: 10, color: Colors.blueAccent),
                            )
                          else
                            Text(
                              'Server: ${ApiConfig.baseUrl}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                        ],
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
