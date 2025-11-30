// lib/features/game_record/application/game_recorder_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../team_mgmt/application/team_store.dart';
import '../../team_mgmt/domain/schema.dart';
import '../../settings/data/action_dao.dart';
import '../data/match_dao.dart';
import '../domain/models.dart';
import '../data/persistence.dart';

final gameRecorderProvider = ChangeNotifierProvider.autoDispose<GameRecorderController>((ref) {
  return GameRecorderController(ref);
});

class GameRecorderController extends ChangeNotifier {
  final Ref ref;
  final ActionDao _actionDao = ActionDao();
  final MatchDao _matchDao = MatchDao();
  TeamStore get _teamStore => ref.read(teamStoreProvider);

  GameRecorderController(this.ref);

  AppSettings settings = AppSettings(squadNumbers: [], actions: []);
  List<UIActionItem?> uiActions = [];

  Map<String, String> playerNames = {};
  List<String> courtPlayers = [];
  List<String> benchPlayers = [];
  List<String> absentPlayers = [];
  List<LogEntry> logs = [];

  DateTime _matchDate = DateTime.now();
  Timer? _gameTimer;
  int _remainingSeconds = 300;
  bool _isRunning = false;
  bool _hasMatchStarted = false;
  String? selectedPlayer;
  Set<String> selectedForMove = {};
  bool isMultiSelectMode = false;
  UIActionItem? selectedUIAction;
  String? selectedSubAction;
  ActionResult selectedResult = ActionResult.none;

  DateTime get matchDate => _matchDate;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get hasMatchStarted => _hasMatchStarted;
  String get formattedTime { final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0'); final s = (_remainingSeconds % 60).toString().padLeft(2, '0'); return "$m:$s"; }

  // --- 初期化 ---
  Future<void> loadData() async {
    final loadedSettings = await DataManager.loadSettings();
    final currentLogs = await DataManager.loadCurrentLogs();

    if (!_teamStore.isLoaded) await _teamStore.loadFromDb();
    final currentTeam = _teamStore.currentTeam;

    List<String> rosterNumbers = [];
    Map<String, String> nameMap = {};
    Map<int, UIActionItem> gridMap = {};
    int maxIndex = 0;

    // 安全に配置するヘルパー
    void placeSafe(int pos, UIActionItem item) {
      if (!gridMap.containsKey(pos)) {
        gridMap[pos] = item;
        if (pos > maxIndex) maxIndex = pos;
      } else {
        int newPos = 0;
        while (gridMap.containsKey(newPos)) newPos++;
        gridMap[newPos] = item;
        if (newPos > maxIndex) maxIndex = newPos;
      }
    }

    if (currentTeam != null) {
      // 選手ロード
      String? numberFieldId; String? nameFieldId; String? courtNameFieldId;
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
            if (courtNameFieldId != null) { final cn = item.data[courtNameFieldId]?.toString(); if (cn != null && cn.isNotEmpty) displayName = cn; }
            if (displayName.isEmpty && nameFieldId != null) { final nameVal = item.data[nameFieldId]; if (nameVal is Map) displayName = "${nameVal['last'] ?? ''} ${nameVal['first'] ?? ''}".trim(); }
            nameMap[numVal] = displayName;
          }
        }
        rosterNumbers.sort((a, b) => (int.tryParse(a) ?? 999).compareTo(int.tryParse(b) ?? 999));
      }

      // アクションロードと配置
      final dbActions = await _actionDao.getActionDefinitions(currentTeam.id);
      for (var map in dbActions) {
        final name = map['name'] as String;
        final isSubReq = map['isSubRequired'] == true;
        final hasSuccess = map['hasSuccess'] == true;
        final hasFailure = map['hasFailure'] == true;
        final posIndex = map['positionIndex'] as int? ?? 0;
        final successPos = map['successPositionIndex'] as int? ?? 0;
        final failurePos = map['failurePositionIndex'] as int? ?? 0;
        final subMap = map['subActionsMap'] as Map<String, dynamic>? ?? {};
        List<String> getSubs(String key) => (subMap[key] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

        // 1. 成功ボタン
        if (hasSuccess) {
          final item = UIActionItem(
              name: "${name}成功", // カッコなし
              parentName: name,
              fixedResult: ActionResult.success,
              subActions: getSubs('success'),
              isSubRequired: isSubReq,
              hasSuccess: true,
              hasFailure: false
          );
          placeSafe(successPos, item);
        }

        // 2. 失敗ボタン
        if (hasFailure) {
          final item = UIActionItem(
              name: "${name}失敗", // カッコなし
              parentName: name,
              fixedResult: ActionResult.failure,
              subActions: getSubs('failure'),
              isSubRequired: isSubReq,
              hasSuccess: false,
              hasFailure: true
          );
          placeSafe(failurePos, item);
        }

        // 3. 通常ボタン (成功も失敗もない場合)
        if (!hasSuccess && !hasFailure) {
          final item = UIActionItem(
              name: name, // 項目名のみ
              parentName: name,
              fixedResult: ActionResult.none,
              subActions: getSubs('default'),
              isSubRequired: isSubReq,
              hasSuccess: false,
              hasFailure: false
          );
          placeSafe(posIndex, item);
        }
      }
    }

    List<UIActionItem?> finalList = [];
    for (int i = 0; i <= maxIndex; i++) finalList.add(gridMap[i]);

    settings = loadedSettings;
    logs = currentLogs;
    uiActions = finalList;
    _remainingSeconds = settings.matchDurationMinutes * 60;
    playerNames = nameMap;

    _matchDate = DateTime.now();

    // 既に配置済みならリセットしない（試合連続実施のため）
    if (courtPlayers.isEmpty && benchPlayers.isEmpty && absentPlayers.isEmpty) {
      if (rosterNumbers.isNotEmpty) { benchPlayers = rosterNumbers; } else { benchPlayers = List.from(settings.squadNumbers); }
    }

    notifyListeners();
  }

  void updateMatchDate(DateTime date) {
    _matchDate = date;
    notifyListeners();
  }

  void selectPlayer(String number) { if (isMultiSelectMode) { _toggleMultiSelect(number); } else { selectedPlayer = number; notifyListeners(); } }
  void startMultiSelect(String number) { _toggleMultiSelect(number); }
  void _toggleMultiSelect(String number) { if (selectedForMove.contains(number)) { selectedForMove.remove(number); if (selectedForMove.isEmpty) isMultiSelectMode = false; } else { selectedForMove.add(number); isMultiSelectMode = true; selectedPlayer = null; } notifyListeners(); }
  void clearMultiSelect() { selectedForMove.clear(); isMultiSelectMode = false; notifyListeners(); }
  void moveSelectedPlayers(String toType) { if (selectedForMove.isEmpty) return; courtPlayers.removeWhere((p) => selectedForMove.contains(p)); benchPlayers.removeWhere((p) => selectedForMove.contains(p)); absentPlayers.removeWhere((p) => selectedForMove.contains(p)); if (toType == 'court') courtPlayers.addAll(selectedForMove); if (toType == 'bench') benchPlayers.addAll(selectedForMove); if (toType == 'absent') absentPlayers.addAll(selectedForMove); _sortList(courtPlayers); _sortList(benchPlayers); _sortList(absentPlayers); selectedForMove.clear(); isMultiSelectMode = false; selectedPlayer = null; notifyListeners(); }

  void _sortList(List<String> list) {
    list.sort((a, b) {
      final numA = int.tryParse(a);
      final numB = int.tryParse(b);

      if (numA != null && numB != null) {
        return numA.compareTo(numB);
      }
      if (numA != null) return -1;
      if (numB != null) return 1;

      return a.compareTo(b);
    });
  }

  void selectAction(UIActionItem action) { selectedUIAction = action; selectedSubAction = null; selectedResult = action.fixedResult; notifyListeners(); }
  void selectResult(ActionResult result) { selectedResult = result; notifyListeners(); }
  void selectSubAction(String sub) { selectedSubAction = sub; notifyListeners(); }

  void startTimer() {
    if (!_hasMatchStarted) {
      _hasMatchStarted = true;
      _recordSystemLog("試合開始");
    } else if (!_isRunning) {
      _recordSystemLog("試合再開");
    }
    _isRunning = true;
    notifyListeners();

    _gameTimer?.cancel();

    final startTime = DateTime.now();
    final initialSeconds = _remainingSeconds;

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      final newRemaining = initialSeconds - elapsed;

      if (newRemaining <= 0) {
        _remainingSeconds = 0;
        notifyListeners();
        stopTimer();
      } else {
        _remainingSeconds = newRemaining;
        notifyListeners();
      }
    });
  }

  void stopTimer() {
    _gameTimer?.cancel();
    _isRunning = false;
    if (_hasMatchStarted) _recordSystemLog("タイム");
    notifyListeners();
  }

  void _recordSystemLog(String action) {
    logs.insert(0, LogEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), matchDate: DateFormat('yyyy-MM-dd').format(_matchDate), opponent: '記録中', gameTime: formattedTime, playerNumber: '', action: action, type: LogType.system, result: ActionResult.none));
    DataManager.saveCurrentLogs(logs);
    notifyListeners();
  }

  String? confirmLog() {
    if (selectedPlayer == null || selectedUIAction == null) return null;

    if (selectedUIAction!.isSubRequired && selectedUIAction!.subActions.isNotEmpty && selectedSubAction == null) {
      return "詳細項目の選択が必須です";
    }

    logs.insert(0, LogEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), matchDate: DateFormat('yyyy-MM-dd').format(_matchDate), opponent: '記録中', gameTime: formattedTime, playerNumber: selectedPlayer!, action: selectedUIAction!.parentName, subAction: selectedSubAction, type: LogType.action, result: selectedUIAction!.fixedResult));
    selectedUIAction = null;
    selectedSubAction = null;
    DataManager.saveCurrentLogs(logs);
    notifyListeners();
    return null;
  }

  void deleteLog(int index) { logs.removeAt(index); DataManager.saveCurrentLogs(logs); notifyListeners(); }
  void restoreLog(int index, LogEntry log) { logs.insert(index, log); DataManager.saveCurrentLogs(logs); notifyListeners(); }
  void updateLog(LogEntry log, String number, String actionName, String? subAction) { log.playerNumber = number; log.action = actionName; log.subAction = subAction; DataManager.saveCurrentLogs(logs); notifyListeners(); }
  void endMatch() { _gameTimer?.cancel(); _isRunning = false; _recordSystemLog("試合終了"); }

  // --- 保存処理 ---
  Future<bool> saveMatchToDb() async {
    final currentTeam = _teamStore.currentTeam;
    if (currentTeam == null) return false;

    // 1. 同日試合数をカウントし、連番を決定するロジック
    final dateStr = DateFormat('yyyy-MM-dd').format(_matchDate);

    // その日の試合数を取得
    final existingMatches = await _matchDao.getMatches(currentTeam.id);
    final matchesToday = existingMatches.where((m) => m['date'] == dateStr).length;
    final sequentialId = matchesToday + 1;
    // 自動生成した連番をopponentとして使用
    final generatedOpponentName = "試合-${dateStr} #${sequentialId}";

    final matchId = DateTime.now().millisecondsSinceEpoch.toString();
    final matchData = {
      'id': matchId,
      'opponent': generatedOpponentName, // 自動生成名を使用
      'date': dateStr,
    };

    // ログ内のplaceholder '記録中' を実際の連番に置換
    final logMaps = logs.reversed.map((log) {
      final map = log.toJson();
      map['opponent'] = generatedOpponentName; // LogEntryのtoJsonはopponentを使用しないが、MapとしてDBに渡す際にopponentが必要
      return map;
    }).toList();

    // ★削除: デバッグログ

    await _matchDao.insertMatchWithLogs(currentTeam.id, matchData, logMaps, courtPlayers);
    await DataManager.clearCurrentLogs();

    resetMatch();
    return true;
  }

  // --- リセット処理 ---
  void resetMatch() {
    logs.clear();
    _hasMatchStarted = false;
    _isRunning = false;
    _remainingSeconds = settings.matchDurationMinutes * 60;

    loadData();

    selectedForMove.clear();
    selectedPlayer = null;
    selectedUIAction = null;
    selectedSubAction = null;
    selectedResult = ActionResult.none;

    notifyListeners();
  }

  @override
  void dispose() { _gameTimer?.cancel(); super.dispose(); }
}