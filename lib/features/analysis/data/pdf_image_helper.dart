// lib/features/analysis/data/pdf_image_helper.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfImageHelper {
  Future<void> printMultipleImages({
    required String baseFileName,
    required List<Uint8List> images,
  }) async {
    final doc = pw.Document();

    for (final imgBytes in images) {
      final image = pw.MemoryImage(imgBytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: baseFileName,
    );
  }

  Future<void> printPlayerDetailImages({
    required String playerName,
    required int matchCount,
    required List<Uint8List> images,
  }) async {
    final font = await PdfGoogleFonts.notoSansJPRegular();
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) {
          return _buildPlayerDetailContent(
            playerName,
            matchCount,
            images,
            font,
            PdfPageFormat.a4.landscape.width - 40,
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: '${playerName}_詳細',
    );
  }

  Future<void> printMultiplePlayersDetails({
    required List<Map<String, dynamic>> playersData,
  }) async {
    final font = await PdfGoogleFonts.notoSansJPRegular();
    final doc = pw.Document();

    for (var player in playersData) {
      final playerName = player['name'] as String;
      final matchCount = player['matchCount'] as int;
      final images = player['images'] as List<Uint8List>;

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          theme: pw.ThemeData.withFont(base: font),
          build: (pw.Context context) {
            return _buildPlayerDetailContent(
              playerName,
              matchCount,
              images,
              font,
              PdfPageFormat.a4.landscape.width - 40,
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: '全選手詳細分析',
    );
  }

  List<pw.Widget> _buildPlayerDetailContent(
      String playerName,
      int matchCount,
      List<Uint8List> images,
      pw.Font font,
      double availableWidth,
      ) {
    const double spacing = 10.0;
    // 5列で計算
    final double itemWidth = (availableWidth - (spacing * 4)) / 5;

    return [
      pw.Header(
        level: 0,
        child: pw.Text(
          "#$playerName  ${matchCount}試合出場",
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: font),
        ),
      ),
      pw.SizedBox(height: 10),
      if (images.isNotEmpty)
        pw.Wrap(
          spacing: spacing,
          runSpacing: spacing,
          crossAxisAlignment: pw.WrapCrossAlignment.start,
          children: images.map((imgBytes) {
            final image = pw.MemoryImage(imgBytes);
            return pw.Container(
              width: itemWidth,
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          }).toList(),
        )
      else
        pw.Center(
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 50),
            child: pw.Text("表示するデータがありません", style: pw.TextStyle(fontSize: 14, font: font)),
          ),
        ),
    ];
  }
}