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
              _buildList(courtPlayers),
              _buildList(benchPlayers),
              _buildList(absentPlayers),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<String> players) {
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
          child: ListTile(
            title: Text(
                number,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center
            ),
            subtitle: name.isNotEmpty
                ? Text(name, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)
                : null,
            onTap: () => onPlayerTap(number),
            onLongPress: () => onPlayerLongPress(number),
          ),
        );
      },
    );
  }
}