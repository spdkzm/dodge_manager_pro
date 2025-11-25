import 'package:flutter/material.dart';
import 'team_store.dart';
import 'schema.dart';

class SchemaSettingsScreen extends StatefulWidget {
  const SchemaSettingsScreen({super.key});

  @override
  State<SchemaSettingsScreen> createState() => _SchemaSettingsScreenState();
}

class _SchemaSettingsScreenState extends State<SchemaSettingsScreen> {
  final TeamStore _store = TeamStore();
  List<FieldDefinition> _localSchema = [];
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _loadSchema();
  }

  void _loadSchema() {
    final currentTeam = _store.currentTeam;
    if (currentTeam != null) {
      _localSchema = currentTeam.schema.map((f) => f.clone()).toList();
      _isDirty = false;
    }
  }

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
              if (optionInputCtrl.text.isNotEmpty) {
                setStateDialog(() {
                  tempOptions.add(optionInputCtrl.text);
                  optionInputCtrl.clear();
                });
              }
            }

            Widget buildConfigArea() {
              if (selectedType == FieldType.text) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text('入力方式', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Radio<bool>(
                          value: false, groupValue: useDropdown,
                          onChanged: (v) => setStateDialog(() => useDropdown = v!),
                        ),
                        const Text('自由入力'),
                        const SizedBox(width: 16),
                        Radio<bool>(
                          value: true, groupValue: useDropdown,
                          onChanged: (v) => setStateDialog(() => useDropdown = v!),
                        ),
                        const Text('プルダウン'),
                      ],
                    ),
                    if (useDropdown) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: optionInputCtrl,
                              decoration: const InputDecoration(labelText: '選択肢を追加'),
                              onSubmitted: (_) => addOption(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.blue),
                            onPressed: addOption,
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: tempOptions.map((opt) => Chip(
                          label: Text(opt),
                          onDeleted: () => setStateDialog(() => tempOptions.remove(opt)),
                        )).toList(),
                      ),
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
                    RadioListTile<int>(
                      title: const Text('自由入力'),
                      value: 0, groupValue: !useDropdown ? 0 : (isRange ? 2 : 1),
                      onChanged: (v) => setStateDialog(() { useDropdown = false; isRange = false; }),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<int>(
                      title: const Text('リスト選択'),
                      value: 1, groupValue: !useDropdown ? 0 : (isRange ? 2 : 1),
                      onChanged: (v) => setStateDialog(() { useDropdown = true; isRange = false; }),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<int>(
                      title: const Text('範囲選択'),
                      value: 2, groupValue: !useDropdown ? 0 : (isRange ? 2 : 1),
                      onChanged: (v) => setStateDialog(() { useDropdown = true; isRange = true; }),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (useDropdown && !isRange) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: optionInputCtrl,
                              decoration: const InputDecoration(labelText: '数値をリストに追加'),
                              keyboardType: TextInputType.number,
                              onSubmitted: (_) => addOption(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.blue),
                            onPressed: addOption,
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: tempOptions.map((opt) => Chip(
                          label: Text(opt),
                          onDeleted: () => setStateDialog(() => tempOptions.remove(opt)),
                        )).toList(),
                      ),
                    ],
                    if (useDropdown && isRange) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minCtrl,
                              decoration: const InputDecoration(labelText: '下限'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text('〜'),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: maxCtrl,
                              decoration: const InputDecoration(labelText: '上限'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              }
              return const SizedBox();
            }

            Widget buildUniqueSetting() {
              if (useDropdown || selectedType == FieldType.uniformNumber) {
                return Column(
                  children: [
                    const Divider(),
                    CheckboxListTile(
                      title: const Text('重複を禁止する'),
                      subtitle: const Text('既存データとの入れ替えが可能になります'),
                      value: isUnique,
                      onChanged: (v) => setStateDialog(() => isUnique = v!),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                );
              }
              return const SizedBox();
            }

            return AlertDialog(
              title: Text(isEditing ? '項目を編集' : '項目を追加'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '項目名'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<FieldType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'データの種類'),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: FieldType.text, child: Text('自由テキスト')),
                        DropdownMenuItem(value: FieldType.number, child: Text('数値')),
                        DropdownMenuItem(value: FieldType.date, child: Text('日付')),
                        DropdownMenuItem(value: FieldType.uniformNumber, child: Text('背番号')),
                        DropdownMenuItem(value: FieldType.courtName, child: Text('コートネーム')), // ★追加
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() {
                            selectedType = val;
                            useDropdown = false;
                            isRange = false;
                            // 背番号ならデフォルトで重複禁止
                            isUnique = (val == FieldType.uniformNumber);
                            tempOptions.clear();
                          });
                        }
                      },
                    ),
                    buildConfigArea(),
                    buildUniqueSetting(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isEmpty) return;

                    final newDef = FieldDefinition(
                      id: field?.id,
                      label: nameController.text,
                      type: selectedType,
                      isSystem: false,
                      isVisible: field?.isVisible ?? true,
                      useDropdown: useDropdown,
                      isRange: isRange,
                      options: tempOptions,
                      minNum: int.tryParse(minCtrl.text),
                      maxNum: int.tryParse(maxCtrl.text),
                      isUnique: isUnique,
                    );

                    if (isEditing && index != null) {
                      setState(() {
                        _localSchema[index] = newDef;
                        _isDirty = true;
                      });
                    } else {
                      setState(() {
                        _localSchema.add(newDef);
                        _isDirty = true;
                      });
                    }
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

  Future<void> _confirmDelete(FieldDefinition field) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('項目の削除'),
        content: Text('項目「${field.label}」を削除しますか？\n(保存ボタンを押すまで確定しません)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
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

  void _saveChanges() {
    final currentTeam = _store.currentTeam;
    if (currentTeam == null) return;

    _store.saveSchema(currentTeam.id, _localSchema);
    setState(() { _isDirty = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('設定を保存しました')),
    );
    Navigator.pop(context);
  }

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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('破棄する', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存して閉じる'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      _saveChanges();
    } else if (shouldSave == false) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('名簿の項目設計'),
          actions: [
            TextButton(
              onPressed: _handlePop,
              child: const Text('キャンセル', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: _isDirty ? _saveChanges : null,
              child: Text(
                '保存',
                style: TextStyle(
                  color: _isDirty ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'ドラッグで並び替え、タップで編集が可能です。\n右上の保存ボタンを押すまで変更は反映されません。',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = _localSchema.removeAt(oldIndex);
                    _localSchema.insert(newIndex, item);
                    _isDirty = true;
                  });
                },
                children: [
                  for (int i = 0; i < _localSchema.length; i++)
                    ListTile(
                      key: ValueKey(_localSchema[i].id),
                      leading: Icon(_getIconForType(_localSchema[i].type)),
                      title: Row(
                        children: [
                          Text(
                            _localSchema[i].label + (_localSchema[i].isSystem ? ' (基本)' : ''),
                            style: TextStyle(
                              fontWeight: _localSchema[i].isSystem ? FontWeight.bold : FontWeight.normal,
                              color: _localSchema[i].isVisible ? Colors.black : Colors.grey,
                            ),
                          ),
                          if (_localSchema[i].useDropdown)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.arrow_drop_down_circle, size: 16, color: Colors.blue),
                            ),
                          if (_localSchema[i].isUnique)
                            const Padding(
                              padding: EdgeInsets.only(left: 4.0),
                              child: Icon(Icons.lock, size: 16, color: Colors.orange),
                            ),
                        ],
                      ),
                      subtitle: Text(_getSubtitle(_localSchema[i])),
                      trailing: _localSchema[i].isSystem
                          ? Switch(
                        value: _localSchema[i].isVisible,
                        activeColor: Colors.blue,
                        onChanged: (val) {
                          setState(() {
                            _localSchema[i].isVisible = val;
                            _isDirty = true;
                          });
                        },
                      )
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showFieldDialog(field: _localSchema[i], index: i),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(_localSchema[i]),
                          ),
                        ],
                      ),
                    ),
                ],
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
      case FieldType.courtName: return Icons.sports_handball; // ★追加
    }
  }

  String _getSubtitle(FieldDefinition field) {
    String typeName = '';
    switch (field.type) {
      case FieldType.text: typeName = 'テキスト'; break;
      case FieldType.number: typeName = '数値'; break;
      case FieldType.date: typeName = '日付'; break;
      case FieldType.uniformNumber: typeName = '背番号'; break;
      case FieldType.courtName: typeName = 'コートネーム'; break; // ★追加
      default: typeName = '';
    }
    if (field.useDropdown) {
      typeName += ' (プルダウン';
      if (field.isRange) typeName += ':範囲';
      if (field.isUnique) typeName += ':重複不可';
      typeName += ')';
    } else if (field.isUnique) {
      typeName += ' (重複不可)';
    }
    return typeName;
  }
}