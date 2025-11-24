// lib/match_record_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'game_settings_screen.dart';
import 'persistence.dart';
import 'history_screen.dart';

class MatchRecordScreen extends StatefulWidget {
  const MatchRecordScreen({super.key});

  @override
  State<MatchRecordScreen> createState() => _MatchRecordScreenState();
}

class _MatchRecordScreenState extends State<MatchRecordScreen> with SingleTickerProviderStateMixin {
  AppSettings settings = AppSettings(squadNumbers: [], actions: []);
  List<String> courtPlayers = [];
  List<String> benchPlayers = [];
  List<String> absentPlayers = [];
  List<LogEntry> logs = [];

  String? selectedPlayer;
  Set<String> selectedForMove = {};
  bool isMultiSelectMode = false;

  ActionItem? selectedAction;
  String? selectedSubAction;

  String _opponentName = "";
  DateTime _matchDate = DateTime.now();

  late TabController _tabController;
  Timer? _gameTimer;
  int _remainingSeconds = 300;
  bool _isRunning = false;
  bool _hasMatchStarted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() { setState(() {}); });
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedSettings = await DataManager.loadSettings();
    final currentLogs = await DataManager.loadCurrentLogs();

    setState(() {
      settings = loadedSettings;
      logs = currentLogs;
      _opponentName = settings.lastOpponent;
      benchPlayers = List.from(settings.squadNumbers);
      _remainingSeconds = settings.matchDurationMinutes * 60;
    });
  }

  void _saveCurrentLogs() => DataManager.saveCurrentLogs(logs);

  // --- 編集・削除・復元ロジック ---
  void _deleteLogWithUndo(LogEntry log, int index) {
    setState(() {
      logs.removeAt(index);
    });
    _saveCurrentLogs();

    // Undo機能付きスナックバーを表示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("ログを削除しました"),
        action: SnackBarAction(
          label: "復元",
          onPressed: () {
            setState(() {
              logs.insert(index, log);
            });
            _saveCurrentLogs();
          },
        ),
        duration: const Duration(seconds: 5), // 5秒間表示
      ),
    );
  }

  void _showEditLogDialog(LogEntry log, int index) {
    // 編集用の一時変数
    String editNumber = log.playerNumber;
    String editActionName = log.action;
    String? editSubAction = log.subAction;

    // 現在選択されている親アクションを取得（サブアクションのリスト用）
    ActionItem? currentActionItem;
    try {
      currentActionItem = settings.actions.firstWhere((a) => a.name == editActionName);
    } catch (e) {
      currentActionItem = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(log.type == LogType.system ? "システム記録" : "記録の編集"),
              content: SizedBox(
                width: 400,
                child: log.type == LogType.system
                    ? const Text("「試合開始」などのシステム記録は編集できません。\n削除のみ可能です。")
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 選手選択
                    DropdownButtonFormField<String>(
                      value: settings.squadNumbers.contains(editNumber) ? editNumber : null,
                      decoration: const InputDecoration(labelText: "選手"),
                      items: settings.squadNumbers.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                      onChanged: (val) {
                        if (val != null) setStateDialog(() => editNumber = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    // アクション選択
                    DropdownButtonFormField<String>(
                      value: settings.actions.any((a) => a.name == editActionName) ? editActionName : null,
                      decoration: const InputDecoration(labelText: "親カテゴリ"),
                      items: settings.actions.map((a) => DropdownMenuItem(value: a.name, child: Text(a.name))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() {
                            editActionName = val;
                            // 親が変わったら子はリセット
                            editSubAction = null;
                            currentActionItem = settings.actions.firstWhere((a) => a.name == val);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // 子アクション選択 (親アクションがサブアクションを持っている場合のみ)
                    if (currentActionItem != null && currentActionItem!.subActions.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: (editSubAction != null && currentActionItem!.subActions.contains(editSubAction)) ? editSubAction : null,
                        decoration: const InputDecoration(labelText: "子カテゴリ"),
                        items: currentActionItem!.subActions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setStateDialog(() => editSubAction = val),
                      ),
                  ],
                ),
              ),
              actions: [
                // 削除ボタン（ここでしか削除できない）
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // ダイアログを閉じる
                    _deleteLogWithUndo(log, index); // 削除＆復元バー表示
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text("削除", style: TextStyle(color: Colors.red)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("キャンセル"),
                ),
                if (log.type == LogType.action)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        log.playerNumber = editNumber;
                        log.action = editActionName;
                        log.subAction = editSubAction;
                      });
                      _saveCurrentLogs();
                      Navigator.pop(context);
                    },
                    child: const Text("保存"),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 試合情報、移動、タイマーなどの既存ロジック ---
  void _editMatchInfo() {
    final oppCtrl = TextEditingController(text: _opponentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("試合情報の記録"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: oppCtrl, decoration: const InputDecoration(labelText: "対戦相手名")),
              const SizedBox(height: 16),
              InputDatePickerFormField(
                initialDate: _matchDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                onDateSaved: (date) => setState(() => _matchDate = date),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _opponentName = oppCtrl.text;
                  settings.lastOpponent = _opponentName;
                });
                DataManager.saveSettings(settings);
                Navigator.pop(context);
              },
              child: const Text("設定"),
            )
          ],
        );
      },
    );
  }

  void _moveSelectedPlayers(String toType) {
    if (selectedForMove.isEmpty) return;
    setState(() {
      courtPlayers.removeWhere((p) => selectedForMove.contains(p));
      benchPlayers.removeWhere((p) => selectedForMove.contains(p));
      absentPlayers.removeWhere((p) => selectedForMove.contains(p));
      if (toType == 'court') courtPlayers.addAll(selectedForMove);
      if (toType == 'bench') benchPlayers.addAll(selectedForMove);
      if (toType == 'absent') absentPlayers.addAll(selectedForMove);
      _sortList(courtPlayers); _sortList(benchPlayers); _sortList(absentPlayers);
      selectedForMove.clear();
      isMultiSelectMode = false;
      selectedPlayer = null;
    });
  }

  void _toggleMultiSelect(String number) {
    setState(() {
      if (selectedForMove.contains(number)) {
        selectedForMove.remove(number);
        if (selectedForMove.isEmpty) isMultiSelectMode = false;
      } else {
        selectedForMove.add(number);
        isMultiSelectMode = true;
        selectedPlayer = null;
      }
    });
  }

  void _recordSystemLog(String action) {
    setState(() {
      logs.insert(0, LogEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        matchDate: DateFormat('yyyy-MM-dd').format(_matchDate),
        opponent: _opponentName,
        gameTime: _getFormattedTime(),
        playerNumber: '',
        action: action,
        type: LogType.system,
      ));
    });
    _saveCurrentLogs();
  }

  void _startTimer() {
    if (!_hasMatchStarted) {
      _hasMatchStarted = true;
      _recordSystemLog("試合開始");
    } else if (!_isRunning) {
      _recordSystemLog("試合再開");
    }
    setState(() => _isRunning = true);
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) setState(() => _remainingSeconds--);
      else _stopTimer();
    });
  }

  void _stopTimer() {
    _gameTimer?.cancel();
    setState(() => _isRunning = false);
    if (_hasMatchStarted) _recordSystemLog("タイム");
  }

  void _endMatchSequence() {
    _gameTimer?.cancel();
    setState(() => _isRunning = false);
    _recordSystemLog("試合終了");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildSaveDialog(),
    );
  }

  Widget _buildSaveDialog() {
    return AlertDialog(
      title: const Text("試合記録の確認・保存"),
      content: SizedBox(
        width: 800,
        height: 500,
        child: Column(
          children: [
            const Text("内容を確認し、必要であれば編集してください。"),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                  columns: const [
                    DataColumn(label: Text("操作")), // 削除ボタンを操作に変更
                    DataColumn(label: Text("背番号")),
                    DataColumn(label: Text("時間")),
                    DataColumn(label: Text("親カテゴリ")),
                    DataColumn(label: Text("子カテゴリ")),
                    DataColumn(label: Text("タイプ")),
                  ],
                  rows: logs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final log = entry.value;
                    final isSystem = log.type == LogType.system;
                    return DataRow(
                      cells: [
                        DataCell(
                          // ここでの編集・削除は、ダイアログを一度閉じてからメイン画面で行うように誘導するか、
                          // 簡易的に削除のみ許可する。今回は「タップで編集」がメイン画面の機能なので
                          // ここでは削除のみ提供する
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () {
                              setState(() => logs.removeAt(index));
                            },
                          ),
                        ),
                        DataCell(Text(log.playerNumber)),
                        DataCell(Text(log.gameTime)),
                        DataCell(isSystem ? Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold)) : Text(log.action)),
                        DataCell(Text(log.subAction ?? "")),
                        DataCell(Text(isSystem ? "進行" : "プレー")),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("保存せずに閉じますか？"),
                content: const Text("現在の記録は破棄されませんが、履歴には保存されません。"),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("いいえ")),
                  TextButton(onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  }, child: const Text("はい (編集に戻る)")),
                ],
              ),
            );
          },
          child: const Text("キャンセル"),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          icon: const Icon(Icons.save),
          label: const Text("保存して終了"),
          onPressed: () async {
            final record = MatchRecord(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              date: DateFormat('yyyy-MM-dd').format(_matchDate),
              opponent: _opponentName,
              logs: List.from(logs.reversed),
            );
            await DataManager.saveMatchToHistory(record);
            await DataManager.clearCurrentLogs();
            if (context.mounted) {
              Navigator.pop(context);
              _resetMatch();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("記録を保存しました")));
            }
          },
        ),
      ],
    );
  }

  void _resetMatch() {
    setState(() {
      logs.clear();
      _hasMatchStarted = false;
      _isRunning = false;
      _remainingSeconds = settings.matchDurationMinutes * 60;
      benchPlayers = List.from(settings.squadNumbers);
      courtPlayers.clear();
      absentPlayers.clear();
      selectedForMove.clear();
      selectedPlayer = null;
    });
  }

  String _getFormattedTime() {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _confirmLog() {
    if (selectedPlayer == null || selectedAction == null) return;
    if (selectedAction!.isSubRequired && selectedAction!.subActions.isNotEmpty && selectedSubAction == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("詳細項目の選択が必須です"), backgroundColor: Colors.red));
      return;
    }
    setState(() {
      logs.insert(0, LogEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        matchDate: DateFormat('yyyy-MM-dd').format(_matchDate),
        opponent: _opponentName,
        gameTime: _getFormattedTime(),
        playerNumber: selectedPlayer!,
        action: selectedAction!.name,
        subAction: selectedSubAction,
        type: LogType.action,
      ));
      selectedAction = null;
      selectedSubAction = null;
    });
    _saveCurrentLogs();
  }

  void _movePlayer(String number, String fromType, String toType) {
    setState(() {
      if (fromType == 'court') courtPlayers.remove(number);
      if (fromType == 'bench') benchPlayers.remove(number);
      if (fromType == 'absent') absentPlayers.remove(number);
      if (toType == 'court') courtPlayers.add(number);
      if (toType == 'bench') benchPlayers.add(number);
      if (toType == 'absent') absentPlayers.add(number);
      _sortList(courtPlayers); _sortList(benchPlayers); _sortList(absentPlayers);
      if (selectedPlayer == number) selectedPlayer = null;
    });
  }

  void _sortList(List<String> list) => list.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => SettingsScreen(currentSettings: settings)));
    if (result != null && result is AppSettings) {
      await DataManager.saveSettings(result);
      setState(() { settings = result; _loadData(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (settings.squadNumbers.isEmpty && settings.actions.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('DodgeLog'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 28),
            tooltip: "記録一覧",
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HistoryScreen())),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: _editMatchInfo,
            icon: const Icon(Icons.sports_handball),
            label: Text(_opponentName.isEmpty ? "相手設定" : "VS $_opponentName"),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_getFormattedTime(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _remainingSeconds <= 30 ? Colors.red : Colors.black87)),
          ),
          IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings),
        ],
      ),
      body: Row(
        children: [
          // 左：選手
          Expanded(
            flex: 2,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.indigo,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'コート (${courtPlayers.length})'),
                    Tab(text: 'ベンチ (${benchPlayers.length})'),
                    Tab(text: '欠席 (${absentPlayers.length})'),
                  ],
                ),
                if (isMultiSelectMode)
                  Container(
                    color: Colors.orange.shade100,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Text("${selectedForMove.length}人選択中", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        const Text("移動先:"),
                        IconButton(icon: const Icon(Icons.sports_basketball), tooltip: "コートへ", onPressed: () => _moveSelectedPlayers('court')),
                        IconButton(icon: const Icon(Icons.chair), tooltip: "ベンチへ", onPressed: () => _moveSelectedPlayers('bench')),
                        IconButton(icon: const Icon(Icons.cancel), tooltip: "欠席へ", onPressed: () => _moveSelectedPlayers('absent')),
                        IconButton(icon: const Icon(Icons.close), tooltip: "選択解除", onPressed: () => setState(() { selectedForMove.clear(); isMultiSelectMode = false; })),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPlayerList(courtPlayers),
                      _buildPlayerList(benchPlayers),
                      _buildPlayerList(absentPlayers),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // 中：プレー
          Expanded(
            flex: 6,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blueGrey[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimerButton("試合開始", Colors.green, _startTimer, !_hasMatchStarted),
                      const SizedBox(width: 8),
                      _buildTimerButton("タイム", Colors.orange, _stopTimer, _isRunning),
                      const SizedBox(width: 8),
                      _buildTimerButton("試合再開", Colors.blue, _startTimer, _hasMatchStarted && !_isRunning),
                      const SizedBox(width: 8),
                      _buildTimerButton("試合終了", Colors.red, _endMatchSequence, _hasMatchStarted),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(border: Border.all(color: Colors.indigo.shade200), borderRadius: BorderRadius.circular(12), color: Colors.indigo.shade50),
                          child: Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text("選手:", style: TextStyle(color: Colors.grey)),
                                    Text(selectedPlayer ?? "-", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.arrow_right, color: Colors.grey),
                                    const SizedBox(width: 16),
                                    const Text("プレー:", style: TextStyle(color: Colors.grey)),
                                    Text(selectedAction?.name ?? "-", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    if (selectedSubAction != null) ...[
                                      const SizedBox(width: 8),
                                      Chip(label: Text(selectedSubAction!), backgroundColor: Colors.white, padding: EdgeInsets.zero),
                                    ]
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: (_hasMatchStarted && selectedPlayer != null && selectedAction != null) ? _confirmLog : null,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                                icon: const Icon(Icons.check_circle),
                                label: const Text("確定", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: IgnorePointer(
                            ignoring: !_hasMatchStarted,
                            child: Opacity(
                              opacity: _hasMatchStarted ? 1.0 : 0.5,
                              child: GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: settings.gridColumns, childAspectRatio: 2.5, crossAxisSpacing: 8, mainAxisSpacing: 8),
                                itemCount: settings.actions.length,
                                itemBuilder: (context, index) {
                                  final action = settings.actions[index];
                                  final isSelected = selectedAction == action;
                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSelected ? Colors.orange[100] : Colors.white,
                                      foregroundColor: Colors.black87,
                                      side: isSelected ? const BorderSide(color: Colors.orange, width: 3) : BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        selectedAction = action;
                                        selectedSubAction = null;
                                      });
                                    },
                                    child: Text(action.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        if (selectedAction != null && selectedAction!.subActions.isNotEmpty) ...[
                          const Divider(),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text("詳細 (${selectedAction!.isSubRequired ? '必須' : '任意'}):", style: TextStyle(color: selectedAction!.isSubRequired ? Colors.red : Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            flex: 1,
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 2.0, crossAxisSpacing: 8, mainAxisSpacing: 8),
                              itemCount: selectedAction!.subActions.length,
                              itemBuilder: (context, index) {
                                final sub = selectedAction!.subActions[index];
                                final isSelected = selectedSubAction == sub;
                                return OutlinedButton(
                                  style: OutlinedButton.styleFrom(backgroundColor: isSelected ? Colors.indigoAccent : Colors.white, foregroundColor: isSelected ? Colors.white : Colors.black87),
                                  onPressed: () => setState(() => selectedSubAction = sub),
                                  child: Text(sub),
                                );
                              },
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // 右：ログ
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[200],
                  child: const Text("ログ (タップして編集)", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final isSystem = log.type == LogType.system;
                      return Card(
                        color: isSystem ? Colors.grey[300] : Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: Text(log.gameTime, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace')),
                          title: isSystem
                              ? Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
                              : RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black87, fontFamily: 'NotoSansJP'),
                              children: [
                                TextSpan(text: "#${log.playerNumber} ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                                TextSpan(text: log.action),
                                if (log.subAction != null)
                                  TextSpan(text: " (${log.subAction})", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          // ★修正：ゴミ箱アイコンを削除し、タップで編集ダイアログを開く
                          onTap: () => _showEditLogDialog(log, index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(List<String> players) {
    if (players.isEmpty) return const Center(child: Text("なし", style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final number = players[index];
        final isSelected = selectedPlayer == number;
        final isMultiSelected = selectedForMove.contains(number);

        return Card(
          color: isMultiSelected ? Colors.orange[200] : (isSelected ? Colors.yellow[100] : Colors.white),
          child: ListTile(
            title: Text(number, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            onTap: () {
              if (isMultiSelectMode) {
                _toggleMultiSelect(number);
              } else {
                setState(() => selectedPlayer = number);
              }
            },
            onLongPress: () {
              _toggleMultiSelect(number);
            },
          ),
        );
      },
    );
  }

  Widget _buildTimerButton(String label, Color color, VoidCallback onPressed, bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(60, 36)),
      child: Text(label),
    );
  }
}