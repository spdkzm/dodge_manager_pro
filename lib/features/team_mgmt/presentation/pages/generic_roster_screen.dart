// lib/features/team_mgmt/presentation/pages/generic_roster_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../application/team_store.dart';
import '../../domain/schema.dart';
import '../../domain/roster_item.dart';
import '../../domain/team.dart';
import '../../domain/roster_category.dart';
import '../../data/uniform_number_dao.dart'; // ★追加

import 'team_management_screen.dart';
import 'schema_settings_screen.dart';

class GenericRosterScreen extends ConsumerStatefulWidget {
  final RosterCategory category;
  final bool showAppBar;

  const GenericRosterScreen({
    super.key,
    required this.category,
    this.showAppBar = true,
  });

  @override
  ConsumerState<GenericRosterScreen> createState() => _GenericRosterScreenState();
}

class _GenericRosterScreenState extends ConsumerState<GenericRosterScreen> {
  final UniformNumberDao _uniformDao = UniformNumberDao(); // ★追加
  final List<String> _prefectures = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県',
    '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県',
    '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県',
    '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
  ];

  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  // ★追加: 選手の現在の背番号を保持するマップ (PlayerID -> 背番号文字列)
  Map<String, String> _currentUniformMap = {};

  @override
  void initState() {
    super.initState();
    _fetchUniforms();
  }

  @override
  void didUpdateWidget(covariant GenericRosterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fetchUniforms();
  }

  // ★追加: 背番号情報をDBから取得
  Future<void> _fetchUniforms() async {
    if (widget.category != RosterCategory.player) return;

    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    if (currentTeam == null) return;

    final now = DateTime.now();
    final allUniforms = await _uniformDao.getUniformNumbersByTeam(currentTeam.id);
    final Map<String, String> newMap = {};

    for (var item in currentTeam.items) {
      // 現在有効な背番号を探す
      try {
        final active = allUniforms.firstWhere((u) =>
        u.playerId == item.id && u.isActiveAt(now)
        );
        newMap[item.id] = active.number;
      } catch (_) {
        // なければマップに入れない（未設定）
      }
    }

    if (mounted) {
      setState(() {
        _currentUniformMap = newMap;
      });
    }
  }

  void _showViewFilterDialog(Team team) {
    // ★修正: FieldType.uniformNumber は除外（既に削除されているはずだが念のため）
    final activeFields = team.getSchema(widget.category)
        .where((f) => f.isVisible && f.type != FieldType.uniformNumber).toList();

    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(title: const Text('一覧の表示項目'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: activeFields.map((field) {
          final isVisibleInView = !team.viewHiddenFields.contains(field.id);
          return CheckboxListTile(title: Text(field.label), value: isVisibleInView, onChanged: (val) {
            ref.read(teamStoreProvider).toggleViewColumn(team.id, field.id);
            setStateDialog(() {});
          });
        }).toList())), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))]);
      });
    });
  }

  Future<void> _showItemDialog({RosterItem? item}) async {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    if (currentTeam == null) return;

    // ★修正: uniformNumberを除外
    final schema = currentTeam.getSchema(widget.category);
    final inputFields = schema.where((f) => f.isVisible && f.type != FieldType.uniformNumber).toList();

    final isEditing = item != null;
    final String targetId = item?.id ?? const Uuid().v4();

    final Map<String, dynamic> tempData = {};
    if (item != null) {
      item.data.forEach((key, value) {
        if (value is Map) { tempData[key] = Map<String, dynamic>.from(value); }
        else { tempData[key] = value; }
      });
    }

    bool isChanged = false;
    void markChanged() { isChanged = true; }

    void tryCalculateAge() {
      if (widget.category != RosterCategory.player) return;
      final dateField = schema.firstWhere((f) => f.type == FieldType.date, orElse: () => FieldDefinition(label: '', type: FieldType.text));
      final ageField = schema.firstWhere((f) => f.type == FieldType.age, orElse: () => FieldDefinition(label: '', type: FieldType.text));
      if (dateField.type == FieldType.date && ageField.type == FieldType.age) {
        final birthDate = tempData[dateField.id];
        if (birthDate is DateTime) {
          final now = DateTime.now();
          int age = now.year - birthDate.year;
          if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) age--;
          tempData[ageField.id] = age;
        }
      }
    }

    final nameField = schema.firstWhere((f) => f.label.contains("名") || f.type == FieldType.text, orElse: () => schema.first);
    final String originalName = item?.data[nameField.id]?.toString() ?? "";

    await showDialog(context: context, barrierDismissible: false, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        Future<void> saveProcess() async {
          // 必須チェック（除外した背番号はチェックされない）
          for(var f in inputFields) { // inputFieldsを使う
            if (f.isRequired) {
              final val = tempData[f.id];
              if (val == null || val.toString().trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${f.label}は必須です')));
                return;
              }
            }
          }

          // 重複チェック
          for (var field in inputFields) {
            if (field.isUnique) {
              final newValue = tempData[field.id];
              if (newValue == null || newValue.toString().isEmpty) continue;
              final conflictItem = currentTeam.getItems(widget.category).cast<RosterItem?>().firstWhere((i) => i!.id != targetId && i.data[field.id].toString() == newValue.toString(), orElse: () => null);
              if (conflictItem != null) {
                final doSwap = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('値が重複しています'), content: Text('項目「${field.label}」の値「$newValue」は既に使用されています。\n入れ替えますか？'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('入れ替える'))]));
                if (doSwap == true) {
                  conflictItem.data[field.id] = null;
                  store.saveItem(currentTeam.id, conflictItem, category: widget.category);
                } else { return; }
              }
            }
          }

          if (widget.category != RosterCategory.player && isEditing && originalName.isNotEmpty) {
            final newName = tempData[nameField.id]?.toString() ?? "";
            if (newName != originalName) {
              final usageCount = await store.checkMatchInfoUsage(widget.category, originalName);
              if (usageCount > 0 && context.mounted) {
                final shouldUpdate = await showDialog<bool>(
                  context: context,
                  builder: (alertCtx) => AlertDialog(
                    title: const Text("名前の変更"),
                    content: Text("「$originalName」は過去 $usageCount 件の試合記録で使用されています。\n過去の記録もすべて「$newName」に変更しますか？"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(alertCtx, false), child: const Text("変更しない")),
                      ElevatedButton(onPressed: () => Navigator.pop(alertCtx, true), child: const Text("変更する")),
                    ],
                  ),
                );
                if (shouldUpdate == true) {
                  await store.updateMatchInfoName(widget.category, originalName, newName);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("過去の記録も更新しました")));
                }
              }
            }
          }

          if (isEditing) {
            item.data = tempData;
            store.saveItem(currentTeam.id, item, category: widget.category);
          } else {
            final newItem = RosterItem(id: targetId, data: tempData);
            store.addItem(currentTeam.id, newItem, category: widget.category);
          }
          if (context.mounted) Navigator.pop(context);

          // 保存後に一覧更新（背番号が変わっている可能性があるため）
          _fetchUniforms();
        }

        Future<void> handleClose() async {
          if (!isChanged && !isEditing) { Navigator.pop(context); return; }
          final shouldSave = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('未保存の変更'), content: const Text('保存せずに閉じますか？'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('破棄')), TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('キャンセル')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存して閉じる'))]));
          if (shouldSave == true) await saveProcess(); else if (shouldSave == false && context.mounted) Navigator.pop(context);
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
                            children: [
                              TextFormField(
                                initialValue: targetId,
                                decoration: const InputDecoration(
                                  labelText: 'システムID (自動付与)',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.black12,
                                  prefixIcon: Icon(Icons.fingerprint),
                                ),
                                readOnly: true,
                                enabled: false,
                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                              const SizedBox(height: 24),
                              ...inputFields.map((field) => Padding(padding: const EdgeInsets.only(bottom: 24.0), child: _buildComplexInput(field, tempData, markChanged, (fn) => setStateDialog(fn), tryCalculateAge))).toList()
                            ]
                        )
                    )
                ),
                actions: [
                  TextButton(onPressed: handleClose, child: const Text('キャンセル')),
                  ElevatedButton(onPressed: saveProcess, child: const Text('保存'))
                ]
            )
        );
      });
    });
  }

  Widget _buildComplexInput(FieldDefinition field, Map<String, dynamic> data, VoidCallback onChange, Function(VoidCallback) setStateDialog, VoidCallback calcAge) {
    Map<String, dynamic> getMap() { if (data[field.id] is! Map) data[field.id] = <String, dynamic>{}; return data[field.id] as Map<String, dynamic>; }
    if (field.useDropdown) {
      final dropdownItems = _generateDropdownItems(field);
      dynamic currentValue = data[field.id];
      if (!dropdownItems.any((item) => item.value.toString() == currentValue.toString())) currentValue = null;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${field.label}${field.isRequired ? ' *' : ''}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: field.isRequired ? Colors.red : null)), const SizedBox(height: 4), DropdownButtonFormField<dynamic>(initialValue: currentValue, decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)), items: dropdownItems, onChanged: (val) { setStateDialog(() { data[field.id] = val; onChange(); }); })]);
    }
    switch (field.type) {
      case FieldType.personName: case FieldType.personKana: final map = getMap(); final l1 = field.type == FieldType.personName ? '氏' : 'セイ'; final l2 = field.type == FieldType.personName ? '名' : 'メイ'; return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${field.label}${field.isRequired ? ' *' : ''}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: field.isRequired ? Colors.red : null)), const SizedBox(height: 4), Row(children: [Expanded(child: TextFormField(initialValue: map['last'], decoration: InputDecoration(labelText: l1), onChanged: (v) { map['last'] = v; onChange(); })), const SizedBox(width: 16), Expanded(child: TextFormField(initialValue: map['first'], decoration: InputDecoration(labelText: l2), onChanged: (v) { map['first'] = v; onChange(); }))])]);
      case FieldType.date: final currentDate = data[field.id] as DateTime?; return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${field.label}${field.isRequired ? ' *' : ''}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: field.isRequired ? Colors.red : null)), const SizedBox(height: 4), InkWell(onTap: () async { final picked = await showDatePicker(context: context, initialDate: currentDate ?? DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now(), locale: const Locale('ja')); if (picked != null) { setStateDialog(() { data[field.id] = picked; onChange(); calcAge(); }); } }, child: InputDecorator(decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today)), child: Text(currentDate != null ? DateFormat('yyyy/MM/dd').format(currentDate) : '選択')) )]);
      case FieldType.age: return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${field.label}${field.isRequired ? ' *' : ''}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: field.isRequired ? Colors.red : null)), const SizedBox(height: 4), TextFormField(controller: TextEditingController(text: data[field.id]?.toString() ?? ''), decoration: const InputDecoration(suffixText: '歳'), keyboardType: TextInputType.number, onChanged: (v) { data[field.id] = int.tryParse(v); onChange(); })]);
      case FieldType.address: final map = getMap(); return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${field.label}${field.isRequired ? ' *' : ''}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: field.isRequired ? Colors.red : null)), const SizedBox(height: 8), Row(children: [const Icon(Icons.markunread_mailbox_outlined, color: Colors.grey), const SizedBox(width: 8), SizedBox(width: 80, child: TextFormField(initialValue: map['zip1'], decoration: const InputDecoration(hintText: '000', counterText: ''), keyboardType: TextInputType.number, maxLength: 3, onChanged: (v) { map['zip1'] = v; onChange(); })), const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')), SizedBox(width: 100, child: TextFormField(initialValue: map['zip2'], decoration: const InputDecoration(hintText: '0000', counterText: ''), keyboardType: TextInputType.number, maxLength: 4, onChanged: (v) { map['zip2'] = v; onChange(); }))]), const SizedBox(height: 8), DropdownButtonFormField<String>(initialValue: _prefectures.contains(map['pref']) ? map['pref'] : null, decoration: const InputDecoration(labelText: '都道府県'), items: _prefectures.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (v) { map['pref'] = v; onChange(); }), const SizedBox(height: 8), TextFormField(initialValue: map['city'], decoration: const InputDecoration(labelText: '市区町村・番地'), onChanged: (v) { map['city'] = v; onChange(); }), const SizedBox(height: 8), TextFormField(initialValue: map['building'], decoration: const InputDecoration(labelText: '建物名'), onChanged: (v) { map['building'] = v; onChange(); })]);
      case FieldType.phone: final map = getMap(); return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${field.label}${field.isRequired ? ' *' : ''}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: field.isRequired ? Colors.red : null)), const SizedBox(height: 4), Row(children: [const Icon(Icons.phone, color: Colors.grey), const SizedBox(width: 16), Expanded(child: TextFormField(initialValue: map['part1'], keyboardType: TextInputType.phone, textAlign: TextAlign.center, onChanged: (v) { map['part1'] = v; onChange(); })), const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')), Expanded(child: TextFormField(initialValue: map['part2'], keyboardType: TextInputType.phone, textAlign: TextAlign.center, onChanged: (v) { map['part2'] = v; onChange(); })), const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')), Expanded(child: TextFormField(initialValue: map['part3'], keyboardType: TextInputType.phone, textAlign: TextAlign.center, onChanged: (v) { map['part3'] = v; onChange(); }))])]);
      case FieldType.uniformNumber: return const SizedBox.shrink(); // 入力画面には表示しない
      case FieldType.courtName: return TextFormField(initialValue: data[field.id]?.toString(), decoration: InputDecoration(labelText: "${field.label}${field.isRequired ? ' *' : ''}", suffixIcon: const Icon(Icons.sports_handball)), onChanged: (val) { data[field.id] = val; onChange(); });
      case FieldType.number: return TextFormField(initialValue: data[field.id]?.toString(), decoration: InputDecoration(labelText: "${field.label}${field.isRequired ? ' *' : ''}", suffixIcon: const Icon(Icons.numbers)), keyboardType: TextInputType.number, onChanged: (val) { data[field.id] = num.tryParse(val); onChange(); });
      default: return TextFormField(initialValue: data[field.id] as String?, decoration: InputDecoration(labelText: "${field.label}${field.isRequired ? ' *' : ''}"), onChanged: (val) { data[field.id] = val; onChange(); });
    }
  }

  List<DropdownMenuItem<dynamic>> _generateDropdownItems(FieldDefinition field) { List<dynamic> items = []; if (field.type == FieldType.number && field.isRange) { for (int i = (field.minNum ?? 1); i <= (field.maxNum ?? 99); i++) items.add(i); } else if (field.type == FieldType.number) { items = field.options.map((e) => int.tryParse(e) ?? 0).toList(); } else { items = field.options; } return items.map((e) => DropdownMenuItem<dynamic>(value: e, child: Text(e.toString()))).toList(); }
  String _formatCellValue(FieldDefinition field, dynamic val) { if (val == null) return '-'; switch (field.type) { case FieldType.date: if (val is DateTime) return DateFormat('yyyy/MM/dd').format(val); return val.toString(); case FieldType.personName: case FieldType.personKana: if (val is Map) return '${val['last'] ?? ''} ${val['first'] ?? ''}'; return val.toString(); case FieldType.address: if (val is Map) return '〒${val['zip1']}-${val['zip2']} ${val['pref']}${val['city']}...'; return val.toString(); case FieldType.phone: if (val is Map) return '${val['part1']}-${val['part2']}-${val['part3']}'; return val.toString(); case FieldType.age: return '$val歳'; case FieldType.uniformNumber: return '#$val'; default: return val.toString(); } }

  Future<void> _deleteItem(RosterItem item) async {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    if(currentTeam==null) return;

    if (widget.category != RosterCategory.player) {
      final schema = currentTeam.getSchema(widget.category);
      final nameField = schema.firstWhere((f) => f.label.contains("名") || f.type == FieldType.text, orElse: () => schema.first);
      final name = item.data[nameField.id]?.toString() ?? "";
      if (name.isNotEmpty) {
        final count = await store.checkMatchInfoUsage(widget.category, name);
        if (count > 0 && mounted) {
          final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('削除確認'),
                content: Text("項目「$name」は過去 $count 件の記録で使用されています。\n削除すると、リストとの紐付けは解除されますが、過去の記録上の名前は残ります。\n\n削除してもよろしいですか？", style: const TextStyle(color: Colors.red)),
                actions: [TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text('キャンセル')), TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: Colors.red)))],
              )
          );
          if (confirm != true) return;
        }
      }
    }

    if (mounted) {
      final confirm = await showDialog<bool>(context: context, builder: (ctx)=>AlertDialog(title: const Text('削除確認'), content: const Text('削除しますか？'), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('キャンセル')), TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: Colors.red)))]));
      if (confirm == true) {
        store.deleteItem(currentTeam.id, item, category: widget.category);
      }
    }
  }

  void _sortItems(List<RosterItem> items, FieldDefinition? field, bool ascending) {
    items.sort((a, b) {
      // ★追加: 背番号ソート(fieldがnullの場合は背番号ソートとみなす)
      if (field == null) {
        final numAStr = _currentUniformMap[a.id] ?? '';
        final numBStr = _currentUniformMap[b.id] ?? '';
        final numA = int.tryParse(numAStr) ?? 9999;
        final numB = int.tryParse(numBStr) ?? 9999;
        return ascending ? numA.compareTo(numB) : numB.compareTo(numA);
      }

      dynamic valA = a.data[field.id];
      dynamic valB = b.data[field.id];
      if (valA == null && valB == null) return 0;
      if (valA == null) return 1;
      if (valB == null) return -1;
      int cmp = 0;
      if (field.type == FieldType.uniformNumber || field.type == FieldType.number || field.type == FieldType.age) {
        final numA = num.tryParse(valA.toString()) ?? 9999;
        final numB = num.tryParse(valB.toString()) ?? 9999;
        cmp = numA.compareTo(numB);
      } else {
        cmp = valA.toString().compareTo(valB.toString());
      }
      return ascending ? cmp : -cmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(teamStoreProvider);
    final currentTeam = store.currentTeam;

    if (!store.isLoaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (currentTeam == null) {
      if (store.teams.isEmpty) return Scaffold(appBar: widget.showAppBar ? AppBar(title: const Text('名簿管理')) : null, body: const Center(child: Text('チームがありません')));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final schema = currentTeam.getSchema(widget.category);
    final items = currentTeam.getItems(widget.category);

    // ★修正: uniformNumberを除外してカラム定義を作成
    final visibleColumns = schema
        .where((f) => f.isVisible && !currentTeam.viewHiddenFields.contains(f.id) && f.type != FieldType.uniformNumber)
        .toList();

    final sortedItems = List<RosterItem>.from(items);

    // ソート処理
    // 0番目を「背番号」列とする (選手リストの場合)
    final isPlayerCategory = widget.category == RosterCategory.player;

    if (isPlayerCategory && _sortColumnIndex == 0) {
      _sortItems(sortedItems, null, _sortAscending);
    } else {
      // 背番号列がある分、インデックスをずらす
      final fieldIndex = isPlayerCategory ? _sortColumnIndex - 1 : _sortColumnIndex;
      if (fieldIndex >= 0 && fieldIndex < visibleColumns.length) {
        _sortItems(sortedItems, visibleColumns[fieldIndex], _sortAscending);
      }
    }

    final List<DataColumn> columns = [];
    if (isPlayerCategory) {
      columns.add(DataColumn(
          label: const Text('背番号'),
          numeric: true,
          onSort: (colIdx, asc) => setState(() { _sortColumnIndex = colIdx; _sortAscending = asc; })
      ));
    }

    columns.addAll(visibleColumns.map((field) => DataColumn(
        label: Text(field.label),
        onSort: (colIdx, asc) => setState(() { _sortColumnIndex = colIdx; _sortAscending = asc; })
    )));

    final body = items.isEmpty
        ? const Center(child: Text('データがありません\n右下のボタンから追加してください'))
        : SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          child: DataTable(
            showCheckboxColumn: false,
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            columns: columns,
            rows: sortedItems.map((item) {
              final List<DataCell> cells = [];

              // ★追加: 背番号セル
              if (isPlayerCategory) {
                final numStr = _currentUniformMap[item.id];
                cells.add(DataCell(
                    Text(numStr != null ? '#$numStr' : '-', style: const TextStyle(fontWeight: FontWeight.bold))
                ));
              }

              cells.addAll(visibleColumns.map((f) => DataCell(Text(_formatCellValue(f, item.data[f.id])))));

              return DataRow(
                cells: cells,
                onSelectChanged: (_) => _showItemDialog(item: item),
                onLongPress: () => _deleteItem(item),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (!widget.showAppBar) {
      return Scaffold(
        body: body,
        floatingActionButton: FloatingActionButton(onPressed: () => _showItemDialog(), child: const Icon(Icons.add)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTeam.name),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), tooltip: '表示項目', onPressed: () => _showViewFilterDialog(currentTeam)),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'team_mgmt') Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamManagementScreen()));
              if (val == 'schema') Navigator.push(context, MaterialPageRoute(builder: (_) => SchemaSettingsScreen(targetCategory: widget.category)));
            },
            itemBuilder: (context) => [
              if (widget.category == RosterCategory.player) ...[
                const PopupMenuItem(value: 'team_mgmt', child: Row(children: [Icon(Icons.group_work, color: Colors.grey), SizedBox(width: 8), Text('チーム管理')])),
              ],
              const PopupMenuItem(value: 'schema', child: Row(children: [Icon(Icons.build, color: Colors.grey), SizedBox(width: 8), Text('項目の設計')])),
            ],
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton(onPressed: () => _showItemDialog(), child: const Icon(Icons.add)),
    );
  }
}