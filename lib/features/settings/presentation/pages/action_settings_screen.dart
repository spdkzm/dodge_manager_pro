// lib/features/settings/presentation/pages/action_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../team_mgmt/application/team_store.dart';
import '../../data/action_dao.dart';
import '../../../game_record/data/match_dao.dart';
import '../../data/action_repository.dart'; // Repository経由で削除等を行うため
import '../../domain/action_definition.dart';
import '../../../game_record/domain/models.dart'; // ActionResult

class ActionSettingsScreen extends ConsumerStatefulWidget {
  const ActionSettingsScreen({super.key});

  @override
  ConsumerState<ActionSettingsScreen> createState() => _ActionSettingsScreenState();
}

class _ActionSettingsScreenState extends ConsumerState<ActionSettingsScreen> {
  final ActionDao _actionDao = ActionDao();
  final MatchDao _matchDao = MatchDao();

  // RepositoryはProvider経由で取得するのが理想ですが、
  // ここではDaoと直接やり取りしている既存構成に合わせつつ、
  // 削除機能など整合性が必要な部分はDaoを直接呼び出します。

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

  // --- 削除ロジック ---
  Future<void> _deleteAction(ActionDefinition action) async {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    if (currentTeam == null) return;

    // 1. 使用状況の確認
    final isUsed = await _matchDao.isActionUsed(currentTeam.id, action.name);

    if (!mounted) return;

    if (isUsed) {
      // ログで使用されている場合の分岐
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("削除の確認"),
          content: Text("アクション「${action.name}」は過去のログで使用されています。\n\nログデータも一緒に削除しますか？\n（「ログを残す」を選ぶと、設定からは消えますが過去の記録は保持されます）"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'CANCEL'),
              child: const Text("キャンセル"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'KEEP_LOGS'),
              child: const Text("ログを残す"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, 'DELETE_LOGS'),
              child: const Text("ログも削除"),
            ),
          ],
        ),
      );

      if (result == 'CANCEL' || result == null) return;

      if (result == 'DELETE_LOGS') {
        await _matchDao.deleteLogsByAction(currentTeam.id, action.name);
      }
      // 'KEEP_LOGS' の場合は何もしない（定義だけ消す）
    } else {
      // 未使用の場合の単純確認
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("削除"),
          content: Text("「${action.name}」を削除しますか？"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("キャンセル")),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("削除")
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    // 定義の削除実行
    await _actionDao.deleteActionDefinition(action.id);
    _loadActions();
  }

  // --- 保存・更新ロジック ---
  Future<void> _processSave(ActionDefinition action, String? oldName) async {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    if (currentTeam == null) return;

    if (action.sortOrder == 0 && _actions.isNotEmpty) {
      action.sortOrder = _actions.length;
    }

    // 新規作成ではなく、かつ名前が変更された場合
    if (oldName != null && oldName.isNotEmpty && oldName != action.name) {
      final isUsed = await _matchDao.isActionUsed(currentTeam.id, oldName);
      if (isUsed && mounted) {
        final updateLogs = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("名前変更の確認"),
            content: Text("アクション名が「$oldName」から「${action.name}」に変更されました。\n\n過去のログデータのアクション名も変更しますか？"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("変更しない"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("変更する"),
              ),
            ],
          ),
        );

        if (updateLogs == true) {
          await _matchDao.updateActionNameInLogs(currentTeam.id, oldName, action.name);
        }
      }
    }

    await _actionDao.insertActionDefinition(currentTeam.id, action);
    _loadActions();
  }

  // --- 編集ダイアログ ---
  void _showEditDialog({ActionDefinition? action}) {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    final isNew = action == null;
    final editingAction = action ?? ActionDefinition(id: const Uuid().v4(), name: '');
    final oldName = isNew ? null : action.name; // 変更検知用

    final nameCtrl = TextEditingController(text: editingAction.name);
    final successSubCtrl = TextEditingController();
    final failureSubCtrl = TextEditingController();
    final commonSubCtrl = TextEditingController();

    // リストをコピーしてローカルで編集する
    List<SubActionDefinition> tempSubs = List.from(editingAction.subActions);

    bool tempRequired = editingAction.isSubRequired;
    bool tempSuccess = editingAction.hasSuccess;
    bool tempFailure = editingAction.hasFailure;

    // ★追加: 保存時に実行するログ操作の予約
    Set<String> subActionIdsToDeleteLogs = {};
    Map<String, String> subActionNamesToUpdate = {};

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {

            // カテゴリごとのリスト取得フィルタ
            List<SubActionDefinition> getSubs(String category) => tempSubs.where((s) => s.category == category).toList();

            void deleteSub(SubActionDefinition sub) async {
              if (currentTeam == null) return;
              // メモリ上の新規追加（DB未保存）なら即削除
              final isDbSaved = _actions.any((a) => a.subActions.any((s) => s.id == sub.id));
              if (!isDbSaved) {
                setStateDialog(() => tempSubs.removeWhere((s) => s.id == sub.id));
                return;
              }

              final isUsed = await _matchDao.isSubActionUsed(currentTeam.id, sub.id);
              if (context.mounted) {
                if (isUsed) {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text("削除の確認"),
                      content: Text("詳細項目「${sub.name}」は過去のログで使用されています。\n\nログデータも一緒に削除しますか？\n（「ログを残す」を選ぶと、設定からは消えますが過去の記録は保持されます）"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx, 'CANCEL'), child: const Text("キャンセル")),
                        TextButton(onPressed: () => Navigator.pop(dCtx, 'KEEP_LOGS'), child: const Text("ログを残す")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(dCtx, 'DELETE_LOGS'),
                            child: const Text("ログも削除")
                        ),
                      ],
                    ),
                  );

                  if (result == 'CANCEL' || result == null) return;
                  if (result == 'DELETE_LOGS') {
                    subActionIdsToDeleteLogs.add(sub.id);
                  }
                }

                setStateDialog(() {
                  tempSubs.removeWhere((s) => s.id == sub.id);
                });
              }
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
              if (currentTeam == null) return;

              // ログ更新確認
              final isDbSaved = _actions.any((a) => a.subActions.any((s) => s.id == sub.id));
              if (isDbSaved) {
                final isUsed = await _matchDao.isSubActionUsed(currentTeam.id, sub.id);
                if (context.mounted && isUsed) {
                  final updateLogs = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text("名称変更の確認"),
                      content: Text("詳細項目名が「${sub.name}」から「$newName」に変更されました。\n\n過去のログデータの詳細項目名も変更しますか？"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text("変更しない")),
                        ElevatedButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text("変更する")),
                      ],
                    ),
                  );
                  if (updateLogs == true) {
                    subActionNamesToUpdate[sub.id] = newName;
                  }
                }
              }

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
                    onDeleted: () => deleteSub(sub),
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

                  if (currentTeam != null) {
                    // ★追加: ログ削除の実行
                    for (var id in subActionIdsToDeleteLogs) {
                      await _matchDao.deleteLogsBySubActionId(currentTeam.id, id);
                    }
                    // ★追加: ログ名称更新の実行
                    for (var entry in subActionNamesToUpdate.entries) {
                      await _matchDao.updateSubActionNameById(currentTeam.id, entry.key, entry.value);
                    }
                  }

                  // 参照渡しではなく値を更新
                  editingAction.name = nameCtrl.text.trim();
                  editingAction.subActions = tempSubs;
                  editingAction.isSubRequired = tempRequired;
                  editingAction.hasSuccess = tempSuccess;
                  editingAction.hasFailure = tempFailure;

                  if (context.mounted) Navigator.pop(ctx);
                  await _processSave(editingAction, oldName);
                }, child: const Text('保存')),
              ],
            );
          },
        );
      },
    );
  }

  // --- ログ置換（マイグレーション）ダイアログ ---
  void _showMigrationDialog() {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    if (currentTeam == null) return;

    // 検索条件
    ActionDefinition? targetAction;
    ActionResult? targetResult; // null = すべて
    SubActionDefinition? targetSubAction; // null = 指定なし

    // 置換内容
    ActionDefinition? destAction;
    ActionResult destResult = ActionResult.success;
    SubActionDefinition? destSubAction;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {

            // ターゲットアクション選択時のリセット処理
            void onTargetActionChanged(ActionDefinition? val) {
              setStateDialog(() {
                targetAction = val;
                targetSubAction = null;
                // targetResultは維持してもいいが、一応リセットしないでおく
              });
            }

            // 出力先アクション選択時のリセット
            void onDestActionChanged(ActionDefinition? val) {
              setStateDialog(() {
                destAction = val;
                destSubAction = null;
                if (val != null) {
                  // デフォルトの結果をセット
                  if (val.hasSuccess) destResult = ActionResult.success;
                  else if (val.hasFailure) destResult = ActionResult.failure;
                  else destResult = ActionResult.none;
                }
              });
            }

            // サブアクション候補の取得
            List<SubActionDefinition> getSubCandidates(ActionDefinition action, ActionResult? res) {
              if (res == null) return action.subActions; // 結果指定なしなら全部
              String cat = 'default';
              if (res == ActionResult.success) cat = 'success';
              if (res == ActionResult.failure) cat = 'failure';
              return action.getSubActions(cat);
            }

            return AlertDialog(
              title: const Row(children: [Icon(Icons.swap_horiz), SizedBox(width: 8), Text("ログ一括置換ツール")]),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("【変更対象の条件】", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<ActionDefinition>(
                              value: targetAction,
                              decoration: const InputDecoration(labelText: "対象アクション (必須)", isDense: true, border: OutlineInputBorder()),
                              items: _actions.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                              onChanged: onTargetActionChanged,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<ActionResult?>(
                                    value: targetResult,
                                    decoration: const InputDecoration(labelText: "結果 (任意)", isDense: true, border: OutlineInputBorder()),
                                    items: const [
                                      DropdownMenuItem(value: null, child: Text("すべて")),
                                      DropdownMenuItem(value: ActionResult.success, child: Text("成功")),
                                      DropdownMenuItem(value: ActionResult.failure, child: Text("失敗")),
                                      DropdownMenuItem(value: ActionResult.none, child: Text("なし")),
                                    ],
                                    onChanged: (val) => setStateDialog(() => targetResult = val),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<SubActionDefinition?>(
                                    value: targetSubAction,
                                    isExpanded: true,
                                    decoration: const InputDecoration(labelText: "詳細 (任意)", isDense: true, border: OutlineInputBorder()),
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text("指定なし")),
                                      if (targetAction != null)
                                        ...getSubCandidates(targetAction!, targetResult).map((s) => DropdownMenuItem(value: s, child: Text(s.name))),
                                    ],
                                    onChanged: (val) => setStateDialog(() => targetSubAction = val),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(child: Icon(Icons.arrow_downward, color: Colors.indigo, size: 32)),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.indigo.shade200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("【変更後の内容】", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<ActionDefinition>(
                              value: destAction,
                              decoration: const InputDecoration(labelText: "新しいアクション (必須)", isDense: true, border: OutlineInputBorder()),
                              items: _actions.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                              onChanged: onDestActionChanged,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<ActionResult>(
                                    value: destResult,
                                    decoration: const InputDecoration(labelText: "結果 (必須)", isDense: true, border: OutlineInputBorder()),
                                    items: const [
                                      DropdownMenuItem(value: ActionResult.success, child: Text("成功")),
                                      DropdownMenuItem(value: ActionResult.failure, child: Text("失敗")),
                                      DropdownMenuItem(value: ActionResult.none, child: Text("なし")),
                                    ],
                                    onChanged: (val) => setStateDialog(() {
                                      destResult = val!;
                                      destSubAction = null; // 結果が変わればサブの候補も変わるためリセット
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<SubActionDefinition?>(
                                    value: destSubAction,
                                    isExpanded: true,
                                    decoration: const InputDecoration(labelText: "詳細 (任意)", isDense: true, border: OutlineInputBorder()),
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text("なし")),
                                      if (destAction != null)
                                        ...getSubCandidates(destAction!, destResult).map((s) => DropdownMenuItem(value: s, child: Text(s.name))),
                                    ],
                                    onChanged: (val) => setStateDialog(() => destSubAction = val),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("※ 注意: この操作は取り消せません。該当する過去のログがすべて書き換わります。", style: TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("実行"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: (targetAction != null && destAction != null) ? () async {
                    // 実行確認
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text("実行確認"),
                        content: const Text("本当にログを置換しますか？\nこの操作は元に戻せません。"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("いいえ")),
                          ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("はい")),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _matchDao.migrateActionLogs(
                        teamId: currentTeam.id,
                        targetAction: targetAction!.name,
                        targetResult: targetResult?.index, // nullなら全結果
                        targetSubAction: targetSubAction?.name, // nullなら全詳細
                        newAction: destAction!.name,
                        newResult: destResult.index,
                        newSubAction: destSubAction?.name,
                        newSubActionId: destSubAction?.id,
                      );
                      if (context.mounted) {
                        Navigator.pop(ctx); // ダイアログ閉じる
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ログの置換が完了しました")));
                      }
                    }
                  } : null,
                ),
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
      appBar: AppBar(
        title: const Text('アクション設定'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: "ログ一括置換ツール",
            onPressed: _showMigrationDialog,
          ),
        ],
      ),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(action: item)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteAction(item)),
              ],
            ),
            isThreeLine: true,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showEditDialog(), child: const Icon(Icons.add)),
    );
  }
}