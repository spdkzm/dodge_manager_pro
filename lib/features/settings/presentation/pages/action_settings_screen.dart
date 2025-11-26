// lib/features/settings/presentation/pages/action_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../team_mgmt/application/team_store.dart';
import '../../data/action_dao.dart';
import '../../domain/action_definition.dart';

class ActionSettingsScreen extends ConsumerStatefulWidget {
  const ActionSettingsScreen({super.key});

  @override
  ConsumerState<ActionSettingsScreen> createState() => _ActionSettingsScreenState();
}

class _ActionSettingsScreenState extends ConsumerState<ActionSettingsScreen> {
  final ActionDao _actionDao = ActionDao();

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

    // 新規作成時は、現在のリストの末尾に追加されるようにsortOrderを設定
    if (action.sortOrder == 0 && _actions.isNotEmpty) {
      // 既存リストの最大sortOrder + 1 をセットするなどのロジックが可能ですが、
      // Daoのgetでsort_order順に取ってきているため、リスト末尾に追加して
      // 一括更新する手もあります。ここでは簡易的にリスト末尾に追加します。
      action.sortOrder = _actions.length;
    }

    await _actionDao.insertActionDefinition(currentTeam.id, action.toMap());
    _loadActions();
  }

  void _showEditDialog({ActionDefinition? action}) {
    final isNew = action == null;

    final editingAction = action ?? ActionDefinition(
        id: const Uuid().v4(),
        name: ''
    );

    final nameCtrl = TextEditingController(text: editingAction.name);
    final successSubCtrl = TextEditingController();
    final failureSubCtrl = TextEditingController();
    final commonSubCtrl = TextEditingController();

    Map<String, List<String>> tempSubsMap = {
      'default': List<String>.from(editingAction.subActionsMap['default'] ?? []),
      'success': List<String>.from(editingAction.subActionsMap['success'] ?? []),
      'failure': List<String>.from(editingAction.subActionsMap['failure'] ?? []),
    };
    bool tempRequired = editingAction.isSubRequired;
    bool tempSuccess = editingAction.hasSuccess;
    bool tempFailure = editingAction.hasFailure;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void addSub(String key, TextEditingController ctrl) {
              if (ctrl.text.trim().isNotEmpty) {
                setStateDialog(() {
                  tempSubsMap[key]!.add(ctrl.text.trim());
                  ctrl.clear();
                });
              }
            }

            Widget buildSubActionList(String key, String label, TextEditingController ctrl) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(children: [
                    Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()), onSubmitted: (_) => addSub(key, ctrl))),
                    IconButton(icon: const Icon(Icons.add_circle, color: Colors.blue), onPressed: () => addSub(key, ctrl)),
                  ]),
                  Wrap(spacing: 4, children: tempSubsMap[key]!.map((sub) => Chip(label: Text(sub), onDeleted: () => setStateDialog(() => tempSubsMap[key]!.remove(sub)))).toList()),
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
                    const Text('詳細項目 (子カテゴリ)', style: TextStyle(fontWeight: FontWeight.bold)),
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

                  editingAction.name = nameCtrl.text;
                  editingAction.subActionsMap = tempSubsMap;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('アクション設定')),
      body: ReorderableListView.builder(
        itemCount: _actions.length,
        // ★修正: 並び替え時にDBも更新する
        onReorder: (oldIndex, newIndex) async {
          if (oldIndex < newIndex) newIndex -= 1;

          // 1. UIのリストを並び替え
          final item = _actions.removeAt(oldIndex);
          _actions.insert(newIndex, item);
          setState(() {}); // 画面更新

          // 2. データベースの順序を更新
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
            leading: const Icon(Icons.drag_handle, color: Colors.grey), // ドラッグハンドルを追加
            title: Text(item.name),
            subtitle: Text('$typeStr / 詳細: ${item.subActionsMap.values.fold(0, (p,e)=>p+e.length)}件'),
            trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(action: item)),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showEditDialog(), child: const Icon(Icons.add)),
    );
  }
}