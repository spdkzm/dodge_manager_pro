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

    // 対戦相手・会場の一時保存用 (State)
    final opponentController = useTextEditingController();
    final venueController = useTextEditingController();
    final opponentId = useState<String?>(null);
    final venueId = useState<String?>(null);

    useEffect(() {
      Future.microtask(() => controller.loadData());
      return null;
    }, const []);

    final tabController = useTabController(initialLength: 3);
    useListenable(tabController);

    // ヘルパー: 種別表示
    String getMatchTypeName(MatchType type) {
      switch (type) {
        case MatchType.official: return "大会";
        case MatchType.practiceMatch: return "練習試合";
        case MatchType.practice: return "練習";
      }
    }

    // --- 一括編集ダイアログ ---
    void showMatchInfoDialog() {
      // リストデータの準備
      final opponents = currentTeam?.opponentItems ?? [];
      final venues = currentTeam?.venueItems ?? [];
      final opSchema = currentTeam?.opponentSchema.firstWhere((f) => f.label == 'チーム名', orElse: () => currentTeam!.opponentSchema.first);
      final veSchema = currentTeam?.venueSchema.firstWhere((f) => f.label == '会場名', orElse: () => currentTeam!.venueSchema.first);

      // ダイアログ内での一時的な状態管理
      MatchType tempType = controller.matchType;
      DateTime tempDate = controller.matchDate;

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
                      // 1. 日付
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

                      // 2. 試合種別
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

                      // 3. 対戦相手
                      const Text("対戦相手", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      Row(children: [
                        Expanded(child: TextField(controller: opponentController, decoration: const InputDecoration(hintText: "直接入力も可"))),
                        PopupMenuButton<RosterItem>(
                          icon: const Icon(Icons.list),
                          tooltip: "リストから選択",
                          onSelected: (item) {
                            final name = item.data[opSchema?.id]?.toString() ?? "";
                            opponentController.text = name;
                            opponentId.value = item.id;
                          },
                          itemBuilder: (context) => opponents.map((item) {
                            final name = item.data[opSchema?.id]?.toString() ?? "名称未設定";
                            return PopupMenuItem(value: item, child: Text(name));
                          }).toList(),
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // 4. 会場
                      const Text("会場", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      Row(children: [
                        Expanded(child: TextField(controller: venueController, decoration: const InputDecoration(hintText: "直接入力も可"))),
                        PopupMenuButton<RosterItem>(
                          icon: const Icon(Icons.list),
                          tooltip: "リストから選択",
                          onSelected: (item) {
                            final name = item.data[veSchema?.id]?.toString() ?? "";
                            venueController.text = name;
                            venueId.value = item.id;
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
                      // Controllerに変更を反映
                      controller.updateMatchDate(tempDate);
                      controller.updateMatchType(tempType);
                      // 対戦相手・会場はTextController経由で画面に反映済み
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("試合記録の保存"),
          content: const Text("記録をデータベースに保存しますか？\n保存すると現在のログはクリアされます。"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
            ElevatedButton(onPressed: () async {
              final success = await controller.saveMatchToDb(
                  opponentName: opponentController.text,
                  opponentId: opponentId.value,
                  venueName: venueController.text,
                  venueId: venueId.value
              );

              if (context.mounted) {
                Navigator.pop(context);
                if (success) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("保存しました")));
                else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("チーム未選択のため保存できません"), backgroundColor: Colors.red));
              }
            }, child: const Text("保存"))
          ],
        ),
      );
    }

    // ログ編集ダイアログ
    void showEditLogDialog(LogEntry log, int index) {
      controller.deleteLog(index);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text("ログを削除しました"),
              action: SnackBarAction(
                  label: "復元",
                  onPressed: () => controller.restoreLog(index, log)
              )
          )
      );
    }

    if (controller.settings.squadNumbers.isEmpty && controller.benchPlayers.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 情報表示用の文字列生成
    final dateStr = DateFormat('MM/dd').format(controller.matchDate);
    final typeStr = getMatchTypeName(controller.matchType);
    final opponentStr = opponentController.text.isEmpty ? "対戦相手未定" : "VS ${opponentController.text}";
    final venueStr = venueController.text.isEmpty ? "" : "@${venueController.text}";

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        // タイトルエリアをタップ可能にする
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
                      // 上段: 日付 (種別)
                      Text(
                          "$dateStr ($typeStr)",
                          style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                      // 下段: VS 相手 @会場
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
          // タイマー表示
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
          // 設定メニュー
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
        Expanded(flex: 2, child: PlayerSelectionPanel(tabController: tabController, courtPlayers: controller.courtPlayers, benchPlayers: controller.benchPlayers, absentPlayers: controller.absentPlayers, playerNames: controller.playerNames, selectedPlayer: controller.selectedPlayer, selectedForMove: controller.selectedForMove, isMultiSelectMode: controller.isMultiSelectMode, onPlayerTap: controller.selectPlayer, onPlayerLongPress: controller.startMultiSelect, onMoveSelected: controller.moveSelectedPlayers, onClearMultiSelect: controller.clearMultiSelect)),
        const VerticalDivider(width: 1),
        Expanded(flex: 6, child: Column(children: [GameTimerBar(isRunning: controller.isRunning, hasMatchStarted: controller.hasMatchStarted, onStart: controller.startTimer, onStop: controller.stopTimer, onEnd: handleEndMatch), Expanded(child: GameOperationPanel(uiActions: controller.uiActions, gridColumns: controller.settings.gridColumns, hasMatchStarted: controller.hasMatchStarted, selectedPlayer: controller.selectedPlayer, playerNames: controller.playerNames, selectedUIAction: controller.selectedUIAction, selectedSubAction: controller.selectedSubAction, selectedResult: controller.selectedResult, onActionSelected: controller.selectAction, onResultSelected: controller.selectResult, onSubActionSelected: controller.selectSubAction, onConfirm: handleLogConfirm))])),
        Expanded(flex: 2, child: GameLogPanel(logs: controller.logs, onLogTap: showEditLogDialog)),
      ]),
    );
  }
}