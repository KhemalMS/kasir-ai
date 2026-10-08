import 'package:flutter/material.dart';

import '../services/error_notifier.dart';
import 'package:provider/provider.dart';
import '../models/app_error.dart';
import '../services/error_mapper.dart';
import '../widgets/error_widgets.dart';
import '../providers/auth_provider.dart';
import 'api_service.dart';

/// [ErrorNotifier] — sistem notifikasi error global.
///
/// Setup di main.dart:
/// ```dart
/// // 1. Tambahkan key ke MaterialApp
/// MaterialApp(
///   scaffoldMessengerKey: ErrorNotifier.messengerKey,
///   navigatorKey: ErrorNotifier.navigatorKey,
///   ...
/// )
///
/// // 2. Gunakan di catch block
/// } catch (e, stack) {
///   final err = ErrorMapper.from(e, stack, module: 'kasir', action: 'loadProduk');
///   ErrorNotifier.show(err);
/// }
/// ```
class ErrorNotifier {
  ErrorNotifier._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Rate limiting: max 1 error Snackbar per 3 detik
  static DateTime? _lastErrorTime;
  static const _errorCooldown = Duration(seconds: 3);

  /// Tampilkan SnackBar error (ringan — untuk aksi gagal)
  ///
  /// Rate-limited: max 1 error per 3 detik untuk mencegah spam.
  static void show(AppError error, {VoidCallback? onRetry}) {
    // Rate limiting: jangan spam user dengan error berulang
    final now = DateTime.now();
    if (_lastErrorTime != null &&
        now.difference(_lastErrorTime!) < _errorCooldown) {
      // Error terlalu cepat — skip tampilkan, tapi tetap log
      debugPrint('⏱️ Error skipped (rate limit): ${error.action}');
      return;
    }
    _lastErrorTime = now;

    if (error.category == ErrorCategory.auth && error.userMessage.toLowerCase().contains('sesi')) {
      handleUnauthorized(navigatorKey.currentContext);
      return;
    }

    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      AppSnackBar.error(
        error,
        onShowDetails: error.hasDetails ? () => showDetails(error) : null,
        onRetry: (onRetry != null || error.canRetry) ? () {
          _dismiss();
          if (onRetry != null) onRetry();
        } : null,
      ),
    );
  }

  /// Tampilkan SnackBar sukses
  static void showSuccess(String message) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(AppSnackBar.success(message));
  }

  /// Tampilkan SnackBar info
  static void showInfo(String message) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(AppSnackBar.info(message));
  }

  /// Tampilkan bottom sheet dengan detail teknis error
  static void showDetails(AppError error) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ErrorDetailsSheet(error: error),
    );
  }

/// Handle 401 — clear auth dan navigasi ke login (dengan debounce)
  static bool _isHandlingUnauthorized = false;
  
  static void handleUnauthorized(BuildContext? context) {
    if (_isHandlingUnauthorized) return; // debounce: jangan proses berulang kali
    _isHandlingUnauthorized = true;
    
    final nav = navigatorKey.currentState;
    final ctx = context ?? navigatorKey.currentContext;

    if (ctx != null) {
      // Clear token and update provider so it knows user is logged out
      ApiService.clearAuth().then((_) {
        ctx.read<AuthProvider>().checkAuth();
      });
    }

    if (nav == null) {
      _isHandlingUnauthorized = false;
      return;
    }

    nav.pushNamedAndRemoveUntil('/login', (_) => false);

    // Tampilkan pesan setelah navigasi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showInfo('Sesi telah berakhir. Silakan login kembali.');
      // Reset debounce setelah 2 detik
      Future.delayed(const Duration(seconds: 2), () {
        _isHandlingUnauthorized = false;
      });
    });
  }

  static void _dismiss() {
    messengerKey.currentState?.hideCurrentSnackBar();
  }
}
