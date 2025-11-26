// lib/features/analysis/presentation/pages/analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/analysis_controller.dart';
import '../../domain/player_stats.dart';

import '../../../settings/domain/action_definition.dart';
import '../../../settings/data/action_dao.dart';
import '../../../team_mgmt/application/team_store.dart';

enum AnalysisPeriod { total, year, month, range }

// 集計項目の種類
enum StatColumnType {
  number,       // 背番号
  name,         // 名前
  matches,      // 試合数
  successCount, // 成功数
  failureCount, // 失敗数
  totalCount,   // 総数
  successRate,  // 成功率
  perGame,      // 1試合平均
  subActions,   // 詳細内訳
}

// 列設定モデル (色や太字の設定を削除)
class _ColumnSpec {
  final String label;
  final StatColumnType type;
  final String? actionName;

  _ColumnSpec({
    required this.label,
    required this.type,
    this.actionName,
  });
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

  // 表示設定
  final AnalysisDisplaySettings _displaySettings = AnalysisDisplaySettings();

  // 表示順序用のアクションリスト
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
                  setState(() {});
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
          IconButton(icon: const Icon(Icons.settings), onPressed: _showSettingsDialog),
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
    final controller = ref.read(analysisControllerProvider.notifier);

    // 1. カラム決定
    final definitions = controller.actionDefinitions;

    final dataActionNames = <String>{};
    for (var p in originalStats) dataActionNames.addAll(p.actions.keys);

    // 表示順序のリストを作成
    final displayDefinitions = List<ActionDefinition>.from(definitions);
    final definedNames = definitions.map((d) => d.name).toSet();

    // 未定義のアクション（削除済みなど）を末尾に追加
    for (var name in dataActionNames) {
      if (!definedNames.contains(name)) {
        displayDefinitions.add(ActionDefinition(name: name, hasSuccess: false, hasFailure: false));
      }
    }

    // 2. カラム構造の定義 (Specリストを作成)
    final List<_ColumnSpec> columnSpecs = [];

    // 固定列
    columnSpecs.add(_ColumnSpec(label: "No.", type: StatColumnType.number));
    columnSpecs.add(_ColumnSpec(label: "名前", type: StatColumnType.name));
    columnSpecs.add(_ColumnSpec(label: "試合数", type: StatColumnType.matches));

    // 動的列
    for (var action in displayDefinitions) {
      if (action.hasSuccess && action.hasFailure) {
        // 両方あり
        columnSpecs.add(_ColumnSpec(label: "${action.name}\n成功", type: StatColumnType.successCount, actionName: action.name));
        columnSpecs.add(_ColumnSpec(label: "${action.name}\n失敗", type: StatColumnType.failureCount, actionName: action.name));
        if (_displaySettings.showSuccessRate) {
          columnSpecs.add(_ColumnSpec(label: "${action.name}\n率", type: StatColumnType.successRate, actionName: action.name));
        }
      } else if (action.hasSuccess) {
        // 成功のみ -> 「成功」と表示
        columnSpecs.add(_ColumnSpec(label: "${action.name}\n成功", type: StatColumnType.successCount, actionName: action.name));
      } else if (action.hasFailure) {
        // 失敗のみ -> 「失敗」と表示
        columnSpecs.add(_ColumnSpec(label: "${action.name}\n失敗", type: StatColumnType.failureCount, actionName: action.name));
      } else {
        // どちらもなし -> 「数」と表示
        columnSpecs.add(_ColumnSpec(label: "${action.name}\n数", type: StatColumnType.totalCount, actionName: action.name));
      }

      // 共通オプション
      if (_displaySettings.showPerGame) {
        columnSpecs.add(_ColumnSpec(label: "${action.name}\nAv", type: StatColumnType.perGame, actionName: action.name));
      }
      if (_displaySettings.showSubActions) {
        columnSpecs.add(_ColumnSpec(label: "${action.name}\n詳細", type: StatColumnType.subActions, actionName: action.name));
      }
    }

    // 3. ソート処理
    final sortedStats = List<PlayerStats>.from(originalStats);
    sortedStats.sort((a, b) {
      int cmp = 0;
      if (_sortColumnIndex < columnSpecs.length) {
        final spec = columnSpecs[_sortColumnIndex];

        switch (spec.type) {
          case StatColumnType.number:
            cmp = (int.tryParse(a.playerNumber) ?? 999).compareTo(int.tryParse(b.playerNumber) ?? 999); break;
          case StatColumnType.name:
            cmp = a.playerName.compareTo(b.playerName); break;
          case StatColumnType.matches:
            cmp = a.matchesPlayed.compareTo(b.matchesPlayed); break;

          default:
            if (spec.actionName != null) {
              final statA = a.actions[spec.actionName];
              final statB = b.actions[spec.actionName];

              double valA = 0, valB = 0;
              switch (spec.type) {
                case StatColumnType.successCount: valA = (statA?.successCount ?? 0).toDouble(); break;
                case StatColumnType.failureCount: valA = (statA?.failureCount ?? 0).toDouble(); break;
                case StatColumnType.totalCount:   valA = (statA?.totalCount ?? 0).toDouble(); break;
                case StatColumnType.successRate:  valA = statA?.successRate ?? -1.0; break;
                case StatColumnType.perGame:      valA = statA?.getPerGame(a.matchesPlayed) ?? 0.0; break;
                default: break;
              }
              cmp = valA.compareTo(valB);
            }
        }
      }
      return _sortAscending ? cmp : -cmp;
    });

    // 4. ハイライト計算
    final maxValues = <String, Map<StatColumnType, double>>{};
    if (_displaySettings.highlightTop) {
      for (var action in displayDefinitions) {
        maxValues[action.name] = {};
        for (var type in [StatColumnType.successCount, StatColumnType.failureCount, StatColumnType.totalCount, StatColumnType.successRate, StatColumnType.perGame]) {
          double max = -1.0;
          for (var p in originalStats) {
            final stat = p.actions[action.name];
            double val = 0.0;
            if (stat != null) {
              if (type == StatColumnType.successCount) val = stat.successCount.toDouble();
              if (type == StatColumnType.failureCount) val = stat.failureCount.toDouble();
              if (type == StatColumnType.totalCount) val = stat.totalCount.toDouble();
              if (type == StatColumnType.successRate) val = stat.successRate;
              if (type == StatColumnType.perGame) val = stat.getPerGame(p.matchesPlayed);
            }
            if (val > max) max = val;
          }
          maxValues[action.name]![type] = max;
        }
      }
    }

    // 5. Widget生成 (DataTable)
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          headingRowColor: WidgetStateProperty.all(Colors.grey[200]), // シンプルなグレー
          columnSpacing: 20,
          dataRowMinHeight: 40,
          border: TableBorder.all(color: Colors.grey.shade300),

          columns: columnSpecs.asMap().entries.map((entry) {
            final index = entry.key;
            final spec = entry.value;
            return DataColumn(
              label: Text(
                spec.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), // 色指定削除
              ),
              numeric: spec.type != StatColumnType.number && spec.type != StatColumnType.name,
              onSort: (colIdx, asc) => setState(() {
                _sortColumnIndex = index;
                _sortAscending = asc;
              }),
            );
          }).toList(),

          rows: sortedStats.map((player) {
            return DataRow(
              cells: columnSpecs.map((spec) {
                // 固定列
                if (spec.type == StatColumnType.number) return DataCell(Text(player.playerNumber));
                if (spec.type == StatColumnType.name) return DataCell(Text(player.playerName));
                if (spec.type == StatColumnType.matches) return DataCell(Text(player.matchesPlayed.toString()));

                // アクション列
                final stat = player.actions[spec.actionName];
                String text = "-";
                bool isTop = false;

                if (stat != null && (stat.totalCount > 0 || spec.type == StatColumnType.subActions)) {
                  switch (spec.type) {
                    case StatColumnType.successCount:
                      text = stat.successCount.toString();
                      isTop = stat.successCount >= (maxValues[spec.actionName]![spec.type] ?? 9999);
                      break;
                    case StatColumnType.failureCount:
                      text = stat.failureCount.toString();
                      isTop = stat.failureCount >= (maxValues[spec.actionName]![spec.type] ?? 9999);
                      break;
                    case StatColumnType.totalCount:
                      text = stat.totalCount.toString();
                      isTop = stat.totalCount >= (maxValues[spec.actionName]![spec.type] ?? 9999);
                      break;
                    case StatColumnType.successRate:
                      text = stat.totalCount > 0 ? "${stat.successRate.toStringAsFixed(0)}%" : "-";
                      isTop = stat.successRate >= (maxValues[spec.actionName]![spec.type] ?? 100);
                      break;
                    case StatColumnType.perGame:
                      final av = stat.getPerGame(player.matchesPlayed);
                      text = av.toStringAsFixed(2);
                      isTop = av >= (maxValues[spec.actionName]![spec.type] ?? 9999);
                      break;
                    case StatColumnType.subActions:
                      if (stat.subActionCounts.isNotEmpty) {
                        text = stat.subActionCounts.entries.map((e) => "${e.key}:${e.value}").join(",");
                      }
                      break;
                    default: break;
                  }
                }

                if (_displaySettings.highlightTop && isTop && text != "-" && text != "0") {
                  return DataCell(Text(text, style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)));
                }

                return DataCell(Text(text, style: spec.type == StatColumnType.subActions ? const TextStyle(fontSize: 10, color: Colors.black54) : null));
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class AnalysisDisplaySettings {
  bool showSuccessRate = true;
  bool showPerGame = false;
  bool showSubActions = false;
  bool highlightTop = true;
}