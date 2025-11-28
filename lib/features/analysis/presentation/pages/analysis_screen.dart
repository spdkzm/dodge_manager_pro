// lib/features/analysis/presentation/pages/analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/analysis_controller.dart';
import '../../domain/player_stats.dart';

import '../../../settings/domain/action_definition.dart';
import '../../../settings/data/action_dao.dart';
import '../../../team_mgmt/application/team_store.dart';

// 集計項目の種類
enum StatColumnType {
  number,       // 背番号
  name,         // コートネーム
  matches,      // 試合数
  successCount, // 成功数
  failureCount, // 失敗数
  successRate,  // 成功率
  totalCount,   // 合計回数
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

  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;
  // ★追加: 選択された試合ID (null = 日累計)
  String? _selectedMatchId;

  bool _isInitialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActionOrder();
    });
  }

  // Providerの状態変更エラー回避のため、didChangeDependenciesをFuture.microtaskでラップ
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialLoadComplete) {
      // Future.microtaskで、現在のビルドフェーズが完了した直後にanalyzeを実行する
      Future.microtask(() {
        _runAnalysis();
        if (mounted) { // ウィジェットがマウントされているか確認
          setState(() {
            _isInitialLoadComplete = true;
          });
        }
      });
    }
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

  // ★修正: analyze メソッドに選択された年、月、日、試合IDを渡す
  void _runAnalysis() {
    ref.read(analysisControllerProvider.notifier).analyze(year: _selectedYear, month: _selectedMonth, day: _selectedDay, matchId: _selectedMatchId);
  }

  // 月タブの描画ウィジェット (既存)
  Widget _buildMonthTabs(List<int> months, int selectedIndex) {
    // 累計 (null) + 存在する月
    final List<int?> tabs = [null, ...months];

    return Container(
      width: 80,
      color: Colors.grey[100],
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final month = tabs[index];
          final isSelected = index == selectedIndex;
          final label = month == null ? '年累計' : '${month}月';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: isSelected ? Colors.indigo.shade100 : Colors.transparent,
                foregroundColor: isSelected ? Colors.indigo : Colors.black87,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                setState(() {
                  _selectedMonth = month;
                  _selectedDay = null; // 月が変わったら日を月累計(null)にリセット
                  _selectedMatchId = null; // 試合もリセット
                });
                _runAnalysis();
              },
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }

  // 日タブの描画ウィジェット (既存)
  Widget _buildDayTabs(List<int> days, int selectedIndex) {
    // 累計 (null) + 存在する日
    final List<int?> tabs = [null, ...days];

    return Container(
      width: 80,
      color: Colors.grey[200],
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final day = tabs[index];
          final isSelected = index == selectedIndex;
          final label = day == null ? '月累計' : '${day}日';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: isSelected ? Colors.indigo.shade100 : Colors.transparent,
                foregroundColor: isSelected ? Colors.indigo : Colors.black87,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                setState(() {
                  _selectedDay = day;
                  _selectedMatchId = null; // 日が変わったら試合を日累計(null)にリセット
                });
                _runAnalysis();
              },
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }

  // ★追加: 試合タブの描画ウィジェット
  Widget _buildMatchTabs(Map<String, String> matches, int selectedIndex) {
    // 累計 (null) + 存在する試合ID
    final List<String?> matchIds = [null, ...matches.keys];

    return Container(
      width: 150, // 試合名表示のため幅を広げる
      color: Colors.grey[300],
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: matchIds.length,
        itemBuilder: (context, index) {
          final matchId = matchIds[index];
          final isSelected = index == selectedIndex;
          final label = matchId == null ? '日累計' : matches[matchId] ?? '(不明な試合)';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: isSelected ? Colors.indigo.shade100 : Colors.transparent,
                foregroundColor: isSelected ? Colors.indigo : Colors.black87,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                setState(() {
                  _selectedMatchId = matchId;
                });
                _runAnalysis();
              },
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final asyncStats = ref.watch(analysisControllerProvider);
    final availableYears = ref.watch(availableYearsProvider);
    final availableMonths = ref.watch(availableMonthsProvider);
    final availableDays = ref.watch(availableDaysProvider);
    final availableMatches = ref.watch(availableMatchesProvider); // ★追加

    // 1. 年タブ設定
    final List<int?> yearTabs = [null, ...availableYears];
    int selectedYearIndex = yearTabs.indexOf(_selectedYear);
    if (selectedYearIndex == -1) selectedYearIndex = 0;

    // 2. 月タブ設定
    final List<int?> monthTabs = [null, ...availableMonths];
    int selectedMonthIndex = monthTabs.indexOf(_selectedMonth);
    if (selectedMonthIndex == -1) selectedMonthIndex = 0;

    // 3. 日タブ設定
    final List<int?> dayTabs = [null, ...availableDays];
    int selectedDayIndex = dayTabs.indexOf(_selectedDay);
    if (selectedDayIndex == -1) selectedDayIndex = 0;

    // 4. 試合タブ設定
    final List<String?> matchIdTabs = [null, ...availableMatches.keys]; // ★追加
    int selectedMatchIndex = matchIdTabs.indexOf(_selectedMatchId);
    if (selectedMatchIndex == -1) selectedMatchIndex = 0;


    return Scaffold(
      appBar: AppBar(
        title: const Text("データ分析"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _runAnalysis),
        ],
      ),
      // ★修正: 最大5ペイン構成
      body: Row(
        children: [
          // ペイン 1: 年/累計タブ (120px)
          Container(
            width: 120,
            color: Colors.grey[50],
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: yearTabs.length,
              itemBuilder: (context, index) {
                final year = yearTabs[index];
                final isSelected = index == selectedYearIndex;
                final label = year == null ? '累計' : '${year}年';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: isSelected ? Colors.indigo.shade100 : Colors.transparent,
                      foregroundColor: isSelected ? Colors.indigo : Colors.black87,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedYear = year;
                        _selectedMonth = null;
                        _selectedDay = null;
                        _selectedMatchId = null; // 全てリセット
                      });
                      _runAnalysis();
                    },
                    child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),

          // ペイン 2: 月タブ (80px) - 年が選択されている場合のみ表示
          if (_selectedYear != null)
            _buildMonthTabs(availableMonths, selectedMonthIndex),

          // ペイン 3: 日タブ (80px) - 月が選択されている場合のみ表示
          if (_selectedMonth != null)
            _buildDayTabs(availableDays, selectedDayIndex),

          // ★追加: ペイン 4: 試合タブ (150px) - 日が選択されている場合のみ表示
          if (_selectedDay != null)
            _buildMatchTabs(availableMatches, selectedMatchIndex),

          const VerticalDivider(width: 1, thickness: 1),

          // ペイン 5: 分析テーブル
          Expanded(
            child: Column(
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
      // どちらもなしの場合: 合計回数(数)を表示する
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
              child: Text(currentActionName, style: headerStyle, textAlign: TextAlign.center),
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

          // ★修正: デフォルト値を '-' に設定
          String text = '-';

          // 1. 固定列のデータ設定
          if (spec.type == StatColumnType.number) text = player.playerNumber;
          if (spec.type == StatColumnType.name) text = player.playerName;
          if (spec.type == StatColumnType.matches) text = player.matchesPlayed.toString();

          // 2. 動的列のデータ設定
          if (!isFixed) {
            if (stat != null) {
              // Statが存在する場合
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
                // 成功率: totalCountが0の場合は "-" を表示
                  text = stat.totalCount > 0 ? "${stat.successRate.toStringAsFixed(0)}%" : "-";
                  break;
                default:
                  text = '0'; // 未定義のカウント系は 0
                  break;
              }
            } else {
              // Statが null (データなし) の場合
              if (spec.type == StatColumnType.successRate) {
                text = '-'; // 成功率の場合は '-'
              } else {
                text = '0'; // カウント系の場合は '0'
              }
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