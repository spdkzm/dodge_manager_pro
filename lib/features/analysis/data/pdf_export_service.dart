// lib/features/analysis/data/pdf_export_service.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportService {
  /// 画像データをPDFに貼り付けて印刷プレビューを表示する
  Future<void> printStatsImage({
    required String teamName,
    required Uint8List imageBytes,
  }) async {
    final doc = pw.Document();
    final image = pw.MemoryImage(imageBytes);

    doc.addPage(
      pw.Page(
        // A4 横向き
        pageFormat: PdfPageFormat.a4.landscape,
        // 余白を少し設ける
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Center(
            // 画像をページ内に収める（アスペクト比維持）
            child: pw.Image(image, fit: pw.BoxFit.contain),
          );
        },
      ),
    );

    // 印刷ダイアログ（プレビュー）を表示
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: '${teamName}_集計表',
    );
  }
}