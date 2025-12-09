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
  final MatchDao _matchDao = MatchDao();

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

    await _actionDao.insertActionDefinition(currentTeam.id, action.toMap());
    _loadActions();
  }

  Future<void> _renameActionLogs(String oldName, String newName) async {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    if (currentTeam == null) return;
    await _matchDao.updateActionNameInLogs(currentTeam.id, oldName, newName);
  }

  Future<void> _renameSubActionLogs(String actionName, String oldSubName, String newSubName) async {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    if (currentTeam == null) return;
    await _matchDao.updateSubActionNameInLogs(currentTeam.id, actionName, oldSubName, newSubName);
  }

  void _showEditDialog({ActionDefinition? action}) {
    final isNew = action == null;

    final editingAction = action ?? ActionDefinition(
        id: const Uuid().v4(),
        name: ''
    );

    final String originalActionName = editingAction.name;

    final nameCtrl = TextEditingController(text: editingAction.name);
    final successSubCtrl = TextEditingController();
    final failureSubCtrl = TextEditingController();
    final commonSubCtrl = TextEditingController();

    Map<String, List<String>> tempSubsMap = {
      'default': List<String>.from(editingAction.subActionsMap['default'] ?? []),
      'success': List<String>.from(editingAction.subActionsMap['success'] ?? []),
      'failure': List<String>.from(editingAction.subActionsMap['failure'] ?? []),
    };

    List<Map<String, String>> pendingSubRenames = [];

    bool tempRequired = editingAction.isSubRequired;
    bool tempSuccess = editingAction.hasSuccess;
    bool tempFailure = editingAction.hasFailure;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final store = ref.read(teamStoreProvider);
            final teamId = store.currentTeam?.id;

            Future<void> deleteSub(String key, String subName) async {
              if (isNew || teamId == null) {
                setStateDialog(() => tempSubsMap[key]!.remove(subName));
                return;
              }

              final count = await _matchDao.countSubActionUsage(teamId, originalActionName, subName);

              if (count > 0 && context.mounted) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (alertCtx) => AlertDialog(
                    title: const Text("詳細項目の削除"),
                    content: Text(
                        "項目「$subName」は過去 $count 件の記録で使用されています。\n"
                            "削除すると、過去の記録上には名前が残りますが、今後の選択肢からは消えます。\n\n"
                            "削除してもよろしいですか？"
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(alertCtx, false), child: const Text("キャンセル")),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(alertCtx, true),
                          child: const Text("削除する")
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
              }

              setStateDialog(() => tempSubsMap[key]!.remove(subName));
            }

            Future<void> editSub(String key, String oldSubName) async {
              final newNameCtrl = TextEditingController(text: oldSubName);
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

              if (newName == null || newName.isEmpty || newName == oldSubName) return;

              if (!isNew && teamId != null) {
                final count = await _matchDao.countSubActionUsage(teamId, originalActionName, oldSubName);
                if (count > 0 && context.mounted) {
                  final choice = await showDialog<int>(
                    context: context,
                    builder: (alertCtx) => AlertDialog(
                      title: const Text("名前の変更"),
                      content: Text(
                          "「$oldSubName」→「$newName」\n\n"
                              "この項目は過去 $count 件の記録で使用されています。\n"
                              "過去の記録も変更しますか？"
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(alertCtx, 0), child: const Text("キャンセル")),
                        TextButton(onPressed: () => Navigator.pop(alertCtx, 1), child: const Text("変更しない\n(新規として扱う)")),
                        ElevatedButton(onPressed: () => Navigator.pop(alertCtx, 2), child: const Text("過去の記録も変更")),
                      ],
                    ),
                  );

                  if (choice == null || choice == 0) return;

                  if (choice == 2) {
                    pendingSubRenames.add({'old': oldSubName, 'new': newName});
                  }
                }
              }

              setStateDialog(() {
                final idx = tempSubsMap[key]!.indexOf(oldSubName);
                if (idx != -1) {
                  tempSubsMap[key]![idx] = newName;
                }
              });
            }

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
                  Wrap(spacing: 4, children: tempSubsMap[key]!.map((sub) => InputChip(
                    label: Text(sub),
                    onPressed: () => editSub(key, sub),
                    onDeleted: () => deleteSub(key, sub),
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

                  final newName = nameCtrl.text.trim();

                  if (!isNew && originalActionName != newName) {
                    // ★修正: 簡易チェックは省略し、ダイアログだけ出す(Warning解消)
                    final choice = await showDialog<int>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text("アクション名の変更"),
                        content: Text(
                            "アクション名が「$originalActionName」から「$newName」に変更されました。\n"
                                "過去の記録データも新しい名前に変更しますか？\n\n"
                                "・変更する: 過去の「$originalActionName」の記録も「$newName」として集計されます。\n"
                                "・変更しない: 過去の記録は「$originalActionName」のまま残ります（集計は別々になります）。"
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogCtx, 0), child: const Text("キャンセル")),
                          TextButton(onPressed: () => Navigator.pop(dialogCtx, 1), child: const Text("変更しない")),
                          ElevatedButton(onPressed: () => Navigator.pop(dialogCtx, 2), child: const Text("過去の記録も変更する")),
                        ],
                      ),
                    );

                    if (choice == null || choice == 0) return;

                    if (choice == 2) {
                      await _renameActionLogs(originalActionName, newName);
                    }
                  }

                  final targetActionName = newName;

                  for (var rename in pendingSubRenames) {
                    await _renameSubActionLogs(targetActionName, rename['old']!, rename['new']!);
                  }

                  editingAction.name = newName;
                  editingAction.subActionsMap = tempSubsMap;
                  editingAction.isSubRequired = tempRequired;
                  editingAction.hasSuccess = tempSuccess;
                  editingAction.hasFailure = tempFailure;

                  await _saveAction(editingAction);
                  if (context.mounted) {
                    if (pendingSubRenames.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("詳細項目の名前変更を反映しました")));
                    }
                    Navigator.pop(ctx);
                  }
                }, child: const Text('保存')),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSubActionRow(String label, List<String>? items, Color color) {
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
                child: Text(sub, style: const TextStyle(fontSize: 11)),
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
                _buildSubActionRow('共通', item.subActionsMap['default'], Colors.grey),
                _buildSubActionRow('成功', item.subActionsMap['success'], Colors.red),
                _buildSubActionRow('失敗', item.subActionsMap['failure'], Colors.blue),

                if ((item.subActionsMap['default']?.isEmpty ?? true) &&
                    (item.subActionsMap['success']?.isEmpty ?? true) &&
                    (item.subActionsMap['failure']?.isEmpty ?? true))
                  const Text("詳細なし", style: TextStyle(fontSize: 11, color: Colors.grey)),
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