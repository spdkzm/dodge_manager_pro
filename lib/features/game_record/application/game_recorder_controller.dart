// lib/features/game_record/application/game_recorder_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Team Management (パス修正)
import '../../team_mgmt/application/team_store.dart';
import '../../team_mgmt/domain/schema.dart'; // ★修正: domainを追加

// Settings
import '../../settings/data/action_dao.dart';

// Game Record
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

  List<UIActionItem?> uiActions = []; // null含む

  Map<String, String> playerNames = {};
  List<String> courtPlayers = [];
  List<String> benchPlayers = [];
  List<String> absentPlayers = [];
  List<LogEntry> logs = [];

  String _opponentName = "";
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

  String get opponentName => _opponentName;
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

        if (!hasSuccess && !hasFailure) {
          gridMap[posIndex] = UIActionItem(
              name: name, parentName: name, fixedResult: ActionResult.none,
              subActions: getSubs('default'), isSubRequired: isSubReq, hasSuccess: false, hasFailure: false
          );
          if (posIndex > maxIndex) maxIndex = posIndex;
        }
        else {
          if (hasSuccess) {
            gridMap[successPos] = UIActionItem(
                name: "$name(成功)", parentName: name, fixedResult: ActionResult.success,
                subActions: getSubs('success'), isSubRequired: isSubReq, hasSuccess: true, hasFailure: false
            );
            if (successPos > maxIndex) maxIndex = successPos;
          }
          if (hasFailure) {
            gridMap[failurePos] = UIActionItem(
                name: "$name(失敗)", parentName: name, fixedResult: ActionResult.failure,
                subActions: getSubs('failure'), isSubRequired: isSubReq, hasSuccess: false, hasFailure: true
            );
            if (failurePos > maxIndex) maxIndex = failurePos;
          }
        }
      }
    }

    List<UIActionItem?> finalList = [];
    for (int i = 0; i <= maxIndex; i++) {
      finalList.add(gridMap[i]);
    }

    settings = loadedSettings;
    logs = currentLogs;
    uiActions = finalList;
    _opponentName = settings.lastOpponent;
    _remainingSeconds = settings.matchDurationMinutes * 60;
    playerNames = nameMap;

    if (rosterNumbers.isNotEmpty) { benchPlayers = rosterNumbers; } else { benchPlayers = List.from(settings.squadNumbers); }
    courtPlayers.clear(); absentPlayers.clear();

    notifyListeners();
  }

  void updateMatchInfo(String opponent, DateTime date) { _opponentName = opponent; _matchDate = date; settings.lastOpponent = opponent; DataManager.saveSettings(settings); notifyListeners(); }
  void selectPlayer(String number) { if (isMultiSelectMode) { _toggleMultiSelect(number); } else { selectedPlayer = number; notifyListeners(); } }
  void startMultiSelect(String number) { _toggleMultiSelect(number); }
  void _toggleMultiSelect(String number) { if (selectedForMove.contains(number)) { selectedForMove.remove(number); if (selectedForMove.isEmpty) isMultiSelectMode = false; } else { selectedForMove.add(number); isMultiSelectMode = true; selectedPlayer = null; } notifyListeners(); }
  void clearMultiSelect() { selectedForMove.clear(); isMultiSelectMode = false; notifyListeners(); }
  void moveSelectedPlayers(String toType) { if (selectedForMove.isEmpty) return; courtPlayers.removeWhere((p) => selectedForMove.contains(p)); benchPlayers.removeWhere((p) => selectedForMove.contains(p)); absentPlayers.removeWhere((p) => selectedForMove.contains(p)); if (toType == 'court') courtPlayers.addAll(selectedForMove); if (toType == 'bench') benchPlayers.addAll(selectedForMove); if (toType == 'absent') absentPlayers.addAll(selectedForMove); _sortList(courtPlayers); _sortList(benchPlayers); _sortList(absentPlayers); selectedForMove.clear(); isMultiSelectMode = false; selectedPlayer = null; notifyListeners(); }
  void _sortList(List<String> list) => list.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  void selectAction(UIActionItem action) { selectedUIAction = action; selectedSubAction = null; selectedResult = action.fixedResult; notifyListeners(); }
  void selectResult(ActionResult result) { selectedResult = result; notifyListeners(); }
  void selectSubAction(String sub) { selectedSubAction = sub; notifyListeners(); }
  void startTimer() { if (!_hasMatchStarted) { _hasMatchStarted = true; _recordSystemLog("試合開始"); } else if (!_isRunning) { _recordSystemLog("試合再開"); } _isRunning = true; notifyListeners(); _gameTimer?.cancel(); _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) { if (_remainingSeconds > 0) { _remainingSeconds--; notifyListeners(); } else { stopTimer(); } }); }
  void stopTimer() { _gameTimer?.cancel(); _isRunning = false; if (_hasMatchStarted) _recordSystemLog("タイム"); notifyListeners(); }
  void _recordSystemLog(String action) { logs.insert(0, LogEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), matchDate: DateFormat('yyyy-MM-dd').format(_matchDate), opponent: _opponentName, gameTime: formattedTime, playerNumber: '', action: action, type: LogType.system, result: ActionResult.none)); DataManager.saveCurrentLogs(logs); notifyListeners(); }
  String? confirmLog() { if (selectedPlayer == null || selectedUIAction == null) return null; if (selectedUIAction!.isSubRequired && selectedUIAction!.subActions.isNotEmpty && selectedSubAction == null) return "詳細項目の選択が必須です"; logs.insert(0, LogEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), matchDate: DateFormat('yyyy-MM-dd').format(_matchDate), opponent: _opponentName, gameTime: formattedTime, playerNumber: selectedPlayer!, action: selectedUIAction!.parentName, subAction: selectedSubAction, type: LogType.action, result: selectedUIAction!.fixedResult)); selectedUIAction = null; selectedSubAction = null; DataManager.saveCurrentLogs(logs); notifyListeners(); return null; }
  void deleteLog(int index) { logs.removeAt(index); DataManager.saveCurrentLogs(logs); notifyListeners(); }
  void restoreLog(int index, LogEntry log) { logs.insert(index, log); DataManager.saveCurrentLogs(logs); notifyListeners(); }
  void updateLog(LogEntry log, String number, String actionName, String? subAction) { log.playerNumber = number; log.action = actionName; log.subAction = subAction; DataManager.saveCurrentLogs(logs); notifyListeners(); }
  void endMatch() { _gameTimer?.cancel(); _isRunning = false; _recordSystemLog("試合終了"); }
  Future<bool> saveMatchToDb() async { final currentTeam = _teamStore.currentTeam; if (currentTeam == null) return false; final matchId = DateTime.now().millisecondsSinceEpoch.toString(); final matchData = {'id': matchId, 'opponent': _opponentName, 'date': DateFormat('yyyy-MM-dd').format(_matchDate)}; final logMaps = logs.reversed.map((log) => log.toJson()).toList(); await _matchDao.insertMatchWithLogs(currentTeam.id, matchData, logMaps); await DataManager.clearCurrentLogs(); resetMatch(); return true; }
  void resetMatch() { logs.clear(); _hasMatchStarted = false; _isRunning = false; _remainingSeconds = settings.matchDurationMinutes * 60; loadData(); selectedForMove.clear(); selectedPlayer = null; selectedUIAction = null; selectedSubAction = null; notifyListeners(); }
  @override void dispose() { _gameTimer?.cancel(); super.dispose(); }
}