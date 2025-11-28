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

// ★修正: HookConsumerWidget に build メソッドを再定義
class MatchRecordScreen extends HookConsumerWidget {
  const MatchRecordScreen({super.key});

  // ★修正: 全てのロジックを build メソッド内へ移動
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(gameRecorderProvider);

    // Hooksの呼び出しはbuildメソッドの先頭で行う
    useEffect(() {
      Future.microtask(() => controller.loadData());
      return null;
    }, const []);

    final tabController = useTabController(initialLength: 3);
    useListenable(tabController);

    // --- UIイベントハンドラ ---

    // showDateSelectDialog は build 内で定義
    void showDateSelectDialog() {
      DateTime tempDate = controller.matchDate;

      showDialog(context: context, builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("試合日付の選択"),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Text("日付: ", style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: tempDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (picked != null) setStateDialog(() => tempDate = picked);
                  },
                  child: Text(DateFormat('yyyy/MM/dd').format(tempDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                )
              ])
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
              ElevatedButton(onPressed: () {
                controller.updateMatchDate(tempDate);
                Navigator.pop(context);
              }, child: const Text("設定"))
            ],
          );
        });
      });
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
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("キャンセル")
            ),
            ElevatedButton(onPressed: () async {
              // 保存処理
              final success = await controller.saveMatchToDb();

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

    void showEditLogDialog(LogEntry log, int index) {
      controller.deleteLog(index);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("ログを削除しました"), action: SnackBarAction(label: "復元", onPressed: () => controller.restoreLog(index, log))));
    }

    // ==========================================
    // UI構築
    // ==========================================

    if (controller.settings.squadNumbers.isEmpty && controller.benchPlayers.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Stack(
          alignment: Alignment.center,
          children: [
            // 左寄せ: 日付表示と選択ボタン
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    DateFormat('yyyy/MM/dd').format(controller.matchDate),
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  IconButton(
                    onPressed: showDateSelectDialog,
                    icon: const Icon(Icons.calendar_today, size: 20, color: Colors.black54),
                  ),
                ],
              ),
            ),

            // 中央: タイマー
            Align(
              alignment: Alignment.center,
              child: Text(
                controller.formattedTime,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: controller.remainingSeconds <= 30 ? Colors.red : Colors.black87,
                  fontFamily: 'monospace', // 等幅フォントで見やすく
                ),
              ),
            ),
          ],
        ),
        actions: const [],
      ),
      body: Row(children: [
        Expanded(
          flex: 2,
          child: PlayerSelectionPanel(
            tabController: tabController,
            courtPlayers: controller.courtPlayers,
            benchPlayers: controller.benchPlayers,
            absentPlayers: controller.absentPlayers,
            playerNames: controller.playerNames,
            selectedPlayer: controller.selectedPlayer,
            selectedForMove: controller.selectedForMove,
            isMultiSelectMode: controller.isMultiSelectMode,
            onPlayerTap: controller.selectPlayer,
            onPlayerLongPress: controller.startMultiSelect,
            onMoveSelected: controller.moveSelectedPlayers,
            onClearMultiSelect: controller.clearMultiSelect,
          ),
        ),

        const VerticalDivider(width: 1),

        Expanded(
          flex: 6,
          child: Column(children: [
            GameTimerBar(
              isRunning: controller.isRunning,
              hasMatchStarted: controller.hasMatchStarted,
              onStart: controller.startTimer,
              onStop: controller.stopTimer,
              onEnd: handleEndMatch,
            ),
            Expanded(
              child: GameOperationPanel(
                uiActions: controller.uiActions,
                gridColumns: controller.settings.gridColumns,
                hasMatchStarted: controller.hasMatchStarted,
                selectedPlayer: controller.selectedPlayer,
                playerNames: controller.playerNames,
                selectedUIAction: controller.selectedUIAction,
                selectedSubAction: controller.selectedSubAction,
                selectedResult: controller.selectedResult,
                onActionSelected: controller.selectAction,
                onResultSelected: controller.selectResult,
                onSubActionSelected: controller.selectSubAction,
                onConfirm: handleLogConfirm,
              ),
            ),
          ]),
        ),

        Expanded(
          flex: 2,
          child: GameLogPanel(
            logs: controller.logs,
            onLogTap: showEditLogDialog,
          ),
        ),
      ]),
    );
  }
}