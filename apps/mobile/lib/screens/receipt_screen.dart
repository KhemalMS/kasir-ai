import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../utils/web_print.dart' if (dart.library.io) '../utils/web_print_stub.dart';

class ReceiptScreen extends StatelessWidget {
  final String orderNumber;
  final String paymentMethod;
  final int totalAmount;
  final int paidAmount;
  final int changeAmount;
  final List<Map<String, dynamic>> items;
  final String cashierName;
  final String orderType;

  const ReceiptScreen({
    super.key,
    required this.orderNumber,
    required this.paymentMethod,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.items,
    required this.cashierName,
    required this.orderType,
  });

  String _formatCurrency(int amount) {
    return NumberFormat('#,###', 'id_ID').format(amount);
  }

  void _handlePrint(BuildContext context) {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cetak tersedia via web browser')),
      );
      return;
    }
    
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final itemsHtml = items.map((item) {
      final qty = item['quantity'] as int;
      final price = item['price'] as int;
      final subtotal = qty * price;
      final notes = item['notes']?.toString() ?? '';
      final notesRow = notes.isNotEmpty
          ? '<tr><td colspan="3" style="padding:0 0 2px 8px;font-style:italic;font-size:10px;color:#666">📝 $notes</td></tr>'
          : '';
      return '<tr><td colspan="3" style="padding:2px 0 0 0;">${item['name']}</td></tr>'
             '<tr><td style="padding:0 0 2px 8px;">$qty x ${_formatCurrency(price)}</td><td></td>'
             '<td style="text-align:right">Rp ${_formatCurrency(subtotal)}</td></tr>'
             '$notesRow';
    }).join('');

    final changeHtml = paymentMethod == 'Tunai'
      ? '<tr style="font-weight:bold"><td>Kembali</td><td></td><td style="text-align:right">Rp ${_formatCurrency(changeAmount)}</td></tr>'
      : '';

    final html = '''<!DOCTYPE html><html><head><meta charset="utf-8"><title>Struk $orderNumber</title>
<style>@page{margin:0;size:80mm auto}*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Courier New',monospace;font-size:12px;width:80mm;padding:8px;color:#000}
.c{text-align:center}.b{font-weight:bold}.d{border-top:1px dashed #000;margin:6px 0}
table{width:100%;border-collapse:collapse}td{vertical-align:top}.r{text-align:right}
.lg{font-size:14px}.sm{font-size:10px}</style></head><body>
<div class="c b lg">KASIR-AI POS</div><div class="c sm">Jl. Contoh No. 123</div>
<div class="c sm">Telp: 021-1234567</div><div class="d"></div>
<table><tr><td>No</td><td>: </td><td>$orderNumber</td></tr>
<tr><td>Tanggal</td><td>: </td><td>$dateStr</td></tr>
<tr><td>Kasir</td><td>: </td><td>$cashierName</td></tr>
<tr><td>Tipe</td><td>: </td><td>$orderType</td></tr></table><div class="d"></div>
<table>$itemsHtml</table><div class="d"></div>
<table><tr class="b"><td>TOTAL</td><td></td><td class="r lg">Rp ${_formatCurrency(totalAmount)}</td></tr>
<tr><td>Bayar ($paymentMethod)</td><td></td><td class="r">Rp ${_formatCurrency(paidAmount)}</td></tr>
$changeHtml</table><div class="d"></div>
<div class="c sm" style="margin-top:8px">Terima kasih atas kunjungan Anda!<br>
Barang yang sudah dibeli<br>tidak dapat ditukar/dikembalikan</div>
<div class="c sm" style="margin-top:8px">Powered by Kasir-AI</div>
<script>window.onload=function(){window.print()}</script></body></html>''';

    printReceiptHtml(html);
  }

  void _handleKitchenPrint(BuildContext context) {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cetak tersedia via web browser')),
      );
      return;
    }

    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);

    final kitchenItems = items.map((item) {
      final qty = item['quantity'] as int;
      final notes = item['notes']?.toString() ?? '';
      final notesHtml = notes.isNotEmpty
          ? '<div style="font-size:12px;font-style:italic;color:#555;padding-left:16px;margin-bottom:4px">📝 $notes</div>'
          : '';
      return '<div style="font-size:16px;font-weight:bold;padding:3px 0">${qty}x  ${item['name']}</div>$notesHtml';
    }).join('');

    final html = '''<!DOCTYPE html><html><head><meta charset="utf-8"><title>Kitchen $orderNumber</title>
<style>@page{margin:2mm;size:80mm auto}*{margin:0;padding:0;box-sizing:border-box}
body{font-family:monospace;font-size:14px;width:72mm;padding:4px;color:#000}
.c{text-align:center}.d{border-top:1px dashed #000;margin:6px 0}
table{width:100%;border-collapse:collapse}td{vertical-align:top;padding:2px 0}
.hdr{font-size:24px;font-weight:900;letter-spacing:2px}</style></head><body>
<div class="c"><div class="hdr">🍳 DAPUR</div></div><div class="d"></div>
<table>
<tr><td>No</td><td style="text-align:right;font-weight:bold">$orderNumber</td></tr>
<tr><td>Waktu</td><td style="text-align:right;font-weight:bold">$timeStr</td></tr>
<tr><td>Tipe</td><td style="text-align:right">$orderType</td></tr>
</table><div class="d"></div>
$kitchenItems
<div class="d"></div>
<div class="c" style="font-size:11px;color:#888;margin-top:4px">── KITCHEN TICKET ──</div>
<script>window.onload=function(){window.print()}</script></body></html>''';

    printReceiptHtml(html);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(now);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  // Success header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                    ),
                    child: const Column(children: [
                      Icon(Icons.check_circle, color: AppTheme.success, size: 48),
                      SizedBox(height: 10),
                      Text('Pembayaran Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.success)),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Receipt preview (white paper style)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text('KASIR-AI POS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black, fontFamily: 'monospace')),
                        const Text('Jl. Contoh No. 123', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 8),
                        _dottedDivider(),
                        const SizedBox(height: 8),

                        _receiptRow('No', orderNumber),
                        _receiptRow('Tanggal', dateStr),
                        _receiptRow('Kasir', cashierName),
                        _receiptRow('Tipe', orderType),
                        const SizedBox(height: 8),
                        _dottedDivider(),
                        const SizedBox(height: 8),

                        ...items.map((item) {
                          final qty = item['quantity'] as int;
                          final price = item['price'] as int;
                          final notes = item['notes']?.toString() ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('  $qty x Rp ${_formatCurrency(price)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text('Rp ${_formatCurrency(qty * price)}', style: const TextStyle(fontSize: 12, color: Colors.black)),
                                  ],
                                ),
                                if (notes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2, left: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit_note, size: 12, color: Color(0xFFFF9800)),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(notes, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFFFF9800)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        _dottedDivider(),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
                            Text('Rp ${_formatCurrency(totalAmount)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Bayar ($paymentMethod)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('Rp ${_formatCurrency(paidAmount)}', style: const TextStyle(fontSize: 12, color: Colors.black)),
                          ],
                        ),
                        if (paymentMethod == 'Tunai') ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Kembali', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black)),
                              Text('Rp ${_formatCurrency(changeAmount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        _dottedDivider(),
                        const SizedBox(height: 10),
                        const Text('Terima kasih atas kunjungan Anda!', style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
                        const Text('Powered by Kasir-AI', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () => _handlePrint(context),
                                icon: const Icon(Icons.receipt_long, size: 18),
                                label: const Text('Struk Pembeli', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textWhite,
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () => _handleKitchenPrint(context),
                                icon: const Icon(Icons.restaurant, size: 18),
                                label: const Text('Struk Dapur', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF6B35),
                                  side: const BorderSide(color: Color(0x40FF6B35)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Kembali ke Kasir'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          const Text(': ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.black))),
        ],
      ),
    );
  }

  Widget _dottedDivider() {
    return Row(
      children: List.generate(50, (i) => Expanded(
        child: Container(
          height: 1,
          color: i.isEven ? Colors.grey.shade400 : Colors.transparent,
        ),
      )),
    );
  }
}
