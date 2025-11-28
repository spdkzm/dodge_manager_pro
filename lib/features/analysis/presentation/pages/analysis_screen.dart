// lib/features/analysis/presentation/pages/analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/analysis_controller.dart';
import '../../domain/player_stats.dart';

import '../../../settings/domain/action_definition.dart';
import '../../../settings/data/action_dao.dart';
import '../../../team_mgmt/application/team_store.dart';

// 集計項目の種類 (totalCountを復活)
enum StatColumnType {
  number,       // 背番号
  name,         // コートネーム
  matches,      // 試合数
  successCount, // 成功数
  failureCount, // 失敗数
  successRate,  // 成功率
  totalCount,   // ★復活: 合計回数
}

// 列設定モデル
class _ColumnSpec {
  final String label;
  final StatColumnType type;
  final String? actionName;
  final bool isFixed; // 固定列か否か

  _ColumnSpec({
    required this.label,
    required this.type,
    this.actionName,
    this.isFixed = false,
  });
}

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});
  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {

  List<String> _sortedActionNames = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActionOrder();
      _runAnalysis();
    });
  }

  Future<void> _loadActionOrder() async {
    final store = ref.read(teamStoreProvider);
    if (!store.isLoaded) await store.loadFromDb();

    if (store.currentTeam != null) {
      final actions = await ActionDao().getActionDefinitions(store.currentTeam!.id);
      if (mounted) {
        setState(() {
          _sortedActionNames = actions.map((m) => m['name'] as String).toList();
        });
      }
    }
  }

  void _runAnalysis() {
    ref.read(analysisControllerProvider.notifier).analyze();
  }

  @override
  Widget build(BuildContext context) {
    final asyncStats = ref.watch(analysisControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("データ分析 (累計)"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _runAnalysis),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: asyncStats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("エラー: $err")),
              data: (stats) {
                if (stats.isEmpty) return const Center(child: Text("データがありません"));
                return _buildDataTable(stats);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- テーブル構築 ---
  Widget _buildDataTable(List<PlayerStats> originalStats) {
    final controller = ref.read(analysisControllerProvider.notifier);

    // 1. カラム決定と 2. カラム構造の定義
    final List<_ColumnSpec> columnSpecs = [];
    final definitions = controller.actionDefinitions;

    // ★固定列 (ヘッダー結合) - ラベルを修正
    columnSpecs.add(_ColumnSpec(label: "背番号", type: StatColumnType.number, isFixed: true));
    columnSpecs.add(_ColumnSpec(label: "コートネーム", type: StatColumnType.name, isFixed: true));
    columnSpecs.add(_ColumnSpec(label: "試合数", type: StatColumnType.matches, isFixed: true));

    // 動的列: 定義されたアクションとデータに含まれるアクションを結合
    final dataActionNames = <String>{};
    for (var p in originalStats) dataActionNames.addAll(p.actions.keys);

    final displayDefinitions = List<ActionDefinition>.from(definitions);
    final definedNames = definitions.map((d) => d.name).toSet();
    for (var name in dataActionNames) {
      if (!definedNames.contains(name)) {
        displayDefinitions.add(ActionDefinition(name: name, hasSuccess: false, hasFailure: false));
      }
    }

    // ★動的列生成ロジック (成功/失敗フラグに依存)
    for (var action in displayDefinitions) {
      // 成功と失敗の両方がある場合: 成功, 失敗, 成功率 (3列)
      if (action.hasSuccess && action.hasFailure) {
        columnSpecs.add(_ColumnSpec(label: "成功", type: StatColumnType.successCount, actionName: action.name));
        columnSpecs.add(_ColumnSpec(label: "失敗", type: StatColumnType.failureCount, actionName: action.name));
        columnSpecs.add(_ColumnSpec(label: "成功率", type: StatColumnType.successRate, actionName: action.name));
      }
      // 成功のみの場合: 成功数 (1列)
      else if (action.hasSuccess) {
        columnSpecs.add(_ColumnSpec(label: "成功数", type: StatColumnType.successCount, actionName: action.name));
      }
      // 失敗のみの場合: 失敗数 (1列)
      else if (action.hasFailure) {
        columnSpecs.add(_ColumnSpec(label: "失敗数", type: StatColumnType.failureCount, actionName: action.name));
      }
      // ★修正: どちらもなしの場合: 合計回数(数)を表示する
      else {
        columnSpecs.add(_ColumnSpec(label: "数", type: StatColumnType.totalCount, actionName: action.name));
      }
    }

    // 3. ソート処理: 背番号順に固定
    final sortedStats = List<PlayerStats>.from(originalStats);
    sortedStats.sort((a, b) => (int.tryParse(a.playerNumber) ?? 99999).compareTo(int.tryParse(b.playerNumber) ?? 99999));

    // 4. ハイライト計算: 削除済み
    final maxValues = <String, Map<StatColumnType, double>>{};


    // 5. Widget生成 (カスタムTable構造)
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTableHeader(columnSpecs),
            const Divider(height: 1, thickness: 1),
            _buildTableBody(sortedStats, columnSpecs, maxValues),
          ],
        ),
      ),
    );
  }

  // --- カスタムヘッダー描画 (二段組と結合) ---
  Widget _buildTableHeader(List<_ColumnSpec> columnSpecs) {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87);
    const headerHeight = 40.0;
    const fixedWidth = 90.0;
    const dynamicWidth = 60.0;

    // 固定列と動的列を分ける
    final fixedSpecs = columnSpecs.where((s) => s.isFixed).toList();
    final dynamicSpecs = columnSpecs.where((s) => !s.isFixed).toList();

    // 1. 上段ヘッダー (アクション名): 固定列部分は空白
    final List<Widget> topRowCells = [];

    // 固定列の空白セル
    topRowCells.addAll(fixedSpecs.map((_) => SizedBox(width: fixedWidth, height: headerHeight)));

    // 動的列の上段 (アクション名)
    String? currentActionName;
    int currentActionColumnCount = 0;

    for (int i = 0; i < dynamicSpecs.length; i++) {
      final spec = dynamicSpecs[i];

      // アクション名が変わった、または最初のカラムの場合
      if (spec.actionName != currentActionName) {
        // 前のアクションが完了していたら、そのウィジェットを確定させる
        if (currentActionName != null) {
          topRowCells.add(
            Container(
              width: dynamicWidth * currentActionColumnCount,
              height: headerHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[200]),
              child: Text(currentActionName!, style: headerStyle, textAlign: TextAlign.center),
            ),
          );
        }
        currentActionName = spec.actionName;
        currentActionColumnCount = 1;
      } else {
        currentActionColumnCount++;
      }

      // 最後の要素の場合、または次の要素のアクション名が異なる場合
      if (i == dynamicSpecs.length - 1 || (i + 1 < dynamicSpecs.length && dynamicSpecs[i + 1].actionName != currentActionName)) {
        topRowCells.add(
          Container(
            width: dynamicWidth * currentActionColumnCount,
            height: headerHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[200]),
            child: Text(currentActionName!, style: headerStyle, textAlign: TextAlign.center),
          ),
        );
        currentActionName = null; // リセット
        currentActionColumnCount = 0;
      }
    }

    // 2. 下段ヘッダー (項目名: 成功/失敗/成功率)
    final List<Widget> bottomRowCells = [];

    // 固定列の結合セル (Rowspan=2)
    for (final spec in fixedSpecs) {
      bottomRowCells.add(
        Container(
          width: fixedWidth,
          height: headerHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[200]),
          child: Text(spec.label, style: headerStyle, textAlign: TextAlign.center),
        ),
      );
    }

    // 動的列の下段 (項目名)
    for (final spec in dynamicSpecs) {
      bottomRowCells.add(
        Container(
          width: dynamicWidth,
          height: headerHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey[100],
          ),
          child: Text(spec.label, style: headerStyle, textAlign: TextAlign.center, maxLines: 1),
        ),
      );
    }

    // 描画: Row1 (Action Title)と Row2 (Sub Title/Fixed Title)を縦に並べる
    return Column(
      children: [
        // Row 1: 上段 (固定列は空白、動的列は結合タイトル)
        Row(children: topRowCells),
        // Row 2: 下段 (固定列はタイトル、動的列はサブタイトル)
        Row(children: bottomRowCells),
      ],
    );
  }

  // --- カスタムボディ描画 ---
  Widget _buildTableBody(
      List<PlayerStats> sortedStats,
      List<_ColumnSpec> columnSpecs,
      Map<String, Map<StatColumnType, double>> maxValues
      ) {
    const cellStyle = TextStyle(fontSize: 13, color: Colors.black87);
    const fixedWidth = 90.0;
    const dynamicWidth = 60.0;

    return Column(
      children: sortedStats.asMap().entries.map((entry) {
        final playerRowIndex = entry.key;
        final player = entry.value;
        final List<Widget> cells = [];

        for (final spec in columnSpecs) {
          final isFixed = spec.isFixed;
          final stat = player.actions[spec.actionName];
          String text = isFixed ? '-' : '';

          // 固定列のデータをセット
          if (spec.type == StatColumnType.number) text = player.playerNumber;
          if (spec.type == StatColumnType.name) text = player.playerName;
          if (spec.type == StatColumnType.matches) text = player.matchesPlayed.toString();

          // 動的列のデータをセット
          if (!isFixed && stat != null && stat.totalCount > 0) {
            switch (spec.type) {
              case StatColumnType.successCount:
                text = stat.successCount.toString();
                break;
              case StatColumnType.failureCount:
                text = stat.failureCount.toString();
                break;
              case StatColumnType.successRate:
                text = stat.totalCount > 0 ? "${stat.successRate.toStringAsFixed(0)}%" : "-";
                break;
            // ★追加: totalCount の表示ロジック
              case StatColumnType.totalCount:
                text = stat.totalCount.toString();
                break;
              default:
                break;
            }
          }

          // 色付け機能の削除: シンプルな行ストライプのみ残す
          Color? bgColor = playerRowIndex.isOdd ? Colors.grey.shade100 : Colors.white;

          TextStyle finalStyle = cellStyle.copyWith(
            fontWeight: FontWeight.normal,
            color: Colors.black87,
          );


          cells.add(
            Container(
              width: isFixed ? fixedWidth : dynamicWidth,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
                color: bgColor,
              ),
              child: Text(text, style: finalStyle),
            ),
          );
        }

        return Row(children: cells);
      }).toList(),
    );
  }
}