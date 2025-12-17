// lib/features/analysis/presentation/widgets/analysis_log_print_view.dart
import 'package:flutter/material.dart';
import '../../domain/player_stats.dart';
import '../../../game_record/domain/models.dart';

class AnalysisLogPrintView extends StatelessWidget {
  final MatchRecord matchRecord;
  final List<PlayerStats> playerStats;
  // ★追加: ヘッダー表示用のパラメータ
  final String teamName;
  final String periodLabel;

  static const double timeFontSize = 11;
  static const double playerNumberFontSize = 12;
  static const double actionFontSize = 13;
  static const double nameFontSize = 11;

  static const double timeColWidth = 45;
  static const double numberColWidth = 36;
  static const double nameColWidth = 60;
  static const double numberNameGap = 4;
  static const double columnWidth = 400;

  static const double rowHeight = 30.0;
  static const double columnHeaderFooterHeight = 40.0;

  // A4横向き印刷を想定した全体の描画エリアの高さ
  static const double printTargetHeight = 700.0;

  // ★追加: ヘッダー部分（チーム名など）の推定高さ
  static const double headerHeightEstimate = 80.0;

  const AnalysisLogPrintView({
    super.key,
    required this.matchRecord,
    required this.playerStats,
    required this.teamName,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, String> nameMap = {};
    for (var p in playerStats) {
      nameMap[p.playerNumber] = p.playerName;
    }

    final logs = matchRecord.logs;
    final List<dynamic> allItems = [...logs];
    if (matchRecord.result != MatchResult.none) {
      allItems.add('RESULT_FOOTER');
    }

    // ★修正: ログ表示に使える高さを計算（全体 - ヘッダー - 列の上下余白）
    final double contentHeight = printTargetHeight - headerHeightEstimate - columnHeaderFooterHeight;

    int itemsPerColumn = (contentHeight / rowHeight).floor();
    if (itemsPerColumn < 1) itemsPerColumn = 1;

    final List<List<dynamic>> chunks = [];
    for (var i = 0; i < allItems.length; i += itemsPerColumn) {
      chunks.add(allItems.sublist(
          i, i + itemsPerColumn > allItems.length ? allItems.length : i + itemsPerColumn));
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ★追加: リクエストされたヘッダー部分
          Text(teamName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(periodLabel, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 10),
          // ログにはテーブルヘッダー(AnalysisTableHelper)は不要なため、区切り線のみ配置
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 10),

          // ログのカラム部分
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < chunks.length; i++) ...[
                SizedBox(
                  width: columnWidth,
                  child: _buildColumn(
                    matchRecord,
                    nameMap,
                    chunks[i],
                    isFirstColumn: i == 0,
                    isLastColumn: i == chunks.length - 1,
                  ),
                ),
                if (i < chunks.length - 1)
                  const VerticalDivider(width: 32, thickness: 1),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ... _buildColumn, _buildLogItem, _buildResultFooter, _LogEntryRow は変更なし ...
  Widget _buildColumn(
      MatchRecord matchRecord,
      Map<String, String> nameMap,
      List<dynamic> items, {
        required bool isFirstColumn,
        required bool isLastColumn,
      }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isFirstColumn) ...[
          Container(
            height: 20,
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
          ),
          const Divider(height: 1),
        ],
        ...items.map((item) {
          if (item == 'RESULT_FOOTER') {
            return _buildResultFooter(matchRecord);
          } else if (item is LogEntry) {
            return Column(
              children: [
                _buildLogItem(matchRecord, nameMap, item),
                const Divider(height: 1),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
        if (!isLastColumn) ...[
          const SizedBox(height: 4),
          Container(
            height: 20,
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _buildLogItem(
      MatchRecord matchRecord,
      Map<String, String> nameMap,
      LogEntry log,
      ) {
    if (log.type == LogType.system) {
      return _LogEntryRow(
        backgroundColor: Colors.grey[50],
        timeText: log.gameTime,
        numberText: null,
        nameText: null,
        actionContent: Text(
          log.action,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: timeFontSize,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final name = nameMap[log.playerNumber] ?? "";
    String resultText = "";
    Color? bgColor = Colors.white;
    if (log.result == ActionResult.success) {
      resultText = "(成功)";
      bgColor = Colors.red.shade50;
    } else if (log.result == ActionResult.failure) {
      resultText = "(失敗)";
      bgColor = Colors.blue.shade50;
    }

    return _LogEntryRow(
      backgroundColor: bgColor,
      timeText: log.gameTime,
      numberText: "#${log.playerNumber}",
      nameText: name,
      actionContent: Row(
        children: [
          Expanded(
            child: Text(
              "${log.action} $resultText",
              style: const TextStyle(fontSize: actionFontSize),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (log.subAction != null)
            Text(
              log.subAction!,
              style: const TextStyle(color: Colors.grey, fontSize: timeFontSize),
            ),
        ],
      ),
    );
  }

  Widget _buildResultFooter(MatchRecord record) {
    Color bgColor = Colors.white;
    String resultText = "";
    if (record.result == MatchResult.win) {
      bgColor = Colors.red.shade100;
      resultText = "勝ち";
    } else if (record.result == MatchResult.lose) {
      bgColor = Colors.blue.shade100;
      resultText = "負け";
    } else {
      bgColor = Colors.grey.shade200;
      resultText = "引き分け";
    }
    String scoreText = "";
    if (record.scoreOwn != null && record.scoreOpponent != null) {
      scoreText = "${record.scoreOwn} - ${record.scoreOpponent}";
    }
    if (record.isExtraTime) {
      resultText += " (Vポイント)";
      if (record.extraScoreOwn != null) {
        scoreText += " [${record.extraScoreOwn} - ${record.extraScoreOpponent}]";
      }
    }
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(resultText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 8),
          Text(scoreText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}

class _LogEntryRow extends StatelessWidget {
  final Color? backgroundColor;
  final String timeText;
  final String? numberText;
  final String? nameText;
  final Widget actionContent;

  const _LogEntryRow({
    this.backgroundColor,
    required this.timeText,
    this.numberText,
    this.nameText,
    required this.actionContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: AnalysisLogPrintView.timeColWidth,
            child: Text(
              timeText,
              style: const TextStyle(color: Colors.grey, fontSize: AnalysisLogPrintView.timeFontSize),
            ),
          ),
          SizedBox(
            width: AnalysisLogPrintView.numberColWidth,
            child: numberText != null
                ? Text(
              numberText!,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AnalysisLogPrintView.playerNumberFontSize,
              ),
            )
                : null,
          ),
          const SizedBox(width: AnalysisLogPrintView.numberNameGap),
          SizedBox(
            width: AnalysisLogPrintView.nameColWidth,
            child: nameText != null
                ? Text(
              nameText!,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AnalysisLogPrintView.nameFontSize,
                color: Colors.black54,
              ),
            )
                : null,
          ),
          Expanded(
            child: actionContent,
          ),
        ],
      ),
    );
  }
}