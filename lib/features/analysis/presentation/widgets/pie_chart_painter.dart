// lib/features/analysis/presentation/widgets/pie_chart_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';

/// 円グラフの1つのセグメントデータ
class PieSegment {
  final int value;
  final Color color;
  final String label;
  final String category;

  PieSegment({
    required this.value,
    required this.color,
    required this.label,
    required this.category,
  });
}

/// ラベル配置計算用（内部クラス）
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

class PieChartPainter extends CustomPainter {
  final List<PieSegment> segments;
  final int total;

  PieChartPainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, (size.height / 2) + 20);
    final radius = min(size.width / 2, size.height / 2) * 0.65;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paintFill = Paint()..style = PaintingStyle.fill;

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
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.segments.length != segments.length;
  }
}