// lib/features/game_record/presentation/widgets/player_selection_panel.dart
import 'package:flutter/material.dart';

class PlayerSelectionPanel extends StatelessWidget {
  final TabController tabController;
  final List<String> courtPlayers;
  final List<String> benchPlayers;
  final List<String> absentPlayers;
  final Map<String, String> playerNames;

  // 選択状態
  final String? selectedPlayer;
  final Set<String> selectedForMove;
  final bool isMultiSelectMode;

  // コールバック
  final Function(String number) onPlayerTap;
  final Function(String number) onPlayerLongPress;
  final Function(String toType) onMoveSelected;
  final VoidCallback onClearMultiSelect;

  const PlayerSelectionPanel({
    super.key,
    required this.tabController,
    required this.courtPlayers,
    required this.benchPlayers,
    required this.absentPlayers,
    required this.playerNames,
    required this.selectedPlayer,
    required this.selectedForMove,
    required this.isMultiSelectMode,
    required this.onPlayerTap,
    required this.onPlayerLongPress,
    required this.onMoveSelected,
    required this.onClearMultiSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: tabController,
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'コート (${courtPlayers.length})'),
            Tab(text: 'ベンチ (${benchPlayers.length})'),
            Tab(text: '欠席 (${absentPlayers.length})'),
          ],
        ),
        // 複数選択モード時の移動バー
        if (isMultiSelectMode)
          Container(
            color: Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Text("${selectedForMove.length}人選択中", style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.sports_basketball), tooltip: "コートへ", onPressed: () => onMoveSelected('court')),
                IconButton(icon: const Icon(Icons.chair), tooltip: "ベンチへ", onPressed: () => onMoveSelected('bench')),
                IconButton(icon: const Icon(Icons.cancel), tooltip: "欠席へ", onPressed: () => onMoveSelected('absent')),
                IconButton(icon: const Icon(Icons.close), tooltip: "選択解除", onPressed: onClearMultiSelect),
              ],
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              // ★変更: 第2引数に「アクション選択可能か」フラグを渡す
              _buildList(courtPlayers, canSelectForAction: true),  // コート: 選択OK
              _buildList(benchPlayers, canSelectForAction: false), // ベンチ: 選択NG
              _buildList(absentPlayers, canSelectForAction: false),// 欠席: 選択NG
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<String> players, {required bool canSelectForAction}) {
    if (players.isEmpty) return const Center(child: Text("なし", style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final number = players[index];
        final name = playerNames[number] ?? "";
        final isSelected = selectedPlayer == number;
        final isMultiSelected = selectedForMove.contains(number);

        return Card(
          color: isMultiSelected ? Colors.orange[200] : (isSelected ? Colors.yellow[100] : Colors.white),
          // ベンチ・欠席で選択不可の場合は少し薄く表示する（視覚的フィードバック）
          elevation: (canSelectForAction || isMultiSelectMode) ? 1 : 0,
          child: ListTile(
            title: Text(
                number,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    // 選択不可モードならグレーアウト（ただしマルチセレクト中は普通に表示）
                    color: (!canSelectForAction && !isMultiSelectMode) ? Colors.grey : Colors.black87
                ),
                textAlign: TextAlign.center
            ),
            subtitle: name.isNotEmpty
                ? Text(name, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)
                : null,
            onTap: () {
              // ★修正: タップ時の挙動分岐
              if (isMultiSelectMode) {
                // マルチセレクト（移動）モードなら、どこにいても選択可能
                onPlayerTap(number);
              } else if (canSelectForAction) {
                // 通常モードなら、コートの選手のみ選択可能
                onPlayerTap(number);
              } else {
                // 選択不可（ベンチ・欠席）の場合
                // 必要であればここに「ベンチの選手は記録できません」等のトーストを表示可能
                // 今回は何もせず無視する
              }
            },
            onLongPress: () => onPlayerLongPress(number), // 長押し（移動開始）は常に有効
          ),
        );
      },
    );
  }
}