// lib/features/analysis/presentation/widgets/analysis_print_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/analysis_controller.dart';
import '../../domain/player_stats.dart';
import 'analysis_table_helper.dart';

class AnalysisPrintView extends ConsumerWidget {
  final AsyncValue<List<PlayerStats>> asyncStats;
  final String teamName;
  final String periodLabel;

  const AnalysisPrintView({
    super.key,
    required this.asyncStats,
    required this.teamName,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncStats.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (stats) => _buildPrintableTable(context, ref, stats),
    );
  }

  Widget _buildPrintableTable(BuildContext context, WidgetRef ref, List<PlayerStats> originalStats) {
    // 印刷時は試合数0の選手は除外する
    final filteredStats = originalStats.where((s) => s.matchesPlayed > 0).toList();
    if (filteredStats.isEmpty) return const SizedBox(width: 100, height: 100);

    // カラム定義の生成
    final columnSpecs = AnalysisTableHelper.generateColumnSpecs(
        filteredStats,
        ref.read(analysisControllerProvider.notifier).actionDefinitions
    );

    // ソート
    final sortedStats = List<PlayerStats>.from(filteredStats);
    sortedStats.sort((a, b) => (int.tryParse(a.playerNumber) ?? 999).compareTo(int.tryParse(b.playerNumber) ?? 999));

    // テーブルボディの生成 (タップ不可)
    final rows = AnalysisTableHelper.buildTableRows(
      sortedStats,
      columnSpecs,
      rowHeight: 30.0,
      fontSize: 11.0,
      onTap: null,
    );

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(teamName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(periodLabel, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 10),
          AnalysisTableHelper.buildTableHeader(columnSpecs),
          const Divider(height: 1, thickness: 1),
          Column(children: rows),
        ],
      ),
    );
  }
}