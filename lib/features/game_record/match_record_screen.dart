// lib/features/game_record/match_record_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/team_mgmt/team_store.dart';
import '../../features/team_mgmt/schema.dart';
import '../../features/team_mgmt/roster_item.dart';
import '../../features/team_mgmt/database_helper.dart';

import 'models.dart';
import 'persistence.dart';
import 'history_screen.dart';

// 内部管理用の拡張ActionItem
class UIActionItem {
  String name; // 表示名 (例: アタック成功)
  String parentName; // 親名 (例: アタック)
  ActionResult fixedResult; // このボタンが押されたときの結果
  List<String> subActions; // このボタン用のサブアクション
  bool isSubRequired;

  UIActionItem({
    required this.name,
    required this.parentName,
    required this.fixedResult,
    required this.subActions,
    required this.isSubRequired,
  });
}

class MatchRecordScreen extends StatefulWidget {
  const MatchRecordScreen({super.key});
  @override
  State<MatchRecordScreen> createState() => _MatchRecordScreenState();
}

class _MatchRecordScreenState extends State<MatchRecordScreen> with SingleTickerProviderStateMixin {
  final TeamStore _teamStore = TeamStore();
  AppSettings settings = AppSettings(squadNumbers: [], actions: []);

  // ★UI表示用に展開されたアクションリスト
  List<UIActionItem> _uiActions = [];

  List<String> courtPlayers = [];
  List<String> benchPlayers = [];
  List<String> absentPlayers = [];
  Map<String, String> _playerNames = {};

  List<LogEntry> logs = [];
  String? selectedPlayer;
  Set<String> selectedForMove = {};
  bool isMultiSelectMode = false;

  UIActionItem? selectedUIAction;
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
    if (!_teamStore.isLoaded) await _teamStore.loadFromDb();

    final currentTeam = _teamStore.currentTeam;
    List<String> rosterNumbers = [];
    Map<String, String> nameMap = {};
    List<UIActionItem> generatedUIActions = [];

    if (currentTeam != null) {
      // 選手ロード (省略なし)
      String? numberFieldId;
      String? nameFieldId;
      String? courtNameFieldId;
      for (var field in currentTeam.schema) {
        if (field.type == FieldType.uniformNumber) numberFieldId = field.id;
        else if (field.type == FieldType.personName) nameFieldId = field.id;
        else if (field.type == FieldType.courtName) courtNameFieldId = field.id;
      }
      if (numberFieldId != null) {
        for (var item in currentTeam.items) {
          final numVal = item.data[numberFieldId]?.toString();
          if (numVal != null && numVal.isNotEmpty) {
            rosterNumbers.add(numVal);
            String displayName = "";
            if (courtNameFieldId != null) {
              final cn = item.data[courtNameFieldId]?.toString();
              if (cn != null && cn.isNotEmpty) displayName = cn;
            }
            if (displayName.isEmpty && nameFieldId != null) {
              final nameVal = item.data[nameFieldId];
              if (nameVal is Map) displayName = "${nameVal['last'] ?? ''} ${nameVal['first'] ?? ''}".trim();
            }
            nameMap[numVal] = displayName;
          }
        }
        rosterNumbers.sort((a, b) => (int.tryParse(a) ?? 999).compareTo(int.tryParse(b) ?? 999));
      }

      // ★アクションロードとボタン生成
      final dbActions = await DatabaseHelper().getActionDefinitions(currentTeam.id);
      for (var map in dbActions) {
        final name = map['name'] as String;
        final isSubReq = map['isSubRequired'] == true;
        final hasSuccess = map['hasSuccess'] == true;
        final hasFailure = map['hasFailure'] == true;
        final subMap = map['subActionsMap'] as Map<String, dynamic>? ?? {};

        // サブアクションの安全な取り出し
        List<String> getSubs(String key) => (subMap[key] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

        if (!hasSuccess && !hasFailure) {
          // 従来通り1つのボタン
          generatedUIActions.add(UIActionItem(
            name: name, parentName: name, fixedResult: ActionResult.none,
            subActions: getSubs('default'), isSubRequired: isSubReq,
          ));
        } else {
          // 成功ボタン
          if (hasSuccess) {
            generatedUIActions.add(UIActionItem(
              name: "$name成功", parentName: name, fixedResult: ActionResult.success,
              subActions: getSubs('success'), isSubRequired: isSubReq,
            ));
          }
          // 失敗ボタン
          if (hasFailure) {
            generatedUIActions.add(UIActionItem(
              name: "$name失敗", parentName: name, fixedResult: ActionResult.failure,
              subActions: getSubs('failure'), isSubRequired: isSubReq,
            ));
          }
        }
      }
    }

    setState(() {
      settings = loadedSettings;
      logs = currentLogs;
      _uiActions = generatedUIActions; // ★UI用リスト更新
      _opponentName = settings.lastOpponent;
      _remainingSeconds = settings.matchDurationMinutes * 60;
      if (rosterNumbers.isNotEmpty) {
        benchPlayers = rosterNumbers;
        _playerNames = nameMap;
      } else {
        benchPlayers = List.from(settings.squadNumbers);
      }
    });
  }

  void _saveCurrentLogs() => DataManager.saveCurrentLogs(logs);

  // ... (editMatchInfo, moveSelectedPlayers 等は前回と同じため変更なし)
  void _editMatchInfo() {
    final oppCtrl = TextEditingController(text: _opponentName);
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(title: const Text("試合情報の記録"), content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: oppCtrl, decoration: const InputDecoration(labelText: "対戦相手名 / タイトル")), const SizedBox(height: 8),
          Wrap(spacing: 8, children: ["大会", "練習試合", "練習"].map((label) => ActionChip(label: Text(label), onPressed: () { oppCtrl.text = label; })).toList()),
          const SizedBox(height: 16),
          Row(children: [const Text("日付: "), TextButton(onPressed: () async { final picked = await showDatePicker(context: context, initialDate: _matchDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if(picked != null) setStateDialog(() => _matchDate = picked); }, child: Text(DateFormat('yyyy-MM-dd').format(_matchDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))])
        ]), actions: [ElevatedButton(onPressed: () { setState(() { _opponentName = oppCtrl.text; settings.lastOpponent = _opponentName; }); DataManager.saveSettings(settings); Navigator.pop(context); }, child: const Text("設定"))]);
      });
    });
  }
  void _moveSelectedPlayers(String toType) { if (selectedForMove.isEmpty) return; setState(() { courtPlayers.removeWhere((p) => selectedForMove.contains(p)); benchPlayers.removeWhere((p) => selectedForMove.contains(p)); absentPlayers.removeWhere((p) => selectedForMove.contains(p)); if (toType == 'court') courtPlayers.addAll(selectedForMove); if (toType == 'bench') benchPlayers.addAll(selectedForMove); if (toType == 'absent') absentPlayers.addAll(selectedForMove); _sortList(courtPlayers); _sortList(benchPlayers); _sortList(absentPlayers); selectedForMove.clear(); isMultiSelectMode = false; selectedPlayer = null; }); }
  void _sortList(List<String> list) => list.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  void _toggleMultiSelect(String number) { setState(() { if (selectedForMove.contains(number)) { selectedForMove.remove(number); if (selectedForMove.isEmpty) isMultiSelectMode = false; } else { selectedForMove.add(number); isMultiSelectMode = true; selectedPlayer = null; } }); }

  void _recordSystemLog(String action) {
    setState(() { logs.insert(0, LogEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), matchDate: DateFormat('yyyy-MM-dd').format(_matchDate), opponent: _opponentName, gameTime: _getFormattedTime(), playerNumber: '', action: action, type: LogType.system, result: ActionResult.none)); });
    _saveCurrentLogs();
  }
  void _startTimer() {
    if (!_hasMatchStarted) { _hasMatchStarted = true; _recordSystemLog("試合開始"); } else if (!_isRunning) { _recordSystemLog("試合再開"); }
    setState(() => _isRunning = true);
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) { if (_remainingSeconds > 0) setState(() => _remainingSeconds--); else _stopTimer(); });
  }
  void _stopTimer() { _gameTimer?.cancel(); setState(() => _isRunning = false); if (_hasMatchStarted) _recordSystemLog("タイム"); } // ★タイムに修正
  String _getFormattedTime() { final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0'); final s = (_remainingSeconds % 60).toString().padLeft(2, '0'); return "$m:$s"; }

  // ★修正: 試合終了後の処理
  void _endMatchSequence() {
    _gameTimer?.cancel();
    setState(() => _isRunning = false);

    // 1. まずログに記録
    _recordSystemLog("試合終了");

    // 2. 即座に保存ダイアログを出す
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildSaveDialog(),
    );
  }

  Widget _buildSaveDialog() {
    return AlertDialog(
        title: const Text("試合記録の保存"),
        content: const Text("記録をデータベースに保存しますか？"),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 保存せずにキャンセルした場合、ログは残ったまま（閲覧可能）
              },
              child: const Text("キャンセル")
          ),
          ElevatedButton(onPressed: () async {
            final currentTeam = _teamStore.currentTeam;
            if(currentTeam==null) return;
            final matchId = DateTime.now().millisecondsSinceEpoch.toString();
            final matchData = {'id': matchId, 'opponent': _opponentName, 'date': DateFormat('yyyy-MM-dd').format(_matchDate)};
            final logMaps = logs.reversed.map((log) => log.toJson()).toList();

            // DB保存
            await DatabaseHelper().insertMatchWithLogs(currentTeam.id, matchData, logMaps);
            // 一時保存クリア
            await DataManager.clearCurrentLogs();

            if(context.mounted) {
              Navigator.pop(context);
              // ★重要: 保存完了後にリセットして新しい試合状態にする
              _resetMatch();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("保存しました")));
            }
          }, child: const Text("保存"))
        ]
    );
  }

  // ★リセット処理
  void _resetMatch() {
    setState(() {
      logs.clear();
      _hasMatchStarted = false;
      _isRunning = false;
      _remainingSeconds = settings.matchDurationMinutes * 60;
      // 選手の状態はベンチに戻す
      _loadData();
      courtPlayers.clear();
      absentPlayers.clear();
      selectedForMove.clear();
      selectedPlayer = null;
      selectedUIAction = null;
      selectedSubAction = null;
    });
  }

  // ★ログ確定処理
  void _confirmLog() {
    if (selectedPlayer == null || selectedUIAction == null) return;

    if (selectedUIAction!.isSubRequired && selectedUIAction!.subActions.isNotEmpty && selectedSubAction == null) {
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
        action: selectedUIAction!.parentName, // 親名で記録（例: アタック）
        subAction: selectedSubAction,
        type: LogType.action,
        result: selectedUIAction!.fixedResult, // ボタンに紐づいた結果（成功/失敗）を記録
      ));
      selectedUIAction = null;
      selectedSubAction = null;
    });
    _saveCurrentLogs();
  }

  @override
  Widget build(BuildContext context) {
    if (settings.squadNumbers.isEmpty && settings.actions.isEmpty && benchPlayers.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('DodgeLog'),
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HistoryScreen()))),
          TextButton(onPressed: _editMatchInfo, child: Text(_opponentName.isEmpty ? "相手設定" : "VS $_opponentName", style: const TextStyle(color: Colors.black))),
          Text(_getFormattedTime(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _remainingSeconds <= 30 ? Colors.red : Colors.black87)),
        ],
      ),
      body: Row(children: [
        Expanded(flex: 2, child: Column(children: [
          TabBar(controller: _tabController, labelColor: Colors.indigo, unselectedLabelColor: Colors.grey, tabs: [Tab(text: 'コート (${courtPlayers.length})'), Tab(text: 'ベンチ'), Tab(text: '欠席')]),
          if (isMultiSelectMode) Container(color: Colors.orange.shade100, padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: [Text("${selectedForMove.length}人選択"), Spacer(), IconButton(icon: const Icon(Icons.sports_basketball), onPressed: () => _moveSelectedPlayers('court')), IconButton(icon: const Icon(Icons.chair), onPressed: () => _moveSelectedPlayers('bench')), IconButton(icon: const Icon(Icons.close), onPressed: () => setState((){selectedForMove.clear(); isMultiSelectMode=false;}))])),
          Expanded(child: TabBarView(controller: _tabController, children: [_buildPlayerList(courtPlayers), _buildPlayerList(benchPlayers), _buildPlayerList(absentPlayers)])),
        ])),
        const VerticalDivider(width: 1),
        Expanded(flex: 6, child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8), color: Colors.blueGrey[50],
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _buildTimerButton("開始", Colors.green, _startTimer, !_hasMatchStarted), const SizedBox(width:8),
              _buildTimerButton("タイム", Colors.orange, _stopTimer, _isRunning), const SizedBox(width:8), // ★修正: タイム
              _buildTimerButton("再開", Colors.blue, _startTimer, _hasMatchStarted && !_isRunning), const SizedBox(width:8),
              _buildTimerButton("終了", Colors.red, _endMatchSequence, _hasMatchStarted),
            ]),
          ),
          Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            Container(
                margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(border: Border.all(color: Colors.indigo.shade200), borderRadius: BorderRadius.circular(12), color: Colors.indigo.shade50),
                child: Row(children: [
                  Expanded(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                    const Text("選手:", style: TextStyle(color: Colors.grey)),
                    Text(selectedPlayer != null ? "$selectedPlayer ${_playerNames[selectedPlayer] != null ? '(${_playerNames[selectedPlayer]})' : ''}" : "-", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    const Text("プレー:", style: TextStyle(color: Colors.grey)),
                    // ★表示名をUIActionItemから取得
                    Text(selectedUIAction?.name ?? "-", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (selectedSubAction != null) ...[const SizedBox(width: 8), Chip(label: Text(selectedSubAction!), backgroundColor: Colors.white)],
                  ])),
                  ElevatedButton.icon(onPressed: (_hasMatchStarted && selectedPlayer != null && selectedUIAction != null) ? _confirmLog : null, icon: const Icon(Icons.check_circle), label: const Text("確定"), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white)),
                ])),

            // ★ボタン生成: _uiActions を使用
            Expanded(flex: 2, child: IgnorePointer(ignoring: !_hasMatchStarted, child: Opacity(opacity: _hasMatchStarted ? 1.0 : 0.5, child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: settings.gridColumns, childAspectRatio: 2.5, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: _uiActions.length,
              itemBuilder: (context, index) {
                final action = _uiActions[index];
                final isSelected = selectedUIAction == action;

                // 色分け: 成功=青系, 失敗=赤系, 通常=白
                Color? bgCol = Colors.white;
                if (action.fixedResult == ActionResult.success) bgCol = Colors.blue.shade50;
                if (action.fixedResult == ActionResult.failure) bgCol = Colors.red.shade50;
                if (isSelected) bgCol = Colors.orange.shade100;

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bgCol,
                    foregroundColor: Colors.black87,
                    side: isSelected ? const BorderSide(color: Colors.orange, width: 3) : BorderSide(color: Colors.grey.shade300),
                  ),
                  onPressed: () {
                    setState(() {
                      selectedUIAction = action;
                      selectedSubAction = null;
                    });
                  },
                  child: Text(action.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            )))),

            // サブアクション選択
            if (selectedUIAction != null && selectedUIAction!.subActions.isNotEmpty) ...[
              const Divider(),
              Text("詳細 (${selectedUIAction!.isSubRequired ? '必須' : '任意'}):", style: TextStyle(fontWeight: FontWeight.bold, color: selectedUIAction!.isSubRequired?Colors.red:Colors.grey)),
              Expanded(flex: 1, child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 2.0, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: selectedUIAction!.subActions.length,
                itemBuilder: (context, index) {
                  final sub = selectedUIAction!.subActions[index];
                  final isSelected = selectedSubAction == sub;
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(backgroundColor: isSelected ? Colors.indigoAccent : Colors.white, foregroundColor: isSelected ? Colors.white : Colors.black87),
                    onPressed: () => setState(() => selectedSubAction = sub),
                    child: Text(sub),
                  );
                },
              )),
            ]
          ]))),
        ])),

        // ログ表示
        Expanded(flex: 2, child: Column(children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(8), color: Colors.grey[200], child: const Text("ログ", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: ListView.builder(itemCount: logs.length, itemBuilder: (context, index) {
            final log = logs[index];
            if (log.type == LogType.system) return Card(color: Colors.grey[300], child: ListTile(title: Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold)), leading: Text(log.gameTime)));

            Color? resultColor;
            String resultStr = "";
            if (log.result == ActionResult.success) { resultColor = Colors.blue[50]; resultStr = "(成功)"; }
            else if (log.result == ActionResult.failure) { resultColor = Colors.red[50]; resultStr = "(失敗)"; }

            return Card(
              color: resultColor ?? Colors.white,
              child: ListTile(
                leading: Text(log.gameTime, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                title: RichText(text: TextSpan(style: const TextStyle(color: Colors.black87), children: [
                  TextSpan(text: "#${log.playerNumber} ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                  TextSpan(text: log.action),
                  TextSpan(text: " $resultStr", style: TextStyle(color: log.result == ActionResult.success ? Colors.blue : Colors.red)),
                  if (log.subAction != null) TextSpan(text: " (${log.subAction})", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ])),
              ),
            );
          }))
        ])),
      ]),
    );
  }

  Widget _buildPlayerList(List<String> players) {
    if (players.isEmpty) return const Center(child: Text("なし", style: TextStyle(color: Colors.grey)));
    return ListView.builder(itemCount: players.length, itemBuilder: (context, index) {
      final number = players[index];
      final name = _playerNames[number] ?? "";
      final isSelected = selectedPlayer == number;
      final isMulti = selectedForMove.contains(number);
      return Card(color: isMulti?Colors.orange[200]:(isSelected?Colors.yellow[100]:Colors.white), child: ListTile(
        title: Text(number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22), textAlign: TextAlign.center),
        subtitle: name.isNotEmpty?Text(name, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis):null,
        onTap: (){ if(isMultiSelectMode) _toggleMultiSelect(number); else setState(()=>selectedPlayer=number); },
        onLongPress: ()=>_toggleMultiSelect(number),
      ));
    });
  }
  Widget _buildTimerButton(String l, Color c, VoidCallback f, bool e) => ElevatedButton(onPressed: e?f:null, style: ElevatedButton.styleFrom(backgroundColor: c, foregroundColor: Colors.white), child: Text(l));
}