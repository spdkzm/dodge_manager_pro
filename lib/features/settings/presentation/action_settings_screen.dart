import 'package:flutter/material.dart';
import '../../team_mgmt/database_helper.dart'; // DBヘルパー
import '../../team_mgmt/team_store.dart';      // チームID取得用
import '../domain/action_definition.dart';     // 新モデル

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
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    if (!_teamStore.isLoaded) await _teamStore.loadFromDb();
    final currentTeam = _teamStore.currentTeam;

    if (currentTeam == null) {
      setState(() => _isLoading = false);
      return;
    }

    // DBからアクション定義を取得
    final rawData = await DatabaseHelper().getActionDefinitions(currentTeam.id);
    final loaded = rawData.map((d) => ActionDefinition.fromMap(d)).toList();

    // データがない場合、初期値をセットするロジックを入れても良いが、
    // ここでは「空なら空」として扱う（あるいは別途初期化ボタンを作る）

    setState(() {
      _actions = loaded;
      _isLoading = false;
    });
  }

  Future<void> _saveAction(ActionDefinition action) async {
    final currentTeam = _teamStore.currentTeam;
    if (currentTeam == null) return;

    await DatabaseHelper().insertActionDefinition(currentTeam.id, action.toMap());
    _loadActions(); // リロード
  }

  Future<void> _deleteAction(ActionDefinition action) async {
    // 削除機能はDatabaseHelperにメソッドが必要だが、
    // 今回のStep 2-1では insertActionDefinition しかなかったため
    // 暫定的に「削除機能は次回実装」とするか、DBHelperへの追加が必要。
    // ここではUIのみ実装し、削除確認だけ出す。
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('削除機能はDBHelperへの追加が必要です')));
  }

  void _showEditDialog({ActionDefinition? action}) {
    final isNew = action == null;
    final editingAction = action ?? ActionDefinition(name: '');

    final nameCtrl = TextEditingController(text: editingAction.name);
    final subCtrl = TextEditingController();

    // UI用の一時変数
    List<String> tempSubs = List.from(editingAction.subActions);
    bool tempRequired = editingAction.isSubRequired;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void addSub() {
              if (subCtrl.text.trim().isNotEmpty) {
                setStateDialog(() {
                  tempSubs.add(subCtrl.text.trim());
                  subCtrl.clear();
                });
              }
            }

            return AlertDialog(
              title: Text(isNew ? 'アクション追加' : 'アクション編集'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'アクション名 (例: アタック成功)'),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('詳細(子カテゴリ)の入力を必須にする'),
                        value: tempRequired,
                        onChanged: (v) => setStateDialog(() => tempRequired = v!),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: subCtrl,
                              decoration: const InputDecoration(labelText: '詳細項目を追加 (例: 正面, 横)'),
                              onSubmitted: (_) => addSub(),
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.add_circle), onPressed: addSub),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: tempSubs.map((sub) => Chip(
                          label: Text(sub),
                          onDeleted: () => setStateDialog(() => tempSubs.remove(sub)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;

                    editingAction.name = nameCtrl.text;
                    editingAction.subActions = tempSubs;
                    editingAction.isSubRequired = tempRequired;
                    // 新規なら末尾に追加するためのソート順設定ロジックなどが本来必要

                    await _saveAction(editingAction);
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('保存'),
                ),
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
      appBar: AppBar(title: const Text('アクション設定 (DB)')),
      body: _actions.isEmpty
          ? Center(
        child: ElevatedButton.icon(
          onPressed: () => _showEditDialog(),
          icon: const Icon(Icons.add),
          label: const Text('最初のアクションを追加'),
        ),
      )
          : ReorderableListView.builder(
        itemCount: _actions.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) newIndex -= 1;
            final item = _actions.removeAt(oldIndex);
            _actions.insert(newIndex, item);
          });
          // 並び替え後の順序保存ロジック（全件update）はパフォーマンス考慮し別途実装推奨
          // 今回はメモリ上のみ反映
        },
        itemBuilder: (context, index) {
          final item = _actions[index];
          return ListTile(
            key: ValueKey(item.id),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item.subActions.isEmpty ? '詳細なし' : item.subActions.join(', ')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditDialog(action: item),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}