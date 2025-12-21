// lib/features/game_record/presentation/widgets/game_operation_panel.dart
import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../../../settings/domain/action_definition.dart'; // SubActionDefinition
import '../../application/game_recorder_controller.dart'; // PlayerDisplayInfo

class GameOperationPanel extends StatelessWidget {
  final List<UIActionItem?> uiActions;
  final int gridColumns;
  final bool hasMatchStarted;

  // ★変更: IDを受け取る
  final String? selectedPlayerId;
  final PlayerDisplayInfo? Function(String) playerInfoGetter;

  final UIActionItem? selectedUIAction;
  final SubActionDefinition? selectedSubAction;
  final ActionResult selectedResult;

  final Function(UIActionItem) onActionSelected;
  final Function(ActionResult) onResultSelected;
  final Function(SubActionDefinition) onSubActionSelected;
  final VoidCallback onConfirm;

  const GameOperationPanel({
    super.key,
    required this.uiActions,
    required this.gridColumns,
    required this.hasMatchStarted,
    required this.selectedPlayerId,
    required this.playerInfoGetter,
    required this.selectedUIAction,
    required this.selectedSubAction,
    required this.selectedResult,
    required this.onActionSelected,
    required this.onResultSelected,
    required this.onSubActionSelected,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildConfirmBar(),
          Expanded(
            flex: 2,
            child: Opacity(
              opacity: 1.0,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridColumns,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: uiActions.length,
                itemBuilder: (context, index) {
                  final action = uiActions[index];
                  if (action == null) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }
                  return _buildButton(action, action.fixedResult);
                },
              ),
            ),
          ),

          if (selectedUIAction != null && selectedUIAction!.subActions.isNotEmpty) ...[
            const Divider(),
            Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 4), child: Text("詳細 (${selectedUIAction!.isSubRequired ? '必須' : '任意'}):", style: TextStyle(fontWeight: FontWeight.bold, color: selectedUIAction!.isSubRequired ? Colors.red : Colors.grey))),
            Expanded(flex: 1, child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 2.0, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: selectedUIAction!.subActions.length, itemBuilder: (context, index) {
              final sub = selectedUIAction!.subActions[index];
              final isSelected = selectedSubAction?.id == sub.id;
              return OutlinedButton(style: OutlinedButton.styleFrom(backgroundColor: isSelected ? Colors.indigoAccent : Colors.white, foregroundColor: isSelected ? Colors.white : Colors.black87), onPressed: () => onSubActionSelected(sub), child: Text(sub.name));
            })),
          ]
        ],
      ),
    );
  }

  Widget _buildButton(UIActionItem action, ActionResult result) {
    final isSelected = selectedUIAction?.parentName == action.parentName && selectedResult == result;
    Color? bgCol = Colors.white;
    if (result == ActionResult.success) bgCol = Colors.red.shade50;
    if (result == ActionResult.failure) bgCol = Colors.blue.shade50;
    if (isSelected) bgCol = Colors.orange.shade100;

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgCol,
          foregroundColor: Colors.black87,
          side: isSelected ? const BorderSide(color: Colors.orange, width: 3) : BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        onPressed: () => onActionSelected(action),
        child: Text(action.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildConfirmBar() {
    // ★修正: 表示情報を解決
    String playerText = "-";
    if (selectedPlayerId != null) {
      final info = playerInfoGetter(selectedPlayerId!);
      if (info != null) {
        playerText = "${info.number} (${info.name})";
      } else {
        playerText = "不明な選手";
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.indigo.shade200),
        borderRadius: BorderRadius.circular(12),
        color: Colors.indigo.shade50,
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text("選手:", style: TextStyle(color: Colors.grey)),
                Text(playerText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_right, color: Colors.grey),
                const SizedBox(width: 16),
                const Text("プレー:", style: TextStyle(color: Colors.grey)),
                Text(selectedUIAction?.parentName ?? "-", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (selectedResult != ActionResult.none) ...[const SizedBox(width: 8), Chip(label: Text(selectedResult == ActionResult.success ? "成功" : "失敗"), backgroundColor: selectedResult == ActionResult.success ? Colors.red.shade100 : Colors.blue.shade100, padding: EdgeInsets.zero)],
                if (selectedSubAction != null) ...[const SizedBox(width: 8), Chip(label: Text(selectedSubAction!.name), backgroundColor: Colors.white, padding: EdgeInsets.zero)]
              ],
            ),
          ),
          ElevatedButton.icon(
              onPressed: (selectedPlayerId != null && selectedUIAction != null) ? onConfirm : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              icon: const Icon(Icons.check_circle),
              label: const Text("確定", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}