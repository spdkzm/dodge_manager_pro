// lib/features/analysis/presentation/widgets/analysis_members_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/analysis_controller.dart';
import '../../../team_mgmt/application/team_store.dart';
import '../../../team_mgmt/domain/schema.dart';

class AnalysisMembersTab extends ConsumerStatefulWidget {
  final String matchId;
  final VoidCallback onUpdate; // ★追加: 更新完了時のコールバック

  const AnalysisMembersTab({
    super.key,
    required this.matchId,
    required this.onUpdate,
  });

  @override
  ConsumerState<AnalysisMembersTab> createState() => _AnalysisMembersTabState();
}

class _AnalysisMembersTabState extends ConsumerState<AnalysisMembersTab> {
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
    benchMembers.addAll(others);

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
    // ★変更: 親画面の再ロード処理を呼び出す
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("出場メンバー編集", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (hasSelection)
                    Row(
                      children: [
                        ElevatedButton(onPressed: () => _moveSelectedMembers('court'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade50, foregroundColor: Colors.orange), child: const Text("コートへ")),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: () => _moveSelectedMembers('bench'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue), child: const Text("ベンチへ")),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: () => _moveSelectedMembers('absent'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87), child: const Text("欠席へ")),
                        const SizedBox(width: 16),
                        IconButton(onPressed: _clearMemberSelection, icon: const Icon(Icons.close), tooltip: "選択解除"),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _saveMembers,
                      icon: const Icon(Icons.save),
                      label: const Text("メンバー変更を保存"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    )
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildMemberColumn("コート (${_editingCourtMembers.length})", _editingCourtMembers, Colors.orange.shade100, Colors.orange.shade50)),
                  const VerticalDivider(width: 1),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMemberColumn("ベンチ (${_editingBenchMembers.length})", _editingBenchMembers, Colors.blue.shade100, Colors.blue.shade50)),
                  const VerticalDivider(width: 1),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMemberColumn("欠席 (${_editingAbsentMembers.length})", _editingAbsentMembers, Colors.grey.shade300, Colors.grey.shade100)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberColumn(String title, List<String> members, Color headerColor, Color bgColor) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: headerColor,
          alignment: Alignment.center,
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Container(
          color: bgColor,
          constraints: const BoxConstraints(minHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final num = members[index];
              final isSelected = _selectedMember == num || _selectedMembersForMove.contains(num);

              return InkWell(
                onTap: () => _onMemberTap(num),
                onLongPress: () => _onMemberLongPress(num),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.indigo.shade100 : Colors.white,
                    border: Border.all(color: isSelected ? Colors.indigo : Colors.transparent),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey.shade300,
                        child: Text(num, style: const TextStyle(fontSize: 10, color: Colors.black87)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _playerNames[num] ?? "",
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) const Icon(Icons.check_circle, size: 16, color: Colors.indigo),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}