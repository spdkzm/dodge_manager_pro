// lib/features/analysis/presentation/widgets/analysis_members_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/analysis_controller.dart';
import '../../../team_mgmt/application/team_store.dart';
import '../../../team_mgmt/domain/schema.dart';
import '../../../team_mgmt/data/uniform_number_dao.dart';
import '../../../team_mgmt/domain/uniform_number.dart';

class AnalysisMembersTab extends ConsumerStatefulWidget {
  final String matchId;
  final VoidCallback onUpdate;

  const AnalysisMembersTab({
    super.key,
    required this.matchId,
    required this.onUpdate,
  });

  @override
  ConsumerState<AnalysisMembersTab> createState() => _AnalysisMembersTabState();
}

class _AnalysisMembersTabState extends ConsumerState<AnalysisMembersTab> {
  final UniformNumberDao _uniformDao = UniformNumberDao();

  List<String> _editingCourtMembers = [];
  List<String> _editingBenchMembers = [];
  List<String> _editingAbsentMembers = [];
  Map<String, String> _playerNames = {};

  String? _selectedMember;
  Set<String> _selectedMembersForMove = {};
  bool _isMemberMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _loadMemberEditorData();
  }

  @override
  void didUpdateWidget(covariant AnalysisMembersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId != widget.matchId) {
      _loadMemberEditorData();
    }
  }

  Future<void> _loadMemberEditorData() async {
    final store = ref.read(teamStoreProvider);
    if (!store.isLoaded) await store.loadFromDb();
    final currentTeam = store.currentTeam;
    if (currentTeam == null) return;

    // 試合情報の取得（日付のため）
    final matchRecord = await ref.read(analysisControllerProvider.notifier).fetchMatchRecordById(widget.matchId);
    if (matchRecord == null) return;

    final matchDate = DateTime.tryParse(matchRecord.date) ?? DateTime.now();

    // 試合日時点の背番号を取得
    final allUniforms = await _uniformDao.getUniformNumbersByTeam(currentTeam.id);
    final allMembers = <String, String>{};

    String? courtNameFieldId; String? nameFieldId;
    for(var f in currentTeam.schema) {
      if(f.type == FieldType.courtName) courtNameFieldId = f.id;
      if(f.type == FieldType.personName) nameFieldId = f.id;
    }

    for (var item in currentTeam.items) {
      // 試合日時点で有効な背番号を探す
      UniformNumber? activeNum;
      try {
        activeNum = allUniforms.firstWhere((u) => u.playerId == item.id && u.isActiveAt(matchDate));
      } catch (_) {
        activeNum = null;
      }

      if (activeNum != null) {
        final num = activeNum.number;
        String name = "";
        if (courtNameFieldId != null) name = item.data[courtNameFieldId]?.toString() ?? "";
        if (name.isEmpty && nameFieldId != null) { final n = item.data[nameFieldId]; if (n is Map) name = "${n['last'] ?? ''} ${n['first'] ?? ''}".trim(); }
        allMembers[num] = name;
      }
    }

    final statusMap = await ref.read(analysisControllerProvider.notifier).getMatchMemberStatus(widget.matchId);

    final courtMembers = <String>[];
    final benchMembers = <String>[];
    final absentMembers = <String>[];

    statusMap.forEach((num, status) {
      if (status == 0) courtMembers.add(num);
      else if (status == 1) benchMembers.add(num);
      else if (status == 2) absentMembers.add(num);
    });

    final registeredSet = statusMap.keys.toSet();
    final others = allMembers.keys.where((n) => !registeredSet.contains(n)).toList();
    benchMembers.addAll(others); // 試合に記録されていないが、当時背番号を持っていた選手はベンチ候補へ

    int sortFunc(String a, String b) => (int.tryParse(a) ?? 999).compareTo(int.tryParse(b) ?? 999);
    courtMembers.sort(sortFunc);
    benchMembers.sort(sortFunc);
    absentMembers.sort(sortFunc);

    if (mounted) {
      setState(() {
        _editingCourtMembers = courtMembers;
        _editingBenchMembers = benchMembers;
        _editingAbsentMembers = absentMembers;
        _playerNames = allMembers;
        _selectedMembersForMove.clear();
        _isMemberMultiSelectMode = false;
        _selectedMember = null;
      });
    }
  }

  Future<void> _saveMembers() async {
    await ref.read(analysisControllerProvider.notifier).updateMatchMembers(
        widget.matchId,
        _editingCourtMembers,
        _editingBenchMembers,
        _editingAbsentMembers
    );
    widget.onUpdate();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("出場メンバーを更新しました")));
  }

  void _onMemberTap(String number) {
    if (_isMemberMultiSelectMode) {
      setState(() {
        if (_selectedMembersForMove.contains(number)) {
          _selectedMembersForMove.remove(number);
          if (_selectedMembersForMove.isEmpty) _isMemberMultiSelectMode = false;
        } else {
          _selectedMembersForMove.add(number);
        }
      });
    } else {
      setState(() {
        _selectedMember = (_selectedMember == number) ? null : number;
      });
    }
  }

  void _onMemberLongPress(String number) {
    setState(() {
      _isMemberMultiSelectMode = true;
      _selectedMembersForMove.add(number);
      _selectedMember = null;
    });
  }

  void _moveSelectedMembers(String toType) {
    if (_selectedMembersForMove.isEmpty && _selectedMember == null) return;

    final targets = _selectedMembersForMove.isNotEmpty ? _selectedMembersForMove.toList() : [_selectedMember!];

    setState(() {
      _editingCourtMembers.removeWhere((p) => targets.contains(p));
      _editingBenchMembers.removeWhere((p) => targets.contains(p));
      _editingAbsentMembers.removeWhere((p) => targets.contains(p));

      if (toType == 'court') _editingCourtMembers.addAll(targets);
      if (toType == 'bench') _editingBenchMembers.addAll(targets);
      if (toType == 'absent') _editingAbsentMembers.addAll(targets);

      int sortFunc(String a, String b) => (int.tryParse(a) ?? 999).compareTo(int.tryParse(b) ?? 999);
      _editingCourtMembers.sort(sortFunc);
      _editingBenchMembers.sort(sortFunc);
      _editingAbsentMembers.sort(sortFunc);

      _selectedMembersForMove.clear();
      _selectedMember = null;
      _isMemberMultiSelectMode = false;
    });
  }

  void _clearMemberSelection() {
    setState(() {
      _selectedMembersForMove.clear();
      _isMemberMultiSelectMode = false;
      _selectedMember = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedMember != null || _selectedMembersForMove.isNotEmpty;

    return Column(
      children: [
        // ヘッダーエリア (通常時と選択時で切り替え)
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: hasSelection ? Colors.orange.shade100 : Colors.white,
          child: hasSelection
              ? Row(
            children: [
              Text(
                "${_isMemberMultiSelectMode ? _selectedMembersForMove.length : 1}人選択中",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.sports_basketball), tooltip: "コートへ", onPressed: () => _moveSelectedMembers('court')),
              IconButton(icon: const Icon(Icons.chair), tooltip: "ベンチへ", onPressed: () => _moveSelectedMembers('bench')),
              IconButton(icon: const Icon(Icons.cancel), tooltip: "欠席へ", onPressed: () => _moveSelectedMembers('absent')),
              IconButton(icon: const Icon(Icons.close), tooltip: "選択解除", onPressed: _clearMemberSelection),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("出場メンバー編集", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                onPressed: _saveMembers,
                icon: const Icon(Icons.save),
                label: const Text("保存"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              )
            ],
          ),
        ),
        const Divider(height: 1),

        // 3分割リストエリア
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildSection("コート", _editingCourtMembers, Colors.orange.shade50, Colors.orange.shade100),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _buildSection("ベンチ", _editingBenchMembers, Colors.blue.shade50, Colors.blue.shade100),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _buildSection("欠席", _editingAbsentMembers, Colors.grey.shade100, Colors.grey.shade300),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<String> members, Color bgColor, Color headerColor) {
    return Column(
      children: [
        // セクションヘッダー
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: headerColor,
          alignment: Alignment.center,
          child: Text(
            "$title (${members.length})",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        // リスト
        Expanded(
          child: Container(
            color: bgColor,
            child: members.isEmpty
                ? const Center(child: Text("なし", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final num = members[index];
                final name = _playerNames[num] ?? "";
                final isSelected = _selectedMember == num;
                final isMultiSelected = _selectedMembersForMove.contains(num);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: isMultiSelected
                      ? Colors.orange[200]
                      : (isSelected ? Colors.yellow[100] : Colors.white),
                  elevation: 1,
                  child: InkWell(
                    onTap: () => _onMemberTap(num),
                    onLongPress: () => _onMemberLongPress(num),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Column(
                        children: [
                          Text(
                            num,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (name.isNotEmpty)
                            Text(
                              name,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}