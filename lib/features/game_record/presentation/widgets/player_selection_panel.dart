// lib/features/game_record/presentation/widgets/player_selection_panel.dart
import 'package:flutter/material.dart';
import '../../application/game_recorder_controller.dart'; // PlayerDisplayInfo利用のため

class PlayerSelectionPanel extends StatelessWidget {
  final TabController tabController;
  // ★変更: IDリストを受け取る
  final List<String> courtPlayerIds;
  final List<String> benchPlayerIds;
  final List<String> absentPlayerIds;
  // ★変更: 情報取得関数
  final PlayerDisplayInfo? Function(String) playerInfoGetter;

  final String? selectedPlayerId;
  final Set<String> selectedForMoveIds;
  final bool isMultiSelectMode;

  final Function(String id) onPlayerTap;
  final Function(String id) onPlayerLongPress;
  final Function(String toType) onMoveSelected;
  final VoidCallback onClearMultiSelect;

  const PlayerSelectionPanel({
    super.key,
    required this.tabController,
    required this.courtPlayerIds,
    required this.benchPlayerIds,
    required this.absentPlayerIds,
    required this.playerInfoGetter,
    required this.selectedPlayerId,
    required this.selectedForMoveIds,
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
            Tab(text: 'コート (${courtPlayerIds.length})'),
            Tab(text: 'ベンチ (${benchPlayerIds.length})'),
            Tab(text: '欠席 (${absentPlayerIds.length})'),
          ],
        ),
        if (isMultiSelectMode)
          Container(
            color: Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Text("${selectedForMoveIds.length}人選択中", style: const TextStyle(fontWeight: FontWeight.bold)),
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
              _buildList(courtPlayerIds, canSelectForAction: true),
              _buildList(benchPlayerIds, canSelectForAction: false),
              _buildList(absentPlayerIds, canSelectForAction: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<String> playerIds, {required bool canSelectForAction}) {
    if (playerIds.isEmpty) return const Center(child: Text("なし", style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      itemCount: playerIds.length,
      itemBuilder: (context, index) {
        final id = playerIds[index];
        // ★修正: IDから表示情報を解決
        final info = playerInfoGetter(id);
        final number = info?.number ?? "?";
        final name = info?.name ?? "";

        final isSelected = selectedPlayerId == id;
        final isMultiSelected = selectedForMoveIds.contains(id);

        return Card(
          color: isMultiSelected ? Colors.orange[200] : (isSelected ? Colors.yellow[100] : Colors.white),
          elevation: (canSelectForAction || isMultiSelectMode) ? 1 : 0,
          child: ListTile(
            title: Text(
                number,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: (!canSelectForAction && !isMultiSelectMode) ? Colors.grey : Colors.black87
                ),
                textAlign: TextAlign.center
            ),
            subtitle: name.isNotEmpty
                ? Text(name, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)
                : null,
            onTap: () {
              if (isMultiSelectMode) {
                onPlayerTap(id);
              } else if (canSelectForAction) {
                onPlayerTap(id);
              }
            },
            onLongPress: () => onPlayerLongPress(id),
          ),
        );
      },
    );
  }
}