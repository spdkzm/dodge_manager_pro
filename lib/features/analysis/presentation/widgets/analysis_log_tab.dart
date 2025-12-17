// lib/features/analysis/presentation/widgets/analysis_log_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../application/analysis_controller.dart';
import '../../domain/player_stats.dart';
import '../../../game_record/domain/models.dart';
import '../../../settings/domain/action_definition.dart';

/// レイアウト設定を一元管理するクラス
class _LayoutConfig {
  // フォントサイズ
  static const double timeFontSize = 11;
  static const double playerNumberFontSize = 12;
  static const double actionFontSize = 13;
  static const double nameFontSize = 11;

  // カラム幅
  static const double timeColWidth = 45;
  static const double numberColWidth = 36;
  static const double nameColWidth = 60;
  static const double numberNameGap = 4;
  static const double columnWidth = 400;

  // ★追加: ログ1行あたりの推定高さ (パディング上下 + フォントサイズ + Dividerなど)
  // 実際の実装に合わせて微調整してください (例: 32.0 〜 40.0 程度)
  static const double rowHeight = 30.0;

  // ★追加: カラム上下の矢印やパディングの合計高さ
  // (上矢印エリア約25px + 下矢印エリア約25px + 上下パディングなど)
  static const double columnHeaderFooterHeight = 60.0;
}

/// ログタブのウィジェット
class AnalysisLogTab extends ConsumerWidget {
  final AsyncValue<List<PlayerStats>> asyncStats;
  final VoidCallback onUpdate;

  const AnalysisLogTab({
    super.key,
    required this.asyncStats,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchRecord = ref.watch(selectedMatchRecordProvider);
    if (matchRecord == null) return const Center(child: CircularProgressIndicator());

    // データ準備
    final logs = matchRecord.logs;
    final Map<String, String> nameMap = {};
    asyncStats.whenData((stats) {
      for (var p in stats) {
        nameMap[p.playerNumber] = p.playerName;
      }
    });

    final List<dynamic> allItems = [...logs];
    if (matchRecord.result != MatchResult.none) {
      allItems.add('RESULT_FOOTER');
    }
// ★変更: LayoutBuilderで高さを取得して計算する
    return LayoutBuilder(
      builder: (context, constraints) {
        // 1. 利用可能な高さを取得 (親のpadding等を考慮する場合はここで引く)
        // ListViewのpaddingが上下16ずつあるので、32を引いています
        final double availableHeight = constraints.maxHeight - 32.0;

        // 2. ログ表示に使える高さを計算 (矢印などの固定スペースを引く)
        final double contentHeight = availableHeight - _LayoutConfig.columnHeaderFooterHeight;

        // 3. 行数を計算 (高さ ÷ 1行の高さ)
        int itemsPerColumn = (contentHeight / _LayoutConfig.rowHeight).floor();

        // 最低でも1行は表示するようにガード
        if (itemsPerColumn < 1) itemsPerColumn = 1;

        // 4. チャンク分割
        final List<List<dynamic>> chunks = [];
        for (var i = 0; i < allItems.length; i += itemsPerColumn) {
          chunks.add(allItems.sublist(
              i, i + itemsPerColumn > allItems.length ? allItems.length : i + itemsPerColumn));
        }

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          itemCount: chunks.length,
          itemBuilder: (context, index) {
            final items = chunks[index];
            final isFirst = index == 0;
            final isLast = index == chunks.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _LayoutConfig.columnWidth,
                  child: _buildColumn(
                    context,
                    ref,
                    matchRecord,
                    nameMap,
                    items,
                    isFirstColumn: isFirst,
                    isLastColumn: isLast,
                  ),
                ),
                if (!isLast)
                  const VerticalDivider(width: 32, thickness: 1),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColumn(
      BuildContext context,
      WidgetRef ref,
      MatchRecord matchRecord,
      Map<String, String> nameMap,
      List<dynamic> items, {
        required bool isFirstColumn,
        required bool isLastColumn,
      }) {
    return Column(
      mainAxisSize: MainAxisSize.min, // コンテンツの高さに合わせる
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 前の列からの続きを示す矢印（最初の列以外）
        if (!isFirstColumn) ...[
          Container(
            height: 20,
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
          ),
          const Divider(height: 1),
        ],

        // アイテムリスト
        ...items.map((item) {
          if (item == 'RESULT_FOOTER') {
            return _buildResultFooter(context, ref, matchRecord);
          } else if (item is LogEntry) {
            return Column(
              children: [
                _buildLogItem(context, ref, matchRecord, nameMap, item),
                const Divider(height: 1),
              ],
            );
          }
          return const SizedBox.shrink();
        }),

        // 次の列へ続く矢印（最後の列以外）
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
      BuildContext context,
      WidgetRef ref,
      MatchRecord matchRecord,
      Map<String, String> nameMap,
      LogEntry log,
      ) {
    if (log.type == LogType.system) {
      return _LogEntryRow(
        onTap: () => showEditLogDialog(context, ref, matchRecord.id, log: log, onUpdate: onUpdate),
        backgroundColor: Colors.grey[50],
        timeText: log.gameTime,
        numberText: null,
        nameText: null,
        actionContent: Text(
          log.action,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: _LayoutConfig.timeFontSize,
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
      onTap: () => showEditLogDialog(context, ref, matchRecord.id, log: log, onUpdate: onUpdate),
      backgroundColor: bgColor,
      timeText: log.gameTime,
      numberText: "#${log.playerNumber}",
      nameText: name,
      actionContent: Row(
        children: [
          Expanded(
            child: Text(
              "${log.action} $resultText",
              style: const TextStyle(fontSize: _LayoutConfig.actionFontSize),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (log.subAction != null)
            Text(
              log.subAction!,
              style: const TextStyle(color: Colors.grey, fontSize: _LayoutConfig.timeFontSize),
            ),
        ],
      ),
    );
  }

  Widget _buildResultFooter(BuildContext context, WidgetRef ref, MatchRecord record) {
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
    return InkWell(
      onTap: () => showResultEditDialog(context, ref, record, onUpdate: onUpdate),
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(resultText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 8),
            Text(scoreText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 14, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

/// ログ1行分のレイアウト定義（Row構造の一元化）
class _LogEntryRow extends StatelessWidget {
  final VoidCallback onTap;
  final Color? backgroundColor;
  final String timeText;
  final String? numberText;
  final String? nameText;
  final Widget actionContent;

  const _LogEntryRow({
    required this.onTap,
    this.backgroundColor,
    required this.timeText,
    this.numberText,
    this.nameText,
    required this.actionContent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: _LayoutConfig.timeColWidth,
              child: Text(
                timeText,
                style: const TextStyle(color: Colors.grey, fontSize: _LayoutConfig.timeFontSize),
              ),
            ),
            SizedBox(
              width: _LayoutConfig.numberColWidth,
              child: numberText != null
                  ? Text(
                numberText!,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: _LayoutConfig.playerNumberFontSize,
                ),
              )
                  : null,
            ),
            const SizedBox(width: _LayoutConfig.numberNameGap),
            SizedBox(
              width: _LayoutConfig.nameColWidth,
              child: nameText != null
                  ? Text(
                nameText!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: _LayoutConfig.nameFontSize,
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
      ),
    );
  }
}

// --- 以下、showEditLogDialog と showResultEditDialog は変更がないためそのまま利用してください ---

// --- 公開用ダイアログ関数 (onUpdate引数を追加) ---

void showEditLogDialog(BuildContext context, WidgetRef ref, String matchId,
    {LogEntry? log, required VoidCallback onUpdate}) {
  final controller = ref.read(analysisControllerProvider.notifier);
  final definitions = controller.actionDefinitions;
  final isNew = log == null;
  final stats = ref.read(analysisControllerProvider).valueOrNull ?? [];
  final isSystemLog = !isNew && log.type == LogType.system;
  final players =
  stats.map((p) => {'number': p.playerNumber, 'name': p.playerName}).toList();
  final actionNames = definitions.map((d) => d.name).toList();
  String timeVal = log?.gameTime ?? "00:00";
  String? playerNumVal = log?.playerNumber;
  String? actionNameVal = log?.action;
  SubActionDefinition? subActionVal;
  ActionResult resultVal = log?.result ?? ActionResult.none;
  final timeCtrl = TextEditingController(text: timeVal);
  final systemActionCtrl = TextEditingController(text: isSystemLog ? log.action : "");
  if (!isSystemLog && actionNameVal != null && !actionNames.contains(actionNameVal)) {
    actionNames.add(actionNameVal);
  }
  if (isNew && players.isNotEmpty) playerNumVal = players.first['number'];
  if (isNew && actionNames.isNotEmpty) actionNameVal = actionNames.first;
  if (!isSystemLog && actionNameVal != null) {
    final def = definitions.firstWhere((d) => d.name == actionNameVal,
        orElse: () => ActionDefinition(name: '', subActions: []));
    if (log?.subActionId != null) {
      subActionVal = def.subActions.where((s) => s.id == log!.subActionId).firstOrNull;
    }
  }

  showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateDialog) {
        if (isSystemLog) {
          return AlertDialog(
              title: const Text("システムログ編集"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: timeCtrl,
                    decoration: const InputDecoration(labelText: "時間 (分:秒)")),
                const SizedBox(height: 16),
                TextField(
                    controller: systemActionCtrl,
                    decoration:
                    const InputDecoration(labelText: "内容 (試合開始, タイムなど)"))
              ]),
              actions: [
                TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                              title: const Text("削除確認"),
                              content: const Text("このログを削除しますか？"),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text("キャンセル")),
                                ElevatedButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: const Text("削除"))
                              ]));
                      if (confirm == true && context.mounted) {
                        await controller.deleteLog(log.id);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          onUpdate();
                        }
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("削除")),
                TextButton(
                    onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
                ElevatedButton(
                    onPressed: () async {
                      if (systemActionCtrl.text.isEmpty) return;
                      final newLog = log.copyWith(
                          gameTime: timeCtrl.text, action: systemActionCtrl.text);
                      await controller.updateLog(matchId, newLog);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        onUpdate();
                      }
                    },
                    child: const Text("保存"))
              ]);
        }

        final selectedDef = definitions.firstWhere((d) => d.name == actionNameVal,
            orElse: () => ActionDefinition(name: '', subActions: []));
        final subActions = selectedDef.getSubActions(
            resultVal == ActionResult.success
                ? 'success'
                : (resultVal == ActionResult.failure ? 'failure' : 'default'));

        return AlertDialog(
            title: Text(isNew ? "ログ追加" : "ログ編集"),
            content: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                          controller: timeCtrl,
                          decoration: const InputDecoration(
                              labelText: "時間 (分:秒)", hintText: "05:30"),
                          keyboardType: TextInputType.datetime),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                          value: playerNumVal,
                          decoration: const InputDecoration(labelText: "選手"),
                          items: players
                              .map((p) => DropdownMenuItem(
                              value: p['number'],
                              child: Text("#${p['number']} ${p['name']}")))
                              .toList(),
                          onChanged: (v) => setStateDialog(() => playerNumVal = v)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                          value: actionNameVal,
                          decoration: const InputDecoration(labelText: "アクション"),
                          items: actionNames
                              .map((a) =>
                              DropdownMenuItem(value: a, child: Text(a)))
                              .toList(),
                          onChanged: (v) => setStateDialog(() {
                            actionNameVal = v;
                            subActionVal = null;
                          })),
                      const SizedBox(height: 16),
                      const Text("結果",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Row(children: [
                        Radio<ActionResult>(
                            value: ActionResult.none,
                            groupValue: resultVal,
                            onChanged: (v) => setStateDialog(() {
                              resultVal = v!;
                              subActionVal = null;
                            })),
                        const Text("なし"),
                        Radio<ActionResult>(
                            value: ActionResult.success,
                            groupValue: resultVal,
                            onChanged: (v) => setStateDialog(() {
                              resultVal = v!;
                              subActionVal = null;
                            })),
                        const Text("成功"),
                        Radio<ActionResult>(
                            value: ActionResult.failure,
                            groupValue: resultVal,
                            onChanged: (v) => setStateDialog(() {
                              resultVal = v!;
                              subActionVal = null;
                            })),
                        const Text("失敗")
                      ]),
                      if (subActions.isNotEmpty)
                        DropdownButtonFormField<SubActionDefinition>(
                            value: subActions.any((s) => s.id == subActionVal?.id)
                                ? subActionVal
                                : null,
                            decoration: const InputDecoration(labelText: "詳細"),
                            items: subActions
                                .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s.name)))
                                .toList(),
                            onChanged: (v) => setStateDialog(() => subActionVal = v))
                    ])),
            actions: [
              if (!isNew)
                TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                              title: const Text("削除確認"),
                              content: const Text("このログを削除しますか？"),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text("キャンセル")),
                                ElevatedButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: const Text("削除"))
                              ]));
                      if (confirm == true && context.mounted) {
                        await controller.deleteLog(log.id);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          onUpdate();
                        }
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("削除")),
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
              ElevatedButton(
                  onPressed: () async {
                    if (playerNumVal == null || actionNameVal == null) return;
                    final newLog = LogEntry(
                        id: isNew ? const Uuid().v4() : log.id,
                        matchDate: "",
                        opponent: "",
                        gameTime: timeCtrl.text,
                        playerNumber: playerNumVal!,
                        action: actionNameVal!,
                        subAction: subActionVal?.name,
                        subActionId: subActionVal?.id,
                        result: resultVal,
                        type: LogType.action);
                    if (isNew) {
                      await controller.addLog(matchId, newLog);
                    } else {
                      await controller.updateLog(matchId, newLog);
                    }
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      onUpdate();
                    }
                  },
                  child: const Text("保存"))
            ]);
      }));
}

void showResultEditDialog(BuildContext context, WidgetRef ref, MatchRecord record,
    {required VoidCallback onUpdate}) {
  MatchResult tempResult = record.result;
  MatchResult tempExtraResult =
  record.isExtraTime ? record.result : MatchResult.none;
  if (record.isExtraTime) tempResult = MatchResult.draw;
  final scoreOwnCtrl =
  TextEditingController(text: record.scoreOwn?.toString() ?? "");
  final scoreOppCtrl =
  TextEditingController(text: record.scoreOpponent?.toString() ?? "");
  final extraScoreOwnCtrl =
  TextEditingController(text: record.extraScoreOwn?.toString() ?? "");
  final extraScoreOppCtrl =
  TextEditingController(text: record.extraScoreOpponent?.toString() ?? "");

  showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          Widget buildScoreInput(String label, TextEditingController ctrl1,
              TextEditingController ctrl2) {
            return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                  width: 50,
                  child: TextField(
                      controller: ctrl1,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.all(8),
                          border: OutlineInputBorder()))),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text("-", style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 50,
                  child: TextField(
                      controller: ctrl2,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.all(8),
                          border: OutlineInputBorder())))
            ]);
          }

          Widget buildResultToggle(
              MatchResult current, Function(MatchResult) onSelect) {
            return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ChoiceChip(
                  label: const Text("勝"),
                  selected: current == MatchResult.win,
                  onSelected: (v) => onSelect(MatchResult.win),
                  selectedColor: Colors.red.shade100),
              const SizedBox(width: 8),
              ChoiceChip(
                  label: const Text("引分"),
                  selected: current == MatchResult.draw,
                  onSelected: (v) => onSelect(MatchResult.draw),
                  selectedColor: Colors.grey.shade300),
              const SizedBox(width: 8),
              ChoiceChip(
                  label: const Text("負"),
                  selected: current == MatchResult.lose,
                  onSelected: (v) => onSelect(MatchResult.lose),
                  selectedColor: Colors.blue.shade100)
            ]);
          }

          return AlertDialog(
              title: const Text("試合結果の編集"),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text("本戦結果", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    buildResultToggle(
                        tempResult, (r) => setStateDialog(() => tempResult = r)),
                    const SizedBox(height: 8),
                    buildScoreInput("スコア", scoreOwnCtrl, scoreOppCtrl),
                    if (tempResult == MatchResult.draw) ...[
                      const Divider(height: 24),
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8)),
                          child: Column(children: [
                            const Text("▼ 延長・決着戦",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("なし", style: TextStyle(fontSize: 12)),
                                  Radio<MatchResult>(
                                      value: MatchResult.none,
                                      groupValue: tempExtraResult,
                                      onChanged: (v) => setStateDialog(
                                              () => tempExtraResult = v!)),
                                  const Text("勝", style: TextStyle(fontSize: 12)),
                                  Radio<MatchResult>(
                                      value: MatchResult.win,
                                      groupValue: tempExtraResult,
                                      onChanged: (v) => setStateDialog(
                                              () => tempExtraResult = v!)),
                                  const Text("負", style: TextStyle(fontSize: 12)),
                                  Radio<MatchResult>(
                                      value: MatchResult.lose,
                                      groupValue: tempExtraResult,
                                      onChanged: (v) => setStateDialog(
                                              () => tempExtraResult = v!))
                                ]),
                            if (tempExtraResult != MatchResult.none)
                              buildScoreInput(
                                  "延長スコア", extraScoreOwnCtrl, extraScoreOppCtrl)
                          ]))
                    ]
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("キャンセル")),
                ElevatedButton(
                    onPressed: () async {
                      MatchResult finalResult =
                      tempExtraResult != MatchResult.none
                          ? tempExtraResult
                          : tempResult;
                      bool isExtra = tempExtraResult != MatchResult.none;
                      await ref
                          .read(analysisControllerProvider.notifier)
                          .updateMatchResult(
                          record.id,
                          finalResult,
                          int.tryParse(scoreOwnCtrl.text),
                          int.tryParse(scoreOppCtrl.text),
                          isExtra,
                          int.tryParse(extraScoreOwnCtrl.text),
                          int.tryParse(extraScoreOppCtrl.text));
                      if (context.mounted) {
                        Navigator.pop(context);
                        onUpdate();
                      }
                    },
                    child: const Text("保存"))
              ]);
        });
      });
}

