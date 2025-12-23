// lib/features/analysis/data/pdf_export_service.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../settings/domain/action_definition.dart';
import '../domain/player_stats.dart';
import '../../game_record/domain/models.dart';

class PdfExportService {
  /// 成績集計表をPDFとして出力する
  Future<void> printStatsList({
    required String teamName,
    required String periodLabel,
    required List<PlayerStats> stats,
    required List<ActionDefinition> actionDefinitions,
  }) async {
    final font = await PdfGoogleFonts.notoSansJPRegular();
    final doc = pw.Document();

    const double wNumber = 11.0 * PdfPageFormat.mm;
    const double wName = 32.0 * PdfPageFormat.mm;
    const double wMatch = 11.0 * PdfPageFormat.mm;
    const double wActionSub = 13.0 * PdfPageFormat.mm;

    const headerTextColor = PdfColors.black;
    const borderColor = PdfColors.grey400;
    const borderSide = pw.BorderSide(color: borderColor, width: 0.5);

    pw.Widget buildFixedHeader(String text, double width, {bool isFirst = false}) {
      return pw.Container(
        width: width,
        height: 36,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border(
            top: borderSide,
            bottom: borderSide,
            left: isFirst ? borderSide : pw.BorderSide.none,
            right: borderSide,
          ),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(font: font, color: headerTextColor, fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      );
    }

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

    final headerWidget = pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        buildFixedHeader('背番号', wNumber, isFirst: true),
        buildFixedHeader('コートネーム', wName),
        buildFixedHeader('試合数', wMatch),
        ...actionDefinitions.map((def) => buildActionHeader(def)),
      ],
    );

    pw.Widget buildDataCell(String text, double width, {bool isFirst = false, bool alignLeft = false}) {
      return pw.Container(
        width: width,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: borderSide,
            left: isFirst ? borderSide : pw.BorderSide.none,
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

    final List<pw.Widget> dataRows = stats.map((player) {
      final cells = <pw.Widget>[];
      final displayNumber = player.playerNumber.isEmpty ? '-' : player.playerNumber;

      cells.add(buildDataCell(displayNumber, wNumber, isFirst: true));
      cells.add(buildDataCell(player.playerName, wName, alignLeft: true));
      cells.add(buildDataCell(player.matchesPlayed.toString(), wMatch));

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

      return pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: cells,
      );
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(base: font),
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
            headerWidget,
          ],
        ),
        build: (pw.Context context) {
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

  // ■■■ 以下、ネイティブログ印刷用の追加メソッド ■■■

  /// 試合ログをネイティブPDFとして出力する（段組みレイアウト対応）
  /// [printRequests] は { 'record': MatchRecord, 'nameMap': Map<String, String> } のリストを受け取る
  Future<void> printMatchLogsNative({
    required String baseFileName,
    required List<Map<String, dynamic>> printRequests,
  }) async {
    final font = await PdfGoogleFonts.notoSansJPRegular();
    final doc = pw.Document();

    // レイアウト設定 (A4横)
    final pageFormat = PdfPageFormat.a4.landscape;

    const double margin = 15.0 * PdfPageFormat.mm; // マージン
    final double contentHeight = pageFormat.height - (margin * 2);

    // 2列構成
    const int colsPerPage = 2;
    const double gapWidth = 4.0 * PdfPageFormat.mm;
    // (全幅 - ギャップ合計) / 列数
    final double colWidth = (pageFormat.width - (margin * 2) - (gapWidth * (colsPerPage - 1))) / colsPerPage;

    // ヘッダーやフッターの高さを概算
    const double headerAreaHeight = 25.0 * PdfPageFormat.mm; // ページ上部の試合情報
    const double logRowHeight = 18.0; // 1行の高さ

    // 共通スタイル
    final textStyle = pw.TextStyle(font: font, fontSize: 9);
    final boldStyle = pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold);
    final systemLogColor = PdfColors.grey200;
    final successColor = PdfColors.red50;
    final failureColor = PdfColors.blue50;

    // カラム幅の定義
    const double wTime = 35;
    const double wNumber = 25;
    const double wGap = 4;
    const double wName = 50;
    // システムログのインデント用 (Number + Gap + Name)
    const double wSystemIndent = wNumber + wGap + wName;
    // サブアクション用の幅
    const double wSubAction = 120;

    // 1行分のWidgetを作る関数
    pw.Widget buildLogItem(LogEntry log, Map<String, String> nameMap) {
      if (log.type == LogType.system) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: pw.BoxDecoration(
            color: systemLogColor,
            border: const pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          child: pw.Row(
            children: [
              pw.SizedBox(width: wTime, child: pw.Text(log.gameTime, style: textStyle.copyWith(color: PdfColors.grey700))),
              // ★変更: アクションログの位置(背番号+名前分)までスペースを空ける
              pw.SizedBox(width: wSystemIndent),
              pw.Expanded(child: pw.Text(log.action, style: boldStyle.copyWith(color: PdfColors.grey700))),
              // ★変更: サブアクションエリア分のスペースも確保して、罫線等の整合性をとる
              pw.SizedBox(width: wSubAction),
            ],
          ),
        );
      }

      final name = nameMap[log.playerNumber] ?? "";
      String resultText = "";
      PdfColor bgColor = PdfColors.white;
      if (log.result == ActionResult.success) {
        resultText = "(成功)";
        bgColor = successColor;
      } else if (log.result == ActionResult.failure) {
        resultText = "(失敗)";
        bgColor = failureColor;
      }

      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: pw.BoxDecoration(
          color: bgColor,
          border: const pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
        ),
        child: pw.Row(
          children: [
            pw.SizedBox(width: wTime, child: pw.Text(log.gameTime, style: textStyle.copyWith(color: PdfColors.grey700))),
            pw.SizedBox(width: wNumber, child: pw.Text("#${log.playerNumber}", style: boldStyle, textAlign: pw.TextAlign.right)),
            pw.SizedBox(width: wGap),
            pw.SizedBox(width: wName, child: pw.Text(name, style: textStyle, maxLines: 1, overflow: pw.TextOverflow.clip)),
            // ★変更: アクション名とサブアクションを分離して配置
            pw.Expanded(child: pw.Text("${log.action} $resultText", style: textStyle),),
            // ★変更: サブアクションを右側の固定幅エリアに表示
            pw.Container(width: wSubAction, child: log.subAction != null
                ? pw.Text(log.subAction!, style: textStyle.copyWith(color: PdfColors.grey700, fontSize: 8))
                  : null,
            ),
          ],
        ),
      );
    }

    // 結果フッターを作る関数
    pw.Widget buildResultFooter(MatchRecord record) {
      String resultText = "";
      PdfColor bgColor = PdfColors.white;
      if (record.result == MatchResult.win) {
        bgColor = PdfColors.red100;
        resultText = "勝ち";
      } else if (record.result == MatchResult.lose) {
        bgColor = PdfColors.blue100;
        resultText = "負け";
      } else {
        bgColor = PdfColors.grey200;
        resultText = "引き分け";
      }

      String scoreText = "${record.scoreOwn ?? 0} - ${record.scoreOpponent ?? 0}";
      if (record.isExtraTime) {
        resultText += " (Vポイント)";
        if (record.extraScoreOwn != null) {
          scoreText += " [${record.extraScoreOwn} - ${record.extraScoreOpponent}]";
        }
      }

      return pw.Container(
        color: bgColor,
        padding: const pw.EdgeInsets.all(6),
        alignment: pw.Alignment.centerRight,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(resultText, style: boldStyle.copyWith(fontSize: 11)),
            pw.SizedBox(width: 10),
            pw.Text(scoreText, style: boldStyle.copyWith(fontSize: 14)),
          ],
        ),
      );
    }

    // リクエストごとにMultiPageを追加
    for (final req in printRequests) {
      final MatchRecord record = req['record'];
      final Map<String, String> nameMap = req['nameMap'];

      // 試合日時フォーマット
      String dateStr = record.date;
      try {
        final d = DateTime.parse(record.date.replaceAll('/', '-'));
        dateStr = DateFormat('yyyy年M月d日').format(d);
      } catch (_) {}

      final title = "$dateStr vs ${record.opponent}  @${record.venueName ?? ''}";
      final note = record.note ?? "";

      // ログリストをWidget化
      final List<pw.Widget> logWidgets = [];
      for (final log in record.logs) {
        logWidgets.add(buildLogItem(log, nameMap));
      }
      if (record.result != MatchResult.none) {
        logWidgets.add(buildResultFooter(record));
      }

      // ■ 段組み計算ロジック ■
      // 1ページ目の有効高さ
      final h1 = contentHeight - headerAreaHeight;
      // 2ページ目以降の有効高さ (ヘッダー簡易版が入るならその分引くが、ここではフル)
      const h2 = 180.0 * PdfPageFormat.mm; // マージン考慮

      // 1列に入る行数(概算)
      final itemsPerColPage1 = (h1 / logRowHeight).floor();
      final itemsPerColPage2 = (h2 / logRowHeight).floor();

      // ページごとにデータを分割し、各ページ内でさらに列に分割するWidgetを生成する
      // pw.MultiPageは自動改ページするが、Wrap(direction: vertical)はページをまたげない。
      // そのため、手動でページ単位のWidget (Row containing Columns) を作って、
      // それをMultiPageに渡すのが最も確実。

      final List<pw.Widget> pageWidgets = [];
      int currentIndex = 0;
      int pageIndex = 0;

      while (currentIndex < logWidgets.length) {
        final bool isFirstPage = (pageIndex == 0);
        final int itemsPerCol = isFirstPage ? itemsPerColPage1 : itemsPerColPage2;
        final int itemsPerPage = itemsPerCol * colsPerPage;

        // このページに収まる最大数
        final int remaining = logWidgets.length - currentIndex;
        final int takeCount = remaining > itemsPerPage ? itemsPerPage : remaining;

        final List<pw.Widget> thisPageItems = logWidgets.sublist(currentIndex, currentIndex + takeCount);
        currentIndex += takeCount;
        pageIndex++;

        // このページのアイテムを列に分割
        final List<pw.Widget> columns = [];
        for (int i = 0; i < colsPerPage; i++) {
          final int colStart = i * itemsPerCol;
          if (colStart >= thisPageItems.length) break;

          int colEnd = colStart + itemsPerCol;
          if (colEnd > thisPageItems.length) colEnd = thisPageItems.length;

          final colItems = thisPageItems.sublist(colStart, colEnd);

          if (i > 0) {
            // 列間の区切り線 (矢印なし、縦線のみ)
            columns.add(
                pw.Container(
                  width: gapWidth,
                  height: isFirstPage ? h1 : h2,
                  child: pw.Center(
                    child: pw.VerticalDivider(color: PdfColors.grey400, width: 1),
                  ),
                )
            );
          }

          columns.add(
            pw.Container(
              width: colWidth,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: colItems,
              ),
            ),
          );
        }

        // 1ページ分の塊
        pageWidgets.add(
          pw.Container(
            height: isFirstPage ? h1 : h2,
            margin: const pw.EdgeInsets.only(bottom: 10), // ページ間マージン(論理的)
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: columns,
            ),
          ),
        );
      }

      // Documentに追加
      doc.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(margin),
          theme: pw.ThemeData.withFont(base: font, icons: await PdfGoogleFonts.materialIcons()),
          header: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: font)),
                if (note.isNotEmpty)
                  pw.Text(note, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, font: font)),
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 5),
              ],
            );
          },
          build: (context) {
            return pageWidgets;
          },
        ),
      );
    } // end for requests

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: baseFileName,
    );
  }
}