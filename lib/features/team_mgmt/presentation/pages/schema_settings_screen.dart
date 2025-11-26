// lib/features/team_mgmt/presentation/pages/schema_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/team_store.dart'; // Provider
import '../../domain/schema.dart';

class SchemaSettingsScreen extends ConsumerStatefulWidget {
  const SchemaSettingsScreen({super.key});

  @override
  ConsumerState<SchemaSettingsScreen> createState() => _SchemaSettingsScreenState();
}

class _SchemaSettingsScreenState extends ConsumerState<SchemaSettingsScreen> {
  List<FieldDefinition> _localSchema = [];
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    // 画面構築後にデータをロード
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchema();
    });
  }

  void _loadSchema() {
    final store = ref.read(teamStoreProvider);
    // ロードされていなければロード
    if (!store.isLoaded) {
      store.loadFromDb().then((_) {
        _syncSchema();
      });
    } else {
      _syncSchema();
    }
  }

  void _syncSchema() {
    final currentTeam = ref.read(teamStoreProvider).currentTeam;
    if (currentTeam != null) {
      setState(() {
        // データをコピーしてローカル変数へ（編集用）
        _localSchema = currentTeam.schema.map((f) => f.clone()).toList();
        _isDirty = false;
      });
    }
  }

  // --- ダイアログ (追加・編集) ---
  void _showFieldDialog({FieldDefinition? field, int? index}) {
    final isEditing = field != null;
    final nameController = TextEditingController(text: field?.label ?? '');

    FieldType selectedType = field?.type ?? FieldType.text;
    bool useDropdown = field?.useDropdown ?? false;
    bool isRange = field?.isRange ?? false;
    bool isUnique = field?.isUnique ?? false;

    final optionInputCtrl = TextEditingController();
    List<String> tempOptions = field != null ? List.from(field.options) : [];

    final minCtrl = TextEditingController(text: field?.minNum?.toString() ?? '');
    final maxCtrl = TextEditingController(text: field?.maxNum?.toString() ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void addOption() {
              if (optionInputCtrl.text.trim().isNotEmpty) {
                setStateDialog(() {
                  tempOptions.add(optionInputCtrl.text.trim());
                  optionInputCtrl.clear();
                });
              }
            }

            // 入力方式エリアの構築
            Widget buildConfigArea() {
              if (selectedType == FieldType.text) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text('入力方式', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Radio<bool>(value: false, groupValue: useDropdown, onChanged: (v) => setStateDialog(() => useDropdown = v!)),
                        const Text('自由入力'),
                        const SizedBox(width: 16),
                        Radio<bool>(value: true, groupValue: useDropdown, onChanged: (v) => setStateDialog(() => useDropdown = v!)),
                        const Text('プルダウン'),
                      ],
                    ),
                    if (useDropdown) ...[
                      Row(children: [
                        Expanded(child: TextField(controller: optionInputCtrl, decoration: const InputDecoration(labelText: '選択肢を追加'), onSubmitted: (_) => addOption())),
                        IconButton(icon: const Icon(Icons.add_circle, color: Colors.blue), onPressed: addOption),
                      ]),
                      Wrap(spacing: 8, children: tempOptions.map((opt) => Chip(label: Text(opt), onDeleted: () => setStateDialog(() => tempOptions.remove(opt)))).toList()),
                    ],
                  ],
                );
              }
              if (selectedType == FieldType.number) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text('入力方式', style: TextStyle(fontWeight: FontWeight.bold)),
                    RadioListTile<int>(title: const Text('自由入力'), value: 0, groupValue: !useDropdown ? 0 : (isRange ? 2 : 1), onChanged: (v) => setStateDialog(() { useDropdown = false; isRange = false; }), contentPadding: EdgeInsets.zero),
                    RadioListTile<int>(title: const Text('リスト選択'), value: 1, groupValue: !useDropdown ? 0 : (isRange ? 2 : 1), onChanged: (v) => setStateDialog(() { useDropdown = true; isRange = false; }), contentPadding: EdgeInsets.zero),
                    RadioListTile<int>(title: const Text('範囲選択'), value: 2, groupValue: !useDropdown ? 0 : (isRange ? 2 : 1), onChanged: (v) => setStateDialog(() { useDropdown = true; isRange = true; }), contentPadding: EdgeInsets.zero),
                    if (useDropdown && !isRange) ...[
                      Row(children: [
                        Expanded(child: TextField(controller: optionInputCtrl, decoration: const InputDecoration(labelText: '数値をリストに追加'), keyboardType: TextInputType.number, onSubmitted: (_) => addOption())),
                        IconButton(icon: const Icon(Icons.add_circle, color: Colors.blue), onPressed: addOption),
                      ]),
                      Wrap(spacing: 8, children: tempOptions.map((opt) => Chip(label: Text(opt), onDeleted: () => setStateDialog(() => tempOptions.remove(opt)))).toList()),
                    ],
                    if (useDropdown && isRange) ...[
                      Row(children: [
                        Expanded(child: TextField(controller: minCtrl, decoration: const InputDecoration(labelText: '下限'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 16), const Text('〜'), const SizedBox(width: 16),
                        Expanded(child: TextField(controller: maxCtrl, decoration: const InputDecoration(labelText: '上限'), keyboardType: TextInputType.number)),
                      ]),
                    ],
                  ],
                );
              }
              return const SizedBox();
            }

            return AlertDialog(
              title: Text(isEditing ? '項目を編集' : '項目を追加'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: '項目名'), autofocus: true),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<FieldType>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'データの種類'),
                        items: const [
                          DropdownMenuItem(value: FieldType.text, child: Text('自由テキスト')),
                          DropdownMenuItem(value: FieldType.number, child: Text('数値')),
                          DropdownMenuItem(value: FieldType.date, child: Text('日付')),
                          DropdownMenuItem(value: FieldType.uniformNumber, child: Text('背番号')),
                          DropdownMenuItem(value: FieldType.courtName, child: Text('コートネーム')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() {
                              selectedType = val;
                              useDropdown = false;
                              isRange = false;
                              isUnique = (val == FieldType.uniformNumber);
                              tempOptions.clear();
                            });
                          }
                        },
                      ),
                      buildConfigArea(),
                      if (useDropdown || selectedType == FieldType.uniformNumber)
                        CheckboxListTile(
                          title: const Text('重複を禁止する'),
                          value: isUnique,
                          onChanged: (v) => setStateDialog(() => isUnique = v!),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isEmpty) return;
                    final newDef = FieldDefinition(
                      id: field?.id, // 編集時はID維持、新規はnull(自動生成)
                      label: nameController.text,
                      type: selectedType,
                      isSystem: field?.isSystem ?? false, // システムフラグ維持
                      isVisible: field?.isVisible ?? true,
                      useDropdown: useDropdown,
                      isRange: isRange,
                      options: tempOptions,
                      minNum: int.tryParse(minCtrl.text),
                      maxNum: int.tryParse(maxCtrl.text),
                      isUnique: isUnique,
                    );

                    setState(() {
                      if (isEditing && index != null) {
                        _localSchema[index] = newDef;
                      } else {
                        _localSchema.add(newDef);
                      }
                      _isDirty = true;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 削除確認 ---
  Future<void> _confirmDelete(FieldDefinition field) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('項目の削除'),
        content: Text('項目「${field.label}」を削除しますか？\n保存するまで確定しません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _localSchema.remove(field);
        _isDirty = true;
      });
    }
  }

  // --- 保存処理 ---
  void _saveChanges() {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    if (currentTeam == null) return;

    store.saveSchema(currentTeam.id, _localSchema);
    setState(() { _isDirty = false; });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('設定を保存しました')));
    Navigator.pop(context);
  }

  // --- 戻る処理 ---
  Future<void> _handlePop() async {
    if (!_isDirty) {
      Navigator.pop(context);
      return;
    }
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('変更が保存されていません'),
        content: const Text('変更を保存しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('破棄する', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('キャンセル')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存して閉じる')),
        ],
      ),
    );

    if (shouldSave == true) {
      _saveChanges();
    } else if (shouldSave == false) {
      if (mounted) Navigator.pop(context);
    }
  }

  IconData _getIconForType(FieldType type) {
    switch (type) {
      case FieldType.text: return Icons.short_text;
      case FieldType.number: return Icons.numbers;
      case FieldType.date: return Icons.calendar_today;
      case FieldType.personName: return Icons.badge;
      case FieldType.personKana: return Icons.translate;
      case FieldType.address: return Icons.home;
      case FieldType.phone: return Icons.phone;
      case FieldType.age: return Icons.cake;
      case FieldType.uniformNumber: return Icons.looks_one;
      case FieldType.courtName: return Icons.sports_handball;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) { if (!didPop) _handlePop(); },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('名簿の項目設計'),
          actions: [
            TextButton(
              onPressed: _isDirty ? _saveChanges : null,
              child: Text('保存', style: TextStyle(color: _isDirty ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('項目の並び替え、追加、編集ができます。\n「基本項目」は削除できませんが、表示/非表示を切り替えられます。', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            ),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _localSchema.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = _localSchema.removeAt(oldIndex);
                    _localSchema.insert(newIndex, item);
                    _isDirty = true;
                  });
                },
                itemBuilder: (context, index) {
                  final field = _localSchema[index];

                  // ★ここが重要: 基本項目かカスタム項目かで表示を分ける
                  return ListTile(
                    key: ValueKey(field.id),
                    leading: Icon(_getIconForType(field.type)),
                    title: Row(
                      children: [
                        Text(field.label, style: TextStyle(fontWeight: field.isSystem ? FontWeight.bold : FontWeight.normal)),
                        if (field.isSystem)
                          const Padding(padding: EdgeInsets.only(left: 8.0), child: Chip(label: Text("基本", style: TextStyle(fontSize: 10)), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact)),
                      ],
                    ),
                    // システム項目なら「スイッチ」、カスタム項目なら「編集・削除ボタン」
                    trailing: field.isSystem
                        ? Switch(
                      value: field.isVisible,
                      activeColor: Colors.blue,
                      onChanged: (val) {
                        setState(() {
                          // Freezedではない(またはclone済みのミュータブル)なら直接変更可
                          // FieldDefinitionは現状Freezedではないため直接変更
                          field.isVisible = val;
                          _isDirty = true;
                        });
                      },
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showFieldDialog(field: field, index: index)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(field)),
                        const Icon(Icons.drag_handle, color: Colors.grey),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showFieldDialog(),
          label: const Text('項目追加'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}