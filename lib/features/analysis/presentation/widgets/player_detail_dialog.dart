// lib/features/analysis/presentation/widgets/player_detail_dialog.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/player_stats.dart';
import '../../../settings/domain/action_definition.dart';
import '../../../../core/theme/app_theme.dart';
import 'action_detail_column.dart';

class PlayerDetailDialog extends StatelessWidget {
  final PlayerStats player;
  final List<ActionDefinition> definitions;

  const PlayerDetailDialog({
    super.key,
    required this.player,
    required this.definitions,
  });

  @override
  Widget build(BuildContext context) {
    // フィルタリング条件:
    // 1. 実績がある (totalCount > 0)
    // 2. かつ、サブアクション(内訳)の定義がある (subActions.isNotEmpty)
    final displayActions = definitions.map((def) {
      final stat = player.actions[def.name];
      return MapEntry(def, stat);
    }).where((entry) {
      final def = entry.key;
      final stat = entry.value;
      return (stat != null && stat.totalCount > 0) && def.subActions.isNotEmpty;
    }).toList();

    final size = MediaQuery.of(context).size;
    final dialogHeight = min(size.height * 0.85, 800.0);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: const EdgeInsets.all(0),
      clipBehavior: Clip.antiAlias,

      title: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle, size: 40, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "#${player.playerNumber} ${player.playerName}",
                      style: AppTextStyles.titleLarge,
                    ),
                    Text(
                      "${player.matchesPlayed} 試合出場",
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
        ],
      ),

      content: SizedBox(
        width: double.maxFinite,
        height: 700,
        child: displayActions.isEmpty
            ? const Center(child: Text("表示するデータがありません"))
            : Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: displayActions.map((entry) {
                return ActionDetailColumn(
                  definition: entry.key,
                  stats: entry.value,
                );
              }).toList(),
            ),
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("閉じる"),
        ),
      ],
    );
  }
}