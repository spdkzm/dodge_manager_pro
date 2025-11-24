// lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'models.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings currentSettings;

  const SettingsScreen({super.key, required this.currentSettings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late List<String> _numbers;
  late List<ActionItem> _actions;
  late int _durationMinutes;
  late int _gridColumns;

  int _selectedIndex = 0;

  final TextEditingController _numController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _numbers = List.from(widget.currentSettings.squadNumbers);
    _actions = widget.currentSettings.actions.map((a) => ActionItem(
        name: a.name,
        subActions: List.from(a.subActions),
        isSubRequired: a.isSubRequired
    )).toList();

    _durationMinutes = widget.currentSettings.matchDurationMinutes;
    _gridColumns = widget.currentSettings.gridColumns;

    _timeController.text = _durationMinutes.toString();
    _numbers.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  }

  void _saveAndBack() {
    final int? time = int.tryParse(_timeController.text);
    if (time != null && time > 0) _durationMinutes = time;

    Navigator.of(context).pop(AppSettings(
      squadNumbers: _numbers,
      actions: _actions,
      matchDurationMinutes: _durationMinutes,
      gridColumns: _gridColumns,
      lastOpponent: widget.currentSettings.lastOpponent,
    ));
  }

  // アクション詳細編集ダイアログ
  void _editAction(int index, {bool isNew = false}) {
    final action = isNew ? ActionItem(name: "") : _actions[index];
    final nameCtrl = TextEditingController(text: action.name);
    final subCtrl = TextEditingController();
    bool isRequired = action.isSubRequired;
    List<String> subs = List.from(action.subActions);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void addSub() {
              final val = subCtrl.text.trim();
              if (val.isNotEmpty) {
                setStateDialog(() {
                  subs.add(val);
                  subCtrl.clear();
                });
              }
            }

            return AlertDialog(
              title: Text(isNew ? "アクション追加" : "アクション編集"),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "親カテゴリ名 (例: アタック成功)", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                            value: isRequired,
                            onChanged: (v) => setStateDialog(() => isRequired = v!)
                        ),
                        const Text("子カテゴリの選択を必須にする"),
                      ],
                    ),
                    const Divider(),
                    const Text("子カテゴリ設定 (オプション)", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subCtrl,
                            decoration: const InputDecoration(labelText: "子カテゴリ名", isDense: true, border: OutlineInputBorder()),
                            onSubmitted: (_) => addSub(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: addSub, child: const Text("追加")),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                      child: ListView.builder(
                        itemCount: subs.length,
                        itemBuilder: (context, i) => ListTile(
                          title: Text(subs[i]),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setStateDialog(() => subs.removeAt(i)),
                          ),
                          dense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty) {
                      action.name = nameCtrl.text;
                      action.subActions = subs;
                      action.isSubRequired = isRequired;
                      setState(() {
                        if (isNew) {
                          _actions.add(action);
                        } else {
                          _actions[index] = action;
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("決定"),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('アプリ設定'),
        actions: [
          FilledButton.icon(
            onPressed: _saveAndBack,
            icon: const Icon(Icons.check),
            label: const Text("保存して戻る"),
            style: FilledButton.styleFrom(backgroundColor: Colors.indigoAccent),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: Container(
              color: Colors.grey[100],
              child: ListView(
                children: [
                  _buildMenuItem(0, "背番号管理", Icons.format_list_numbered),
                  _buildMenuItem(1, "アクション設定", Icons.touch_app),
                  _buildMenuItem(2, "試合設定", Icons.timer),
                  _buildMenuItem(3, "表示設定", Icons.grid_view),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.indigo : Colors.grey),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.indigo : Colors.black87)),
      selected: isSelected,
      selectedTileColor: Colors.indigo.withOpacity(0.1),
      onTap: () => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildListEditor(_numController, _numbers, "番号 (例: 10)", true);
      case 1:
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("アクションリスト", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(onPressed: () => _editAction(0, isNew: true), icon: const Icon(Icons.add), label: const Text("新規作成")),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _actions.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = _actions.removeAt(oldIndex);
                    _actions.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final action = _actions[index];
                  return Card(
                    key: ValueKey(action),
                    child: ListTile(
                      title: Text(action.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(action.subActions.isEmpty ? "子カテゴリなし" : "子カテゴリ: ${action.subActions.join(', ')}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editAction(index)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _actions.removeAt(index))),
                          const Icon(Icons.drag_handle, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("試合時間の長さ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: 150,
              child: TextField(
                controller: _timeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: "分", labelText: "分"),
              ),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("アクションボタンの列数", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _gridColumns.toDouble(),
                    min: 2, max: 6, divisions: 4,
                    label: "$_gridColumns 列",
                    onChanged: (val) => setState(() => _gridColumns = val.toInt()),
                  ),
                ),
                Text("$_gridColumns 列", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.all(8),
                // ★修正点：ダミーデータでプレビューを表示するように変更
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridColumns,
                    childAspectRatio: 2.0,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 8, // ダミーで8個表示
                  itemBuilder: (context, index) => ElevatedButton(
                    onPressed: null,
                    child: Text("ボタン${index + 1}"),
                  ),
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildListEditor(TextEditingController ctrl, List<String> list, String hint, bool isNum) {
    void add() {
      final val = ctrl.text.trim();
      if (val.isNotEmpty) {
        if (isNum && list.contains(val)) return;
        setState(() {
          list.add(val);
          if (isNum) list.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
          ctrl.clear();
        });
      }
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: TextField(controller: ctrl, keyboardType: isNum ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: hint, border: const OutlineInputBorder()), onSubmitted: (_) => add())),
            const SizedBox(width: 16),
            ElevatedButton.icon(onPressed: add, icon: const Icon(Icons.add), label: const Text("追加")),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (context, index) => ListTile(
              title: Text(list[index]),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => list.removeAt(index))),
            ),
          ),
        ),
      ],
    );
  }
}