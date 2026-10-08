import 'package:flutter/material.dart';
import '../widgets/error_widgets.dart';
import 'package:flutter/services.dart';
import '../models/app_error.dart';
import '../services/error_mapper.dart';
import '../config/app_theme.dart';

/// ────────────────────────────────────────────────────────────────────────────
/// AppSnackBar — Snackbar standar untuk notifikasi error/sukses
/// ────────────────────────────────────────────────────────────────────────────
class AppSnackBar {
  static SnackBar error(
    AppError error, {
    VoidCallback? onShowDetails,
    VoidCallback? onRetry,
  }) {
    // Parse hex color (hilangkan #)
    final hexColor = error.severityColor.replaceAll('#', '');
    final color = Color(int.parse('FF$hexColor', radix: 16));

    return SnackBar(
      content: Row(
        children: [
          Icon(Icons.error_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error.categoryLabel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  error.userMessage,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onShowDetails != null)
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white70),
              onPressed: onShowDetails,
              tooltip: 'Detail Error',
            ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('COBA LAGI', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      backgroundColor: AppTheme.surfaceDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      action: SnackBarAction(
        label: 'TUTUP',
        textColor: Colors.white70,
        onPressed: () {},
      ),
    );
  }

  static SnackBar success(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
      backgroundColor: AppTheme.surfaceDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.green.withOpacity(0.5)),
      ),
    );
  }

  static SnackBar info(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
      backgroundColor: AppTheme.surfaceDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.blue.withOpacity(0.5)),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// ErrorDetailsSheet — Bottom sheet berisi info teknis untuk developer
/// ────────────────────────────────────────────────────────────────────────────
class ErrorDetailsSheet extends StatelessWidget {
  final AppError error;

  const ErrorDetailsSheet({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final hexColor = error.severityColor.replaceAll('#', '');
    final color = Color(int.parse('FF$hexColor', radix: 16));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: color, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Detail Kesalahan Sistem',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow('Kategori', error.categoryLabel),
            _DetailRow('Kode', error.code ?? '-'),
            _DetailRow('Waktu', error.timestamp.toLocal().toString().substring(0, 19)),
            if (error.requestId != null) _DetailRow('Request ID', error.requestId!),
            if (error.endpoint != null)
              _DetailRow('Endpoint', '${error.method ?? 'GET'} ${error.endpoint}'),
            const SizedBox(height: 16),
            const Text('Pesan untuk Pengguna:', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(error.userMessage, style: const TextStyle(color: Colors.white)),
            if (error.technicalMessage != null) ...[
              const SizedBox(height: 16),
              const Text('Detail Teknis:', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error.technicalMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Salin Info Teknis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: error.copyableDetails));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Info berhasil disalin!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal menyalin. Coba seleksi manual.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// ErrorState — Widget untuk layar penuh saat gagal memuat data
/// ────────────────────────────────────────────────────────────────────────────
class ErrorState extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              error.category == ErrorCategory.network
                  ? Icons.wifi_off
                  : Icons.error_outline,
              size: 64,
              color: Colors.redAccent.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              error.userMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (error.hasDetails) ...[
              const SizedBox(height: 8),
              Text(
                'Kode: ${error.code ?? error.category.name} | ReqId: ${error.requestId ?? '-'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
            if (onRetry != null || error.canRetry) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
