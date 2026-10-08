import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/platform_helper_web.dart' if (dart.library.io) '../utils/platform_helper_stub.dart';

class ExportService {
  static Future<void> exportToExcel(String reportTitle, List<String> headers, List<List<dynamic>> rows) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Title
    sheet.cell(CellIndex.indexByString("A1")).value = TextCellValue(reportTitle);
    
    // Headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(bold: true);
    }

    // Rows
    for (int r = 0; r < rows.length; r++) {
      for (int c = 0; c < rows[r].length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 3));
        final val = rows[r][c];
        if (val is num) {
          if (val is int) {
            cell.value = IntCellValue(val);
          } else {
            cell.value = DoubleCellValue(val.toDouble());
          }
        } else {
          cell.value = TextCellValue(val?.toString() ?? '');
        }
      }
    }

    final bytes = excel.encode();
    if (bytes != null) {
      final safeTitle = reportTitle.replaceAll(' ', '_').toLowerCase();
      webDownloadFile(
        bytes: bytes,
        fileName: '${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }

  static Future<void> exportToPdf(BuildContext ctx, String reportTitle, List<String> headers, List<List<dynamic>> rows) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(reportTitle, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows.map((row) => row.map((e) => e?.toString() ?? '').toList()).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellHeight: 30,
              cellAlignments: {
                for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft,
              },
            ),
          ];
        },
      ),
    );

    final safeTitle = reportTitle.replaceAll(' ', '_').toLowerCase();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
