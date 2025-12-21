// lib/features/game_record/application/game_recorder_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../team_mgmt/application/team_store.dart';
import '../../team_mgmt/domain/schema.dart';
import '../../team_mgmt/domain/roster_category.dart';
import '../../settings/data/action_dao.dart';
import '../../settings/domain/action_definition.dart'; // SubActionDefinition
import '../data/match_dao.dart';
import '../domain/models.dart';
import '../data/persistence.dart';

/// 選手情報をまとめて管理する内部クラス
class PlayerDisplayInfo {
  final String id;
  final String number;
  final String name;

  PlayerDisplayInfo({
    required this.id,
    required this.number,
    required this.name,
  });
}

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
  List<ActionDefinition> actionDefinitions = [];

  // ID管理用のマップ
  Map<String, PlayerDisplayInfo> _playerInfoMap = {}; // Key: PlayerID
  Map<String, String> _numberToIdMap = {}; // Key: 背番号 -> PlayerID (UI入力用)

  // 状態管理 (IDリスト)
  List<String> courtPlayerIds = [];
  List<String> benchPlayerIds = [];
  List<String> absentPlayerIds = [];
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

  // 選択状態 (ID)
  String? selectedPlayerId;
  Set<String> selectedForMoveIds = {};
  bool isMultiSelectMode = false;

  UIActionItem? selectedUIAction;
  SubActionDefinition? selectedSubAction;
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

  // ★追加: IDから情報を取得するヘルパー
  PlayerDisplayInfo? getPlayerInfo(String id) => _playerInfoMap[id];

  // ★追加: UI入力用ヘルパー (名前解決用マップではなく、ID検索用)
  // 古いplayerNames (背番号->名前) は削除し、必要な場合は getPlayerInfo を使う

  Future<void> loadData() async {
    final loadedSettings = await DataManager.loadSettings();
    final currentLogs = await DataManager.loadCurrentLogs();

    if (!_teamStore.isLoaded) await _teamStore.loadFromDb();
    final currentTeam = _teamStore.currentTeam;

    // マップの初期化
    _playerInfoMap.clear();
    _numberToIdMap.clear();

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
            String displayName = "";
            if (courtNameFieldId != null) { final cn = item.data[courtNameFieldId]?.toString(); if (cn != null && cn.isNotEmpty) displayName = cn; }
            if (displayName.isEmpty && nameFieldId != null) { final nameVal = item.data[nameFieldId]; if (nameVal is Map) displayName = "${nameVal['last'] ?? ''} ${nameVal['first'] ?? ''}".trim(); }

            final info = PlayerDisplayInfo(id: item.id, number: numVal, name: displayName);
            _playerInfoMap[item.id] = info;
            _numberToIdMap[numVal] = item.id;
          }
        }
      }

      uiActions = await _buildUIActionList(currentTeam.id);
    }

    settings = loadedSettings;
    logs = currentLogs;
    if (_remainingSeconds == 300 && !_hasMatchStarted) {
      _remainingSeconds = settings.matchDurationMinutes * 60;
    }

    // リスト初期化ロジック (IDベース)
    if (courtPlayerIds.isEmpty && benchPlayerIds.isEmpty && absentPlayerIds.isEmpty) {
      // 初回ロード時: 全員ベンチへ
      final allIds = _playerInfoMap.keys.toList();
      _sortIdList(allIds);
      benchPlayerIds = List.from(allIds);
    } else {
      // 再ロード時: 整合性チェック
      final currentRegistered = {...courtPlayerIds, ...benchPlayerIds, ...absentPlayerIds};
      final allIds = _playerInfoMap.keys.toSet();

      final newIds = allIds.difference(currentRegistered).toList();
      if (newIds.isNotEmpty) {
        benchPlayerIds.addAll(newIds);
        _sortIdList(benchPlayerIds);
      }

      courtPlayerIds.removeWhere((id) => !allIds.contains(id));
      benchPlayerIds.removeWhere((id) => !allIds.contains(id));
      absentPlayerIds.removeWhere((id) => !allIds.contains(id));
    }

    notifyListeners();
  }

  Future<List<UIActionItem?>> _buildUIActionList(String teamId) async {
    final dbActions = await _actionDao.getActionDefinitions(teamId);
    actionDefinitions = dbActions.map((d) => ActionDefinition.fromMap(d)).toList();

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

    for (var def in actionDefinitions) {
      final isSubReq = def.isSubRequired;

      if (def.hasSuccess) {
        final item = UIActionItem(
            name: "${def.name}成功",
            parentName: def.name,
            fixedResult: ActionResult.success,
            subActions: def.getSubActions('success'),
            isSubRequired: isSubReq,
            hasSuccess: true,
            hasFailure: false
        );
        placeSafe(def.successPositionIndex, item);
      }
      if (def.hasFailure) {
        final item = UIActionItem(
            name: "${def.name}失敗",
            parentName: def.name,
            fixedResult: ActionResult.failure,
            subActions: def.getSubActions('failure'),
            isSubRequired: isSubReq,
            hasSuccess: false,
            hasFailure: true
        );
        placeSafe(def.failurePositionIndex, item);
      }
      if (!def.hasSuccess && !def.hasFailure) {
        final item = UIActionItem(
            name: def.name,
            parentName: def.name,
            fixedResult: ActionResult.none,
            subActions: def.getSubActions('default'),
            isSubRequired: isSubReq,
            hasSuccess: false,
            hasFailure: false
        );
        placeSafe(def.positionIndex, item);
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

  // ★変更: IDを直接受け取る
  void selectPlayer(String id) {
    if (!_playerInfoMap.containsKey(id)) return;

    if (isMultiSelectMode) {
      _toggleMultiSelect(id);
    } else {
      selectedPlayerId = id;
      notifyListeners();
    }
  }

  void startMultiSelect(String id) {
    if (_playerInfoMap.containsKey(id)) _toggleMultiSelect(id);
  }

  void _toggleMultiSelect(String id) {
    if (selectedForMoveIds.contains(id)) {
      selectedForMoveIds.remove(id);
      if (selectedForMoveIds.isEmpty) isMultiSelectMode = false;
    } else {
      selectedForMoveIds.add(id);
      isMultiSelectMode = true;
      selectedPlayerId = null;
    }
    notifyListeners();
  }

  void clearMultiSelect() {
    selectedForMoveIds.clear();
    isMultiSelectMode = false;
    notifyListeners();
  }

  void moveSelectedPlayers(String toType) {
    if (selectedForMoveIds.isEmpty) return;

    courtPlayerIds.removeWhere((p) => selectedForMoveIds.contains(p));
    benchPlayerIds.removeWhere((p) => selectedForMoveIds.contains(p));
    absentPlayerIds.removeWhere((p) => selectedForMoveIds.contains(p));

    if (toType == 'court') courtPlayerIds.addAll(selectedForMoveIds);
    if (toType == 'bench') benchPlayerIds.addAll(selectedForMoveIds);
    if (toType == 'absent') absentPlayerIds.addAll(selectedForMoveIds);

    _sortIdList(courtPlayerIds);
    _sortIdList(benchPlayerIds);
    _sortIdList(absentPlayerIds);

    selectedForMoveIds.clear();
    isMultiSelectMode = false;
    selectedPlayerId = null;
    notifyListeners();
  }

  void _sortIdList(List<String> ids) {
    ids.sort((a, b) {
      final numAStr = _playerInfoMap[a]?.number;
      final numBStr = _playerInfoMap[b]?.number;
      final numA = int.tryParse(numAStr ?? '');
      final numB = int.tryParse(numBStr ?? '');
      if (numA != null && numB != null) { return numA.compareTo(numB); }
      if (numA != null) return -1;
      if (numB != null) return 1;
      return (numAStr ?? '').compareTo(numBStr ?? '');
    });
  }

  void selectAction(UIActionItem action) { selectedUIAction = action; selectedSubAction = null; selectedResult = action.fixedResult; notifyListeners(); }
  void selectResult(ActionResult result) { selectedResult = result; notifyListeners(); }
  void selectSubAction(SubActionDefinition sub) { selectedSubAction = sub; notifyListeners(); }

  void startTimer() {
    if (!_hasMatchStarted) { _hasMatchStarted = true; _recordSystemLog("試合開始"); } else if (!_isRunning) { _recordSystemLog("試合再開"); }
    _isRunning = true; notifyListeners();
    _gameTimer?.cancel();
    final startTime = DateTime.now(); final initialSeconds = _remainingSeconds;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) { final elapsed = DateTime.now().difference(startTime).inSeconds; final newRemaining = initialSeconds - elapsed; if (newRemaining <= 0) { _remainingSeconds = 0; notifyListeners(); stopTimer(); } else { _remainingSeconds = newRemaining; notifyListeners(); } });
  }
  void stopTimer() { _gameTimer?.cancel(); _isRunning = false; if (_hasMatchStarted) _recordSystemLog("タイム"); notifyListeners(); }
  void _recordSystemLog(String action) { logs.insert(0, LogEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), matchDate: DateFormat('yyyy-MM-dd').format(_matchDate), opponent: '記録中', gameTime: formattedTime, playerNumber: '', action: action, type: LogType.system, result: ActionResult.none)); DataManager.saveCurrentLogs(logs); notifyListeners(); }

  String? confirmLog() {
    if (selectedPlayerId == null || selectedUIAction == null) return null;
    if (selectedUIAction!.isSubRequired && selectedUIAction!.subActions.isNotEmpty && selectedSubAction == null) {
      return "詳細項目の選択が必須です";
    }

    final info = _playerInfoMap[selectedPlayerId];
    final playerNumber = info?.number ?? "";

    logs.insert(0, LogEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        matchDate: DateFormat('yyyy-MM-dd').format(_matchDate),
        opponent: '記録中',
        gameTime: formattedTime,
        playerNumber: playerNumber,
        playerId: selectedPlayerId,
        action: selectedUIAction!.parentName,
        subAction: selectedSubAction?.name,
        subActionId: selectedSubAction?.id,
        type: LogType.action,
        result: selectedUIAction!.fixedResult
    ));

    selectedUIAction = null;
    selectedSubAction = null;
    DataManager.saveCurrentLogs(logs);
    notifyListeners();
    return null;
  }

  void deleteLog(int index) { logs.removeAt(index); DataManager.saveCurrentLogs(logs); notifyListeners(); }
  void restoreLog(int index, LogEntry log) { logs.insert(index, log); DataManager.saveCurrentLogs(logs); notifyListeners(); }

  void updateLog(int index, LogEntry newLog) {
    if (index >= 0 && index < logs.length) {
      logs[index] = newLog;
      DataManager.saveCurrentLogs(logs);
      notifyListeners();
    }
  }

  void endMatch() { _gameTimer?.cancel(); _isRunning = false; _recordSystemLog("試合終了"); }

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
      'result': result.index,
      'score_own': scoreOwn,
      'score_opponent': scoreOpponent,
      'is_extra_time': isExtraTime ? 1 : 0,
      'extra_score_own': extraScoreOwn,
      'extra_score_opponent': extraScoreOpponent,
    };

    final logMaps = logs.reversed.map((log) {
      final map = log.toJson();
      map['opponent'] = finalOpponentName;
      return map;
    }).toList();

    final List<Map<String, dynamic>> participationList = [];

    void addToList(List<String> ids, int status) {
      for (var id in ids) {
        final info = _playerInfoMap[id];
        if (info != null) {
          participationList.add({
            'player_number': info.number,
            'player_id': id,
            'status': status,
          });
        }
      }
    }

    addToList(courtPlayerIds, 0); // コート
    addToList(benchPlayerIds, 1); // ベンチ
    addToList(absentPlayerIds, 2); // 欠席

    await _matchDao.insertMatchWithLogs(currentTeam.id, matchData, logMaps, participationList);
    await DataManager.clearCurrentLogs();

    resetMatch();
    return true;
  }

  void resetMatch() {
    logs.clear();
    _hasMatchStarted = false;
    _isRunning = false;
    _remainingSeconds = settings.matchDurationMinutes * 60;
    selectedForMoveIds.clear();
    selectedPlayerId = null;
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

    courtPlayerIds.clear();
    benchPlayerIds.clear();
    absentPlayerIds.clear();
    _opponentName = ""; _opponentId = null; _venueName = ""; _venueId = null;

    await loadData();
    selectedForMoveIds.clear();
    selectedPlayerId = null;
    selectedUIAction = null;
    selectedSubAction = null;
    selectedResult = ActionResult.none;
    notifyListeners();
  }

  @override
  void dispose() { _gameTimer?.cancel(); super.dispose(); }
}