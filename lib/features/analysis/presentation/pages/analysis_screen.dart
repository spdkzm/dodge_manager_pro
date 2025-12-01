// lib/features/analysis/presentation/pages/analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../application/analysis_controller.dart';
import '../../domain/player_stats.dart';
import '../../../game_record/domain/models.dart';

import '../../../settings/domain/action_definition.dart';
import '../../../settings/data/action_dao.dart';
import '../../../team_mgmt/application/team_store.dart';
import '../../../team_mgmt/data/csv_export_service.dart';

// Enum, _ColumnSpec は変更なし (省略)
enum StatColumnType { number, name, matches, successCount, failureCount, successRate, totalCount }
class _ColumnSpec {
  final String label; final StatColumnType type; final String? actionName; final bool isFixed;
  _ColumnSpec({required this.label, required this.type, this.actionName, this.isFixed = false});
}

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});
  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> with TickerProviderStateMixin {
  List<String> _sortedActionNames = [];
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;
  String? _selectedMatchId;
  bool _isInitialLoadComplete = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) { _loadActionOrder(); });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialLoadComplete) {
      Future.microtask(() { _runAnalysis(); if (mounted) setState(() => _isInitialLoadComplete = true); });
    }
  }

  Future<void> _loadActionOrder() async {
    final store = ref.read(teamStoreProvider);
    if (!store.isLoaded) await store.loadFromDb();
    if (store.currentTeam != null) {
      final actions = await ActionDao().getActionDefinitions(store.currentTeam!.id);
      if (mounted) setState(() => _sortedActionNames = actions.map((m) => m['name'] as String).toList());
    }
  }

  void _runAnalysis() {
    ref.read(analysisControllerProvider.notifier).analyze(year: _selectedYear, month: _selectedMonth, day: _selectedDay, matchId: _selectedMatchId);
  }

  // CSVエクスポート、ログ編集ダイアログなどのメソッドは変更なし (省略して記述)
  Future<void> _handleCsvExport() async {
    final asyncStats = ref.read(analysisControllerProvider);
    final stats = asyncStats.valueOrNull;
    if (stats == null || stats.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("出力するデータがありません"))); return; }
    final store = ref.read(teamStoreProvider); final currentTeam = store.currentTeam; final controller = ref.read(analysisControllerProvider.notifier);
    String periodLabel = "全期間";
    if (_selectedMatchId != null) { final matches = ref.read(availableMatchesProvider); periodLabel = matches[_selectedMatchId] ?? "試合"; } else if (_selectedDay != null) { periodLabel = "${_selectedYear}年${_selectedMonth}月${_selectedDay}日"; } else if (_selectedMonth != null) { periodLabel = "${_selectedYear}年${_selectedMonth}月"; } else if (_selectedYear != null) { periodLabel = "${_selectedYear}年"; }
    try { await CsvExportService().exportAnalysisStats(currentTeam?.name ?? 'Team', periodLabel, stats, controller.actionDefinitions); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CSVを出力しました"))); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("エラー: $e"), backgroundColor: Colors.red)); }
  }

  void _showEditLogDialog({LogEntry? log}) {
    // ... (前回のコードと同様)
    final controller = ref.read(analysisControllerProvider.notifier); final definitions = controller.actionDefinitions; final isNew = log == null; final stats = ref.read(analysisControllerProvider).valueOrNull ?? [];
    final players = stats.map((p) => {'number': p.playerNumber, 'name': p.playerName}).toList(); final actionNames = definitions.map((d) => d.name).toList();
    String timeVal = log?.gameTime ?? "00:00"; String? playerNumVal = log?.playerNumber; String? actionNameVal = log?.action; String? subActionVal = log?.subAction; ActionResult resultVal = log?.result ?? ActionResult.none;
    if (actionNameVal != null && !actionNames.contains(actionNameVal)) actionNames.add(actionNameVal); if (isNew && players.isNotEmpty) playerNumVal = players.first['number']; if (isNew && actionNames.isNotEmpty) actionNameVal = actionNames.first;
    final timeCtrl = TextEditingController(text: timeVal);
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setStateDialog) {
      final selectedDef = definitions.firstWhere((d) => d.name == actionNameVal, orElse: () => ActionDefinition(name: '', subActionsMap: {}));
      List<String> subActions = []; if (resultVal == ActionResult.success) subActions = selectedDef.subActionsMap['success'] ?? []; else if (resultVal == ActionResult.failure) subActions = selectedDef.subActionsMap['failure'] ?? []; else subActions = selectedDef.subActionsMap['default'] ?? [];
      return AlertDialog(title: Text(isNew ? "ログ追加" : "ログ編集"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: "時間 (分:秒)", hintText: "05:30"), keyboardType: TextInputType.datetime), const SizedBox(height: 16), DropdownButtonFormField<String>(value: playerNumVal, decoration: const InputDecoration(labelText: "選手"), items: players.map((p) => DropdownMenuItem(value: p['number'], child: Text("#${p['number']} ${p['name']}"),)).toList(), onChanged: (v) => setStateDialog(() => playerNumVal = v)), const SizedBox(height: 16), DropdownButtonFormField<String>(value: actionNameVal, decoration: const InputDecoration(labelText: "アクション"), items: actionNames.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(), onChanged: (v) => setStateDialog(() { actionNameVal = v; subActionVal = null; })), const SizedBox(height: 16), const Text("結果", style: TextStyle(fontSize: 12, color: Colors.grey)), Row(children: [Radio<ActionResult>(value: ActionResult.none, groupValue: resultVal, onChanged: (v) => setStateDialog(() => resultVal = v!)), const Text("なし"), Radio<ActionResult>(value: ActionResult.success, groupValue: resultVal, onChanged: (v) => setStateDialog(() => resultVal = v!)), const Text("成功"), Radio<ActionResult>(value: ActionResult.failure, groupValue: resultVal, onChanged: (v) => setStateDialog(() => resultVal = v!)), const Text("失敗")]), if (subActions.isNotEmpty) DropdownButtonFormField<String>(value: subActions.contains(subActionVal) ? subActionVal : null, decoration: const InputDecoration(labelText: "詳細"), items: subActions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setStateDialog(() => subActionVal = v))])), actions: [if (!isNew) TextButton(onPressed: () async { final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text("削除確認"), content: const Text("このログを削除しますか？"), actions: [TextButton(onPressed: ()=>Navigator.pop(c, false), child: const Text("キャンセル")), ElevatedButton(onPressed: ()=>Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("削除"))])); if (confirm == true && mounted) { await controller.deleteLog(log!.id); if (context.mounted) { Navigator.pop(ctx); _runAnalysis(); } } }, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text("削除")), TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")), ElevatedButton(onPressed: () async { if (playerNumVal == null || actionNameVal == null) return; final newLog = LogEntry(id: isNew ? const Uuid().v4() : log!.id, matchDate: "", opponent: "", gameTime: timeCtrl.text, playerNumber: playerNumVal!, action: actionNameVal!, subAction: subActionVal, result: resultVal, type: LogType.action); if (isNew) { await controller.addLog(_selectedMatchId!, newLog); } else { await controller.updateLog(_selectedMatchId!, newLog); } if (context.mounted) { Navigator.pop(ctx); _runAnalysis(); } }, child: const Text("保存"))]);
    }));
  }

  Widget _buildVerticalTabs<T>({ required List<T?> items, required T? selectedItem, required String Function(T?) labelBuilder, required Function(T?) onSelect, required double width, required Color color, }) {
    return Container(width: width, color: color, child: ListView.builder(padding: const EdgeInsets.symmetric(vertical: 8), itemCount: items.length, itemBuilder: (context, index) { final item = items[index]; final isSelected = item == selectedItem; return Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: TextButton(style: TextButton.styleFrom(backgroundColor: isSelected ? Colors.indigo.shade100 : Colors.transparent, foregroundColor: isSelected ? Colors.indigo : Colors.black87, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12)), onPressed: () => onSelect(item), child: Text(labelBuilder(item), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12), overflow: TextOverflow.ellipsis))); }));
  }

  @override
  Widget build(BuildContext context) {
    final teamStore = ref.watch(teamStoreProvider);
    final currentTeam = teamStore.currentTeam;

    // ★追加: チーム変更検知 (IDが変わったら再集計)
    ref.listen(teamStoreProvider, (previous, next) {
      if (previous?.currentTeam?.id != next.currentTeam?.id) {
        // フィルタをリセットして再集計
        setState(() {
          _selectedYear = null;
          _selectedMonth = null;
          _selectedDay = null;
          _selectedMatchId = null;
        });
        _loadActionOrder().then((_) => _runAnalysis());
      }
    });

    final asyncStats = ref.watch(analysisControllerProvider);
    final availableYears = ref.watch(availableYearsProvider);
    final availableMonths = ref.watch(availableMonthsProvider);
    final availableDays = ref.watch(availableDaysProvider);
    final availableMatches = ref.watch(availableMatchesProvider);

    final yearTabs = [null, ...availableYears];
    final monthTabs = [null, ...availableMonths];
    final dayTabs = [null, ...availableDays];
    final matchTabs = [null, ...availableMatches.keys];
    final isLogTabVisible = _selectedMatchId != null && _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        // ★修正: ドロップダウンを廃止し、タイトル表示へ
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("データ分析", style: TextStyle(fontSize: 16)),
            Text(currentTeam?.name ?? "", style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.file_download), tooltip: "CSV出力", onPressed: _handleCsvExport),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _runAnalysis),
        ],
      ),
      body: Row(
        children: [
          _buildVerticalTabs<int>(items: yearTabs, selectedItem: _selectedYear, labelBuilder: (y) => y == null ? '全期間' : '$y年', onSelect: (y) { setState(() { _selectedYear = y; _selectedMonth = null; _selectedDay = null; _selectedMatchId = null; }); _runAnalysis(); }, width: 90, color: Colors.grey[50]!),
          if (_selectedYear != null) _buildVerticalTabs<int>(items: monthTabs, selectedItem: _selectedMonth, labelBuilder: (m) => m == null ? '年計' : '$m月', onSelect: (m) { setState(() { _selectedMonth = m; _selectedDay = null; _selectedMatchId = null; }); _runAnalysis(); }, width: 60, color: Colors.grey[100]!),
          if (_selectedMonth != null) _buildVerticalTabs<int>(items: dayTabs, selectedItem: _selectedDay, labelBuilder: (d) => d == null ? '月計' : '$d日', onSelect: (d) { setState(() { _selectedDay = d; _selectedMatchId = null; }); _runAnalysis(); }, width: 60, color: Colors.grey[200]!),
          if (_selectedDay != null) _buildVerticalTabs<String>(items: matchTabs, selectedItem: _selectedMatchId, labelBuilder: (id) => id == null ? '日計' : (availableMatches[id] ?? '試合'), onSelect: (id) { setState(() { _selectedMatchId = id; }); _runAnalysis(); }, width: 140, color: Colors.grey[300]!),

          const VerticalDivider(width: 1, thickness: 1),

          Expanded(
            child: Column(
              children: [
                if (_selectedMatchId != null)
                  Container(
                    color: Colors.grey[50],
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.indigo,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.indigo,
                      onTap: (idx) => setState((){}),
                      tabs: const [Tab(icon: Icon(Icons.analytics, size: 18), text: "集計"), Tab(icon: Icon(Icons.list, size: 18), text: "ログ")],
                    ),
                  ),
                const Divider(height: 1),
                Expanded(
                  child: _selectedMatchId != null
                      ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStatsContent(asyncStats),
                      _buildLogContent(asyncStats),
                    ],
                  )
                      : _buildStatsContent(asyncStats),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isLogTabVisible
          ? FloatingActionButton(onPressed: () => _showEditLogDialog(), child: const Icon(Icons.add))
          : null,
    );
  }

  Widget _buildStatsContent(AsyncValue<List<PlayerStats>> asyncStats) {
    return asyncStats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("エラー: $err")),
      data: (stats) { if (stats.isEmpty) return const Center(child: Text("データがありません")); return _buildDataTable(stats); },
    );
  }

  Widget _buildLogContent(AsyncValue<List<PlayerStats>> asyncStats) {
    final matchRecord = ref.watch(selectedMatchRecordProvider);
    if (matchRecord == null) return const Center(child: CircularProgressIndicator());
    if (matchRecord.logs.isEmpty) return const Center(child: Text("ログがありません"));
    final Map<String, String> nameMap = {};
    asyncStats.whenData((stats) { for (var p in stats) { nameMap[p.playerNumber] = p.playerName; } });
    final logs = matchRecord.logs;
    return ListView.separated(
      itemCount: logs.length, separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final log = logs[index];
        final name = nameMap[log.playerNumber] ?? "";
        if (log.type == LogType.system) {
          return Container(color: Colors.grey[50], padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), child: Row(children: [SizedBox(width: 45, child: Text(log.gameTime, style: const TextStyle(color: Colors.grey, fontSize: 11))), const SizedBox(width: 90), Expanded(child: Text(log.action, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))]));
        }
        String resultText = ""; Color? bgColor = Colors.white;
        if (log.result == ActionResult.success) { resultText = "(成功)"; bgColor = Colors.red.shade50; } else if (log.result == ActionResult.failure) { resultText = "(失敗)"; bgColor = Colors.blue.shade50; }
        return InkWell(onTap: () => _showEditLogDialog(log: log), child: Container(color: bgColor, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), child: Row(children: [SizedBox(width: 45, child: Text(log.gameTime, style: const TextStyle(color: Colors.grey, fontSize: 11))), SizedBox(width: 90, child: RichText(overflow: TextOverflow.ellipsis, text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 12), children: [TextSpan(text: "#${log.playerNumber} ", style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: name, style: const TextStyle(fontSize: 11, color: Colors.black54))]))), Expanded(child: Text("${log.action} $resultText", style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)), if (log.subAction != null) Text(log.subAction!, style: const TextStyle(color: Colors.grey, fontSize: 11))])));
      },
    );
  }

  // _buildDataTable, _buildTableHeader, _buildTableBody は変更なし (前回のものを使用)
  Widget _buildDataTable(List<PlayerStats> originalStats) {
    final controller = ref.read(analysisControllerProvider.notifier); final definitions = controller.actionDefinitions; final List<_ColumnSpec> columnSpecs = []; columnSpecs.add(_ColumnSpec(label: "背番号", type: StatColumnType.number, isFixed: true)); columnSpecs.add(_ColumnSpec(label: "コートネーム", type: StatColumnType.name, isFixed: true)); columnSpecs.add(_ColumnSpec(label: "試合数", type: StatColumnType.matches, isFixed: true)); final dataActionNames = <String>{}; for (var p in originalStats) dataActionNames.addAll(p.actions.keys); final displayDefinitions = List<ActionDefinition>.from(definitions); final definedNames = definitions.map((d) => d.name).toSet(); for (var name in dataActionNames) { if (!definedNames.contains(name)) displayDefinitions.add(ActionDefinition(name: name, hasSuccess: false, hasFailure: false)); } for (var action in displayDefinitions) { if (action.hasSuccess && action.hasFailure) { columnSpecs.add(_ColumnSpec(label: "成功", type: StatColumnType.successCount, actionName: action.name)); columnSpecs.add(_ColumnSpec(label: "失敗", type: StatColumnType.failureCount, actionName: action.name)); columnSpecs.add(_ColumnSpec(label: "成功率", type: StatColumnType.successRate, actionName: action.name)); } else if (action.hasSuccess) { columnSpecs.add(_ColumnSpec(label: "成功数", type: StatColumnType.successCount, actionName: action.name)); } else if (action.hasFailure) { columnSpecs.add(_ColumnSpec(label: "失敗数", type: StatColumnType.failureCount, actionName: action.name)); } else { columnSpecs.add(_ColumnSpec(label: "数", type: StatColumnType.totalCount, actionName: action.name)); } } final sortedStats = List<PlayerStats>.from(originalStats); sortedStats.sort((a, b) => (int.tryParse(a.playerNumber) ?? 999).compareTo(int.tryParse(b.playerNumber) ?? 999)); final maxValues = <String, Map<StatColumnType, double>>{}; return SingleChildScrollView(scrollDirection: Axis.vertical, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildTableHeader(columnSpecs), const Divider(height: 1, thickness: 1), _buildTableBody(sortedStats, columnSpecs, maxValues)])));
  }
  Widget _buildTableHeader(List<_ColumnSpec> columnSpecs) { const headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87); const headerHeight = 40.0; const fixedWidth = 90.0; const dynamicWidth = 60.0; final fixedSpecs = columnSpecs.where((s) => s.isFixed).toList(); final dynamicSpecs = columnSpecs.where((s) => !s.isFixed).toList(); final List<Widget> topRowCells = []; topRowCells.addAll(fixedSpecs.map((_) => SizedBox(width: fixedWidth, height: headerHeight))); String? currentActionName; int currentActionColumnCount = 0; for (int i = 0; i < dynamicSpecs.length; i++) { final spec = dynamicSpecs[i]; if (spec.actionName != currentActionName) { if (currentActionName != null) { topRowCells.add(Container(width: dynamicWidth * currentActionColumnCount, height: headerHeight, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[200]), child: Text(currentActionName, style: headerStyle, textAlign: TextAlign.center))); } currentActionName = spec.actionName; currentActionColumnCount = 1; } else { currentActionColumnCount++; } if (i == dynamicSpecs.length - 1 || (i + 1 < dynamicSpecs.length && dynamicSpecs[i + 1].actionName != currentActionName)) { topRowCells.add(Container(width: dynamicWidth * currentActionColumnCount, height: headerHeight, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[200]), child: Text(currentActionName!, style: headerStyle, textAlign: TextAlign.center))); currentActionName = null; currentActionColumnCount = 0; } } final List<Widget> bottomRowCells = []; for (final spec in fixedSpecs) { bottomRowCells.add(Container(width: fixedWidth, height: headerHeight, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[200]), child: Text(spec.label, style: headerStyle, textAlign: TextAlign.center))); } for (final spec in dynamicSpecs) { bottomRowCells.add(Container(width: dynamicWidth, height: headerHeight, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[100]), child: Text(spec.label, style: headerStyle, textAlign: TextAlign.center, maxLines: 1))); } return Column(children: [Row(children: topRowCells), Row(children: bottomRowCells)]); }
  Widget _buildTableBody(List<PlayerStats> sortedStats, List<_ColumnSpec> columnSpecs, Map<String, Map<StatColumnType, double>> maxValues) { const cellStyle = TextStyle(fontSize: 13, color: Colors.black87); const fixedWidth = 90.0; const dynamicWidth = 60.0; return Column(children: sortedStats.asMap().entries.map((entry) { final playerRowIndex = entry.key; final player = entry.value; final List<Widget> cells = []; for (final spec in columnSpecs) { final isFixed = spec.isFixed; final stat = player.actions[spec.actionName]; String text = '-'; if (spec.type == StatColumnType.number) text = player.playerNumber; if (spec.type == StatColumnType.name) text = player.playerName; if (spec.type == StatColumnType.matches) text = player.matchesPlayed.toString(); if (!isFixed) { if (stat != null) { switch (spec.type) { case StatColumnType.successCount: case StatColumnType.failureCount: case StatColumnType.totalCount: text = (spec.type == StatColumnType.totalCount ? stat.totalCount : (spec.type == StatColumnType.successCount ? stat.successCount : stat.failureCount)).toString(); break; case StatColumnType.successRate: text = stat.totalCount > 0 ? "${stat.successRate.toStringAsFixed(0)}%" : "-"; break; default: text = '0'; break; } } else { if (spec.type == StatColumnType.successRate) text = '-'; else text = '0'; } } Color? bgColor = playerRowIndex.isOdd ? Colors.grey.shade100 : Colors.white; cells.add(Container(width: isFixed ? fixedWidth : dynamicWidth, height: 40, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5), color: bgColor), child: Text(text, style: cellStyle))); } return Row(children: cells); }).toList()); }
}