// lib/features/settings/presentation/action_settings_screen.dart
import 'package:flutter/material.dart';
import '../../team_mgmt/database_helper.dart';
import '../../team_mgmt/team_store.dart';
import '../domain/action_definition.dart';

class ActionSettingsScreen extends StatefulWidget {
  const ActionSettingsScreen({super.key});
  @override
  State<ActionSettingsScreen> createState() => _ActionSettingsScreenState();
}

class _ActionSettingsScreenState extends State<ActionSettingsScreen> {
  final TeamStore _teamStore = TeamStore();
  List<ActionDefinition> _actions = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadActions(); }

  Future<void> _loadActions() async {
    if (!_teamStore.isLoaded) await _teamStore.loadFromDb();
    final currentTeam = _teamStore.currentTeam;
    if (currentTeam == null) { setState(() => _isLoading = false); return; }
    final raw = await DatabaseHelper().getActionDefinitions(currentTeam.id);
    setState(() {
      _actions = raw.map((d) => ActionDefinition.fromMap(d)).toList();
      _isLoading = false;
    });
  }

  Future<void> _saveAction(ActionDefinition action) async {
    if (_teamStore.currentTeam == null) return;
    await DatabaseHelper().insertActionDefinition(_teamStore.currentTeam!.id, action.toMap());
    _loadActions();
  }

  void _showEditDialog({ActionDefinition? action}) {
    final isNew = action == null;
    final editingAction = action ?? ActionDefinition(name: '');
    final nameCtrl = TextEditingController(text: editingAction.name);

    // 入力用コントローラ（成功・失敗・共通）
    final commonSubCtrl = TextEditingController();
    final successSubCtrl = TextEditingController();
    final failureSubCtrl = TextEditingController();

    // 一時データ
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
            // サブアクション追加ヘルパー
            void addSub(String key, TextEditingController ctrl) {
              if (ctrl.text.trim().isNotEmpty) {
                setStateDialog(() {
                  tempSubsMap[key]!.add(ctrl.text.trim());
                  ctrl.clear();
                });
              }
            }

            // サブアクションリスト表示ウィジェット
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

                    CheckboxListTile(
                        title: const Text('詳細(子カテゴリ)の入力を必須にする'),
                        value: tempRequired,
                        onChanged: (v) => setStateDialog(() => tempRequired = v!),
                        contentPadding: EdgeInsets.zero
                    ),
                    const SizedBox(height: 8),
                    const Text('詳細項目 (子カテゴリ)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // 成功・失敗の設定に応じて入力欄を出し分け
                    if (tempSuccess)
                      buildSubActionList('success', '【成功】の時の詳細項目 (例: 正面, 横)', successSubCtrl),

                    if (tempFailure)
                      buildSubActionList('failure', '【失敗】の時の詳細項目 (例: パスミス, キャッチミス)', failureSubCtrl),

                    if (!tempSuccess && !tempFailure)
                      buildSubActionList('default', '詳細項目 (共通)', commonSubCtrl),

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
        onReorder: (o, n) { if(o<n)n--; final i=_actions.removeAt(o); _actions.insert(n, i); },
        itemBuilder: (context, index) {
          final item = _actions[index];
          List<String> types = [];
          if(item.hasSuccess) types.add("成功");
          if(item.hasFailure) types.add("失敗");
          final typeStr = types.isEmpty ? "結果なし" : types.join("・");

          return ListTile(
            key: ValueKey(item.id),
            title: Text(item.name),
            subtitle: Text(typeStr),
            trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(action: item)),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showEditDialog(), child: const Icon(Icons.add)),
    );
  }
}