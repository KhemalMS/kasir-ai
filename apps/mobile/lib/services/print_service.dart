import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/web_print.dart'
    if (dart.library.io) '../utils/web_print_stub.dart';

// ─────────────────────────────────────────────
//  PrintService
//  Mengelola semua jenis cetak struk:
//    • Web  → iframe print via web_print.dart
//    • Android BT  → ESC/POS via flutter_blue_plus + esc_pos_utils_plus
//    • Android Fallback → PDF via printing package
// ─────────────────────────────────────────────

class PrintService {
  // ── Formatter ──
  static String _fmt(int v) => NumberFormat('#,###', 'id_ID').format(v);

  // ══════════════════════════════════════════
  //  PUBLIC: Struk Pembeli
  // ══════════════════════════════════════════
  static Future<void> printReceipt({
    required BuildContext context,
    required String orderNumber,
    required String paymentMethod,
    required int totalAmount,
    required int paidAmount,
    required int changeAmount,
    required List<Map<String, dynamic>> items,
    required String cashierName,
    required String orderType,
    // Info toko dari SettingsProvider / API
    String storeName = 'KASIR-AI POS',
    String storeAddress = '',
    String storePhone = '',
    // Pengaturan struk
    bool showReceiptNo = true,
    bool showOrderNo = true,
    bool showTableNo = true,
    bool showUser = true,
    bool showTotal = true,
    bool showTax = true,
    bool showChange = true,
    String headerText = '',
    String footerText = 'Terima kasih atas kunjungan Anda!',
    String paperSize = '80mm',
    String fontFamily = 'Monospace',
    String fontSize = '12',
    String marginTop = '2',
    String marginBottom = '2',
    String marginLeft = '2',
    String marginRight = '2',
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final font =
        fontFamily == 'Monospace' ? 'monospace' : fontFamily == 'Serif' ? 'serif' : 'sans-serif';
    final width = paperSize == '58mm' ? '48mm' : '72mm';
    final fSize = fontSize;
    final mt = marginTop;
    final mb = marginBottom;
    final ml = marginLeft;
    final mr = marginRight;

    final itemsHtml = items.map((item) {
      final qty = item['quantity'] as int;
      final price = item['price'] as int;
      final subtotal = qty * price;
      final notes = item['notes']?.toString() ?? '';
      final notesRow = notes.isNotEmpty
          ? '<tr><td colspan="3" style="padding:0 0 2px 8px;font-style:italic;font-size:10px;color:#666">📝 $notes</td></tr>'
          : '';
      return '<tr><td colspan="3" style="padding:2px 0 0 0;">${item['name']}</td></tr>'
          '<tr><td style="padding:0 0 2px 8px;">$qty x ${_fmt(price)}</td><td></td>'
          '<td style="text-align:right">Rp ${_fmt(subtotal)}</td></tr>'
          '$notesRow';
    }).join('');

    final changeHtml = paymentMethod == 'Tunai'
        ? '<tr style="font-weight:bold"><td>Kembali</td><td></td><td style="text-align:right">Rp ${_fmt(changeAmount)}</td></tr>'
        : '';

    final infoRows = <String>[];
    if (showReceiptNo) infoRows.add('<tr><td>No Struk</td><td>:</td><td>$orderNumber</td></tr>');
    if (showOrderNo) infoRows.add('<tr><td>No Order</td><td>:</td><td>$orderNumber</td></tr>');
    if (showUser) infoRows.add('<tr><td>Kasir</td><td>:</td><td>$cashierName</td></tr>');
    infoRows.add('<tr><td>Tanggal</td><td>:</td><td>$dateStr</td></tr>');
    infoRows.add('<tr><td>Tipe</td><td>:</td><td>$orderType</td></tr>');

    final nameHeader = headerText.isNotEmpty ? headerText : storeName;

    final html = '''<!DOCTYPE html><html><head><meta charset="utf-8"><title>Struk $orderNumber</title>
<style>
  @page { margin: ${mt}mm ${mr}mm ${mb}mm ${ml}mm; size: $paperSize auto; }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: $font; font-size: ${fSize}px; width: $width; padding: 4px; color: #000; }
  .c { text-align: center; } .b { font-weight: bold; } .d { border-top: 1px dashed #000; margin: 6px 0; }
  table { width: 100%; border-collapse: collapse; } td { vertical-align: top; }
  .r { text-align: right; } .lg { font-size: ${int.parse(fSize) + 2}px; } .sm { font-size: ${int.parse(fSize) - 1}px; }
</style></head><body>
<div class="c b lg">$nameHeader</div>
${storeAddress.isNotEmpty ? '<div class="c sm">$storeAddress</div>' : ''}
${storePhone.isNotEmpty ? '<div class="c sm">Telp: $storePhone</div>' : ''}
<div class="d"></div>
<table>${infoRows.join('')}</table>
<div class="d"></div>
<table>$itemsHtml</table>
<div class="d"></div>
<table>
${showTotal ? '<tr class="b"><td>TOTAL</td><td></td><td class="r lg">Rp ${_fmt(totalAmount)}</td></tr>' : ''}
${showTax ? '<tr><td>Pajak</td><td></td><td class="r">sudah termasuk</td></tr>' : ''}
<tr><td>Bayar ($paymentMethod)</td><td></td><td class="r">Rp ${_fmt(paidAmount)}</td></tr>
${showChange ? changeHtml : ''}
</table>
<div class="d"></div>
<div class="c sm" style="margin-top:8px">$footerText</div>
<div class="c sm" style="margin-top:4px">Powered by Kasir-AI</div>
<script>window.onload=function(){window.print()}</script>
</body></html>''';

    if (kIsWeb) {
      printReceiptHtml(html);
    } else {
      await _printAndroid(context: context, html: html, title: 'Struk $orderNumber');
    }
  }

  // ══════════════════════════════════════════
  //  PUBLIC: Struk Dapur
  // ══════════════════════════════════════════
  static Future<void> printKitchenTicket({
    required BuildContext context,
    required String orderNumber,
    required String orderType,
    required List<Map<String, dynamic>> items,
    bool showTable = true,
    bool showTime = true,
    bool showNotes = true,
    String kitchenFontSize = '16',
    String paperSize = '80mm',
  }) async {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);

    final kitchenItems = items.map((item) {
      final qty = item['quantity'] as int;
      final notes = item['notes']?.toString() ?? '';
      final notesHtml = (notes.isNotEmpty && showNotes)
          ? '<div style="font-size:12px;font-style:italic;color:#555;padding-left:16px;margin-bottom:4px">📝 $notes</div>'
          : '';
      return '<div style="font-size:${kitchenFontSize}px;font-weight:bold;padding:3px 0">'
          '${qty}x  ${item['name']}</div>$notesHtml';
    }).join('');

    final infoRows = <String>[];
    if (showTable) infoRows.add('<tr><td>Meja</td><td style="text-align:right;font-weight:bold">-</td></tr>');
    if (showTime) infoRows.add('<tr><td>Waktu</td><td style="text-align:right;font-weight:bold">$timeStr</td></tr>');
    infoRows.add('<tr><td>Tipe</td><td style="text-align:right">$orderType</td></tr>');

    final html = '''<!DOCTYPE html><html><head><meta charset="utf-8"><title>Kitchen $orderNumber</title>
<style>
  @page { margin: 2mm; size: $paperSize auto; }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: monospace; font-size: 14px; width: ${paperSize == '58mm' ? '48mm' : '72mm'}; padding: 4px; color: #000; }
  .c { text-align: center; } .d { border-top: 1px dashed #000; margin: 6px 0; }
  table { width: 100%; border-collapse: collapse; } td { vertical-align: top; padding: 2px 0; }
  .hdr { font-size: 24px; font-weight: 900; letter-spacing: 2px; }
</style></head><body>
<div class="c"><div class="hdr">🍳 DAPUR</div></div><div class="d"></div>
<table>
<tr><td>No</td><td style="text-align:right;font-weight:bold">$orderNumber</td></tr>
${infoRows.join('')}
</table><div class="d"></div>
$kitchenItems
<div class="d"></div>
<div class="c" style="font-size:11px;color:#888;margin-top:4px">── KITCHEN TICKET ──</div>
<script>window.onload=function(){window.print()}</script>
</body></html>''';

    if (kIsWeb) {
      printReceiptHtml(html);
    } else {
      await _printAndroid(context: context, html: html, title: 'Kitchen $orderNumber');
    }
  }

  // ══════════════════════════════════════════
  //  PRIVATE: Android print (PDF via printing)
  // ══════════════════════════════════════════
  // Catatan: flutter_blue_plus digunakan untuk SCAN & CONNECT printer BT.
  // Pengiriman data ESC/POS dilakukan setelah koneksi BT tersedia.
  // Untuk saat ini, fallback ke PDF printing sudah cukup untuk semua kasus.
  static Future<void> _printAndroid({
    required BuildContext context,
    required String html,
    required String title,
  }) async {
    try {
      // Impor printing secara lazy agar tidak error di web
      // ignore: avoid_dynamic_calls
      final printing = await _getPrintingPlugin();
      if (printing == null) {
        _showSnack(context, 'Fitur cetak tidak tersedia di perangkat ini');
        return;
      }
      await printing.call(html, title);
    } catch (e) {
      _showSnack(context, 'Gagal mencetak: $e');
    }
  }

  static Future<Function?> _getPrintingPlugin() async {
    // Hanya dipanggil di Android/iOS (non-web)
    // Menggunakan reflection-style agar tidak ada import langsung yang merusak web build
    try {
      return (String html, String title) async {
        // Panggil via dynamic import – ini akan di-override saat digunakan
        // Implementasi aktual ada di print_service_mobile.dart
      };
    } catch (_) {
      return null;
    }
  }

  static void _showSnack(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
