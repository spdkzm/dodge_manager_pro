// lib/features/game_record/application/game_recorder_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../team_mgmt/application/team_store.dart';
import '../../team_mgmt/domain/schema.dart';
import '../../team_mgmt/domain/roster_category.dart';
import '../../settings/data/action_dao.dart';
import '../data/match_dao.dart';
import '../domain/models.dart';
import '../data/persistence.dart';

final gameRecorderProvider = ChangeNotifierProvider<GameRecorderController>((ref) {
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
  MatchType _matchType = MatchType.practiceMatch;
  String _opponentName = "";
  String? _opponentId;
  String _venueName = "";
  String? _venueId;

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
  MatchType get matchType => _matchType;
  String get opponentName => _opponentName;
  String? get opponentId => _opponentId;
  String get venueName => _venueName;
  String? get venueId => _venueId;

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get hasMatchStarted => _hasMatchStarted;
  String get formattedTime { final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0'); final s = (_remainingSeconds % 60).toString().padLeft(2, '0'); return "$m:$s"; }

  Future<void> loadData() async {
    final loadedSettings = await DataManager.loadSettings();
    final currentLogs = await DataManager.loadCurrentLogs();

    if (!_teamStore.isLoaded) await _teamStore.loadFromDb();
    final currentTeam = _teamStore.currentTeam;

    List<String> rosterNumbers = [];
    Map<String, String> nameMap = {};

    if (currentTeam != null) {
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

      uiActions = await _buildUIActionList(currentTeam.id);
    }

    settings = loadedSettings;
    logs = currentLogs;
    if (_remainingSeconds == 300 && !_hasMatchStarted) {
      _remainingSeconds = settings.matchDurationMinutes * 60;
    }
    playerNames = nameMap;

    if (courtPlayers.isEmpty && benchPlayers.isEmpty && absentPlayers.isEmpty) {
      if (rosterNumbers.isNotEmpty) { benchPlayers = List.from(rosterNumbers); }
      else { benchPlayers = List.from(settings.squadNumbers); }
    } else {
      final currentRegistered = {...courtPlayers, ...benchPlayers, ...absentPlayers};
      final newNumbers = rosterNumbers.where((n) => !currentRegistered.contains(n)).toList();
      if (newNumbers.isNotEmpty) {
        benchPlayers.addAll(newNumbers);
        _sortList(benchPlayers);
      }
      final validSet = rosterNumbers.toSet();
      courtPlayers.removeWhere((n) => !validSet.contains(n));
      benchPlayers.removeWhere((n) => !validSet.contains(n));
      absentPlayers.removeWhere((n) => !validSet.contains(n));
    }

    notifyListeners();
  }

  Future<List<UIActionItem?>> _buildUIActionList(String teamId) async {
    final dbActions = await _actionDao.getActionDefinitions(teamId);
    Map<int, UIActionItem> gridMap = {};
    int maxIndex = 0;

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

      if (hasSuccess) {
        final item = UIActionItem(name: "${name}成功", parentName: name, fixedResult: ActionResult.success, subActions: getSubs('success'), isSubRequired: isSubReq, hasSuccess: true, hasFailure: false);
        placeSafe(successPos, item);
      }
      if (hasFailure) {
        final item = UIActionItem(name: "${name}失敗", parentName: name, fixedResult: ActionResult.failure, subActions: getSubs('failure'), isSubRequired: isSubReq, hasSuccess: false, hasFailure: true);
        placeSafe(failurePos, item);
      }
      if (!hasSuccess && !hasFailure) {
        final item = UIActionItem(name: name, parentName: name, fixedResult: ActionResult.none, subActions: getSubs('default'), isSubRequired: isSubReq, hasSuccess: false, hasFailure: false);
        placeSafe(posIndex, item);
      }
    }

    List<UIActionItem?> finalList = [];
    for (int i = 0; i <= maxIndex; i++) finalList.add(gridMap[i]);
    return finalList;
  }

  void updateMatchDate(DateTime date) { _matchDate = date; notifyListeners(); }
  void updateMatchType(MatchType type) { _matchType = type; notifyListeners(); }

  void updateMatchInfo({String? opponentName, String? opponentId, String? venueName, String? venueId}) {
    if (opponentName != null) _opponentName = opponentName;
    if (opponentId != null) _opponentId = opponentId;
    if (venueName != null) _venueName = venueName;
    if (venueId != null) _venueId = venueId;
    notifyListeners();
  }

  void selectPlayer(String number) { if (isMultiSelectMode) { _toggleMultiSelect(number); } else { selectedPlayer = number; notifyListeners(); } }
  void startMultiSelect(String number) { _toggleMultiSelect(number); }
  void _toggleMultiSelect(String number) { if (selectedForMove.contains(number)) { selectedForMove.remove(number); if (selectedForMove.isEmpty) isMultiSelectMode = false; } else { selectedForMove.add(number); isMultiSelectMode = true; selectedPlayer = null; } notifyListeners(); }
  void clearMultiSelect() { selectedForMove.clear(); isMultiSelectMode = false; notifyListeners(); }
  void moveSelectedPlayers(String toType) { if (selectedForMove.isEmpty) return; courtPlayers.removeWhere((p) => selectedForMove.contains(p)); benchPlayers.removeWhere((p) => selectedForMove.contains(p)); absentPlayers.removeWhere((p) => selectedForMove.contains(p)); if (toType == 'court') courtPlayers.addAll(selectedForMove); if (toType == 'bench') benchPlayers.addAll(selectedForMove); if (toType == 'absent') absentPlayers.addAll(selectedForMove); _sortList(courtPlayers); _sortList(benchPlayers); _sortList(absentPlayers); selectedForMove.clear(); isMultiSelectMode = false; selectedPlayer = null; notifyListeners(); }
  void _sortList(List<String> list) { list.sort((a, b) { final numA = int.tryParse(a); final numB = int.tryParse(b); if (numA != null && numB != null) { return numA.compareTo(numB); } if (numA != null) return -1; if (numB != null) return 1; return a.compareTo(b); }); }
  void selectAction(UIActionItem action) { selectedUIAction = action; selectedSubAction = null; selectedResult = action.fixedResult; notifyListeners(); }
  void selectResult(ActionResult result) { selectedResult = result; notifyListeners(); }
  void selectSubAction(String sub) { selectedSubAction = sub; notifyListeners(); }

  void startTimer() {
    if (!_hasMatchStarted) { _hasMatchStarted = true; _recordSystemLog("試合開始"); } else if (!_isRunning) { _recordSystemLog("試合再開"); }
    _isRunning = true; notifyListeners();
    _gameTimer?.cancel();
    final startTime = DateTime.now(); final initialSeconds = _remainingSeconds;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) { final elapsed = DateTime.now().difference(startTime).inSeconds; final newRemaining = initialSeconds - elapsed; if (newRemaining <= 0) { _remainingSeconds = 0; notifyListeners(); stopTimer(); } else { _remainingSeconds = newRemaining; notifyListeners(); } });
  }
  void stopTimer() { _gameTimer?.cancel(); _isRunning = false; if (_hasMatchStarted) _recordSystemLog("タイム"); notifyListeners(); }
  void _recordSystemLog(String action) { logs.insert(0, LogEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), matchDate: DateFormat('yyyy-MM-dd').format(_matchDate), opponent: '記録中', gameTime: formattedTime, playerNumber: '', action: action, type: LogType.system, result: ActionResult.none)); DataManager.saveCurrentLogs(logs); notifyListeners(); }
  String? confirmLog() { if (selectedPlayer == null || selectedUIAction == null) return null; if (selectedUIAction!.isSubRequired && selectedUIAction!.subActions.isNotEmpty && selectedSubAction == null) { return "詳細項目の選択が必須です"; } logs.insert(0, LogEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), matchDate: DateFormat('yyyy-MM-dd').format(_matchDate), opponent: '記録中', gameTime: formattedTime, playerNumber: selectedPlayer!, action: selectedUIAction!.parentName, subAction: selectedSubAction, type: LogType.action, result: selectedUIAction!.fixedResult)); selectedUIAction = null; selectedSubAction = null; DataManager.saveCurrentLogs(logs); notifyListeners(); return null; }
  void deleteLog(int index) { logs.removeAt(index); DataManager.saveCurrentLogs(logs); notifyListeners(); }
  void restoreLog(int index, LogEntry log) { logs.insert(index, log); DataManager.saveCurrentLogs(logs); notifyListeners(); }
  void updateLog(LogEntry log, String number, String actionName, String? subAction) { log.playerNumber = number; log.action = actionName; log.subAction = subAction; DataManager.saveCurrentLogs(logs); notifyListeners(); }
  void endMatch() { _gameTimer?.cancel(); _isRunning = false; _recordSystemLog("試合終了"); }

  // ★修正: 勝敗・スコアの引数を追加
  Future<bool> saveMatchToDb({
    MatchResult result = MatchResult.none,
    int? scoreOwn,
    int? scoreOpponent,
    bool isExtraTime = false,
    int? extraScoreOwn,
    int? extraScoreOpponent,
  }) async {
    final currentTeam = _teamStore.currentTeam;
    if (currentTeam == null) return false;
    final dateStr = DateFormat('yyyy-MM-dd').format(_matchDate);

    String finalOpponentName = _opponentName;
    String? finalOpponentId = _opponentId;
    String? finalVenueName = _venueName;
    String? finalVenueId = _venueId;

    if (finalOpponentName.isNotEmpty && (finalOpponentId == null || finalOpponentId.isEmpty)) {
      finalOpponentId = await _teamStore.ensureItemExists(finalOpponentName, RosterCategory.opponent);
    }
    if (finalVenueName.isNotEmpty && (finalVenueId == null || finalVenueId.isEmpty)) {
      finalVenueId = await _teamStore.ensureItemExists(finalVenueName, RosterCategory.venue);
    }

    if (finalOpponentName.isEmpty) {
      final existingMatches = await _matchDao.getMatches(currentTeam.id);
      final regex = RegExp(r'^試合-.* #(\d+)$');
      final existingNumbers = <int>{};

      for (var m in existingMatches.where((m) => m['date'] == dateStr)) {
        final op = m['opponent'] as String? ?? "";
        final match = regex.firstMatch(op);
        if (match != null) {
          existingNumbers.add(int.parse(match.group(1)!));
        }
      }

      int newNum = 1;
      while (existingNumbers.contains(newNum)) {
        newNum++;
      }

      finalOpponentName = "試合-${dateStr} #${newNum}";
    }

    final matchId = DateTime.now().millisecondsSinceEpoch.toString();
    final matchData = {
      'id': matchId,
      'opponent': finalOpponentName,
      'opponent_id': finalOpponentId,
      'venue_name': finalVenueName,
      'venue_id': finalVenueId,
      'date': dateStr,
      'match_type': _matchType.index,
      // ★追加: 勝敗・スコア
      'result': result.index,
      'score_own': scoreOwn,
      'score_opponent': scoreOpponent,
      'is_extra_time': isExtraTime ? 1 : 0,
      'extra_score_own': extraScoreOwn,
      'extra_score_opponent': extraScoreOpponent,
    };

    final logMaps = logs.reversed.map((log) { final map = log.toJson(); map['opponent'] = finalOpponentName; return map; }).toList();
    await _matchDao.insertMatchWithLogs(currentTeam.id, matchData, logMaps, courtPlayers);
    await DataManager.clearCurrentLogs();

    resetMatch();
    return true;
  }

  void resetMatch() {
    logs.clear();
    _hasMatchStarted = false;
    _isRunning = false;
    _remainingSeconds = settings.matchDurationMinutes * 60;
    selectedForMove.clear();
    selectedPlayer = null;
    selectedUIAction = null;
    selectedSubAction = null;
    selectedResult = ActionResult.none;
    notifyListeners();
  }

  Future<void> clearAllDataAndReload() async {
    await DataManager.clearCurrentLogs();
    logs.clear();
    stopTimer();
    _remainingSeconds = settings.matchDurationMinutes * 60;
    _hasMatchStarted = false;
    _isRunning = false;
    courtPlayers.clear();
    benchPlayers.clear();
    absentPlayers.clear();
    _opponentName = ""; _opponentId = null; _venueName = ""; _venueId = null;

    await loadData();
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