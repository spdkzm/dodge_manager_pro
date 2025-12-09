// lib/features/analysis/presentation/pages/analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../application/analysis_controller.dart';
import '../../domain/player_stats.dart';
import '../../../game_record/domain/models.dart';

import '../../../settings/domain/action_definition.dart';
import '../../../settings/data/action_dao.dart';
import '../../../team_mgmt/application/team_store.dart';
import '../../../team_mgmt/data/csv_export_service.dart';
import '../../../team_mgmt/domain/schema.dart';
import '../../../team_mgmt/domain/roster_item.dart';

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
  // ignore: unused_field
  List<String> _sortedActionNames = [];
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;
  String? _selectedMatchId;
  bool _isInitialLoadComplete = false;
  late TabController _tabController;
  List<MatchType> _selectedMatchTypes = [];

  List<String> _editingCourtMembers = [];
  List<String> _editingBenchMembers = [];
  // ignore: unused_field
  bool _isMemberEditing = false;

  final TextEditingController _opponentCtrl = TextEditingController();
  final TextEditingController _venueCtrl = TextEditingController();
  String? _opponentId;
  String? _venueId;
  DateTime _editingDate = DateTime.now();
  MatchType _editingMatchType = MatchType.practiceMatch;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) { _loadActionOrder(); });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _opponentCtrl.dispose();
    _venueCtrl.dispose();
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
    ref.read(analysisControllerProvider.notifier).analyze(
        year: _selectedYear, month: _selectedMonth, day: _selectedDay, matchId: _selectedMatchId,
        targetTypes: _selectedMatchTypes.isEmpty ? null : _selectedMatchTypes
    );

    if (_selectedMatchId != null) {
      _loadMemberEditorData();
    }
  }

  void _showFilterDialog() {
    final types = MatchType.values;
    final tempSelected = List<MatchType>.from(_selectedMatchTypes.isEmpty ? types : _selectedMatchTypes);
    showDialog(context: context, builder: (ctx) { return StatefulBuilder(builder: (context, setStateDialog) { return AlertDialog(title: const Text("集計フィルタ"), content: Column(mainAxisSize: MainAxisSize.min, children: types.map((type) { final isChecked = tempSelected.contains(type); return CheckboxListTile(title: Text(_getMatchTypeName(type)), value: isChecked, onChanged: (val) { setStateDialog(() { if (val == true) { tempSelected.add(type); } else { tempSelected.remove(type); } }); }); }).toList()), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")), ElevatedButton(onPressed: () { setState(() { if (tempSelected.length == types.length || tempSelected.isEmpty) { _selectedMatchTypes = []; } else { _selectedMatchTypes = tempSelected; } }); Navigator.pop(ctx); _runAnalysis(); }, child: const Text("適用"))]); }); });
  }

  String _getMatchTypeName(MatchType type) { switch (type) { case MatchType.official: return "大会/公式戦"; case MatchType.practiceMatch: return "練習試合"; case MatchType.practice: return "練習"; } }
  IconData _getMatchTypeIcon(MatchType type) { switch (type) { case MatchType.official: return Icons.emoji_events; case MatchType.practiceMatch: return Icons.handshake; case MatchType.practice: return Icons.sports_handball; } }

  Future<void> _handleCsvExport() async {
    final asyncStats = ref.read(analysisControllerProvider); final stats = asyncStats.valueOrNull; if (stats == null || stats.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("出力するデータがありません"))); return; }
    final store = ref.read(teamStoreProvider); final currentTeam = store.currentTeam; final controller = ref.read(analysisControllerProvider.notifier); final availableMatches = ref.read(availableMatchesProvider); if (currentTeam == null) return;
    final Map<String, Map<String, dynamic>> options = {};
    options['全期間 (累計)'] = {'y': null, 'm': null, 'd': null, 'mid': null, 'label': '全期間'};
    if (_selectedYear != null) options['${_selectedYear}年'] = {'y': _selectedYear, 'm': null, 'd': null, 'mid': null, 'label': '${_selectedYear}年'};
    if (_selectedMonth != null) options['${_selectedYear}年${_selectedMonth}月'] = {'y': _selectedYear, 'm': _selectedMonth, 'd': null, 'mid': null, 'label': '${_selectedYear}年${_selectedMonth}月'};
    if (_selectedDay != null) options['${_selectedYear}年${_selectedMonth}月${_selectedDay}日'] = {'y': _selectedYear, 'm': _selectedMonth, 'd': _selectedDay, 'mid': null, 'label': '${_selectedYear}年${_selectedMonth}月${_selectedDay}日'};
    if (_selectedMatchId != null) { final matchName = availableMatches[_selectedMatchId] ?? '試合'; options['この試合 ($matchName)'] = {'y': null, 'm': null, 'd': null, 'mid': _selectedMatchId, 'label': matchName}; }
    List<MatchType> exportMatchTypes = List.from(MatchType.values);
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setStateDialog) { return AlertDialog(title: const Text("CSV出力設定"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("1. 含める試合種別", style: TextStyle(fontWeight: FontWeight.bold)), Wrap(spacing: 8, children: MatchType.values.map((type) { return FilterChip(label: Text(_getMatchTypeName(type).split('/').first), selected: exportMatchTypes.contains(type), onSelected: (selected) { setStateDialog(() { if (selected) exportMatchTypes.add(type); else exportMatchTypes.remove(type); }); }); }).toList()), const SizedBox(height: 16), const Text("2. 出力範囲の選択", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), ...options.entries.map((entry) { return ListTile(dense: true, leading: const Icon(Icons.file_download), title: Text(entry.key), onTap: () async { if (exportMatchTypes.isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("種別を1つ以上選択してください"))); return; } Navigator.pop(ctx); final params = entry.value; try { final stats = await controller.fetchStatsForExport(year: params['y'], month: params['m'], day: params['d'], matchId: params['mid'], targetTypes: exportMatchTypes); if (stats.isEmpty) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("対象データがありません"))); return; } await CsvExportService().exportAnalysisStats(currentTeam.name, params['label'], stats, controller.actionDefinitions); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("CSVを出力しました"))); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("エラー: $e"), backgroundColor: Colors.red)); } }); })])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル"))]); }));
  }

  // ★追加: 追加メニュー (ログか結果か選択)
  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.playlist_add, color: Colors.indigo),
                title: const Text('プレーログを追加'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditLogDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.orange),
                title: const Text('試合結果を記録・修正'),
                onTap: () {
                  Navigator.pop(ctx);
                  final record = ref.read(selectedMatchRecordProvider);
                  if (record != null) {
                    _showResultEditDialog(record);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditLogDialog({LogEntry? log}) {
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

  Widget _buildVerticalTabs<T>({ required List<T?> items, required T? selectedItem, required String Function(T?) labelBuilder, required Function(T?) onSelect, required double width, required Color color, }) { return Container(width: width, color: color, child: ListView.builder(padding: const EdgeInsets.symmetric(vertical: 8), itemCount: items.length, itemBuilder: (context, index) { final item = items[index]; final isSelected = item == selectedItem; return Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: TextButton(style: TextButton.styleFrom(backgroundColor: isSelected ? Colors.indigo.shade100 : Colors.transparent, foregroundColor: isSelected ? Colors.indigo : Colors.black87, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12)), onPressed: () => onSelect(item), child: Text(labelBuilder(item), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12), overflow: TextOverflow.ellipsis))); })); }

  Future<void> _loadMemberEditorData() async {
    final store = ref.read(teamStoreProvider);
    if (!store.isLoaded) await store.loadFromDb();
    final currentTeam = store.currentTeam;
    final matchRecord = ref.read(selectedMatchRecordProvider);

    if (currentTeam == null || _selectedMatchId == null) return;

    if (matchRecord != null) {
      _opponentCtrl.text = matchRecord.opponent;
      _venueCtrl.text = matchRecord.venueName ?? "";
      _opponentId = matchRecord.opponentId;
      _venueId = matchRecord.venueId;
      _editingDate = DateTime.tryParse(matchRecord.date) ?? DateTime.now();
      _editingMatchType = matchRecord.matchType;
    }

    final allMembers = <String, String>{};
    String? numberFieldId; String? courtNameFieldId; String? nameFieldId;
    for(var f in currentTeam.schema) {
      if(f.type == FieldType.uniformNumber) numberFieldId = f.id;
      if(f.type == FieldType.courtName) courtNameFieldId = f.id;
      if(f.type == FieldType.personName) nameFieldId = f.id;
    }
    for (var item in currentTeam.items) {
      final num = item.data[numberFieldId]?.toString() ?? "";
      if (num.isNotEmpty) {
        String name = "";
        if (courtNameFieldId != null) name = item.data[courtNameFieldId]?.toString() ?? "";
        if (name.isEmpty && nameFieldId != null) { final n = item.data[nameFieldId]; if (n is Map) name = "${n['last'] ?? ''} ${n['first'] ?? ''}".trim(); }
        allMembers[num] = name;
      }
    }

    final courtMembers = await ref.read(analysisControllerProvider.notifier).getMatchMembers(_selectedMatchId!);
    final benchMembers = allMembers.keys.where((n) => !courtMembers.contains(n)).toList();

    int sortFunc(String a, String b) => (int.tryParse(a) ?? 999).compareTo(int.tryParse(b) ?? 999);
    courtMembers.sort(sortFunc);
    benchMembers.sort(sortFunc);

    setState(() {
      _editingCourtMembers = courtMembers;
      _editingBenchMembers = benchMembers;
      _isMemberEditing = false;
    });
  }

  Future<void> _saveMembers() async {
    if (_selectedMatchId == null) return;
    await ref.read(analysisControllerProvider.notifier).updateMatchMembers(_selectedMatchId!, _editingCourtMembers);
    setState(() => _isMemberEditing = false);
    _runAnalysis();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("出場メンバーを更新しました")));
  }

  Future<void> _saveMatchInfo() async {
    if (_selectedMatchId == null) return;

    await ref.read(analysisControllerProvider.notifier).updateMatchInfo(
        _selectedMatchId!,
        _editingDate,
        _editingMatchType,
        opponentName: _opponentCtrl.text,
        opponentId: _opponentId,
        venueName: _venueCtrl.text,
        venueId: _venueId
    );

    _runAnalysis();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("基本情報を更新しました")));
  }

  @override
  Widget build(BuildContext context) {
    final teamStore = ref.watch(teamStoreProvider); final currentTeam = teamStore.currentTeam;
    ref.listen(teamStoreProvider, (previous, next) { if (previous?.currentTeam?.id != next.currentTeam?.id) { setState(() { _selectedYear = null; _selectedMonth = null; _selectedDay = null; _selectedMatchId = null; }); _loadActionOrder().then((_) => _runAnalysis()); } });

    final asyncStats = ref.watch(analysisControllerProvider); final matchRecord = ref.watch(selectedMatchRecordProvider);

    ref.listen<MatchRecord?>(selectedMatchRecordProvider, (prev, next) {
      if (next != null) {
        _opponentCtrl.text = next.opponent;
        _venueCtrl.text = next.venueName ?? "";
        _opponentId = next.opponentId;
        _venueId = next.venueId;
        _editingDate = DateTime.tryParse(next.date) ?? DateTime.now();
        _editingMatchType = next.matchType;
        setState(() {});
      }
    });

    final availableYears = ref.watch(availableYearsProvider); final availableMonths = ref.watch(availableMonthsProvider); final availableDays = ref.watch(availableDaysProvider); final availableMatches = ref.watch(availableMatchesProvider);
    final yearTabs = [null, ...availableYears]; final monthTabs = [null, ...availableMonths]; final dayTabs = [null, ...availableDays]; final matchTabs = [null, ...availableMatches.keys];
    final isLogTabVisible = _selectedMatchId != null && _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (_selectedMatchId != null && matchRecord != null) Row(children: [Icon(_getMatchTypeIcon(matchRecord.matchType), size: 16, color: Colors.black54), const SizedBox(width: 4), Text(availableMatches[_selectedMatchId] ?? "試合", style: const TextStyle(fontSize: 16)), const SizedBox(width: 8), const Icon(Icons.calendar_today, size: 14, color: Colors.black54), const SizedBox(width: 4), Text(matchRecord.date, style: const TextStyle(fontSize: 12, color: Colors.black54))]) else ...[const Text("データ分析", style: TextStyle(fontSize: 16)), Text(currentTeam?.name ?? "", style: const TextStyle(fontSize: 12, color: Colors.black54))]]),
        actions: [IconButton(icon: Icon(Icons.filter_alt, color: _selectedMatchTypes.isNotEmpty ? Colors.indigo : Colors.grey), tooltip: "種別フィルタ", onPressed: _showFilterDialog), IconButton(icon: const Icon(Icons.file_download), tooltip: "CSV出力", onPressed: _handleCsvExport), IconButton(icon: const Icon(Icons.refresh), onPressed: _runAnalysis)],
      ),
      body: Row(children: [_buildVerticalTabs<int>(items: yearTabs, selectedItem: _selectedYear, labelBuilder: (y) => y == null ? '全期間' : '$y年', onSelect: (y) { setState(() { _selectedYear = y; _selectedMonth = null; _selectedDay = null; _selectedMatchId = null; }); _runAnalysis(); }, width: 90, color: Colors.grey[50]!), if (_selectedYear != null) _buildVerticalTabs<int>(items: monthTabs, selectedItem: _selectedMonth, labelBuilder: (m) => m == null ? '年計' : '$m月', onSelect: (m) { setState(() { _selectedMonth = m; _selectedDay = null; _selectedMatchId = null; }); _runAnalysis(); }, width: 60, color: Colors.grey[100]!), if (_selectedMonth != null) _buildVerticalTabs<int>(items: dayTabs, selectedItem: _selectedDay, labelBuilder: (d) => d == null ? '月計' : '$d日', onSelect: (d) { setState(() { _selectedDay = d; _selectedMatchId = null; }); _runAnalysis(); }, width: 60, color: Colors.grey[200]!), if (_selectedDay != null) _buildVerticalTabs<String>(items: matchTabs, selectedItem: _selectedMatchId, labelBuilder: (id) => id == null ? '日計' : (availableMatches[id] ?? '試合'), onSelect: (id) { setState(() { _selectedMatchId = id; }); _runAnalysis(); }, width: 140, color: Colors.grey[300]!), const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: Column(children: [
          if (_selectedMatchId != null) Container(color: Colors.grey[50], child: TabBar(
              controller: _tabController,
              labelColor: Colors.indigo, unselectedLabelColor: Colors.grey, indicatorColor: Colors.indigo,
              onTap: (idx) {
                setState((){});
                if (idx == 2) _loadMemberEditorData();
              },
              tabs: const [Tab(icon: Icon(Icons.analytics, size: 18), text: "集計"), Tab(icon: Icon(Icons.list, size: 18), text: "ログ"), Tab(icon: Icon(Icons.info_outline, size: 18), text: "試合情報")]
          )),
          const Divider(height: 1),
          Expanded(child: _selectedMatchId != null ? TabBarView(controller: _tabController, children: [_buildStatsContent(asyncStats), _buildLogContent(asyncStats), _buildMatchInfoContent()]) : _buildStatsContent(asyncStats))
        ]))]),
      // ★修正: 追加ボタン押下時にメニューを表示
      floatingActionButton: isLogTabVisible ? FloatingActionButton(onPressed: _showAddMenu, child: const Icon(Icons.add)) : null,
    );
  }

  Widget _buildMatchInfoContent() { if (_selectedMatchId == null) return const SizedBox(); final store = ref.watch(teamStoreProvider); final team = store.currentTeam; final matchRecord = ref.watch(selectedMatchRecordProvider); if (team == null || matchRecord == null) return const Center(child: CircularProgressIndicator()); final opponents = team.opponentItems; final venues = team.venueItems; final opSchema = team.opponentSchema.firstWhere((f)=>f.label=='チーム名', orElse: ()=>team.opponentSchema.first); final veSchema = team.venueSchema.firstWhere((f)=>f.label=='会場名', orElse: ()=>team.venueSchema.first); final Set<String> playersWithLogs = matchRecord.logs.map((l) => l.playerNumber).toSet(); final Map<String, String> nameMap = {}; String? numberFieldId; String? courtNameFieldId; for(var f in team.schema) { if(f.type == FieldType.uniformNumber) numberFieldId = f.id; if(f.type == FieldType.courtName) courtNameFieldId = f.id; } for(var item in team.items) { final num = item.data[numberFieldId]?.toString() ?? ""; if (num.isNotEmpty) { final name = item.data[courtNameFieldId]?.toString() ?? ""; nameMap[num] = name; } } return SingleChildScrollView( padding: const EdgeInsets.all(8.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Card( elevation: 2, child: Padding( padding: const EdgeInsets.all(12.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ const Text("基本情報編集", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 12), InkWell( onTap: () async { final picked = await showDatePicker( context: context, initialDate: _editingDate, firstDate: DateTime(2000), lastDate: DateTime(2030) ); if(picked != null) setState(() => _editingDate = picked); }, child: InputDecorator( decoration: const InputDecoration(labelText: "日付", border: OutlineInputBorder()), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text(DateFormat('yyyy/MM/dd (E)', 'ja').format(_editingDate)), const Icon(Icons.calendar_today, size: 20), ], ), ), ), const SizedBox(height: 8), DropdownButtonFormField<MatchType>( value: _editingMatchType, decoration: const InputDecoration(labelText: "試合種別", border: OutlineInputBorder()), items: MatchType.values.map((t) => DropdownMenuItem(value: t, child: Text(_getMatchTypeName(t)))).toList(), onChanged: (val) { if(val != null) setState(() => _editingMatchType = val); }, ), const SizedBox(height: 8), Row(children: [ Expanded(child: TextField(controller: _opponentCtrl, decoration: const InputDecoration(labelText: "対戦相手"))), PopupMenuButton<RosterItem>( icon: const Icon(Icons.list), onSelected: (item) { setState(() { _opponentCtrl.text = item.data[opSchema.id]?.toString() ?? ""; _opponentId = item.id; }); }, itemBuilder: (context) => opponents.map((i) => PopupMenuItem(value: i, child: Text(i.data[opSchema.id]?.toString() ?? ""))).toList(), ), ]), const SizedBox(height: 8), Row(children: [ Expanded(child: TextField(controller: _venueCtrl, decoration: const InputDecoration(labelText: "会場"))), PopupMenuButton<RosterItem>( icon: const Icon(Icons.list), onSelected: (item) { setState(() { _venueCtrl.text = item.data[veSchema.id]?.toString() ?? ""; _venueId = item.id; }); }, itemBuilder: (context) => venues.map((i) => PopupMenuItem(value: i, child: Text(i.data[veSchema.id]?.toString() ?? ""))).toList(), ), ]), const SizedBox(height: 12), Align( alignment: Alignment.centerRight, child: ElevatedButton.icon( onPressed: _saveMatchInfo, icon: const Icon(Icons.save, size: 16), label: const Text("基本情報を更新"), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade50), ), ) ], ), ), ), const SizedBox(height: 16), Card( elevation: 2, child: Column( children: [ Padding( padding: const EdgeInsets.all(8), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text("出場メンバー編集", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), ElevatedButton.icon( onPressed: _saveMembers, icon: const Icon(Icons.save), label: const Text("メンバー変更を保存"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), ) ], ), ), const Divider(height: 1), SizedBox( height: 400, child: Row( children: [ Expanded( child: Column( children: [ Container(padding: const EdgeInsets.all(8), color: Colors.orange.shade100, width: double.infinity, child: Text("出場 (${_editingCourtMembers.length})", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))), Expanded( child: ListView.builder( itemCount: _editingCourtMembers.length, itemBuilder: (context, index) { final num = _editingCourtMembers[index]; final hasLog = playersWithLogs.contains(num); return Card( color: Colors.white, margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: ListTile( visualDensity: VisualDensity.compact, leading: CircleAvatar(backgroundColor: Colors.orange, radius: 12, child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 10))), title: Text(nameMap[num] ?? "", style: const TextStyle(fontSize: 12)), trailing: hasLog ? const Icon(Icons.assignment, color: Colors.grey, size: 16) : null, onTap: () { if (hasLog) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("背番号$numは記録があるため外せません"), backgroundColor: Colors.red)); return; } setState(() { _editingCourtMembers.removeAt(index); _editingBenchMembers.add(num); _editingBenchMembers.sort((a,b)=>(int.tryParse(a)??999).compareTo(int.tryParse(b)??999)); }); }, ), ); }, ), ), ], ), ), const VerticalDivider(width: 1), Expanded( child: Column( children: [ Container(padding: const EdgeInsets.all(8), color: Colors.grey.shade200, width: double.infinity, child: Text("未出場 (${_editingBenchMembers.length})", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))), Expanded( child: ListView.builder( itemCount: _editingBenchMembers.length, itemBuilder: (context, index) { final num = _editingBenchMembers[index]; return Card( color: Colors.grey.shade50, margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: ListTile( visualDensity: VisualDensity.compact, leading: CircleAvatar(backgroundColor: Colors.grey, radius: 12, child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 10))), title: Text(nameMap[num] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)), onTap: () { setState(() { _editingBenchMembers.removeAt(index); _editingCourtMembers.add(num); _editingCourtMembers.sort((a,b)=>(int.tryParse(a)??999).compareTo(int.tryParse(b)??999)); }); }, ), ); }, ), ), ], ), ), ], ), ), ], ), ), ], ), ); }
  Widget _buildStatsContent(AsyncValue<List<PlayerStats>> asyncStats) { return asyncStats.when(loading: () => const Center(child: CircularProgressIndicator()), error: (err, stack) => Center(child: Text("エラー: $err")), data: (stats) { if (stats.isEmpty) return const Center(child: Text("データがありません")); return _buildDataTable(stats); }); }
  Widget _buildLogContent(AsyncValue<List<PlayerStats>> asyncStats) { final matchRecord = ref.watch(selectedMatchRecordProvider); if (matchRecord == null) return const Center(child: CircularProgressIndicator()); final logs = matchRecord.logs; final Map<String, String> nameMap = {}; asyncStats.whenData((stats) { for (var p in stats) { nameMap[p.playerNumber] = p.playerName; } }); return ListView.separated( itemCount: logs.length + 1, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (context, index) { if (index == logs.length) { return _buildResultFooter(matchRecord); } final log = logs[index]; final name = nameMap[log.playerNumber] ?? ""; if (log.type == LogType.system) { return Container(color: Colors.grey[50], padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), child: Row(children: [SizedBox(width: 45, child: Text(log.gameTime, style: const TextStyle(color: Colors.grey, fontSize: 11))), const SizedBox(width: 90), Expanded(child: Text(log.action, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))])); } String resultText = ""; Color? bgColor = Colors.white; if (log.result == ActionResult.success) { resultText = "(成功)"; bgColor = Colors.red.shade50; } else if (log.result == ActionResult.failure) { resultText = "(失敗)"; bgColor = Colors.blue.shade50; } return InkWell(onTap: () => _showEditLogDialog(log: log), child: Container(color: bgColor, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), child: Row(children: [SizedBox(width: 45, child: Text(log.gameTime, style: const TextStyle(color: Colors.grey, fontSize: 11))), SizedBox(width: 90, child: RichText(overflow: TextOverflow.ellipsis, text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 12), children: [TextSpan(text: "#${log.playerNumber} ", style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: name, style: const TextStyle(fontSize: 11, color: Colors.black54))]))), Expanded(child: Text("${log.action} $resultText", style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)), if (log.subAction != null) Text(log.subAction!, style: const TextStyle(color: Colors.grey, fontSize: 11))]))); } ); }
  Widget _buildResultFooter(MatchRecord record) { if (record.result == MatchResult.none) return const SizedBox(); Color bgColor = Colors.white; String resultText = ""; if (record.result == MatchResult.win) { bgColor = Colors.red.shade100; resultText = "WIN"; } else if (record.result == MatchResult.lose) { bgColor = Colors.blue.shade100; resultText = "LOSE"; } else { bgColor = Colors.grey.shade200; resultText = "DRAW"; } String scoreText = ""; if (record.scoreOwn != null && record.scoreOpponent != null) { scoreText = "${record.scoreOwn} - ${record.scoreOpponent}"; } if (record.isExtraTime) { resultText += " (延長戦)"; if (record.extraScoreOwn != null) { scoreText += " [EX: ${record.extraScoreOwn} - ${record.extraScoreOpponent}]"; } } return InkWell( onTap: () => _showResultEditDialog(record), child: Container( color: bgColor, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), child: Row( mainAxisAlignment: MainAxisAlignment.center, children: [ Text(resultText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(width: 16), Text(scoreText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), const SizedBox(width: 8), const Icon(Icons.edit, size: 16, color: Colors.black54), ], ), ), ); }
  void _showResultEditDialog(MatchRecord record) { MatchResult tempResult = record.result; MatchResult tempExtraResult = record.isExtraTime ? record.result : MatchResult.none; if (record.isExtraTime) tempResult = MatchResult.draw; final scoreOwnCtrl = TextEditingController(text: record.scoreOwn?.toString() ?? ""); final scoreOppCtrl = TextEditingController(text: record.scoreOpponent?.toString() ?? ""); final extraScoreOwnCtrl = TextEditingController(text: record.extraScoreOwn?.toString() ?? ""); final extraScoreOppCtrl = TextEditingController(text: record.extraScoreOpponent?.toString() ?? ""); showDialog(context: context, builder: (context) { return StatefulBuilder(builder: (context, setStateDialog) { Widget buildScoreInput(String label, TextEditingController ctrl1, TextEditingController ctrl2) { return Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 50, child: TextField(controller: ctrl1, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()))), const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("-", style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 50, child: TextField(controller: ctrl2, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()))),]); } Widget buildResultToggle(MatchResult current, Function(MatchResult) onSelect) { return Row(mainAxisAlignment: MainAxisAlignment.center, children: [ChoiceChip(label: const Text("勝"), selected: current == MatchResult.win, onSelected: (v) => onSelect(MatchResult.win), selectedColor: Colors.red.shade100), const SizedBox(width: 8), ChoiceChip(label: const Text("引分"), selected: current == MatchResult.draw, onSelected: (v) => onSelect(MatchResult.draw), selectedColor: Colors.grey.shade300), const SizedBox(width: 8), ChoiceChip(label: const Text("負"), selected: current == MatchResult.lose, onSelected: (v) => onSelect(MatchResult.lose), selectedColor: Colors.blue.shade100),]); } return AlertDialog( title: const Text("試合結果の編集"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("本戦結果", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), buildResultToggle(tempResult, (r) => setStateDialog(() => tempResult = r)), const SizedBox(height: 8), buildScoreInput("スコア", scoreOwnCtrl, scoreOppCtrl), if (tempResult == MatchResult.draw) ...[const Divider(height: 24), Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)), child: Column(children: [const Text("▼ 延長・決着戦", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("なし", style: TextStyle(fontSize: 12)), Radio<MatchResult>(value: MatchResult.none, groupValue: tempExtraResult, onChanged: (v) => setStateDialog(() => tempExtraResult = v!)), const Text("勝", style: TextStyle(fontSize: 12)), Radio<MatchResult>(value: MatchResult.win, groupValue: tempExtraResult, onChanged: (v) => setStateDialog(() => tempExtraResult = v!)), const Text("負", style: TextStyle(fontSize: 12)), Radio<MatchResult>(value: MatchResult.lose, groupValue: tempExtraResult, onChanged: (v) => setStateDialog(() => tempExtraResult = v!))]), if (tempExtraResult != MatchResult.none) buildScoreInput("延長スコア", extraScoreOwnCtrl, extraScoreOppCtrl)]))]])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")), ElevatedButton(onPressed: () async { MatchResult finalResult = tempExtraResult != MatchResult.none ? tempExtraResult : tempResult; bool isExtra = tempExtraResult != MatchResult.none; await ref.read(analysisControllerProvider.notifier).updateMatchResult(ref.read(selectedMatchRecordProvider)!.id, finalResult, int.tryParse(scoreOwnCtrl.text), int.tryParse(scoreOppCtrl.text), isExtra, int.tryParse(extraScoreOwnCtrl.text), int.tryParse(extraScoreOppCtrl.text)); if (mounted) Navigator.pop(context); }, child: const Text("保存"))], ); }); }, ); }
  Widget _buildDataTable(List<PlayerStats> originalStats) { final controller = ref.read(analysisControllerProvider.notifier); final definitions = controller.actionDefinitions; final List<_ColumnSpec> columnSpecs = []; columnSpecs.add(_ColumnSpec(label: "背番号", type: StatColumnType.number, isFixed: true)); columnSpecs.add(_ColumnSpec(label: "コートネーム", type: StatColumnType.name, isFixed: true)); columnSpecs.add(_ColumnSpec(label: "試合数", type: StatColumnType.matches, isFixed: true)); final dataActionNames = <String>{}; for (var p in originalStats) dataActionNames.addAll(p.actions.keys); final displayDefinitions = List<ActionDefinition>.from(definitions); final definedNames = definitions.map((d) => d.name).toSet(); for (var name in dataActionNames) { if (!definedNames.contains(name)) displayDefinitions.add(ActionDefinition(name: name, hasSuccess: false, hasFailure: false)); } for (var action in displayDefinitions) { if (action.hasSuccess && action.hasFailure) { columnSpecs.add(_ColumnSpec(label: "成功", type: StatColumnType.successCount, actionName: action.name)); columnSpecs.add(_ColumnSpec(label: "失敗", type: StatColumnType.failureCount, actionName: action.name)); columnSpecs.add(_ColumnSpec(label: "成功率", type: StatColumnType.successRate, actionName: action.name)); } else if (action.hasSuccess) { columnSpecs.add(_ColumnSpec(label: "成功数", type: StatColumnType.successCount, actionName: action.name)); } else if (action.hasFailure) { columnSpecs.add(_ColumnSpec(label: "失敗数", type: StatColumnType.failureCount, actionName: action.name)); } else { columnSpecs.add(_ColumnSpec(label: "数", type: StatColumnType.totalCount, actionName: action.name)); } } final sortedStats = List<PlayerStats>.from(originalStats); sortedStats.sort((a, b) => (int.tryParse(a.playerNumber) ?? 999).compareTo(int.tryParse(b.playerNumber) ?? 999)); final maxValues = <String, Map<StatColumnType, double>>{}; return SingleChildScrollView(scrollDirection: Axis.vertical, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildTableHeader(columnSpecs), const Divider(height: 1, thickness: 1), _buildTableBody(sortedStats, columnSpecs, maxValues)]))); }
  Widget _buildTableHeader(List<_ColumnSpec> columnSpecs) { const headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87); const headerHeight = 40.0; const fixedWidth = 90.0; const dynamicWidth = 60.0; final fixedSpecs = columnSpecs.where((s) => s.isFixed).toList(); final dynamicSpecs = columnSpecs.where((s) => !s.isFixed).toList(); final List<Widget> topRowCells = []; topRowCells.addAll(fixedSpecs.map((_) => SizedBox(width: fixedWidth, height: headerHeight))); String? currentActionName; int currentActionColumnCount = 0; for (int i = 0; i < dynamicSpecs.length; i++) { final spec = dynamicSpecs[i]; if (spec.actionName != currentActionName) { if (currentActionName != null) { topRowCells.add(Container(width: dynamicWidth * currentActionColumnCount, height: headerHeight, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[200]), child: Text(currentActionName, style: headerStyle, textAlign: TextAlign.center))); } currentActionName = spec.actionName; currentActionColumnCount = 1; } else { currentActionColumnCount++; } if (i == dynamicSpecs.length - 1 || (i + 1 < dynamicSpecs.length && dynamicSpecs[i + 1].actionName != currentActionName)) { topRowCells.add(Container(width: dynamicWidth * currentActionColumnCount, height: headerHeight, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[200]), child: Text(currentActionName!, style: headerStyle, textAlign: TextAlign.center))); currentActionName = null; currentActionColumnCount = 0; } } final List<Widget> bottomRowCells = []; for (final spec in fixedSpecs) { bottomRowCells.add(Container(width: fixedWidth, height: headerHeight, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[200]), child: Text(spec.label, style: headerStyle, textAlign: TextAlign.center))); } for (final spec in dynamicSpecs) { bottomRowCells.add(Container(width: dynamicWidth, height: headerHeight, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.grey[100]), child: Text(spec.label, style: headerStyle, textAlign: TextAlign.center, maxLines: 1))); } return Column(children: [Row(children: topRowCells), Row(children: bottomRowCells)]); }
  Widget _buildTableBody(List<PlayerStats> sortedStats, List<_ColumnSpec> columnSpecs, Map<String, Map<StatColumnType, double>> maxValues) { const cellStyle = TextStyle(fontSize: 13, color: Colors.black87); const fixedWidth = 90.0; const dynamicWidth = 60.0; return Column(children: sortedStats.asMap().entries.map((entry) { final playerRowIndex = entry.key; final player = entry.value; final List<Widget> cells = []; for (final spec in columnSpecs) { final isFixed = spec.isFixed; final stat = player.actions[spec.actionName]; String text = '-'; if (spec.type == StatColumnType.number) text = player.playerNumber; if (spec.type == StatColumnType.name) text = player.playerName; if (spec.type == StatColumnType.matches) text = player.matchesPlayed.toString(); if (!isFixed) { if (stat != null) { switch (spec.type) { case StatColumnType.successCount: case StatColumnType.failureCount: case StatColumnType.totalCount: text = (spec.type == StatColumnType.totalCount ? stat.totalCount : (spec.type == StatColumnType.successCount ? stat.successCount : stat.failureCount)).toString(); break; case StatColumnType.successRate: text = stat.totalCount > 0 ? "${stat.successRate.toStringAsFixed(0)}%" : "-"; break; default: text = '0'; break; } } else { if (spec.type == StatColumnType.successRate) text = '-'; else text = '0'; } } Color? bgColor = playerRowIndex.isOdd ? Colors.grey.shade100 : Colors.white; cells.add(Container(width: isFixed ? fixedWidth : dynamicWidth, height: 40, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5), color: bgColor), child: Text(text, style: cellStyle))); } return Row(children: cells); }).toList()); }
}