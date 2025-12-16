// lib/features/analysis/presentation/widgets/analysis_log_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../application/analysis_controller.dart';
import '../../domain/player_stats.dart';
import '../../../game_record/domain/models.dart';
import '../../../settings/domain/action_definition.dart';

/// ログタブのウィジェット
class AnalysisLogTab extends ConsumerWidget {
  final AsyncValue<List<PlayerStats>> asyncStats;
  final VoidCallback onUpdate; // ★追加

  const AnalysisLogTab({
    super.key,
    required this.asyncStats,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchRecord = ref.watch(selectedMatchRecordProvider);
    if (matchRecord == null) return const Center(child: CircularProgressIndicator());

    final logs = matchRecord.logs;
    final Map<String, String> nameMap = {};
    asyncStats.whenData((stats) {
      for (var p in stats) {
        nameMap[p.playerNumber] = p.playerName;
      }
    });

    return ListView.separated(
      itemCount: logs.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == logs.length) {
          return _buildResultFooter(context, ref, matchRecord);
        }
        final log = logs[index];
        final name = nameMap[log.playerNumber] ?? "";

        if (log.type == LogType.system) {
          return InkWell(
            onTap: () => showEditLogDialog(context, ref, matchRecord.id, log: log, onUpdate: onUpdate),
            child: Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(children: [
                SizedBox(width: 45, child: Text(log.gameTime, style: const TextStyle(color: Colors.grey, fontSize: 11))),
                const SizedBox(width: 90),
                Flexible(child: Text(log.action, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))
              ]),
            ),
          );
        }

        String resultText = "";
        Color? bgColor = Colors.white;
        if (log.result == ActionResult.success) {
          resultText = "(成功)";
          bgColor = Colors.red.shade50;
        } else if (log.result == ActionResult.failure) {
          resultText = "(失敗)";
          bgColor = Colors.blue.shade50;
        }

        return InkWell(
          onTap: () => showEditLogDialog(context, ref, matchRecord.id, log: log, onUpdate: onUpdate),
          child: Container(
            color: bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(children: [
              SizedBox(width: 45, child: Text(log.gameTime, style: const TextStyle(color: Colors.grey, fontSize: 11))),
              SizedBox(width: 90, child: RichText(overflow: TextOverflow.ellipsis, text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 12), children: [TextSpan(text: "#${log.playerNumber} ", style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: name, style: const TextStyle(fontSize: 11, color: Colors.black54))]))),
              Flexible(child: Text("${log.action} $resultText", style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
              if (log.subAction != null) Text(log.subAction!, style: const TextStyle(color: Colors.grey, fontSize: 11))
            ]),
          ),
        );
      },
    );
  }

  Widget _buildResultFooter(BuildContext context, WidgetRef ref, MatchRecord record) {
    if (record.result == MatchResult.none) return const SizedBox();
    Color bgColor = Colors.white;
    String resultText = "";
    if (record.result == MatchResult.win) {
      bgColor = Colors.red.shade100;
      resultText = "WIN";
    } else if (record.result == MatchResult.lose) {
      bgColor = Colors.blue.shade100;
      resultText = "LOSE";
    } else {
      bgColor = Colors.grey.shade200;
      resultText = "DRAW";
    }
    String scoreText = "";
    if (record.scoreOwn != null && record.scoreOpponent != null) {
      scoreText = "${record.scoreOwn} - ${record.scoreOpponent}";
    }
    if (record.isExtraTime) {
      resultText += " (延長戦)";
      if (record.extraScoreOwn != null) {
        scoreText += " [EX: ${record.extraScoreOwn} - ${record.extraScoreOpponent}]";
      }
    }
    return InkWell(
      onTap: () => showResultEditDialog(context, ref, record, onUpdate: onUpdate),
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(resultText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 16),
            Text(scoreText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

// --- 公開用ダイアログ関数 (onUpdate引数を追加) ---

void showEditLogDialog(BuildContext context, WidgetRef ref, String matchId, {LogEntry? log, required VoidCallback onUpdate}) {
  final controller = ref.read(analysisControllerProvider.notifier);
  final definitions = controller.actionDefinitions;
  final isNew = log == null;
  final stats = ref.read(analysisControllerProvider).valueOrNull ?? [];
  final isSystemLog = !isNew && log.type == LogType.system;
  final players = stats.map((p) => {'number': p.playerNumber, 'name': p.playerName}).toList();
  final actionNames = definitions.map((d) => d.name).toList();
  String timeVal = log?.gameTime ?? "00:00";
  String? playerNumVal = log?.playerNumber;
  String? actionNameVal = log?.action;
  SubActionDefinition? subActionVal;
  ActionResult resultVal = log?.result ?? ActionResult.none;
  final timeCtrl = TextEditingController(text: timeVal);
  final systemActionCtrl = TextEditingController(text: isSystemLog ? log.action : "");
  if (!isSystemLog && actionNameVal != null && !actionNames.contains(actionNameVal)) actionNames.add(actionNameVal);
  if (isNew && players.isNotEmpty) playerNumVal = players.first['number'];
  if (isNew && actionNames.isNotEmpty) actionNameVal = actionNames.first;
  if (!isSystemLog && actionNameVal != null) {
    final def = definitions.firstWhere((d) => d.name == actionNameVal, orElse: () => ActionDefinition(name: '', subActions: []));
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
                TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: "時間 (分:秒)")),
                const SizedBox(height: 16),
                TextField(controller: systemActionCtrl, decoration: const InputDecoration(labelText: "内容 (試合開始, タイムなど)"))
              ]),
              actions: [
                TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text("削除確認"), content: const Text("このログを削除しますか？"), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("キャンセル")), ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("削除"))]));
                      if (confirm == true && context.mounted) {
                        await controller.deleteLog(log.id);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          onUpdate(); // ★変更: コールバック呼び出し
                        }
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("削除")),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
                ElevatedButton(
                    onPressed: () async {
                      if (systemActionCtrl.text.isEmpty) return;
                      final newLog = log.copyWith(gameTime: timeCtrl.text, action: systemActionCtrl.text);
                      await controller.updateLog(matchId, newLog);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        onUpdate(); // ★変更: コールバック呼び出し
                      }
                    },
                    child: const Text("保存"))
              ]);
        }

        final selectedDef = definitions.firstWhere((d) => d.name == actionNameVal, orElse: () => ActionDefinition(name: '', subActions: []));
        final subActions = selectedDef.getSubActions(resultVal == ActionResult.success ? 'success' : (resultVal == ActionResult.failure ? 'failure' : 'default'));

        return AlertDialog(
            title: Text(isNew ? "ログ追加" : "ログ編集"),
            content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: "時間 (分:秒)", hintText: "05:30"), keyboardType: TextInputType.datetime),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      value: playerNumVal,
                      decoration: const InputDecoration(labelText: "選手"),
                      items: players.map((p) => DropdownMenuItem(value: p['number'], child: Text("#${p['number']} ${p['name']}"))).toList(),
                      onChanged: (v) => setStateDialog(() => playerNumVal = v)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      value: actionNameVal,
                      decoration: const InputDecoration(labelText: "アクション"),
                      items: actionNames.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (v) => setStateDialog(() {
                        actionNameVal = v;
                        subActionVal = null;
                      })),
                  const SizedBox(height: 16),
                  const Text("結果", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(children: [
                    Radio<ActionResult>(value: ActionResult.none, groupValue: resultVal, onChanged: (v) => setStateDialog(() { resultVal = v!; subActionVal = null; })), const Text("なし"),
                    Radio<ActionResult>(value: ActionResult.success, groupValue: resultVal, onChanged: (v) => setStateDialog(() { resultVal = v!; subActionVal = null; })), const Text("成功"),
                    Radio<ActionResult>(value: ActionResult.failure, groupValue: resultVal, onChanged: (v) => setStateDialog(() { resultVal = v!; subActionVal = null; })), const Text("失敗")
                  ]),
                  if (subActions.isNotEmpty)
                    DropdownButtonFormField<SubActionDefinition>(
                        value: subActions.any((s) => s.id == subActionVal?.id) ? subActionVal : null,
                        decoration: const InputDecoration(labelText: "詳細"),
                        items: subActions.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                        onChanged: (v) => setStateDialog(() => subActionVal = v))
                ])),
            actions: [
              if (!isNew)
                TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text("削除確認"), content: const Text("このログを削除しますか？"), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("キャンセル")), ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("削除"))]));
                      if (confirm == true && context.mounted) {
                        await controller.deleteLog(log.id);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          onUpdate(); // ★変更: コールバック呼び出し
                        }
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("削除")),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
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
                      onUpdate(); // ★変更: コールバック呼び出し
                    }
                  },
                  child: const Text("保存"))
            ]);
      }));
}

void showResultEditDialog(BuildContext context, WidgetRef ref, MatchRecord record, {required VoidCallback onUpdate}) {
  MatchResult tempResult = record.result;
  MatchResult tempExtraResult = record.isExtraTime ? record.result : MatchResult.none;
  if (record.isExtraTime) tempResult = MatchResult.draw;
  final scoreOwnCtrl = TextEditingController(text: record.scoreOwn?.toString() ?? "");
  final scoreOppCtrl = TextEditingController(text: record.scoreOpponent?.toString() ?? "");
  final extraScoreOwnCtrl = TextEditingController(text: record.extraScoreOwn?.toString() ?? "");
  final extraScoreOppCtrl = TextEditingController(text: record.extraScoreOpponent?.toString() ?? "");

  showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          Widget buildScoreInput(String label, TextEditingController ctrl1, TextEditingController ctrl2) {
            return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 50, child: TextField(controller: ctrl1, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("-", style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 50, child: TextField(controller: ctrl2, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder())))
            ]);
          }

          Widget buildResultToggle(MatchResult current, Function(MatchResult) onSelect) {
            return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ChoiceChip(label: const Text("勝"), selected: current == MatchResult.win, onSelected: (v) => onSelect(MatchResult.win), selectedColor: Colors.red.shade100),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text("引分"), selected: current == MatchResult.draw, onSelected: (v) => onSelect(MatchResult.draw), selectedColor: Colors.grey.shade300),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text("負"), selected: current == MatchResult.lose, onSelected: (v) => onSelect(MatchResult.lose), selectedColor: Colors.blue.shade100)
            ]);
          }

          return AlertDialog(
              title: const Text("試合結果の編集"),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text("本戦結果", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    buildResultToggle(tempResult, (r) => setStateDialog(() => tempResult = r)),
                    const SizedBox(height: 8),
                    buildScoreInput("スコア", scoreOwnCtrl, scoreOppCtrl),
                    if (tempResult == MatchResult.draw) ...[
                      const Divider(height: 24),
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Column(children: [
                            const Text("▼ 延長・決着戦", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Text("なし", style: TextStyle(fontSize: 12)),
                              Radio<MatchResult>(value: MatchResult.none, groupValue: tempExtraResult, onChanged: (v) => setStateDialog(() => tempExtraResult = v!)),
                              const Text("勝", style: TextStyle(fontSize: 12)),
                              Radio<MatchResult>(value: MatchResult.win, groupValue: tempExtraResult, onChanged: (v) => setStateDialog(() => tempExtraResult = v!)),
                              const Text("負", style: TextStyle(fontSize: 12)),
                              Radio<MatchResult>(value: MatchResult.lose, groupValue: tempExtraResult, onChanged: (v) => setStateDialog(() => tempExtraResult = v!))
                            ]),
                            if (tempExtraResult != MatchResult.none) buildScoreInput("延長スコア", extraScoreOwnCtrl, extraScoreOppCtrl)
                          ]))
                    ]
                  ])),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
                ElevatedButton(
                    onPressed: () async {
                      MatchResult finalResult = tempExtraResult != MatchResult.none ? tempExtraResult : tempResult;
                      bool isExtra = tempExtraResult != MatchResult.none;
                      await ref.read(analysisControllerProvider.notifier).updateMatchResult(record.id, finalResult, int.tryParse(scoreOwnCtrl.text), int.tryParse(scoreOppCtrl.text), isExtra, int.tryParse(extraScoreOwnCtrl.text), int.tryParse(extraScoreOppCtrl.text));
                      if (context.mounted) {
                        Navigator.pop(context);
                        onUpdate(); // ★変更: コールバック呼び出し
                      }
                    },
                    child: const Text("保存"))
              ]);
        });
      });
}