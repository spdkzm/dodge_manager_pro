// lib/features/analysis/presentation/widgets/action_detail_column.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/player_stats.dart';
import '../../../settings/domain/action_definition.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import 'pie_chart_painter.dart';

class ActionDetailColumn extends StatelessWidget {
  final ActionDefinition definition;
  final ActionStats? stats;

  const ActionDetailColumn({
    super.key,
    required this.definition,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final success = stats?.successCount ?? 0;
    final failure = stats?.failureCount ?? 0;
    final total = stats?.totalCount ?? 0;
    final subCounts = stats?.subActionCounts ?? {};

    final hasResult = definition.hasSuccess || definition.hasFailure;

    final successSubs = _getSortedSubActions(subCounts, definition, AppConstants.categorySuccess);
    final failureSubs = _getSortedSubActions(subCounts, definition, AppConstants.categoryFailure);
    final defaultSubs = _getSortedSubActions(subCounts, definition, AppConstants.categoryDefault);

    final List<PieSegment> segments = [];

    if (total > 0) {
      if (hasResult) {
        // --- 成功/失敗がある場合 ---
        int successSubTotal = 0;
        for (int i = 0; i < successSubs.length; i++) {
          final entry = successSubs[i];
          successSubTotal += entry.value;
          final double opacity = max(0.3, 0.9 - (i * 0.15));
          segments.add(PieSegment(
            value: entry.value,
            color: AppColors.success.withOpacity(opacity),
            label: entry.key,
            category: AppConstants.categorySuccess,
          ));
        }

        final successUnknown = success - successSubTotal;
        if (successUnknown > 0) {
          segments.add(PieSegment(
            value: successUnknown,
            // ★修正: shade100 を廃止し、透明度で調整
            color: AppColors.success.withOpacity(0.1),
            label: "",
            category: '${AppConstants.categorySuccess}_unknown',
          ));
        }

        int failureSubTotal = 0;
        for (int i = 0; i < failureSubs.length; i++) {
          final entry = failureSubs[i];
          failureSubTotal += entry.value;
          final double opacity = max(0.3, 0.9 - (i * 0.15));
          segments.add(PieSegment(
            value: entry.value,
            color: AppColors.failure.withOpacity(opacity),
            label: entry.key,
            category: AppConstants.categoryFailure,
          ));
        }

        final failureUnknown = failure - failureSubTotal;
        if (failureUnknown > 0) {
          segments.add(PieSegment(
            value: failureUnknown,
            // ★修正: shade100 を廃止し、透明度で調整
            color: AppColors.failure.withOpacity(0.1),
            label: "",
            category: '${AppConstants.categoryFailure}_unknown',
          ));
        }
      } else {
        // --- 単体アクションの場合 ---
        int defaultSubTotal = 0;
        for (int i = 0; i < defaultSubs.length; i++) {
          final entry = defaultSubs[i];
          defaultSubTotal += entry.value;
          final double opacity = max(0.3, 0.9 - (i * 0.15));
          segments.add(PieSegment(
            value: entry.value,
            color: AppColors.defaultAction.withOpacity(opacity),
            label: entry.key,
            category: AppConstants.categoryDefault,
          ));
        }

        final unknown = total - defaultSubTotal;
        if (unknown > 0) {
          segments.add(PieSegment(
            value: unknown,
            color: AppColors.defaultAction.withOpacity(0.1),
            label: "",
            category: '${AppConstants.categoryDefault}_unknown',
          ));
        }
      }
    }

    return Container(
      width: 350,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            color: AppColors.backgroundLight,
            alignment: Alignment.center,
            child: Text(
              definition.name,
              style: AppTextStyles.headerMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  if (segments.isNotEmpty) ...[
                    SizedBox(
                      height: 220,
                      width: 220,
                      child: CustomPaint(
                        painter: PieChartPainter(
                          segments: segments,
                          total: total,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (hasResult) ...[
                    Row(
                      children: [
                        Expanded(child: _buildStatRow("成功", success, AppColors.success)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatRow("失敗", failure, AppColors.failure)),
                      ],
                    ),
                    const Divider(),
                  ],
                  _buildStatRow("合計", total, AppColors.textMain),

                  const SizedBox(height: 12),

                  if (hasResult && total > 0) ...[
                    const Text("成功率", style: AppTextStyles.labelSmall),
                    Text(
                      "${((success / total) * 100).toStringAsFixed(1)}%",
                      style: AppTextStyles.percentageLarge,
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (hasResult) ...[
                    const Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("成功の内訳", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                              const SizedBox(height: 8),
                              if (successSubs.isEmpty)
                                const Text("-", style: AppTextStyles.labelSmall),
                              ...successSubs.asMap().entries.map((e) {
                                final double opacity = max(0.3, 0.9 - (e.key * 0.15));
                                return _buildSubItemRow(e.value.key, e.value.value, AppColors.success.withOpacity(opacity * 0.3));
                              }),
                            ],
                          ),
                        ),
                        const VerticalDivider(width: 32, thickness: 1),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("失敗の内訳", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.failure)),
                              const SizedBox(height: 8),
                              if (failureSubs.isEmpty)
                                const Text("-", style: AppTextStyles.labelSmall),
                              ...failureSubs.asMap().entries.map((e) {
                                final double opacity = max(0.3, 0.9 - (e.key * 0.15));
                                return _buildSubItemRow(e.value.key, e.value.value, AppColors.failure.withOpacity(opacity * 0.3));
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (defaultSubs.isNotEmpty) ...[
                    const Divider(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          hasResult ? "その他の内訳" : "詳細内訳",
                          style: AppTextStyles.labelBold.copyWith(color: hasResult ? AppColors.textSub : AppColors.defaultAction)
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...defaultSubs.map((e) => _buildSubItemRow(e.key, e.value, AppColors.backgroundLight)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, int>> _getSortedSubActions(
      Map<String, int> counts,
      ActionDefinition def,
      String category
      ) {
    final targetNames = def.subActions
        .where((s) => s.category == category)
        .map((s) => s.name)
        .toSet();

    final filtered = counts.entries
        .where((e) => targetNames.contains(e.key))
        .toList();

    filtered.sort((a, b) => b.value.compareTo(a.value));

    return filtered;
  }

  Widget _buildStatRow(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.black87.withOpacity(0.7))),
          Text("$value", style: AppTextStyles.statValue.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildSubItemRow(String name, int count, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "$count",
            style: AppTextStyles.labelBold,
          ),
        ],
      ),
    );
  }
}