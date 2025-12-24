// lib/features/analysis/data/pdf_stats_helper.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../settings/domain/action_definition.dart';
import '../domain/player_stats.dart';

class PdfStatsHelper {
  static const double _kCellPadding = 4.0;
  static const double _kBorderWidth = 0.5;
  static const double _kHeaderHeight = 36.0;
  static const double _kSubHeaderHeight = 18.0;
  static const double _kFontSize = 9.0;
  static const double _kHeaderFontSize = 9.0;

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

    final headerWidget = pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        _buildFixedHeader('背番号', wNumber, font, isFirst: true),
        _buildFixedHeader('コートネーム', wName, font),
        _buildFixedHeader('試合数', wMatch, font),
        ...actionDefinitions.map((def) => _buildActionHeader(def, font)),
      ],
    );

    final List<pw.Widget> dataRows = stats.map((player) {
      return _buildPlayerStatsRow(player, actionDefinitions, wNumber, wName, wMatch, font);
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

  pw.Widget _buildFixedHeader(String text, double width, pw.Font font, {bool isFirst = false}) {
    const borderSide = pw.BorderSide(color: PdfColors.grey400, width: _kBorderWidth);
    return pw.Container(
      width: width,
      height: _kHeaderHeight,
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
        style: pw.TextStyle(font: font, color: PdfColors.black, fontSize: _kHeaderFontSize, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildActionHeader(ActionDefinition def, pw.Font font) {
    const double wActionSub = 13.0 * PdfPageFormat.mm;
    const borderSide = pw.BorderSide(color: PdfColors.grey400, width: _kBorderWidth);

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
          height: _kSubHeaderHeight,
          alignment: pw.Alignment.center,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: borderSide,
              right: borderSide,
              bottom: borderSide,
            ),
          ),
          child: pw.Text(
            def.name,
            style: pw.TextStyle(font: font, color: PdfColors.black, fontSize: _kHeaderFontSize, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Row(
          children: subLabels.map((label) {
            return pw.Container(
              width: wActionSub,
              height: _kSubHeaderHeight,
              alignment: pw.Alignment.center,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  right: borderSide,
                  bottom: borderSide,
                ),
              ),
              child: pw.Text(
                label,
                style: pw.TextStyle(font: font, color: PdfColors.black, fontSize: _kHeaderFontSize, fontWeight: pw.FontWeight.bold),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildPlayerStatsRow(
      PlayerStats player,
      List<ActionDefinition> actionDefinitions,
      double wNumber,
      double wName,
      double wMatch,
      pw.Font font,
      ) {
    const double wActionSub = 13.0 * PdfPageFormat.mm;
    final cells = <pw.Widget>[];
    final displayNumber = player.playerNumber.isEmpty ? '-' : player.playerNumber;

    cells.add(_buildDataCell(displayNumber, wNumber, font, isFirst: true));
    cells.add(_buildDataCell(player.playerName, wName, font, alignLeft: true));
    cells.add(_buildDataCell(player.matchesPlayed.toString(), wMatch, font));

    for (final def in actionDefinitions) {
      final stat = player.actions[def.name];
      if (def.hasSuccess && def.hasFailure) {
        cells.add(_buildDataCell(stat?.successCount.toString() ?? '-', wActionSub, font));
        cells.add(_buildDataCell(stat?.failureCount.toString() ?? '-', wActionSub, font));
        cells.add(_buildDataCell(stat != null && stat.totalCount > 0 ? "${stat.successRate.toStringAsFixed(0)}%" : '-', wActionSub, font));
      } else if (def.hasSuccess) {
        cells.add(_buildDataCell(stat?.successCount.toString() ?? '-', wActionSub, font));
      } else if (def.hasFailure) {
        cells.add(_buildDataCell(stat?.failureCount.toString() ?? '-', wActionSub, font));
      } else {
        cells.add(_buildDataCell(stat?.totalCount.toString() ?? '-', wActionSub, font));
      }
    }

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: cells,
    );
  }

  pw.Widget _buildDataCell(String text, double width, pw.Font font, {bool isFirst = false, bool alignLeft = false}) {
    const borderSide = pw.BorderSide(color: PdfColors.grey400, width: _kBorderWidth);
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
        style: pw.TextStyle(font: font, fontSize: _kFontSize),
        overflow: pw.TextOverflow.clip,
      ),
    );
  }
}