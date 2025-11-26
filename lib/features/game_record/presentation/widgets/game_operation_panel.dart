// lib/features/game_record/presentation/widgets/game_operation_panel.dart
import 'package:flutter/material.dart';
import '../../domain/models.dart';

class GameOperationPanel extends StatelessWidget {
  // ★変更: nullableのリスト
  final List<UIActionItem?> uiActions;
  final int gridColumns;
  final bool hasMatchStarted;

  final String? selectedPlayer;
  final Map<String, String> playerNames;
  final UIActionItem? selectedUIAction;
  final String? selectedSubAction;
  final ActionResult selectedResult;

  final Function(UIActionItem) onActionSelected;
  final Function(ActionResult) onResultSelected;
  final Function(String) onSubActionSelected;
  final VoidCallback onConfirm;

  const GameOperationPanel({
    super.key,
    required this.uiActions,
    required this.gridColumns,
    required this.hasMatchStarted,
    required this.selectedPlayer,
    required this.playerNames,
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
            child: IgnorePointer(
              ignoring: !hasMatchStarted,
              child: Opacity(
                opacity: hasMatchStarted ? 1.0 : 0.5,
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

                    // ★空白スロット
                    if (action == null) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }

                    // ★両方(成功/失敗)ある場合は縦に分割して2つのボタンを表示
                    if (action.hasSuccess && action.hasFailure) {
                      return Column(
                        children: [
                          Expanded(child: _buildButton(action, ActionResult.success)),
                          const SizedBox(height: 4),
                          Expanded(child: _buildButton(action, ActionResult.failure)),
                        ],
                      );
                    }

                    // 通常の1ボタン
                    return _buildButton(action, action.fixedResult);
                  },
                ),
              ),
            ),
          ),
          // ... (詳細選択部分は変更なし)
          if (selectedUIAction != null && selectedUIAction!.subActions.isNotEmpty) ...[
            const Divider(),
            Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 4), child: Text("詳細 (${selectedUIAction!.isSubRequired ? '必須' : '任意'}):", style: TextStyle(fontWeight: FontWeight.bold, color: selectedUIAction!.isSubRequired ? Colors.red : Colors.grey))),
            Expanded(flex: 1, child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 2.0, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: selectedUIAction!.subActions.length, itemBuilder: (context, index) {
              final sub = selectedUIAction!.subActions[index];
              final isSelected = selectedSubAction == sub;
              return OutlinedButton(style: OutlinedButton.styleFrom(backgroundColor: isSelected ? Colors.indigoAccent : Colors.white, foregroundColor: isSelected ? Colors.white : Colors.black87), onPressed: () => onSubActionSelected(sub), child: Text(sub));
            })),
          ]
        ],
      ),
    );
  }

  Widget _buildButton(UIActionItem action, ActionResult result) {
    // 結果に応じたアクションクローンを作る（選択状態管理のため）
    // 実際にはonActionSelectedで渡すときに適切なResultをセットして呼ぶ必要があるが、
    // UIActionItem自体はイミュータブルなので、ここではタップ時にResultを上書きするロジックをControllerに持たせるか、
    // ここで擬似的なアイテムを作って渡す。

    // 簡易的に、タップされたら「その結果を持つアイテム」として扱う
    final targetAction = action.copyWith(fixedResult: result);
    final isSelected = selectedUIAction?.parentName == action.parentName && selectedResult == result;

    Color? bgCol = Colors.white;
    if (result == ActionResult.success) bgCol = Colors.red.shade50;
    if (result == ActionResult.failure) bgCol = Colors.blue.shade50;
    if (isSelected) bgCol = Colors.orange.shade100;

    String label = action.name;
    if (action.hasSuccess && action.hasFailure) {
      label = result == ActionResult.success ? "成功" : "失敗";
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgCol,
          foregroundColor: Colors.black87,
          side: isSelected ? const BorderSide(color: Colors.orange, width: 3) : BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero, // 詰め込むため
        ),
        onPressed: () => onActionSelected(targetAction),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // _buildConfirmBarは変更なし
  Widget _buildConfirmBar() {
    // (前回のコードと同じ内容)
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
                Text(selectedPlayer != null ? "$selectedPlayer ${playerNames[selectedPlayer] != null ? '(${playerNames[selectedPlayer]})' : ''}" : "-", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_right, color: Colors.grey),
                const SizedBox(width: 16),
                const Text("プレー:", style: TextStyle(color: Colors.grey)),
                Text(selectedUIAction?.parentName ?? "-", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (selectedResult != ActionResult.none) ...[const SizedBox(width: 8), Chip(label: Text(selectedResult == ActionResult.success ? "成功" : "失敗"), backgroundColor: selectedResult == ActionResult.success ? Colors.red.shade100 : Colors.blue.shade100, padding: EdgeInsets.zero)],
                if (selectedSubAction != null) ...[const SizedBox(width: 8), Chip(label: Text(selectedSubAction!), backgroundColor: Colors.white, padding: EdgeInsets.zero)]
              ],
            ),
          ),
          ElevatedButton.icon(onPressed: (hasMatchStarted && selectedPlayer != null && selectedUIAction != null) ? onConfirm : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), icon: const Icon(Icons.check_circle), label: const Text("確定", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}