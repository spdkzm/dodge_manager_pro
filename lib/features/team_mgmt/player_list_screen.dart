import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 相対パスインポート
import 'team_store.dart';
import 'schema.dart';
import 'roster_item.dart';
import 'team.dart';

class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen({super.key});

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  final TeamStore _store = TeamStore();

  final List<String> _prefectures = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県',
    '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県',
    '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県',
    '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
  ];

  void _showViewFilterDialog(Team team) {
    final activeFields = team.schema.where((f) => f.isVisible).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('一覧の表示項目'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: activeFields.map((field) {
                    final isVisibleInView = !team.viewHiddenFields.contains(field.id);
                    return CheckboxListTile(
                      title: Text(field.label),
                      value: isVisibleInView,
                      onChanged: (val) {
                        _store.toggleViewColumn(team.id, field.id);
                        setStateDialog(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showItemDialog({RosterItem? item}) async {
    final currentTeam = _store.currentTeam;
    if (currentTeam == null) return;

    final isEditing = item != null;
    final inputFields = currentTeam.schema.where((f) => f.isVisible).toList();

    final Map<String, dynamic> tempData = {};
    if (item != null) {
      item.data.forEach((key, value) {
        if (value is Map) {
          tempData[key] = Map<String, dynamic>.from(value);
        } else {
          tempData[key] = value;
        }
      });
    }

    bool isChanged = false;
    void markChanged() { isChanged = true; }

    void tryCalculateAge() {
      final dateField = currentTeam.schema.firstWhere(
            (f) => f.type == FieldType.date,
        orElse: () => FieldDefinition(label: '', type: FieldType.text),
      );
      final ageField = currentTeam.schema.firstWhere(
            (f) => f.type == FieldType.age,
        orElse: () => FieldDefinition(label: '', type: FieldType.text),
      );

      if (dateField.type == FieldType.date && ageField.type == FieldType.age) {
        final birthDate = tempData[dateField.id];
        if (birthDate is DateTime) {
          final now = DateTime.now();
          int age = now.year - birthDate.year;
          if (now.month < birthDate.month ||
              (now.month == birthDate.month && now.day < birthDate.day)) {
            age--;
          }
          tempData[ageField.id] = age;
        }
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {

            Future<void> saveProcess() async {
              for (var field in inputFields) {
                if (field.isUnique) {
                  final newValue = tempData[field.id];
                  if (newValue == null || newValue.toString().isEmpty) continue;

                  final conflictItem = currentTeam.items.cast<RosterItem?>().firstWhere(
                        (i) => i!.id != (item?.id ?? '') && i.data[field.id].toString() == newValue.toString(),
                    orElse: () => null,
                  );

                  if (conflictItem != null) {
                    String conflictName = '他のデータ';
                    final nameField = currentTeam.schema.firstWhere(
                            (f) => f.type == FieldType.personName,
                        orElse: () => field
                    );
                    if (nameField.type == FieldType.personName && conflictItem.data[nameField.id] is Map) {
                      conflictName = '${conflictItem.data[nameField.id]['last']} ${conflictItem.data[nameField.id]['first']}';
                    }

                    final doSwap = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('値が重複しています'),
                        content: Text(
                            '項目「${field.label}」の値「$newValue」は\n'
                                '「$conflictName」ですでに使用されています。\n\n'
                                '入れ替えますか？\n(相手の値は未設定になります)'
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('入れ替える')),
                        ],
                      ),
                    );

                    if (doSwap == true) {
                      conflictItem.data[field.id] = null;
                      _store.saveItem(currentTeam.id, conflictItem); // StoreのsaveItemを使用
                    } else {
                      return;
                    }
                  }
                }
              }

              if (isEditing) {
                item!.data = tempData;
                _store.saveItem(currentTeam.id, item); // DB保存
              } else {
                final newItem = RosterItem(data: tempData);
                _store.addItem(currentTeam.id, newItem);
              }
              if (context.mounted) Navigator.pop(context);
            }

            Future<void> handleClose() async {
              if (!isChanged && !isEditing) { Navigator.pop(context); return; }
              final shouldSave = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('変更が保存されていません'),
                  content: const Text('保存せずに閉じますか？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('破棄する', style: TextStyle(color: Colors.grey))),
                    TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('キャンセル')),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存して閉じる')),
                  ],
                ),
              );
              if (shouldSave == true) await saveProcess();
              else if (shouldSave == false && context.mounted) Navigator.pop(context);
            }

            return PopScope(
              canPop: false,
              onPopInvoked: (didPop) { if (!didPop) handleClose(); },
              child: AlertDialog(
                title: Text(isEditing ? 'データを編集' : '新規追加'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: inputFields.map((field) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: _buildComplexInput(
                            field,
                            tempData,
                            markChanged,
                                (fn) => setStateDialog(fn),
                            tryCalculateAge,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: handleClose, child: const Text('キャンセル')),
                  ElevatedButton(onPressed: saveProcess, child: const Text('保存')),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildComplexInput(
      FieldDefinition field,
      Map<String, dynamic> data,
      VoidCallback onChange,
      Function(VoidCallback) setStateDialog,
      VoidCallback calcAge,
      ) {
    Map<String, dynamic> getMap() {
      if (data[field.id] is! Map) data[field.id] = <String, dynamic>{};
      return data[field.id] as Map<String, dynamic>;
    }

    if (field.useDropdown) {
      final dropdownItems = _generateDropdownItems(field);
      dynamic currentValue = data[field.id];
      final containsValue = dropdownItems.any((item) => item.value.toString() == currentValue.toString());

      if (!containsValue) {
        currentValue = null;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          DropdownButtonFormField<dynamic>(
            value: currentValue,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
            items: dropdownItems,
            onChanged: (val) { setStateDialog(() { data[field.id] = val; onChange(); }); },
          ),
        ],
      );
    }

    switch (field.type) {
      case FieldType.personName:
      case FieldType.personKana:
        final map = getMap();
        final label1 = field.type == FieldType.personName ? '氏' : 'フリガナ(セイ)';
        final label2 = field.type == FieldType.personName ? '名' : 'フリガナ(メイ)';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: map['last'],
                    decoration: InputDecoration(labelText: label1),
                    onChanged: (v) { map['last'] = v; onChange(); },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: map['first'],
                    decoration: InputDecoration(labelText: label2),
                    onChanged: (v) { map['first'] = v; onChange(); },
                  ),
                ),
              ],
            ),
          ],
        );

      case FieldType.date:
        final currentDate = data[field.id] as DateTime?;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: currentDate ?? DateTime(2000),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  locale: const Locale('ja'),
                );
                if (picked != null) {
                  setStateDialog(() {
                    data[field.id] = picked;
                    onChange();
                    calcAge();
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today)),
                child: Text(
                  currentDate != null
                      ? DateFormat('yyyy年 MM月 dd日').format(currentDate)
                      : '日付を選択',
                ),
              ),
            ),
          ],
        );

      case FieldType.age:
        final val = data[field.id];
        final ctrl = TextEditingController(text: val?.toString() ?? '');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            TextFormField(
              controller: ctrl,
              decoration: const InputDecoration(suffixText: '歳'),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                data[field.id] = int.tryParse(v);
                onChange();
              },
            ),
          ],
        );

      case FieldType.address:
        final map = getMap();
        String? currentPref = map['pref'];
        if (currentPref != null && !_prefectures.contains(currentPref)) {
          currentPref = null;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.markunread_mailbox_outlined, color: Colors.grey),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: map['zip1'],
                    decoration: const InputDecoration(hintText: '000', counterText: ''),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    onChanged: (v) { map['zip1'] = v; onChange(); },
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: map['zip2'],
                    decoration: const InputDecoration(hintText: '0000', counterText: ''),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    onChanged: (v) { map['zip2'] = v; onChange(); },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: currentPref,
              decoration: const InputDecoration(labelText: '都道府県'),
              items: _prefectures.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) { map['pref'] = v; onChange(); },
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: map['city'],
              decoration: const InputDecoration(labelText: '市区町村・番地'),
              onChanged: (v) { map['city'] = v; onChange(); },
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: map['building'],
              decoration: const InputDecoration(labelText: '建物名・部屋番号'),
              onChanged: (v) { map['building'] = v; onChange(); },
            ),
          ],
        );

      case FieldType.phone:
        final map = getMap();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.grey),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: map['part1'],
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.center,
                    onChanged: (v) { map['part1'] = v; onChange(); },
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
                Expanded(
                  child: TextFormField(
                    initialValue: map['part2'],
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.center,
                    onChanged: (v) { map['part2'] = v; onChange(); },
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
                Expanded(
                  child: TextFormField(
                    initialValue: map['part3'],
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.center,
                    onChanged: (v) { map['part3'] = v; onChange(); },
                  ),
                ),
              ],
            ),
          ],
        );

      case FieldType.number:
        return TextFormField(
          initialValue: data[field.id]?.toString(),
          decoration: InputDecoration(labelText: field.label, suffixIcon: const Icon(Icons.numbers)),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            data[field.id] = num.tryParse(val);
            onChange();
          },
        );

    // ★追加: 背番号入力フォーム (数値キーボードだが文字列として扱う)
      case FieldType.uniformNumber:
        return TextFormField(
          initialValue: data[field.id]?.toString(),
          decoration: InputDecoration(
              labelText: field.label,
              suffixIcon: const Icon(Icons.looks_one),
              hintText: '例: 1, 10, 01'
          ),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            data[field.id] = val; // Stringとして保存
            onChange();
          },
        );

      case FieldType.text:
      default:
        return TextFormField(
          initialValue: data[field.id] as String?,
          decoration: InputDecoration(labelText: field.label),
          onChanged: (val) {
            data[field.id] = val;
            onChange();
          },
        );
    }
  }

  List<DropdownMenuItem<dynamic>> _generateDropdownItems(FieldDefinition field) {
    List<dynamic> items = [];
    if (field.type == FieldType.number && field.isRange) {
      final min = field.minNum ?? 1; final max = field.maxNum ?? 99;
      for (int i = min; i <= max; i++) items.add(i);
    } else if (field.type == FieldType.number) {
      items = field.options.map((e) => int.tryParse(e) ?? 0).toList();
    } else {
      items = field.options;
    }
    return items.map((e) => DropdownMenuItem<dynamic>(value: e, child: Text(e.toString()))).toList();
  }

  void _deleteItem(RosterItem item) {
    final currentTeam = _store.currentTeam;
    if(currentTeam==null) return;
    showDialog(context: context, builder: (ctx)=>AlertDialog(title: const Text('削除確認'), content: const Text('削除しますか？'), actions: [
      TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('キャンセル')),
      TextButton(onPressed: () { _store.deleteItem(currentTeam.id, item); Navigator.pop(ctx); }, child: const Text('削除', style: TextStyle(color: Colors.red))),
    ]));
  }

  String _formatCellValue(FieldDefinition field, dynamic val) {
    if (val == null) return '-';
    switch (field.type) {
      case FieldType.date: if (val is DateTime) return DateFormat('yyyy/MM/dd').format(val); return val.toString();
      case FieldType.personName: case FieldType.personKana: if (val is Map) return '${val['last'] ?? ''} ${val['first'] ?? ''}'; return val.toString();
      case FieldType.address: if (val is Map) return '〒${val['zip1']}-${val['zip2']} ${val['pref']}${val['city']}...'; return val.toString();
      case FieldType.phone: if (val is Map) return '${val['part1']}-${val['part2']}-${val['part3']}'; return val.toString();
      case FieldType.age: return '$val歳';
      case FieldType.uniformNumber: return '#$val'; // ★追加: 表示形式
      default: return val.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, child) {
        final currentTeam = _store.currentTeam;

        if (!_store.isLoaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (currentTeam == null) {
          if (_store.teams.isEmpty) {
            return Scaffold(appBar: AppBar(title: const Text('名簿管理')), body: const Center(child: Text('チームがありません')));
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final visibleColumns = currentTeam.schema.where((f) {
          if (!f.isVisible) return false;
          if (currentTeam.viewHiddenFields.contains(f.id)) return false;
          return true;
        }).toList();

        final columns = visibleColumns.map((field) {
          return DataColumn(label: Text(field.label));
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: DropdownButton<String>(
              value: currentTeam.id,
              dropdownColor: Theme.of(context).colorScheme.surface,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down),
              style: Theme.of(context).textTheme.titleLarge,
              items: _store.teams.map((Team team) {
                return DropdownMenuItem<String>(
                  value: team.id,
                  child: Text(team.name),
                );
              }).toList(),
              onChanged: (String? newTeamId) {
                if (newTeamId != null) _store.selectTeam(newTeamId);
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: '表示項目の設定',
                onPressed: () => _showViewFilterDialog(currentTeam),
              ),
            ],
          ),
          body: currentTeam.items.isEmpty
              ? const Center(child: Text('データがありません\n右下のボタンから追加してください'))
              : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columns: columns,
                  rows: currentTeam.items.map((item) {
                    return DataRow(
                      cells: visibleColumns.map((field) {
                        final val = item.data[field.id];
                        return DataCell(Text(_formatCellValue(field, val)));
                      }).toList(),
                      onSelectChanged: (_) => _showItemDialog(item: item),
                      onLongPress: () => _deleteItem(item),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showItemDialog(),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}