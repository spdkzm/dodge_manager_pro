// lib/features/analysis/presentation/widgets/analysis_table_helper.dart
import 'package:flutter/material.dart';
import '../../domain/player_stats.dart';
import '../../../settings/domain/action_definition.dart';

enum StatColumnType { number, name, matches, successCount, failureCount, successRate, totalCount }

class ColumnSpec {
  final String label;
  final StatColumnType type;
  final String? actionName;
  final bool isFixed;
  ColumnSpec({required this.label, required this.type, this.actionName, this.isFixed = false});
}

class AnalysisTableHelper {
  /// カラム仕様を生成する共通メソッド
  static List<ColumnSpec> generateColumnSpecs(List<PlayerStats> stats, List<ActionDefinition> definitions) {
    final List<ColumnSpec> columnSpecs = [];
    // 固定カラム
    columnSpecs.add(ColumnSpec(label: "背番号", type: StatColumnType.number, isFixed: true));
    columnSpecs.add(ColumnSpec(label: "コートネーム", type: StatColumnType.name, isFixed: true));
    columnSpecs.add(ColumnSpec(label: "試合数", type: StatColumnType.matches, isFixed: true));

    // データ内に存在するアクション名を収集
    final dataActionNames = <String>{};
    for (var p in stats) {
      dataActionNames.addAll(p.actions.keys);
    }

    // 定義済みアクション + 未定義だがデータにあるアクション
    final displayDefinitions = List<ActionDefinition>.from(definitions);
    final definedNames = definitions.map((d) => d.name).toSet();
    for (var name in dataActionNames) {
      if (!definedNames.contains(name)) {
        displayDefinitions.add(ActionDefinition(name: name, subActions: []));
      }
    }

    // アクションごとのカラム追加
    for (var action in displayDefinitions) {
      if (action.hasSuccess && action.hasFailure) {
        columnSpecs.add(ColumnSpec(label: "成功", type: StatColumnType.successCount, actionName: action.name));
        columnSpecs.add(ColumnSpec(label: "失敗", type: StatColumnType.failureCount, actionName: action.name));
        columnSpecs.add(ColumnSpec(label: "成功率", type: StatColumnType.successRate, actionName: action.name));
      } else if (action.hasSuccess) {
        columnSpecs.add(ColumnSpec(label: "成功数", type: StatColumnType.successCount, actionName: action.name));
      } else if (action.hasFailure) {
        columnSpecs.add(ColumnSpec(label: "失敗数", type: StatColumnType.failureCount, actionName: action.name));
      } else {
        columnSpecs.add(ColumnSpec(label: "数", type: StatColumnType.totalCount, actionName: action.name));
      }
    }
    return columnSpecs;
  }

  /// テーブルのデータ行(Rowのリスト)を生成する共通メソッド
  static List<Widget> buildTableRows(
      List<PlayerStats> sortedStats,
      List<ColumnSpec> columnSpecs, {
        required double rowHeight,
        required double fontSize,
        Function(PlayerStats)? onTap,
      }) {
    const fixedWidth = 90.0;
    const dynamicWidth = 60.0;
    final cellStyle = TextStyle(fontSize: fontSize, color: Colors.black87);

    return sortedStats.asMap().entries.map((entry) {
      final playerRowIndex = entry.key;
      final player = entry.value;
      final List<Widget> cells = [];

      for (final spec in columnSpecs) {
        final isFixed = spec.isFixed;
        final stat = player.actions[spec.actionName];
        String text = '-';

        if (spec.type == StatColumnType.number) text = player.playerNumber;
        if (spec.type == StatColumnType.name) text = player.playerName;
        if (spec.type == StatColumnType.matches) text = player.matchesPlayed.toString();

        if (!isFixed) {
          if (stat != null) {
            switch (spec.type) {
              case StatColumnType.successCount:
              case StatColumnType.failureCount:
              case StatColumnType.totalCount:
                text = (spec.type == StatColumnType.totalCount
                    ? stat.totalCount
                    : (spec.type == StatColumnType.successCount ? stat.successCount : stat.failureCount))
                    .toString();
                break;
              case StatColumnType.successRate:
                text = stat.totalCount > 0 ? "${stat.successRate.toStringAsFixed(0)}%" : "-";
                break;
              default:
                text = '0';
                break;
            }
          } else {
            if (spec.type == StatColumnType.successRate) {
              text = '-';
            } else {
              text = '0';
            }
          }
        }

        Color? bgColor = playerRowIndex.isOdd ? Colors.grey.shade100 : Colors.white;

        cells.add(
          Container(
            width: isFixed ? fixedWidth : dynamicWidth,
            height: rowHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
              color: bgColor,
            ),
            child: Text(text, style: cellStyle),
          ),
        );
      }

      if (onTap != null) {
        return InkWell(
          onTap: () => onTap(player),
          child: Row(children: cells),
        );
      } else {
        return Row(children: cells);
      }
    }).toList();
  }

  /// テーブルヘッダーを生成する共通メソッド
  static Widget buildTableHeader(List<ColumnSpec> columnSpecs) {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87);
    const headerHeight = 40.0;
    const fixedWidth = 90.0;
    const dynamicWidth = 60.0;

    final fixedSpecs = columnSpecs.where((s) => s.isFixed).toList();
    final dynamicSpecs = columnSpecs.where((s) => !s.isFixed).toList();

    final List<Widget> topRowCells = [];
    topRowCells.addAll(fixedSpecs.map((_) => SizedBox(width: fixedWidth, height: headerHeight)));

    String? currentActionName;
    int currentActionColumnCount = 0;

    for (int i = 0; i < dynamicSpecs.length; i++) {
      final spec = dynamicSpecs[i];
      if (spec.actionName != currentActionName) {
        if (currentActionName != null) {
          topRowCells.add(Container(
              width: dynamicWidth * currentActionColumnCount,
              height: headerHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[200]),
              child: Text(currentActionName, style: headerStyle, textAlign: TextAlign.center)));
        }
        currentActionName = spec.actionName;
        currentActionColumnCount = 1;
      } else {
        currentActionColumnCount++;
      }

      if (i == dynamicSpecs.length - 1 || (i + 1 < dynamicSpecs.length && dynamicSpecs[i + 1].actionName != currentActionName)) {
        topRowCells.add(Container(
            width: dynamicWidth * currentActionColumnCount,
            height: headerHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[200]),
            child: Text(currentActionName!, style: headerStyle, textAlign: TextAlign.center)));
        currentActionName = null;
        currentActionColumnCount = 0;
      }
    }

    final List<Widget> bottomRowCells = [];
    for (final spec in fixedSpecs) {
      bottomRowCells.add(Container(
          width: fixedWidth,
          height: headerHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[200]),
          child: Text(spec.label, style: headerStyle, textAlign: TextAlign.center)));
    }
    for (final spec in dynamicSpecs) {
      bottomRowCells.add(Container(
          width: dynamicWidth,
          height: headerHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[100]),
          child: Text(spec.label, style: headerStyle, textAlign: TextAlign.center, maxLines: 1)));
    }

    return Column(children: [Row(children: topRowCells), Row(children: bottomRowCells)]);
  }
}