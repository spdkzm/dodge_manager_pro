// lib/features/analysis/presentation/pages/analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/analysis_controller.dart';
import '../../domain/player_stats.dart';

enum AnalysisPeriod { total, year, month, range }

// ★追加: 表示設定用のクラス（簡易的にここで定義）
class AnalysisDisplaySettings {
  bool showSuccessRate = true;
  bool showPerGame = false; // 1試合平均
  bool showSubActions = false; // 詳細項目
  bool highlightTop = true; // 1位を色付け
}

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});
  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  AnalysisPeriod _selectedPeriod = AnalysisPeriod.total;
  DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _endDate = DateTime.now();

  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  // 表示設定の状態
  final AnalysisDisplaySettings _displaySettings = AnalysisDisplaySettings();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAnalysis();
    });
  }

  void _runAnalysis() {
    ref.read(analysisControllerProvider.notifier).analyze(_selectedPeriod, _startDate, _endDate);
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("表示項目の設定"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text("成功率を表示"),
                  value: _displaySettings.showSuccessRate,
                  onChanged: (v) => setStateDialog(() => _displaySettings.showSuccessRate = v!),
                ),
                CheckboxListTile(
                  title: const Text("1試合平均を表示"),
                  value: _displaySettings.showPerGame,
                  onChanged: (v) => setStateDialog(() => _displaySettings.showPerGame = v!),
                ),
                CheckboxListTile(
                  title: const Text("詳細項目(内訳)を表示"),
                  subtitle: const Text("テーブルが横に長くなります"),
                  value: _displaySettings.showSubActions,
                  onChanged: (v) => setStateDialog(() => _displaySettings.showSubActions = v!),
                ),
                const Divider(),
                CheckboxListTile(
                  title: const Text("トップ成績を色付け"),
                  value: _displaySettings.highlightTop,
                  onChanged: (v) => setStateDialog(() => _displaySettings.highlightTop = v!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {}); // 画面再描画
                },
                child: const Text("閉じる"),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncStats = ref.watch(analysisControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("データ分析"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog, // ★設定ダイアログ呼び出し
          ),
        ],
      ),
      body: Column(
        children: [
          _buildControlBar(),
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

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Row(
        children: [
          DropdownButton<AnalysisPeriod>(
            value: _selectedPeriod,
            underline: Container(),
            items: const [
              DropdownMenuItem(value: AnalysisPeriod.total, child: Text("累計")),
              DropdownMenuItem(value: AnalysisPeriod.year, child: Text("年間")),
              DropdownMenuItem(value: AnalysisPeriod.month, child: Text("月間")),
              DropdownMenuItem(value: AnalysisPeriod.range, child: Text("期間指定")),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedPeriod = val);
                _runAnalysis();
              }
            },
          ),
          const SizedBox(width: 16),
          if (_selectedPeriod != AnalysisPeriod.total) _buildDateSelector(),
          const Spacer(),
          ElevatedButton.icon(onPressed: _runAnalysis, icon: const Icon(Icons.refresh), label: const Text("更新")),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final dateFormat = DateFormat('yyyy/MM/dd');
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
        );
        if (picked != null) {
          setState(() {
            _startDate = picked.start;
            _endDate = picked.end;
          });
          _runAnalysis();
        }
      },
      child: Text("${dateFormat.format(_startDate)} 〜 ${dateFormat.format(_endDate)}"),
    );
  }

  // --- テーブル構築 ---
  Widget _buildDataTable(List<PlayerStats> originalStats) {
    final allActions = <String>{};
    for (var p in originalStats) allActions.addAll(p.actions.keys);
    final actionList = allActions.toList()..sort();

    final sortedStats = List<PlayerStats>.from(originalStats);

    // ソートロジック
    sortedStats.sort((a, b) {
      int cmp = 0;
      if (_sortColumnIndex == 0) {
        cmp = (int.tryParse(a.playerNumber) ?? 999).compareTo(int.tryParse(b.playerNumber) ?? 999);
      } else if (_sortColumnIndex == 1) {
        cmp = a.matchesPlayed.compareTo(b.matchesPlayed);
      } else {
        // アクション列のソート (成功率優先、なければ総数)
        // ※列が増減するのでインデックス計算が必要だが、簡易的にここでは
        // 「アクションごとの成功率」でのソートとする
        final actionIdx = ((_sortColumnIndex - 2) / (_displaySettings.showSubActions ? 2 : 1)).floor();
        // 厳密なインデックス計算は複雑になるため、今回は簡易ソートとして
        // 選択されたアクションの「成功率」で比較するロジックを組むのが現実的
        if (actionIdx >= 0 && actionIdx < actionList.length) {
          final actionKey = actionList[actionIdx];
          final statA = a.actions[actionKey];
          final statB = b.actions[actionKey];
          cmp = (statA?.successRate ?? 0).compareTo(statB?.successRate ?? 0);
        }
      }
      return _sortAscending ? cmp : -cmp;
    });

    // ハイライト計算
    final maxRates = <String, double>{};
    for (var action in actionList) {
      double max = -1.0;
      for (var p in originalStats) {
        final rate = p.actions[action]?.successRate ?? 0.0;
        if (rate > max) max = rate;
      }
      maxRates[action] = max;
    }

    // カラム生成
    List<DataColumn> columns = [
      DataColumn(label: const Text('選手', style: TextStyle(fontWeight: FontWeight.bold)), onSort: (i, a) => setState(() { _sortColumnIndex = i; _sortAscending = a; })),
      DataColumn(label: const Text('試合数', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true, onSort: (i, a) => setState(() { _sortColumnIndex = i; _sortAscending = a; })),
    ];

    for (var action in actionList) {
      columns.add(DataColumn(
          label: Text(action, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          numeric: true,
          onSort: (i, a) => setState(() { _sortColumnIndex = i; _sortAscending = a; })
      ));
    }

    // 行データ生成
    List<DataRow> rows = sortedStats.map((player) {
      return DataRow(
        cells: [
          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(radius: 12, backgroundColor: Colors.grey[300], child: Text(player.playerNumber, style: const TextStyle(fontSize: 10, color: Colors.black))),
            const SizedBox(width: 8),
            Text(player.playerName),
          ])),
          DataCell(Text(player.matchesPlayed.toString())),

          ...actionList.map((action) {
            final stat = player.actions[action];
            if (stat == null || stat.totalCount == 0) {
              return const DataCell(Text("-", style: TextStyle(color: Colors.grey)));
            }

            final rate = stat.successRate;
            final isTop = _displaySettings.highlightTop && rate > 0 && rate >= (maxRates[action] ?? 100.0);

            List<Widget> content = [];

            // メイン数値 (成功数/全体)
            content.add(Text("${stat.successCount}/${stat.totalCount}", style: const TextStyle(fontSize: 12)));

            // 成功率
            if (_displaySettings.showSuccessRate) {
              content.add(Text("${rate.toStringAsFixed(1)}%", style: TextStyle(fontWeight: isTop ? FontWeight.bold : FontWeight.normal, color: isTop ? Colors.green[700] : Colors.black, fontSize: 14)));
            }

            // 1試合平均
            if (_displaySettings.showPerGame) {
              final perGame = stat.getPerGame(player.matchesPlayed);
              content.add(Text("Av:${perGame.toStringAsFixed(1)}", style: const TextStyle(fontSize: 10, color: Colors.grey)));
            }

            // 詳細内訳 (サブアクション)
            if (_displaySettings.showSubActions && stat.subActionCounts.isNotEmpty) {
              final subs = stat.subActionCounts.entries.map((e) => "${e.key}:${e.value}").join(", ");
              content.add(Text("($subs)", style: const TextStyle(fontSize: 10, color: Colors.black54)));
            }

            return DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: content,
              ),
            );
          }),
        ],
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
          columnSpacing: 24,
          horizontalMargin: 12,
          columns: columns,
          rows: rows,
          dataRowMinHeight: _displaySettings.showSubActions ? 60 : 48, // 詳細表示時は行を高く
          dataRowMaxHeight: _displaySettings.showSubActions ? 80 : 60,
        ),
      ),
    );
  }
}