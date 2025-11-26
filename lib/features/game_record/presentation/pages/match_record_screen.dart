// lib/features/game_record/presentation/pages/match_record_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

// UI部品 (widgets)
import '../widgets/game_timer_bar.dart';
import '../widgets/player_selection_panel.dart';
import '../widgets/game_operation_panel.dart';
import '../widgets/game_log_panel.dart';

// データモデル・ロジック
import '../../domain/models.dart';
import 'history_screen.dart'; // 同じ階層にある想定
import '../../application/game_recorder_controller.dart';

class MatchRecordScreen extends HookConsumerWidget {
  const MatchRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. コントローラーの取得 (Provider経由)
    // autoDispose なので画面を閉じれば自動で破棄され、開けば新品が作られる
    final controller = ref.watch(gameRecorderProvider);

    // 2. 初期ロード (useEffectで1回だけ実行)
    useEffect(() {
      // ビルド完了後に実行しないとエラーになる可能性があるためMicrotaskで
      Future.microtask(() => controller.loadData());
      return null;
    }, const []); // 空配列で初回のみ実行

    // 3. TabController (Hooks)
    final tabController = useTabController(initialLength: 3);
    useListenable(tabController);

    // --- UIイベントハンドラ ---

    void showEditMatchInfo() {
      final oppCtrl = TextEditingController(text: controller.opponentName);
      DateTime tempDate = controller.matchDate;

      showDialog(context: context, builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("試合情報の記録"),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: oppCtrl, decoration: const InputDecoration(labelText: "対戦相手名")),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ["大会", "練習試合", "練習"].map((l) => ActionChip(label: Text(l), onPressed: () => oppCtrl.text = l)).toList()),
              const SizedBox(height: 16),
              Row(children: [
                const Text("日付: "),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: tempDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (picked != null) setStateDialog(() => tempDate = picked);
                  },
                  child: Text(DateFormat('yyyy-MM-dd').format(tempDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                )
              ])
            ]),
            actions: [
              ElevatedButton(onPressed: () {
                controller.updateMatchInfo(oppCtrl.text, tempDate);
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
          content: const Text("記録をデータベースに保存しますか？"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
            ElevatedButton(onPressed: () async {
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
      // 簡易実装: 削除のみ提供
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
        title: const Text('DodgeLog'),
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HistoryScreen()))),
          TextButton(onPressed: showEditMatchInfo, child: Text(controller.opponentName.isEmpty ? "相手設定" : "VS ${controller.opponentName}", style: const TextStyle(color: Colors.black))),
          Text(controller.formattedTime, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: controller.remainingSeconds <= 30 ? Colors.red : Colors.black87)),
        ],
      ),
      body: Row(children: [
        // 左カラム: 選手選択パネル
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

        // 中央カラム: 操作パネル
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

        // 右カラム: ログパネル
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