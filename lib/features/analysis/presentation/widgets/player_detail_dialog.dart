// lib/features/analysis/presentation/widgets/player_detail_dialog.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/player_stats.dart';
import '../../../settings/domain/action_definition.dart';

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
    final displayActions = definitions.map((def) {
      final stat = player.actions[def.name];
      return MapEntry(def, stat);
    }).toList();

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: const EdgeInsets.all(0),
      clipBehavior: Clip.antiAlias,

      title: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle, size: 40, color: Colors.indigo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "#${player.playerNumber} ${player.playerName}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      "${player.matchesPlayed} 試合出場",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
        // ★修正: 縦幅を 700 に修正
        height: 700,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: displayActions.map((entry) {
                return _buildActionColumn(entry.key, entry.value);
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

  Widget _buildActionColumn(ActionDefinition def, ActionStats? stat) {
    final success = stat?.successCount ?? 0;
    final failure = stat?.failureCount ?? 0;
    final total = stat?.totalCount ?? 0;
    final subCounts = stat?.subActionCounts ?? {};

    final hasResult = def.hasSuccess || def.hasFailure;

    final successSubs = _getSortedSubActions(subCounts, def, 'success');
    final failureSubs = _getSortedSubActions(subCounts, def, 'failure');
    final defaultSubs = _getSortedSubActions(subCounts, def, 'default');

    final List<_PieSegment> segments = [];

    if (total > 0) {
      if (hasResult) {
        // --- 成功/失敗がある場合 (赤・青) ---

        // 1. 成功の内訳
        int successSubTotal = 0;
        for (int i = 0; i < successSubs.length; i++) {
          final entry = successSubs[i];
          successSubTotal += entry.value;
          final double opacity = max(0.3, 0.9 - (i * 0.15));
          segments.add(_PieSegment(
            value: entry.value,
            color: Colors.red.withOpacity(opacity),
            label: entry.key,
            category: 'success',
          ));
        }

        // 成功（詳細未設定）
        final successUnknown = success - successSubTotal;
        if (successUnknown > 0) {
          segments.add(_PieSegment(
            value: successUnknown,
            color: Colors.red.shade100.withOpacity(0.5),
            label: "",
            category: 'success_unknown',
          ));
        }

        // 2. 失敗の内訳
        int failureSubTotal = 0;
        for (int i = 0; i < failureSubs.length; i++) {
          final entry = failureSubs[i];
          failureSubTotal += entry.value;
          final double opacity = max(0.3, 0.9 - (i * 0.15));
          segments.add(_PieSegment(
            value: entry.value,
            color: Colors.blue.withOpacity(opacity),
            label: entry.key,
            category: 'failure',
          ));
        }

        // 失敗（詳細未設定）
        final failureUnknown = failure - failureSubTotal;
        if (failureUnknown > 0) {
          segments.add(_PieSegment(
            value: failureUnknown,
            color: Colors.blue.shade100.withOpacity(0.5),
            label: "",
            category: 'failure_unknown',
          ));
        }
      } else {
        // --- 単体アクションの場合 (緑) ---

        // 1. 詳細項目の内訳
        int defaultSubTotal = 0;
        for (int i = 0; i < defaultSubs.length; i++) {
          final entry = defaultSubs[i];
          defaultSubTotal += entry.value;
          // 緑系のグラデーション
          final double opacity = max(0.3, 0.9 - (i * 0.15));
          segments.add(_PieSegment(
            value: entry.value,
            color: Colors.green.withOpacity(opacity),
            label: entry.key,
            category: 'default',
          ));
        }

        // 2. 未設定分 (合計 - 詳細合計)
        final unknown = total - defaultSubTotal;
        if (unknown > 0) {
          segments.add(_PieSegment(
            value: unknown,
            color: Colors.green.shade100.withOpacity(0.5),
            label: "",
            category: 'default_unknown',
          ));
        }
      }
    }

    return Container(
      width: 350,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ① 項目名
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            color: Colors.grey[100],
            alignment: Alignment.center,
            child: Text(
              def.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  // ② 円グラフ
                  if (segments.isNotEmpty) ...[
                    SizedBox(
                      height: 220,
                      width: 220,
                      child: CustomPaint(
                        painter: _PieChartPainter(
                          segments: segments,
                          total: total,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ③ 数値データ
                  if (hasResult) ...[
                    Row(
                      children: [
                        Expanded(child: _buildStatRow("成功", success, Colors.red)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatRow("失敗", failure, Colors.blue)),
                      ],
                    ),
                    const Divider(),
                  ],
                  _buildStatRow("合計", total, Colors.black),

                  const SizedBox(height: 12),

                  // ④ 成功率
                  if (hasResult && total > 0) ...[
                    const Text("成功率", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      "${((success / total) * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ⑤ 詳細内訳
                  if (hasResult) ...[
                    const Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左側：成功の内訳
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("成功の内訳", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                              const SizedBox(height: 8),
                              if (successSubs.isEmpty)
                                const Text("-", style: TextStyle(color: Colors.grey)),
                              ...successSubs.asMap().entries.map((e) {
                                final double opacity = max(0.3, 0.9 - (e.key * 0.15));
                                return _buildSubItemRow(e.value.key, e.value.value, Colors.red.withOpacity(opacity * 0.3));
                              }),
                            ],
                          ),
                        ),
                        // 中央の区切り線
                        const VerticalDivider(width: 32, thickness: 1),
                        // 右側：失敗の内訳
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("失敗の内訳", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                              const SizedBox(height: 8),
                              if (failureSubs.isEmpty)
                                const Text("-", style: TextStyle(color: Colors.grey)),
                              ...failureSubs.asMap().entries.map((e) {
                                final double opacity = max(0.3, 0.9 - (e.key * 0.15));
                                return _buildSubItemRow(e.value.key, e.value.value, Colors.blue.withOpacity(opacity * 0.3));
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
                      child: Text(hasResult ? "その他の内訳" : "詳細内訳", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                    const SizedBox(height: 8),
                    ...defaultSubs.map((e) => _buildSubItemRow(e.key, e.value, Colors.green.withOpacity(0.1))),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
          Text("$value", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
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
        border: Border.all(color: Colors.black12),
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PieSegment {
  final int value;
  final Color color;
  final String label;
  final String category;
  _PieSegment({
    required this.value,
    required this.color,
    required this.label,
    required this.category,
  });
}

class _LabelData {
  final String text;
  final double angle;
  final Offset basePoint;
  Offset labelPoint;
  final bool isRightSide;
  final TextPainter textPainter;

  _LabelData({
    required this.text,
    required this.angle,
    required this.basePoint,
    required this.labelPoint,
    required this.isRightSide,
    required this.textPainter,
  });
}

class _PieChartPainter extends CustomPainter {
  final List<_PieSegment> segments;
  final int total;

  _PieChartPainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, (size.height / 2) + 20);
    final radius = min(size.width / 2, size.height / 2) * 0.65;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paintFill = Paint()..style = PaintingStyle.fill;

    // 区切り線は無し
    // final paintStroke = Paint()..style = PaintingStyle.stroke ...

    final linePaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    if (total == 0) {
      paintFill.color = Colors.grey.shade200;
      canvas.drawCircle(center, radius, paintFill);
      return;
    }

    double startAngle = -pi / 2;
    List<_LabelData> labels = [];

    // --- 1. セグメント描画 ---
    for (var segment in segments) {
      if (segment.value > 0) {
        final sweepAngle = (segment.value / total) * 2 * pi;

        // 塗りつぶしのみ
        paintFill.color = segment.color;
        canvas.drawArc(rect, startAngle, sweepAngle, true, paintFill);

        // ラベル情報の収集
        if (segment.label.isNotEmpty && sweepAngle > 0.05) {
          final midAngle = startAngle + (sweepAngle / 2);

          final x1 = center.dx + radius * cos(midAngle);
          final y1 = center.dy + radius * sin(midAngle);

          final x2 = center.dx + (radius + 20) * cos(midAngle);
          final y2 = center.dy + (radius + 20) * sin(midAngle);

          final isRightSide = cos(midAngle) >= 0;

          final textSpan = TextSpan(
              text: segment.label,
              style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
            textAlign: isRightSide ? TextAlign.left : TextAlign.right,
          );
          textPainter.layout();

          labels.add(_LabelData(
            text: segment.label,
            angle: midAngle,
            basePoint: Offset(x1, y1),
            labelPoint: Offset(x2, y2),
            isRightSide: isRightSide,
            textPainter: textPainter,
          ));
        }

        startAngle += sweepAngle;
      }
    }

    // --- 2. 衝突回避ロジック (Y座標の調整) ---
    List<_LabelData> rightSideLabels = labels.where((l) => l.isRightSide).toList();
    List<_LabelData> leftSideLabels = labels.where((l) => !l.isRightSide).toList();

    double? lastBottomY;
    for (var label in rightSideLabels) {
      if (lastBottomY != null) {
        if (label.labelPoint.dy < lastBottomY) {
          final newY = lastBottomY;
          label.labelPoint = Offset(label.labelPoint.dx, newY);
        }
      }
      lastBottomY = label.labelPoint.dy + label.textPainter.height + 2;
    }

    double? lastTopY;
    for (var label in leftSideLabels) {
      if (lastTopY != null) {
        final currentBottom = label.labelPoint.dy + label.textPainter.height;
        if (currentBottom > lastTopY) {
          final newY = lastTopY - label.textPainter.height;
          label.labelPoint = Offset(label.labelPoint.dx, newY);
        }
      }
      lastTopY = label.labelPoint.dy - 2;
    }

    // --- 3. 引き出し線とテキストの描画 ---
    for (var label in labels) {
      final x3 = label.isRightSide
          ? label.labelPoint.dx + 20
          : label.labelPoint.dx - 20;
      final y3 = label.labelPoint.dy + (label.textPainter.height / 2);

      final path = Path()
        ..moveTo(label.basePoint.dx, label.basePoint.dy)
        ..lineTo(label.labelPoint.dx, y3)
        ..lineTo(x3, y3);

      canvas.drawPath(path, linePaint);

      final textOffset = Offset(
        label.isRightSide ? x3 + 4 : x3 - label.textPainter.width - 4,
        label.labelPoint.dy,
      );
      label.textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.segments.length != segments.length;
  }
}