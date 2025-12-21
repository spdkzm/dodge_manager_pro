// lib/features/game_record/presentation/pages/match_record_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';


import '../widgets/game_timer_bar.dart';
import '../widgets/player_selection_panel.dart';
import '../widgets/game_operation_panel.dart';
import '../widgets/game_log_panel.dart';

import '../../domain/models.dart';
import '../../application/game_recorder_controller.dart';
import '../../../team_mgmt/application/team_store.dart';
import '../../../team_mgmt/domain/roster_item.dart';
import '../../../settings/domain/action_definition.dart'; // SubActionDefinition

import '../../../settings/presentation/pages/button_layout_settings_screen.dart';
import '../../../settings/presentation/pages/action_settings_screen.dart';
import '../../../settings/presentation/pages/match_environment_screen.dart';

class MatchRecordScreen extends HookConsumerWidget {
  const MatchRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(gameRecorderProvider);
    final teamStore = ref.watch(teamStoreProvider);
    final currentTeam = teamStore.currentTeam;

    final opponentController = useTextEditingController(text: controller.opponentName);
    final venueController = useTextEditingController(text: controller.venueName);

    ref.listen(teamStoreProvider, (previous, next) {
      controller.loadData();
    });

    useEffect(() {
      Future.microtask(() => controller.loadData());
      return null;
    }, const []);

    final tabController = useTabController(initialLength: 3);
    useListenable(tabController);

    String getMatchTypeName(MatchType type) {
      switch (type) {
        case MatchType.official: return "大会";
        case MatchType.practiceMatch: return "練習試合";
        case MatchType.practice: return "練習";
      }
    }

    void showMatchInfoDialog() {
      final opponents = currentTeam?.opponentItems ?? [];
      final venues = currentTeam?.venueItems ?? [];
      final opSchema = currentTeam?.opponentSchema.firstWhere((f) => f.label == 'チーム名', orElse: () => currentTeam.opponentSchema.first);
      final veSchema = currentTeam?.venueSchema.firstWhere((f) => f.label == '会場名', orElse: () => currentTeam.venueSchema.first);

      MatchType tempType = controller.matchType;
      DateTime tempDate = controller.matchDate;
      opponentController.text = controller.opponentName;
      venueController.text = controller.venueName;
      String? tempOpponentId = controller.opponentId;
      String? tempVenueId = controller.venueId;

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("試合情報の編集"),
              content: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("日付", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                              context: context,
                              initialDate: tempDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030)
                          );
                          if (picked != null) {
                            setStateDialog(() => tempDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          width: double.infinity,
                          decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5))
                          ),
                          child: Text(
                            DateFormat('yyyy/MM/dd (E)', 'ja').format(tempDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text("試合種別", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      DropdownButton<MatchType>(
                        value: tempType,
                        isExpanded: true,
                        items: MatchType.values.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(getMatchTypeName(type)),
                        )).toList(),
                        onChanged: (newType) {
                          if (newType != null) setStateDialog(() => tempType = newType);
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text("対戦相手", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      Row(children: [
                        Expanded(child: TextField(controller: opponentController, decoration: const InputDecoration(hintText: "直接入力も可"))),
                        PopupMenuButton<RosterItem>(
                          icon: const Icon(Icons.list),
                          tooltip: "リストから選択",
                          onSelected: (item) {
                            final name = item.data[opSchema?.id]?.toString() ?? "";
                            opponentController.text = name;
                            tempOpponentId = item.id;
                          },
                          itemBuilder: (context) => opponents.map((item) {
                            final name = item.data[opSchema?.id]?.toString() ?? "名称未設定";
                            return PopupMenuItem(value: item, child: Text(name));
                          }).toList(),
                        ),
                      ]),

                      const SizedBox(height: 16),

                      const Text("会場", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      Row(children: [
                        Expanded(child: TextField(controller: venueController, decoration: const InputDecoration(hintText: "直接入力も可"))),
                        PopupMenuButton<RosterItem>(
                          icon: const Icon(Icons.list),
                          tooltip: "リストから選択",
                          onSelected: (item) {
                            final name = item.data[veSchema?.id]?.toString() ?? "";
                            venueController.text = name;
                            tempVenueId = item.id;
                          },
                          itemBuilder: (context) => venues.map((item) {
                            final name = item.data[veSchema?.id]?.toString() ?? "名称未設定";
                            return PopupMenuItem(value: item, child: Text(name));
                          }).toList(),
                        ),
                      ]),
                    ]
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
                ElevatedButton(
                    onPressed: () {
                      controller.updateMatchDate(tempDate);
                      controller.updateMatchType(tempType);
                      controller.updateMatchInfo(
                          opponentName: opponentController.text,
                          opponentId: tempOpponentId,
                          venueName: venueController.text,
                          venueId: tempVenueId
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("設定")
                )
              ],
            );
          });
        },
      );
    }

    void handleLogConfirm() {
      final error = controller.confirmLog();
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
    }

    void handleEndMatch() {
      controller.endMatch();

      final bool isResultEnabled = controller.settings.isResultRecordingEnabled;
      final bool isScoreEnabled = controller.settings.isScoreRecordingEnabled;

      MatchResult tempResult = MatchResult.none;
      MatchResult tempExtraResult = MatchResult.none;
      final scoreOwnCtrl = TextEditingController();
      final scoreOppCtrl = TextEditingController();
      final extraScoreOwnCtrl = TextEditingController();
      final extraScoreOppCtrl = TextEditingController();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateDialog) {

            Widget buildScoreInput(String label, TextEditingController ctrl1, TextEditingController ctrl2) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 50, child: TextField(controller: ctrl1, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()))),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("-", style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 50, child: TextField(controller: ctrl2, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()))),
                ],
              );
            }

            Widget buildResultToggle(MatchResult current, Function(MatchResult) onSelect) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(label: const Text("勝"), selected: current == MatchResult.win, onSelected: (v) => onSelect(MatchResult.win), selectedColor: Colors.red.shade100),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text("引分"), selected: current == MatchResult.draw, onSelected: (v) => onSelect(MatchResult.draw), selectedColor: Colors.grey.shade300),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text("負"), selected: current == MatchResult.lose, onSelected: (v) => onSelect(MatchResult.lose), selectedColor: Colors.blue.shade100),
                ],
              );
            }

            return AlertDialog(
              title: const Text("試合記録の保存"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("記録をデータベースに保存しますか？"),
                    if (isResultEnabled) ...[
                      const Divider(height: 24),
                      const Text("試合結果", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      buildResultToggle(tempResult, (r) => setStateDialog(() => tempResult = r)),

                      if (isScoreEnabled) ...[
                        const SizedBox(height: 8),
                        buildScoreInput("スコア", scoreOwnCtrl, scoreOppCtrl),
                      ],

                      if (tempResult == MatchResult.draw) ...[
                        const Divider(height: 24),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: [
                              const Text("▼ 延長・決着戦 (オプション)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("なし", style: TextStyle(fontSize: 12)),
                                  Radio<MatchResult>(value: MatchResult.none, groupValue: tempExtraResult, onChanged: (v) => setStateDialog(() => tempExtraResult = v!)),
                                  const Text("勝", style: TextStyle(fontSize: 12)),
                                  Radio<MatchResult>(value: MatchResult.win, groupValue: tempExtraResult, onChanged: (v) => setStateDialog(() => tempExtraResult = v!)),
                                  const Text("負", style: TextStyle(fontSize: 12)),
                                  Radio<MatchResult>(value: MatchResult.lose, groupValue: tempExtraResult, onChanged: (v) => setStateDialog(() => tempExtraResult = v!)),
                                ],
                              ),
                              if (isScoreEnabled && tempExtraResult != MatchResult.none)
                                buildScoreInput("延長スコア", extraScoreOwnCtrl, extraScoreOppCtrl),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
                ElevatedButton(onPressed: () async {
                  MatchResult finalResult = tempExtraResult != MatchResult.none ? tempExtraResult : tempResult;
                  bool isExtra = tempExtraResult != MatchResult.none;

                  final success = await controller.saveMatchToDb(
                    result: finalResult,
                    scoreOwn: int.tryParse(scoreOwnCtrl.text),
                    scoreOpponent: int.tryParse(scoreOppCtrl.text),
                    isExtraTime: isExtra,
                    extraScoreOwn: int.tryParse(extraScoreOwnCtrl.text),
                    extraScoreOpponent: int.tryParse(extraScoreOppCtrl.text),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("保存しました")));
                    else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("チーム未選択のため保存できません"), backgroundColor: Colors.red));
                  }
                }, child: const Text("保存"))
              ],
            );
          });
        },
      );
    }

    void showEditLogDialog(LogEntry log, int index) {
      final isSystemLog = log.type == LogType.system;

      final definitions = controller.actionDefinitions;

      // ★修正: 選手IDのリストを取得
      final allPlayerIds = [
        ...controller.courtPlayerIds,
        ...controller.benchPlayerIds,
        ...controller.absentPlayerIds
      ];
      // 背番号順にソート (コントローラーのヘルパー使用はできないのでここで簡易ソート)
      allPlayerIds.sort((a, b) {
        final infoA = controller.getPlayerInfo(a);
        final infoB = controller.getPlayerInfo(b);
        final numA = int.tryParse(infoA?.number ?? '') ?? 999;
        final numB = int.tryParse(infoB?.number ?? '') ?? 999;
        return numA.compareTo(numB);
      });

      final actionNames = definitions.map((d) => d.name).toList();

      final timeCtrl = TextEditingController(text: log.gameTime);
      final actionNameCtrl = TextEditingController(text: log.action);

      // ★修正: IDで初期値を設定
      String? playerIdVal = log.playerId;
      // もしログにIDがない場合は、背番号から探すなどのフォールバックが必要だが、
      // ここでは既にID移行済み前提とする
      if (playerIdVal == null || !allPlayerIds.contains(playerIdVal)) {
        // IDが見つからない場合（古いログなど）、表示リストには含めるか、あるいはnullにする
        // ここでは一旦nullにしておき、保存時に再選択を促す形にする
      }

      String? actionNameVal = actionNames.contains(log.action) ? log.action : null;
      SubActionDefinition? subActionVal;
      ActionResult resultVal = log.result;

      if (!isSystemLog && actionNameVal != null) {
        final def = definitions.firstWhere((d) => d.name == actionNameVal, orElse: () => ActionDefinition(name: '', subActions: []));
        if (log.subActionId != null) {
          subActionVal = def.subActions.where((s) => s.id == log.subActionId).firstOrNull;
        }
      }

      showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
              builder: (ctx, setStateDialog) {

                ActionDefinition selectedDef = ActionDefinition(name: '', subActions: []);
                if (!isSystemLog && actionNameVal != null) {
                  selectedDef = definitions.firstWhere(
                          (d) => d.name == actionNameVal,
                      orElse: () => ActionDefinition(name: '', subActions: [])
                  );
                }

                String category = 'default';
                if (resultVal == ActionResult.success) category = 'success';
                else if (resultVal == ActionResult.failure) category = 'failure';

                final subActions = selectedDef.getSubActions(category);

                return AlertDialog(
                    title: Text(isSystemLog ? "システムログ編集" : "ログ編集"),
                    content: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                                controller: timeCtrl,
                                decoration: const InputDecoration(labelText: "時間 (分:秒)", hintText: "05:30"),
                                keyboardType: TextInputType.datetime
                            ),
                            const SizedBox(height: 16),

                            if (isSystemLog) ...[
                              TextField(
                                controller: actionNameCtrl,
                                decoration: const InputDecoration(labelText: "内容 (試合開始, タイムなど)"),
                              ),
                            ] else ...[
                              DropdownButtonFormField<String>(
                                  value: playerIdVal,
                                  decoration: const InputDecoration(labelText: "選手"),
                                  items: allPlayerIds.map((pid) {
                                    // ★修正: IDから表示情報取得
                                    final info = controller.getPlayerInfo(pid);
                                    final num = info?.number ?? "?";
                                    final name = info?.name ?? "";
                                    return DropdownMenuItem(value: pid, child: Text("#$num $name"));
                                  }).toList(),
                                  onChanged: (v) => setStateDialog(() => playerIdVal = v)
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                  value: actionNameVal,
                                  decoration: const InputDecoration(labelText: "アクション"),
                                  items: actionNames.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                                  onChanged: (v) => setStateDialog(() {
                                    actionNameVal = v;
                                    subActionVal = null;
                                  })
                              ),
                              const SizedBox(height: 16),
                              const Text("結果", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Row(
                                  children: [
                                    Radio<ActionResult>(value: ActionResult.none, groupValue: resultVal, onChanged: (v) => setStateDialog(() { resultVal = v!; subActionVal = null; })),
                                    const Text("なし"),
                                    Radio<ActionResult>(value: ActionResult.success, groupValue: resultVal, onChanged: (v) => setStateDialog(() { resultVal = v!; subActionVal = null; })),
                                    const Text("成功"),
                                    Radio<ActionResult>(value: ActionResult.failure, groupValue: resultVal, onChanged: (v) => setStateDialog(() { resultVal = v!; subActionVal = null; })),
                                    const Text("失敗")
                                  ]
                              ),
                              if (subActions.isNotEmpty)
                                DropdownButtonFormField<SubActionDefinition>(
                                    value: subActions.any((s) => s.id == subActionVal?.id) ? subActionVal : null,
                                    decoration: const InputDecoration(labelText: "詳細"),
                                    items: subActions.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                                    onChanged: (v) => setStateDialog(() => subActionVal = v)
                                )
                            ]
                          ]
                      ),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                    title: const Text("削除確認"),
                                    content: const Text("このログを削除しますか？"),
                                    actions: [
                                      TextButton(onPressed: ()=>Navigator.pop(c, false), child: const Text("キャンセル")),
                                      ElevatedButton(onPressed: ()=>Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("削除"))
                                    ]
                                )
                            );
                            if (confirm == true && context.mounted) {
                              controller.deleteLog(index);
                              Navigator.pop(ctx);
                            }
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text("削除")
                      ),
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
                      ElevatedButton(
                          onPressed: () {
                            final newTime = timeCtrl.text;

                            if (isSystemLog) {
                              final newAction = actionNameCtrl.text;
                              if (newAction.isEmpty) return;
                              final newLog = log.copyWith(gameTime: newTime, action: newAction);
                              controller.updateLog(index, newLog);
                            } else {
                              if (playerIdVal == null || actionNameVal == null) return;

                              // ★修正: IDから背番号を取得して保存
                              final info = controller.getPlayerInfo(playerIdVal!);
                              final pNum = info?.number ?? "";

                              final newLog = log.copyWith(
                                gameTime: newTime,
                                playerNumber: pNum, // 表示用
                                playerId: playerIdVal, // ★ID保存
                                action: actionNameVal!,
                                subAction: subActionVal?.name,
                                subActionId: subActionVal?.id,
                                result: resultVal,
                              );
                              controller.updateLog(index, newLog);
                            }
                            Navigator.pop(ctx);
                          },
                          child: const Text("保存")
                      )
                    ]
                );
              }
          )
      );
    }

    final dateStr = DateFormat('MM/dd').format(controller.matchDate);
    final typeStr = getMatchTypeName(controller.matchType);
    final opponentStr = controller.opponentName.isEmpty ? "対戦相手未定" : "VS ${controller.opponentName}";
    final venueStr = controller.venueName.isEmpty ? "" : "@${controller.venueName}";

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: InkWell(
          onTap: showMatchInfoDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8)
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          "$dateStr ($typeStr)",
                          style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                      Text(
                        "$opponentStr $venueStr",
                        style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit, size: 16, color: Colors.black54),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                  controller.formattedTime,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: controller.remainingSeconds <= 30 ? Colors.red : Colors.black87,
                      fontFamily: 'monospace'
                  )
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'layout') await Navigator.push(context, MaterialPageRoute(builder: (_) => const ButtonLayoutSettingsScreen()));
              else if (val == 'action') await Navigator.push(context, MaterialPageRoute(builder: (_) => const ActionSettingsScreen()));
              else if (val == 'env') await Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchEnvironmentScreen()));
              controller.loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'layout', child: Row(children: [Icon(Icons.grid_view, color: Colors.grey), SizedBox(width: 8), Text('ボタン配置と列数')])),
              const PopupMenuItem(value: 'action', child: Row(children: [Icon(Icons.touch_app, color: Colors.grey), SizedBox(width: 8), Text('アクションの定義')])),
              const PopupMenuItem(value: 'env', child: Row(children: [Icon(Icons.timer, color: Colors.grey), SizedBox(width: 8), Text('試合環境設定')])),
            ],
          ),
        ],
      ),
      body: Row(children: [
        // ★修正: パラメータ名を変更して渡す
        Expanded(flex: 2, child: PlayerSelectionPanel(
            tabController: tabController,
            courtPlayerIds: controller.courtPlayerIds, // IDリスト
            benchPlayerIds: controller.benchPlayerIds, // IDリスト
            absentPlayerIds: controller.absentPlayerIds, // IDリスト
            playerInfoGetter: controller.getPlayerInfo, // 情報取得関数
            selectedPlayerId: controller.selectedPlayerId, // ID
            selectedForMoveIds: controller.selectedForMoveIds, // IDセット
            isMultiSelectMode: controller.isMultiSelectMode,
            onPlayerTap: controller.selectPlayer,
            onPlayerLongPress: controller.startMultiSelect,
            onMoveSelected: controller.moveSelectedPlayers,
            onClearMultiSelect: controller.clearMultiSelect
        )),
        const VerticalDivider(width: 1),
        Expanded(flex: 6, child: Column(children: [
          GameTimerBar(isRunning: controller.isRunning, hasMatchStarted: controller.hasMatchStarted, onStart: controller.startTimer, onStop: controller.stopTimer, onEnd: handleEndMatch),
          Expanded(child: GameOperationPanel(
              uiActions: controller.uiActions,
              gridColumns: controller.settings.gridColumns,
              hasMatchStarted: controller.hasMatchStarted,
              // ★修正: パラメータ変更
              selectedPlayerId: controller.selectedPlayerId,
              playerInfoGetter: controller.getPlayerInfo,
              selectedUIAction: controller.selectedUIAction,
              selectedSubAction: controller.selectedSubAction,
              selectedResult: controller.selectedResult,
              onActionSelected: controller.selectAction,
              onResultSelected: controller.selectResult,
              onSubActionSelected: controller.selectSubAction,
              onConfirm: handleLogConfirm
          ))
        ])),
        Expanded(flex: 2, child: GameLogPanel(
            logs: controller.logs,
            onLogTap: showEditLogDialog
        )),
      ]),
    );
  }
}