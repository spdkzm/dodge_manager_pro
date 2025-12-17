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

  /// 複数の画像データを1つのPDFファイルとして印刷（1画像1ページ）
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

  /// 選手詳細の画像を並べて印刷（A4横、横5列）
  Future<void> printPlayerDetailImages({
    required String playerName,
    required int matchCount, // ★追加: 試合数を受け取る
    required List<Uint8List> images,
  }) async {
    // 日本語フォントをロード
    final font = await PdfGoogleFonts.notoSansJPRegular();
    final doc = pw.Document();

    // A4横向きのサイズ定義
    final pageFormat = PdfPageFormat.a4.landscape;
    // 余白
    const double margin = 20.0;
    // 有効幅
    final double contentWidth = pageFormat.width - (margin * 2);
    // 5列にするための1アイテムの幅 (spacing分を少し考慮)
    const double spacing = 10.0;
    // (有効幅 - (間隔 * 4)) / 5
    final double itemWidth = (contentWidth - (spacing * 4)) / 5;

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(margin),
        // ページ全体に日本語フォントを適用するテーマを設定
        theme: pw.ThemeData.withFont(
          base: font,
        ),
        build: (pw.Context context) {
          return [
            // ヘッダー
            pw.Header(
              level: 0,
              child: pw.Text(
                // ★修正: 「#背番号 コートネーム 〇試合出場」の形式に変更
                // playerNameには "背番号 コートネーム" が入ってくる想定
                "#$playerName  ${matchCount}試合出場",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  font: font, // 明示的にも指定
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            // 画像一覧をWrapで配置
            pw.Wrap(
              spacing: spacing,
              runSpacing: spacing,
              crossAxisAlignment: pw.WrapCrossAlignment.start,
              children: images.map((imgBytes) {
                final image = pw.MemoryImage(imgBytes);
                return pw.Container(
                  width: itemWidth,
                  // 画像のアスペクト比を維持しつつ幅に合わせる
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                );
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: '${playerName}_詳細',
    );
  }
}