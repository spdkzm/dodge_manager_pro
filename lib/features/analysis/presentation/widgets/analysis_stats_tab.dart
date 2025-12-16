// lib/features/analysis/presentation/widgets/analysis_stats_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/analysis_controller.dart';
import '../../domain/player_stats.dart';
import 'analysis_table_helper.dart';
import 'player_detail_dialog.dart';

class AnalysisStatsTab extends ConsumerWidget {
  final AsyncValue<List<PlayerStats>> asyncStats;

  const AnalysisStatsTab({super.key, required this.asyncStats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncStats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("エラー: $err")),
      data: (stats) {
        if (stats.isEmpty) return const Center(child: Text("データがありません"));
        return _buildDataTable(context, ref, stats);
      },
    );
  }

  Widget _buildDataTable(BuildContext context, WidgetRef ref, List<PlayerStats> originalStats) {
    // カラム定義の生成
    final columnSpecs = AnalysisTableHelper.generateColumnSpecs(
        originalStats,
        ref.read(analysisControllerProvider.notifier).actionDefinitions
    );

    // ソート
    final sortedStats = List<PlayerStats>.from(originalStats);
    sortedStats.sort((a, b) => (int.tryParse(a.playerNumber) ?? 999).compareTo(int.tryParse(b.playerNumber) ?? 999));

    // テーブルボディの生成
    final rows = AnalysisTableHelper.buildTableRows(
      sortedStats,
      columnSpecs,
      rowHeight: 40.0,
      fontSize: 13.0,
      onTap: (player) => _showPlayerDetail(context, ref, player),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnalysisTableHelper.buildTableHeader(columnSpecs),
            const Divider(height: 1, thickness: 1),
            Column(children: rows),
          ],
        ),
      ),
    );
  }

  void _showPlayerDetail(BuildContext context, WidgetRef ref, PlayerStats player) {
    final controller = ref.read(analysisControllerProvider.notifier);
    final definitions = controller.actionDefinitions;
    showDialog(
      context: context,
      builder: (context) => PlayerDetailDialog(
        player: player,
        definitions: definitions,
      ),
    );
  }
}