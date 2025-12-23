// lib/features/analysis/data/pdf_export_service.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../settings/domain/action_definition.dart';
import '../domain/player_stats.dart';

class PdfExportService {
  /// 成績集計表をPDFとして出力する
  /// Tableウィジェットを廃止し、アプリ画面同様「Rowの羅列」で構築することで
  /// ヘッダーとデータ行の完全な整列を実現する
  Future<void> printStatsList({
    required String teamName,
    required String periodLabel,
    required List<PlayerStats> stats,
    required List<ActionDefinition> actionDefinitions,
  }) async {
    // 日本語フォントをロード
    final font = await PdfGoogleFonts.notoSansJPRegular();
    final doc = pw.Document();

    // ■ 1. 列幅の定義 (単位: mm)
    const double wNumber = 11.0 * PdfPageFormat.mm;     // 背番号 (約11mm)
    const double wName = 32.0 * PdfPageFormat.mm;       // コートネーム (約32mm)
    const double wMatch = 11.0 * PdfPageFormat.mm;      // 試合数 (約11mm)
    const double wActionSub = 13.0 * PdfPageFormat.mm;  // アクション詳細幅 (約13mm)

    // ■ 2. スタイル定義
    const headerTextColor = PdfColors.black;
    const borderColor = PdfColors.grey400;
    const borderSide = pw.BorderSide(color: borderColor, width: 0.5);

    // ■ 3. ヘッダー構築ヘルパー

    // 固定列ヘッダー (2行分の高さ)
    pw.Widget buildFixedHeader(String text, double width, {bool isFirst = false}) {
      return pw.Container(
        width: width,
        height: 36,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border(
            top: borderSide,
            bottom: borderSide,
            left: isFirst ? borderSide : pw.BorderSide.none, // 左端のみ描画
            right: borderSide,
          ),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(font: font, color: headerTextColor, fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    // アクションヘッダー (アクション名 + サブ項目)
    pw.Widget buildActionHeader(ActionDefinition def) {
      final subLabels = <String>[];
      if (def.hasSuccess && def.hasFailure) {
        subLabels.addAll(['成功', '失敗', '率']);
      } else if (def.hasSuccess) {
        subLabels.add('成功数');
      } else if (def.hasFailure) {
        subLabels.add('失敗数');
      } else {
        subLabels.add('回数');
      }

      final double totalWidth = wActionSub * subLabels.length;

      return pw.Column(
        children: [
          // 上段：アクション名
          pw.Container(
            width: totalWidth,
            height: 18,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: borderSide,
                right: borderSide,
                bottom: borderSide,
              ),
            ),
            child: pw.Text(
              def.name,
              style: pw.TextStyle(font: font, color: headerTextColor, fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
          // 下段：サブ項目
          pw.Row(
            children: subLabels.map((label) {
              return pw.Container(
                width: wActionSub,
                height: 18,
                alignment: pw.Alignment.center,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    right: borderSide,
                    bottom: borderSide,
                  ),
                ),
                child: pw.Text(
                  label,
                  style: pw.TextStyle(font: font, color: headerTextColor, fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    // ヘッダー全体 (Row)
    final headerWidget = pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        buildFixedHeader('背番号', wNumber, isFirst: true),
        buildFixedHeader('コートネーム', wName),
        buildFixedHeader('試合数', wMatch),
        ...actionDefinitions.map((def) => buildActionHeader(def)),
      ],
    );

    // ■ 4. データ行構築ヘルパー (TableではなくRowを使用)

    // 1つのセルを作る関数
    pw.Widget buildDataCell(String text, double width, {bool isFirst = false, bool alignLeft = false}) {
      return pw.Container(
        width: width,
        // 高さは内容に応じて自動、または固定。ここではパディングで見栄えを調整
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border(
            // 上の線は「前の行の下線」または「ヘッダーの下線」が既にあるので描かない
            bottom: borderSide,
            left: isFirst ? borderSide : pw.BorderSide.none, // 左端のみ描画
            right: borderSide,
          ),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(font: font, fontSize: 9),
          overflow: pw.TextOverflow.clip,
        ),
      );
    }

    // データ行のリストを作成
    final List<pw.Widget> dataRows = stats.map((player) {
      final cells = <pw.Widget>[];

      // 背番号の表示制御（空ならハイフン）
      final displayNumber = player.playerNumber.isEmpty ? '-' : player.playerNumber;

      // 固定列
      cells.add(buildDataCell(displayNumber, wNumber, isFirst: true));
      cells.add(buildDataCell(player.playerName, wName, alignLeft: true));
      cells.add(buildDataCell(player.matchesPlayed.toString(), wMatch));

      // アクション列
      for (final def in actionDefinitions) {
        final stat = player.actions[def.name];
        if (def.hasSuccess && def.hasFailure) {
          cells.add(buildDataCell(stat?.successCount.toString() ?? '-', wActionSub));
          cells.add(buildDataCell(stat?.failureCount.toString() ?? '-', wActionSub));
          cells.add(buildDataCell(stat != null && stat.totalCount > 0 ? "${stat.successRate.toStringAsFixed(0)}%" : '-', wActionSub));
        } else if (def.hasSuccess) {
          cells.add(buildDataCell(stat?.successCount.toString() ?? '-', wActionSub));
        } else if (def.hasFailure) {
          cells.add(buildDataCell(stat?.failureCount.toString() ?? '-', wActionSub));
        } else {
          cells.add(buildDataCell(stat?.totalCount.toString() ?? '-', wActionSub));
        }
      }

      // Rowで1行を返す
      return pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: cells,
      );
    }).toList();

    // ■ 5. PDF生成
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(base: font),

        // ヘッダー設定
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              teamName,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, font: font),
            ),
            pw.Text(
              periodLabel,
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700, font: font),
            ),
            pw.SizedBox(height: 10),
            // ヘッダー (Row)
            headerWidget,
          ],
        ),

        build: (pw.Context context) {
          // Tableではなく、単なるRowのリストを返す
          return dataRows;
        },
      ),
    );

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

  /// 選手詳細の画像を並べて印刷（単一選手用）
  Future<void> printPlayerDetailImages({
    required String playerName,
    required int matchCount,
    required List<Uint8List> images,
  }) async {
    final font = await PdfGoogleFonts.notoSansJPRegular();
    final doc = pw.Document();

    final pageFormat = PdfPageFormat.a4.landscape;
    const double margin = 20.0;
    final double contentWidth = pageFormat.width - (margin * 2);
    const double spacing = 10.0;
    final double itemWidth = (contentWidth - (spacing * 4)) / 5;

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(margin),
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) {
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
                child: pw.Text("表示するデータがありません", style: pw.TextStyle(font: font)),
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

  /// 複数選手分の詳細を一括印刷
  Future<void> printMultiplePlayersDetails({
    required List<Map<String, dynamic>> playersData,
  }) async {
    final font = await PdfGoogleFonts.notoSansJPRegular();
    final doc = pw.Document();

    final pageFormat = PdfPageFormat.a4.landscape;
    const double margin = 20.0;
    final double contentWidth = pageFormat.width - (margin * 2);
    const double spacing = 10.0;
    final double itemWidth = (contentWidth - (spacing * 4)) / 5;

    for (var player in playersData) {
      final playerName = player['name'] as String;
      final matchCount = player['matchCount'] as int;
      final images = player['images'] as List<Uint8List>;

      doc.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(margin),
          theme: pw.ThemeData.withFont(base: font),
          build: (pw.Context context) {
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
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: '全選手詳細分析',
    );
  }
}