// lib/features/analysis/data/pdf_log_helper.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../game_record/domain/models.dart';

class PdfLogHelper {
  static const int _kColsPerPage = 2;
  static const double _kGapWidth = 4.0 * PdfPageFormat.mm;
  static const double _kLogHeaderAreaHeight = 25.0 * PdfPageFormat.mm;
  static const double _kLogRowHeight = 18.0;

  Future<void> printMatchLogsNative({
    required String baseFileName,
    required List<Map<String, dynamic>> printRequests,
  }) async {
    final font = await PdfGoogleFonts.notoSansJPRegular();
    final materialIcons = await PdfGoogleFonts.materialIcons();
    final doc = pw.Document();

    final pageFormat = PdfPageFormat.a4.landscape;
    const double marginValue = 15.0 * PdfPageFormat.mm;
    final double contentHeight = pageFormat.height - (marginValue * 2);
    final double contentWidth = pageFormat.width - (marginValue * 2);

    for (final req in printRequests) {
      final MatchRecord record = req['record'];
      final Map<String, String> nameMap = req['nameMap'];

      // タイトル・メモ生成
      final headerInfo = _buildMatchHeaderInfo(record);

      // ログリストをWidget化
      final List<pw.Widget> logWidgets = [];
      for (final log in record.logs) {
        logWidgets.add(_buildLogItem(log, nameMap, font));
      }
      if (record.result != MatchResult.none) {
        logWidgets.add(_buildResultFooter(record, font));
      }

      // 段組み計算とページ生成
      final pageWidgets = _layoutLogsIntoColumns(
        logWidgets: logWidgets,
        contentHeight: contentHeight,
        contentWidth: contentWidth,
        headerAreaHeight: _kLogHeaderAreaHeight,
      );

      doc.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(marginValue),
          theme: pw.ThemeData.withFont(base: font, icons: materialIcons),
          header: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(headerInfo.title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: font)),
                if (headerInfo.note.isNotEmpty)
                  pw.Text(headerInfo.note, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, font: font)),
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
    }

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: baseFileName,
    );
  }

  _MatchHeaderInfo _buildMatchHeaderInfo(MatchRecord record) {
    String dateStr = record.date;
    try {
      final d = DateTime.parse(record.date.replaceAll('/', '-'));
      dateStr = DateFormat('yyyy年M月d日').format(d);
    } catch (_) {}

    final title = "$dateStr vs ${record.opponent}  @${record.venueName ?? ''}";
    final note = record.note ?? "";
    return _MatchHeaderInfo(title, note);
  }

  pw.Widget _buildLogItem(LogEntry log, Map<String, String> nameMap, pw.Font font) {
    const double wTime = 35;
    const double wNumber = 25;
    const double wGap = 4;
    const double wName = 50;
    const double wSystemIndent = wNumber + wGap + wName;
    const double wSubAction = 120;

    final textStyle = pw.TextStyle(font: font, fontSize: 9);
    final boldStyle = pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold);

    if (log.type == LogType.system) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey200,
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
        ),
        child: pw.Row(
          children: [
            pw.SizedBox(width: wTime, child: pw.Text(log.gameTime, style: textStyle.copyWith(color: PdfColors.grey700))),
            pw.SizedBox(width: wSystemIndent),
            pw.Expanded(child: pw.Text(log.action, style: boldStyle.copyWith(color: PdfColors.grey700))),
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
      bgColor = PdfColors.red50;
    } else if (log.result == ActionResult.failure) {
      resultText = "(失敗)";
      bgColor = PdfColors.blue50;
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
          pw.Expanded(child: pw.Text("${log.action} $resultText", style: textStyle),),
          pw.Container(
            width: wSubAction,
            child: log.subAction != null
                ? pw.Text(log.subAction!, style: textStyle.copyWith(color: PdfColors.grey700, fontSize: 8))
                : null,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildResultFooter(MatchRecord record, pw.Font font) {
    final boldStyle = pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold);

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

  List<pw.Widget> _layoutLogsIntoColumns({
    required List<pw.Widget> logWidgets,
    required double contentHeight,
    required double contentWidth,
    required double headerAreaHeight,
  }) {
    final double colWidth = (contentWidth - (_kGapWidth * (_kColsPerPage - 1))) / _kColsPerPage;

    final h1 = contentHeight - headerAreaHeight;
    const h2 = 180.0 * PdfPageFormat.mm;

    final itemsPerColPage1 = (h1 / _kLogRowHeight).floor();
    final itemsPerColPage2 = (h2 / _kLogRowHeight).floor();

    final List<pw.Widget> pageWidgets = [];
    int currentIndex = 0;
    int pageIndex = 0;

    while (currentIndex < logWidgets.length) {
      final bool isFirstPage = (pageIndex == 0);
      final int itemsPerCol = isFirstPage ? itemsPerColPage1 : itemsPerColPage2;
      final int itemsPerPage = itemsPerCol * _kColsPerPage;

      final int remaining = logWidgets.length - currentIndex;
      final int takeCount = remaining > itemsPerPage ? itemsPerPage : remaining;

      final List<pw.Widget> thisPageItems = logWidgets.sublist(currentIndex, currentIndex + takeCount);
      currentIndex += takeCount;
      pageIndex++;

      final List<pw.Widget> columns = [];
      for (int i = 0; i < _kColsPerPage; i++) {
        final int colStart = i * itemsPerCol;
        if (colStart >= thisPageItems.length) break;

        int colEnd = colStart + itemsPerCol;
        if (colEnd > thisPageItems.length) colEnd = thisPageItems.length;

        final colItems = thisPageItems.sublist(colStart, colEnd);

        if (i > 0) {
          columns.add(
            pw.Container(
              width: _kGapWidth,
              height: isFirstPage ? h1 : h2,
              child: pw.Center(
                child: pw.VerticalDivider(color: PdfColors.grey400, width: 1),
              ),
            ),
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

      pageWidgets.add(
        pw.Container(
          height: isFirstPage ? h1 : h2,
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: columns,
          ),
        ),
      );
    }
    return pageWidgets;
  }
}

class _MatchHeaderInfo {
  final String title;
  final String note;
  _MatchHeaderInfo(this.title, this.note);
}