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

  const AnalysisInfoTab({super.key, required this.matchId});

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

  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  @override
  void didUpdateWidget(covariant AnalysisInfoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId != widget.matchId) {
      _loadMatchData();
    }
  }

  @override
  void dispose() {
    _opponentCtrl.dispose();
    _venueCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _loadMatchData() {
    final matchRecord = ref.read(selectedMatchRecordProvider);
    if (matchRecord != null && matchRecord.id == widget.matchId) {
      _opponentCtrl.text = matchRecord.opponent;
      _venueCtrl.text = matchRecord.venueName ?? "";
      _noteCtrl.text = matchRecord.note ?? "";
      _opponentId = matchRecord.opponentId;
      _venueId = matchRecord.venueId;
      _editingDate = DateTime.tryParse(matchRecord.date) ?? DateTime.now();
      _editingMatchType = matchRecord.matchType;
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

    ref.read(analysisControllerProvider.notifier).analyze(matchId: widget.matchId);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("基本情報を更新しました")));
  }

  String _getMatchTypeName(MatchType type) { switch (type) { case MatchType.official: return "大会/公式戦"; case MatchType.practiceMatch: return "練習試合"; case MatchType.practice: return "練習"; } }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(teamStoreProvider);
    final team = store.currentTeam;
    final matchRecord = ref.watch(selectedMatchRecordProvider);

    if (team == null || matchRecord == null) return const Center(child: CircularProgressIndicator());

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