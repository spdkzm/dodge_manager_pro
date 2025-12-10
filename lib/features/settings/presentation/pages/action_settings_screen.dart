// lib/features/settings/presentation/pages/action_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../team_mgmt/application/team_store.dart';
import '../../data/action_dao.dart';
import '../../../game_record/data/match_dao.dart';
import '../../domain/action_definition.dart';

class ActionSettingsScreen extends ConsumerStatefulWidget {
  const ActionSettingsScreen({super.key});

  @override
  ConsumerState<ActionSettingsScreen> createState() => _ActionSettingsScreenState();
}

class _ActionSettingsScreenState extends ConsumerState<ActionSettingsScreen> {
  final ActionDao _actionDao = ActionDao();
  final MatchDao _matchDao = MatchDao(); // ignore: unused_field

  List<ActionDefinition> _actions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActions();
    });
  }

  Future<void> _loadActions() async {
    final store = ref.read(teamStoreProvider);
    if (!store.isLoaded) await store.loadFromDb();
    final currentTeam = store.currentTeam;
    if (currentTeam == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final raw = await _actionDao.getActionDefinitions(currentTeam.id);
    if (mounted) {
      setState(() {
        _actions = raw.map((d) => ActionDefinition.fromMap(d)).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAction(ActionDefinition action) async {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    if (currentTeam == null) return;

    if (action.sortOrder == 0 && _actions.isNotEmpty) {
      action.sortOrder = _actions.length;
    }

    await _actionDao.insertActionDefinition(currentTeam.id, action);
    _loadActions();
  }

  void _showEditDialog({ActionDefinition? action}) {
    final isNew = action == null;
    final editingAction = action ?? ActionDefinition(id: const Uuid().v4(), name: '');

    final nameCtrl = TextEditingController(text: editingAction.name);
    final successSubCtrl = TextEditingController();
    final failureSubCtrl = TextEditingController();
    final commonSubCtrl = TextEditingController();

    // ★修正: リストをコピーしてローカルで編集する
    List<SubActionDefinition> tempSubs = List.from(editingAction.subActions);

    bool tempRequired = editingAction.isSubRequired;
    bool tempSuccess = editingAction.hasSuccess;
    bool tempFailure = editingAction.hasFailure;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {

            // カテゴリごとのリスト取得フィルタ
            List<SubActionDefinition> getSubs(String category) => tempSubs.where((s) => s.category == category).toList();

            void deleteSub(String subId) {
              setStateDialog(() {
                tempSubs.removeWhere((s) => s.id == subId);
              });
            }

            void editSub(SubActionDefinition sub) async {
              final newNameCtrl = TextEditingController(text: sub.name);
              final newName = await showDialog<String>(
                context: context,
                builder: (editCtx) => AlertDialog(
                  title: const Text("詳細項目の編集"),
                  content: TextField(
                    controller: newNameCtrl,
                    decoration: const InputDecoration(labelText: "項目名"),
                    autofocus: true,
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(editCtx), child: const Text("キャンセル")),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(editCtx, newNameCtrl.text.trim()),
                        child: const Text("決定")
                    ),
                  ],
                ),
              );

              if (newName == null || newName.isEmpty || newName == sub.name) return;

              setStateDialog(() {
                final index = tempSubs.indexWhere((s) => s.id == sub.id);
                if (index != -1) {
                  tempSubs[index] = sub.copyWith(name: newName);
                }
              });
            }

            void addSub(String category, TextEditingController ctrl) {
              if (ctrl.text.trim().isNotEmpty) {
                setStateDialog(() {
                  tempSubs.add(SubActionDefinition(
                    id: const Uuid().v4(),
                    name: ctrl.text.trim(),
                    category: category,
                    sortOrder: tempSubs.where((s) => s.category == category).length,
                  ));
                  ctrl.clear();
                });
              }
            }

            Widget buildSubActionList(String category, String label, TextEditingController ctrl) {
              final subs = getSubs(category);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(children: [
                    Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()), onSubmitted: (_) => addSub(category, ctrl))),
                    IconButton(icon: const Icon(Icons.add_circle, color: Colors.blue), onPressed: () => addSub(category, ctrl)),
                  ]),
                  Wrap(spacing: 4, children: subs.map((sub) => InputChip(
                    label: Text(sub.name),
                    onPressed: () => editSub(sub),
                    onDeleted: () => deleteSub(sub.id),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  )).toList()),
                  const SizedBox(height: 8),
                ],
              );
            }

            return AlertDialog(
              title: Text(isNew ? 'アクション追加' : 'アクション編集'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'アクション名')),
                    const SizedBox(height: 16),

                    const Text('記録設定', style: TextStyle(fontWeight: FontWeight.bold)),
                    CheckboxListTile(
                      title: const Text('「成功」ボタンを作成する'),
                      value: tempSuccess,
                      onChanged: (v) => setStateDialog(() => tempSuccess = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('「失敗」ボタンを作成する'),
                      value: tempFailure,
                      onChanged: (v) => setStateDialog(() => tempFailure = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    CheckboxListTile(title: const Text('詳細(子カテゴリ)の入力を必須にする'), value: tempRequired, onChanged: (v) => setStateDialog(() => tempRequired = v!), contentPadding: EdgeInsets.zero),
                    const SizedBox(height: 8),
                    const Text('詳細項目 (子カテゴリ) - タップで編集、×で削除', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),

                    if (tempSuccess) buildSubActionList('success', '【成功】の時の詳細項目', successSubCtrl),
                    if (tempFailure) buildSubActionList('failure', '【失敗】の時の詳細項目', failureSubCtrl),
                    if (!tempSuccess && !tempFailure) buildSubActionList('default', '詳細項目 (共通)', commonSubCtrl),

                    if (tempSuccess || tempFailure)
                      const Text('※成功・失敗が選択された場合、それぞれの詳細項目が使われます。', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
                ElevatedButton(onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;

                  editingAction.name = nameCtrl.text.trim();
                  editingAction.subActions = tempSubs;
                  editingAction.isSubRequired = tempRequired;
                  editingAction.hasSuccess = tempSuccess;
                  editingAction.hasFailure = tempFailure;

                  await _saveAction(editingAction);
                  if (context.mounted) Navigator.pop(ctx);
                }, child: const Text('保存')),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSubActionRow(String label, List<SubActionDefinition>? items, Color color) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("【$label】 ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: items.map((sub) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  border: Border.all(color: color.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(sub.name, style: const TextStyle(fontSize: 11)),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('アクション設定')),
      body: ReorderableListView.builder(
        itemCount: _actions.length,
        onReorder: (oldIndex, newIndex) async {
          if (oldIndex < newIndex) newIndex -= 1;
          final item = _actions.removeAt(oldIndex);
          _actions.insert(newIndex, item);
          setState(() {});
          await _actionDao.updateActionOrder(_actions);
        },
        itemBuilder: (context, index) {
          final item = _actions[index];
          List<String> types = [];
          if(item.hasSuccess) types.add("成功");
          if(item.hasFailure) types.add("失敗");
          final typeStr = types.isEmpty ? "結果記録なし" : types.join("・");

          return ListTile(
            key: ValueKey(item.id),
            leading: const Icon(Icons.drag_handle, color: Colors.grey),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (typeStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Text('タイプ: $typeStr', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                _buildSubActionRow('共通', item.getSubActions('default'), Colors.grey),
                _buildSubActionRow('成功', item.getSubActions('success'), Colors.red),
                _buildSubActionRow('失敗', item.getSubActions('failure'), Colors.blue),
              ],
            ),
            trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(action: item)),
            isThreeLine: true,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showEditDialog(), child: const Icon(Icons.add)),
    );
  }
}