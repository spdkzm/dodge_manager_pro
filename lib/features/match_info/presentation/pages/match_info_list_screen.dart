// lib/features/match_info/presentation/pages/match_info_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../team_mgmt/application/team_store.dart';
import '../../../team_mgmt/domain/schema.dart';
import '../../../team_mgmt/domain/roster_item.dart';
import '../../../team_mgmt/presentation/pages/schema_settings_screen.dart';

class MatchInfoListScreen extends ConsumerStatefulWidget {
  const MatchInfoListScreen({super.key});

  @override
  ConsumerState<MatchInfoListScreen> createState() => _MatchInfoListScreenState();
}

class _MatchInfoListScreenState extends ConsumerState<MatchInfoListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentCategory = 1; // 1:Opponent, 2:Venue

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentCategory = _tabController.index + 1; // 0->1, 1->2
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('試合情報リスト'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.indigo,
          tabs: const [
            Tab(text: '対戦相手'),
            Tab(text: '会場'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'schema') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SchemaSettingsScreen(targetCategory: _currentCategory)));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'schema', child: Row(children: [Icon(Icons.build, color: Colors.grey), SizedBox(width: 8), Text('項目の設計')])),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _InfoList(category: 1), // 対戦相手
          _InfoList(category: 2), // 会場
        ],
      ),
    );
  }
}

class _InfoList extends ConsumerStatefulWidget {
  final int category;
  const _InfoList({required this.category});

  @override
  ConsumerState<_InfoList> createState() => _InfoListState();
}

class _InfoListState extends ConsumerState<_InfoList> {

  // --- データ編集ダイアログ ---
  Future<void> _showItemDialog(List<FieldDefinition> schema, {RosterItem? item}) async {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    if (currentTeam == null) return;

    final isEditing = item != null;
    final Map<String, dynamic> tempData = {};

    // 名前フィールドの特定 (「名前」を含むか、テキスト型)
    final nameField = schema.firstWhere(
            (f) => f.label.contains("名") || f.type == FieldType.text,
        orElse: () => schema.first
    );
    final String originalName = item?.data[nameField.id]?.toString() ?? "";

    if (item != null) {
      item.data.forEach((k, v) => tempData[k] = v);
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? '編集' : '新規追加'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: schema.map((field) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildInput(field, tempData),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: () async {
                // 必須チェック
                for(var f in schema) {
                  if (f.isSystem && (tempData[f.id] == null || tempData[f.id].toString().isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${f.label}は必須です')));
                    return;
                  }
                }

                final newName = tempData[nameField.id]?.toString() ?? "";

                // ★追加: 名前変更チェックと一括更新確認
                if (isEditing && originalName.isNotEmpty && newName != originalName) {
                  final usageCount = await store.checkMatchInfoUsage(widget.category, originalName);
                  if (usageCount > 0 && context.mounted) {
                    final shouldUpdate = await showDialog<bool>(
                      context: context,
                      builder: (alertCtx) => AlertDialog(
                        title: const Text("名前の変更"),
                        content: Text(
                            "「$originalName」は過去 $usageCount 件の試合記録で使用されています。\n"
                                "過去の記録もすべて「$newName」に変更しますか？"
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(alertCtx, false), child: const Text("変更しない\n(新規扱い)")),
                          ElevatedButton(
                              onPressed: () => Navigator.pop(alertCtx, true),
                              child: const Text("変更する")
                          ),
                        ],
                      ),
                    );

                    if (shouldUpdate == true) {
                      await store.updateMatchInfoName(widget.category, originalName, newName);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("過去の記録も更新しました")));
                      }
                    }
                  }
                }

                if (isEditing) {
                  item!.data = tempData;
                  store.saveItem(currentTeam.id, item!, category: widget.category);
                } else {
                  final newItem = RosterItem(data: tempData);
                  store.addItem(currentTeam.id, newItem, category: widget.category);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInput(FieldDefinition field, Map<String, dynamic> data) {
    return TextFormField(
      initialValue: data[field.id]?.toString(),
      decoration: InputDecoration(labelText: field.label, border: const OutlineInputBorder()),
      onChanged: (val) => data[field.id] = val,
    );
  }

  // ★修正: 削除時のチェック処理
  Future<void> _deleteItem(RosterItem item, FieldDefinition nameField) async {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    if(currentTeam==null) return;

    final name = item.data[nameField.id]?.toString() ?? "";

    // 使用回数チェック
    int usageCount = 0;
    if (name.isNotEmpty) {
      usageCount = await store.checkMatchInfoUsage(widget.category, name);
    }

    if (!mounted) return;

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('削除確認'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("「$name」をリストから削除しますか？"),
              const SizedBox(height: 16),
              if (usageCount > 0)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(4)
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "警告: この項目は過去 $usageCount 件の試合で使用されています。\n削除すると、過去の記録上の名前は残りますが、リストとの紐付けは解除されます。",
                          style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Text("この項目は現在使用されていません。", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('キャンセル')),
            TextButton(
                onPressed: () {
                  store.deleteItem(currentTeam.id, item, category: widget.category);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("削除しました")));
                },
                child: const Text('削除', style: TextStyle(color: Colors.red))
            ),
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(teamStoreProvider);
    final currentTeam = store.currentTeam;

    if (!store.isLoaded) return const Center(child: CircularProgressIndicator());
    if (currentTeam == null) return const Center(child: Text('チームがありません'));

    final schema = currentTeam.getSchema(widget.category);
    final items = currentTeam.getItems(widget.category);
    final visibleColumns = schema.where((f) => f.isVisible).toList();

    // 名前フィールド（削除時の表示用）
    final nameField = schema.firstWhere(
            (f) => f.label.contains("名") || f.type == FieldType.text,
        orElse: () => schema.first
    );

    if (items.isEmpty) {
      return Stack(
        children: [
          const Center(child: Text('データがありません\n右下のボタンから追加してください')),
          Positioned(
            bottom: 16, right: 16,
            child: FloatingActionButton(
              onPressed: () => _showItemDialog(schema),
              child: const Icon(Icons.add),
            ),
          )
        ],
      );
    }

    // リスト表示
    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          final name = item.data[nameField.id]?.toString() ?? "名称未設定";

          // その他の情報をサブタイトルにまとめる
          List<String> subInfos = [];
          for (var f in visibleColumns) {
            if (f.id != nameField.id) {
              final val = item.data[f.id];
              if (val != null && val.toString().isNotEmpty) {
                subInfos.add("${f.label}: $val");
              }
            }
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade50,
              child: Icon(widget.category == 1 ? Icons.groups : Icons.place, color: Colors.indigo),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: subInfos.isNotEmpty ? Text(subInfos.join(" / ")) : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => _deleteItem(item, nameField),
            ),
            onTap: () => _showItemDialog(schema, item: item),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(schema),
        child: const Icon(Icons.add),
      ),
    );
  }
}