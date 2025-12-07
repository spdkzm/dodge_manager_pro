// lib/features/game_record/presentation/pages/match_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../../../features/analysis/application/analysis_controller.dart';
import '../../../../features/analysis/domain/player_stats.dart';
import '../../../../features/settings/domain/action_definition.dart';
import '../../../team_mgmt/application/team_store.dart';
import '../../../team_mgmt/domain/roster_item.dart';

enum StatColumnType {
  number,
  name,
  matches,
  successCount,
  failureCount,
  successRate,
  totalCount,
}

class _ColumnSpec {
  final String label;
  final StatColumnType type;
  final String? actionName;
  final bool isFixed;

  _ColumnSpec({
    required this.label,
    required this.type,
    this.actionName,
    this.isFixed = false,
  });
}

class MatchDetailScreen extends ConsumerStatefulWidget {
  final MatchRecord record;

  const MatchDetailScreen({super.key, required this.record});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialLoadComplete = false;

  // 編集用データ
  final _opponentCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  String? _opponentId;
  String? _venueId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 初期値セット
    _opponentCtrl.text = widget.record.opponent;
    _venueCtrl.text = widget.record.venueName ?? "";
    _opponentId = widget.record.opponentId;
    _venueId = widget.record.venueId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialLoadComplete) {
      Future.microtask(() {
        ref.read(analysisControllerProvider.notifier).analyze(matchId: widget.record.id);
        if (mounted) setState(() => _isInitialLoadComplete = true);
      });
    }
  }

  Future<void> _saveMatchInfo() async {
    final controller = ref.read(analysisControllerProvider.notifier);

    await controller.updateMatchInfo(
        widget.record.id,
        DateTime.tryParse(widget.record.date) ?? DateTime.now(),
        widget.record.matchType,
        opponentName: _opponentCtrl.text,
        opponentId: _opponentId,
        venueName: _venueCtrl.text,
        venueId: _venueId
    );

    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("試合情報を更新しました")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ★追加: データ更新の監視
    ref.listen<MatchRecord?>(selectedMatchRecordProvider, (prev, next) {
      if (next != null) {
        _opponentCtrl.text = next.opponent;
        _venueCtrl.text = next.venueName ?? "";
        _opponentId = next.opponentId;
        _venueId = next.venueId;
        setState(() {}); // 画面更新
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("VS ${widget.record.opponent}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.record.date, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.indigo.shade50,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
              tabs: const [
                Tab(icon: Icon(Icons.list), text: "ログ"),
                Tab(icon: Icon(Icons.analytics), text: "集計"),
                Tab(icon: Icon(Icons.info), text: "試合情報"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLogTab(),
                _buildStatsTab(),
                _buildMatchInfoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- タブ3: 試合情報 ---
  Widget _buildMatchInfoTab() {
    final store = ref.watch(teamStoreProvider);
    final currentTeam = store.currentTeam;
    if (currentTeam == null) return const SizedBox();

    final opponents = currentTeam.opponentItems;
    final venues = currentTeam.venueItems;
    final opSchema = currentTeam.opponentSchema.firstWhere((f)=>f.label=='チーム名', orElse: ()=>currentTeam.opponentSchema.first);
    final veSchema = currentTeam.venueSchema.firstWhere((f)=>f.label=='会場名', orElse: ()=>currentTeam.venueSchema.first);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("基本情報", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: _opponentCtrl, decoration: const InputDecoration(labelText: "対戦相手"))),
            PopupMenuButton<RosterItem>(
              icon: const Icon(Icons.list),
              onSelected: (item) {
                setState(() {
                  _opponentCtrl.text = item.data[opSchema.id]?.toString() ?? "";
                  _opponentId = item.id;
                });
              },
              itemBuilder: (context) => opponents.map((i) => PopupMenuItem(value: i, child: Text(i.data[opSchema.id]?.toString() ?? ""))).toList(),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _venueCtrl, decoration: const InputDecoration(labelText: "会場"))),
            PopupMenuButton<RosterItem>(
              icon: const Icon(Icons.list),
              onSelected: (item) {
                setState(() {
                  _venueCtrl.text = item.data[veSchema.id]?.toString() ?? "";
                  _venueId = item.id;
                });
              },
              itemBuilder: (context) => venues.map((i) => PopupMenuItem(value: i, child: Text(i.data[veSchema.id]?.toString() ?? ""))).toList(),
            ),
          ]),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(onPressed: _saveMatchInfo, child: const Text("基本情報を更新")),
          ),
          const Divider(height: 32),
          const Text("出場メンバー (既存機能)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Center(child: Text("※ メンバー編集は分析画面から行ってください")),
        ],
      ),
    );
  }

  // --- タブ1: ログ ---
  Widget _buildLogTab() {
    final logs = widget.record.logs;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          alignment: Alignment.centerRight,
          child: Text("全 ${logs.length} 件", style: const TextStyle(color: Colors.grey)),
        ),
        const Divider(height: 1),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[200],
          child: const Row(
            children: [
              SizedBox(width: 60, child: Text("時間", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 80, child: Text("選手", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text("プレー内容", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 1, child: Text("詳細", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogRow(log);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogRow(LogEntry log) {
    if (log.type == LogType.system) {
      return Container(
        color: Colors.grey[50],
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            "${log.gameTime}  -  ${log.action}  -",
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      );
    }

    String resultText = "";
    Color? bgColor = Colors.white;
    if (log.result == ActionResult.success) {
      resultText = "(成功)";
      bgColor = Colors.red.shade50;
    } else if (log.result == ActionResult.failure) {
      resultText = "(失敗)";
      bgColor = Colors.blue.shade50;
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(log.gameTime, style: const TextStyle(fontFamily: 'monospace', color: Colors.black54)),
          ),
          SizedBox(
            width: 80,
            child: Text("#${log.playerNumber}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "${log.action} $resultText",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(log.subAction ?? "-", style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // --- タブ2: 集計 ---
  Widget _buildStatsTab() {
    final asyncStats = ref.watch(analysisControllerProvider);

    return asyncStats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("エラー: $err")),
      data: (stats) {
        if (stats.isEmpty) return const Center(child: Text("集計データがありません"));
        return _buildDataTable(stats);
      },
    );
  }

  Widget _buildDataTable(List<PlayerStats> originalStats) {
    final controller = ref.read(analysisControllerProvider.notifier);
    final definitions = controller.actionDefinitions;

    final List<_ColumnSpec> columnSpecs = [];

    columnSpecs.add(_ColumnSpec(label: "背番号", type: StatColumnType.number, isFixed: true));
    columnSpecs.add(_ColumnSpec(label: "コートネーム", type: StatColumnType.name, isFixed: true));

    final dataActionNames = <String>{};
    for (var p in originalStats) dataActionNames.addAll(p.actions.keys);

    final displayDefinitions = List<ActionDefinition>.from(definitions);
    final definedNames = definitions.map((d) => d.name).toSet();
    for (var name in dataActionNames) {
      if (!definedNames.contains(name)) {
        displayDefinitions.add(ActionDefinition(name: name, hasSuccess: false, hasFailure: false));
      }
    }

    for (var action in displayDefinitions) {
      if (action.hasSuccess && action.hasFailure) {
        columnSpecs.add(_ColumnSpec(label: "成功", type: StatColumnType.successCount, actionName: action.name));
        columnSpecs.add(_ColumnSpec(label: "失敗", type: StatColumnType.failureCount, actionName: action.name));
        columnSpecs.add(_ColumnSpec(label: "成功率", type: StatColumnType.successRate, actionName: action.name));
      } else if (action.hasSuccess) {
        columnSpecs.add(_ColumnSpec(label: "成功数", type: StatColumnType.successCount, actionName: action.name));
      } else if (action.hasFailure) {
        columnSpecs.add(_ColumnSpec(label: "失敗数", type: StatColumnType.failureCount, actionName: action.name));
      } else {
        columnSpecs.add(_ColumnSpec(label: "数", type: StatColumnType.totalCount, actionName: action.name));
      }
    }

    final sortedStats = List<PlayerStats>.from(originalStats);
    sortedStats.sort((a, b) => (int.tryParse(a.playerNumber) ?? 999).compareTo(int.tryParse(b.playerNumber) ?? 999));

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTableHeader(columnSpecs),
            const Divider(height: 1, thickness: 1),
            _buildTableBody(sortedStats, columnSpecs),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(List<_ColumnSpec> columnSpecs) {
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
        currentActionName = null;
        currentActionColumnCount = 0;
      }
    }

    final List<Widget> bottomRowCells = [];
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
    for (final spec in dynamicSpecs) {
      bottomRowCells.add(
        Container(
          width: dynamicWidth,
          height: headerHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[100]),
          child: Text(spec.label, style: headerStyle, textAlign: TextAlign.center, maxLines: 1),
        ),
      );
    }

    return Column(children: [Row(children: topRowCells), Row(children: bottomRowCells)]);
  }

  Widget _buildTableBody(List<PlayerStats> sortedStats, List<_ColumnSpec> columnSpecs) {
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
          String text = '-';

          if (spec.type == StatColumnType.number) text = player.playerNumber;
          if (spec.type == StatColumnType.name) text = player.playerName;

          if (!isFixed) {
            if (stat != null) {
              switch (spec.type) {
                case StatColumnType.successCount:
                case StatColumnType.failureCount:
                case StatColumnType.totalCount:
                  text = (spec.type == StatColumnType.totalCount ? stat.totalCount : (spec.type == StatColumnType.successCount ? stat.successCount : stat.failureCount)).toString();
                  break;
                case StatColumnType.successRate:
                  text = stat.totalCount > 0 ? "${stat.successRate.toStringAsFixed(0)}%" : "-";
                  break;
                default: text = '0'; break;
              }
            } else {
              text = (spec.type == StatColumnType.successRate) ? '-' : '0';
            }
          }

          Color? bgColor = playerRowIndex.isOdd ? Colors.grey.shade100 : Colors.white;

          cells.add(
            Container(
              width: isFixed ? fixedWidth : dynamicWidth,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5), color: bgColor),
              child: Text(text, style: cellStyle),
            ),
          );
        }
        return Row(children: cells);
      }).toList(),
    );
  }
}