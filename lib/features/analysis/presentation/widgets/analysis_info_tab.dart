// lib/features/analysis/presentation/widgets/analysis_info_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/analysis_controller.dart';
import '../../../game_record/domain/models.dart';
import '../../../team_mgmt/application/team_store.dart';
import '../../../team_mgmt/domain/roster_item.dart';

class AnalysisInfoTab extends ConsumerStatefulWidget {
  final String matchId;
  final VoidCallback onUpdate; // ★追加: 更新完了時のコールバック

  const AnalysisInfoTab({
    super.key,
    required this.matchId,
    required this.onUpdate,
  });

  @override
  ConsumerState<AnalysisInfoTab> createState() => _AnalysisInfoTabState();
}

class _AnalysisInfoTabState extends ConsumerState<AnalysisInfoTab> {
  final TextEditingController _opponentCtrl = TextEditingController();
  final TextEditingController _venueCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  String? _opponentId;
  String? _venueId;
  DateTime _editingDate = DateTime.now();
  MatchType _editingMatchType = MatchType.practiceMatch;
  String? _lastLoadedMatchId; // ★修正: 最後にデータをロードして成功したMatch IDを追加

  @override
  void initState() {
    super.initState();
    // initStateではref.readで初期ロードを試みる
    _loadMatchData(readOnly: true);
  }

  @override
  void didUpdateWidget(covariant AnalysisInfoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId != widget.matchId) {
      // matchId が変わったら、最後にロードしたIDをリセットし、_loadMatchDataを実行
      // buildメソッドのwatchが新しいデータの到着を待って更新を行う
      _lastLoadedMatchId = null;
      _loadMatchData(readOnly: true);
    }
  }

  @override
  void dispose() {
    _opponentCtrl.dispose();
    _venueCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ★修正: readOnly引数を追加し、setStateを条件付きで実行するように変更
  void _loadMatchData({bool readOnly = false}) {
    final matchRecord = ref.read(selectedMatchRecordProvider);

    // 現在のmatchIdに対応するデータが来ており、かつ、まだロードされていない場合のみ処理を実行
    if (matchRecord != null && matchRecord.id == widget.matchId && _lastLoadedMatchId != widget.matchId) {
      _opponentCtrl.text = matchRecord.opponent;
      _venueCtrl.text = matchRecord.venueName ?? "";
      _noteCtrl.text = matchRecord.note ?? "";
      _opponentId = matchRecord.opponentId;
      _venueId = matchRecord.venueId;

      final newEditingDate = DateTime.tryParse(matchRecord.date.replaceAll('/', '-')) ?? DateTime.now();

      // readOnlyでない（watch経由の正式な更新）場合、または初期ロード（initState）の場合にsetState
      if (!readOnly) {
        // buildから呼ばれた正式なデータ更新時にはsetStateで画面を再描画する
        setState(() {
          _editingDate = newEditingDate;
          _editingMatchType = matchRecord.matchType;
          _lastLoadedMatchId = widget.matchId; // 成功したIDを記録
        });
      } else {
        // initState/didUpdateWidgetからの呼び出しの場合、setStateは不要（または安全ではない）
        _editingDate = newEditingDate;
        _editingMatchType = matchRecord.matchType;
        _lastLoadedMatchId = widget.matchId;
      }
    }
  }

  Future<void> _saveMatchInfo() async {
    await ref.read(analysisControllerProvider.notifier).updateMatchInfo(
      widget.matchId,
      _editingDate,
      _editingMatchType,
      opponentName: _opponentCtrl.text,
      opponentId: _opponentId,
      venueName: _venueCtrl.text,
      venueId: _venueId,
      note: _noteCtrl.text,
    );

    // ★変更: 親画面の再ロード処理を呼び出す
    widget.onUpdate();

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("基本情報を更新しました")));
  }

  String _getMatchTypeName(MatchType type) { switch (type) { case MatchType.official: return "大会/公式戦"; case MatchType.practiceMatch: return "練習試合"; case MatchType.practice: return "練習"; } }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(teamStoreProvider);
    final team = store.currentTeam;
    // ★修正: selectedMatchRecordProvider を watch する
    final matchRecord = ref.watch(selectedMatchRecordProvider);

    // Provider のデータが更新されたときに、現在のウィジェットの matchId と一致するかをチェックし、
    // まだロードされていない場合はロード処理を実行する
    if (matchRecord != null && matchRecord.id == widget.matchId && _lastLoadedMatchId != widget.matchId) {
      // build完了後のマイクロタスクで_loadMatchDataを呼び出す（_loadMatchData内でsetStateが呼ばれるため）
      Future.microtask(() => _loadMatchData());
      // この時点で matchRecord を利用すると古いデータが表示される可能性があるため、matchRecordが null/古い状態であればローディングを表示
    }

    // 最初にロードが完了するまでローディングを表示、またはデータがない場合は何も表示しない
    if (team == null || matchRecord == null || _lastLoadedMatchId != widget.matchId) {
      // 試合IDは来ているがデータがまだ来ていない、または古いIDの場合
      return const Center(child: CircularProgressIndicator());
    }

    final opponents = team.opponentItems;
    final venues = team.venueItems;
    final opSchema = team.opponentSchema.firstWhere((f)=>f.label=='チーム名', orElse: ()=>team.opponentSchema.first);
    final veSchema = team.venueSchema.firstWhere((f)=>f.label=='会場名', orElse: ()=>team.venueSchema.first);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("基本情報編集", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  InkWell( onTap: () async { final picked = await showDatePicker( context: context, initialDate: _editingDate, firstDate: DateTime(2000), lastDate: DateTime(2030) ); if(picked != null) setState(() => _editingDate = picked); }, child: InputDecorator( decoration: const InputDecoration(labelText: "日付", border: OutlineInputBorder()), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text(DateFormat('yyyy/MM/dd (E)', 'ja').format(_editingDate)), const Icon(Icons.calendar_today, size: 20), ], ), ), ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MatchType>( value: _editingMatchType, decoration: const InputDecoration(labelText: "試合種別", border: OutlineInputBorder()), items: MatchType.values.map((t) => DropdownMenuItem(value: t, child: Text(_getMatchTypeName(t)))).toList(), onChanged: (val) { if(val != null) setState(() => _editingMatchType = val); }, ),
                  const SizedBox(height: 8),
                  Row(children: [ Expanded(child: TextField(controller: _opponentCtrl, decoration: const InputDecoration(labelText: "対戦相手"))), PopupMenuButton<RosterItem>( icon: const Icon(Icons.list), onSelected: (item) { setState(() { _opponentCtrl.text = item.data[opSchema.id]?.toString() ?? ""; _opponentId = item.id; }); }, itemBuilder: (context) => opponents.map((i) => PopupMenuItem(value: i, child: Text(i.data[opSchema.id]?.toString() ?? ""))).toList(), ), ]),
                  const SizedBox(height: 8),
                  Row(children: [ Expanded(child: TextField(controller: _venueCtrl, decoration: const InputDecoration(labelText: "会場"))), PopupMenuButton<RosterItem>( icon: const Icon(Icons.list), onSelected: (item) { setState(() { _venueCtrl.text = item.data[veSchema.id]?.toString() ?? ""; _venueId = item.id; }); }, itemBuilder: (context) => venues.map((i) => PopupMenuItem(value: i, child: Text(i.data[veSchema.id]?.toString() ?? ""))).toList(), ), ]),
                  const SizedBox(height: 8),
                  TextField( controller: _noteCtrl, decoration: const InputDecoration( labelText: "備考", border: OutlineInputBorder(), alignLabelWithHint: true, ), maxLines: 3, ),
                  const SizedBox(height: 12),
                  Align( alignment: Alignment.centerRight, child: ElevatedButton.icon( onPressed: _saveMatchInfo, icon: const Icon(Icons.save, size: 16), label: const Text("基本情報を更新"), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade50), ), )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}