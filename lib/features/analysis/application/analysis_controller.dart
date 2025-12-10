// lib/features/analysis/application/analysis_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../game_record/data/match_dao.dart';
import '../../team_mgmt/application/team_store.dart';
import '../../team_mgmt/domain/schema.dart';
import '../../team_mgmt/domain/roster_category.dart';
import '../../game_record/domain/models.dart';
import '../../settings/data/action_dao.dart';
import '../../settings/domain/action_definition.dart';
import '../domain/player_stats.dart';
import '../../team_mgmt/domain/team.dart';

final availableYearsProvider = StateProvider<List<int>>((ref) => []);
final availableMonthsProvider = StateProvider<List<int>>((ref) => []);
final availableDaysProvider = StateProvider<List<int>>((ref) => []);
final availableMatchesProvider = StateProvider<Map<String, String>>((ref) => {});
final selectedMatchRecordProvider = StateProvider<MatchRecord?>((ref) => null);

final analysisControllerProvider = StateNotifierProvider.autoDispose<AnalysisController, AsyncValue<List<PlayerStats>>>((ref) {
  return AnalysisController(ref);
});

class AnalysisController extends StateNotifier<AsyncValue<List<PlayerStats>>> {
  final Ref ref;
  final MatchDao _matchDao = MatchDao();
  final ActionDao _actionDao = ActionDao();

  List<ActionDefinition> actionDefinitions = [];

  AnalysisController(this.ref) : super(const AsyncValue.loading());

  Future<void> addLog(String matchId, LogEntry log) async {
    if (log.playerId == null || log.playerId!.isEmpty) {
      log.playerId = _findPlayerIdByNumber(log.playerNumber);
    }
    final logMap = log.toJson();
    await _matchDao.insertMatchLog(matchId, logMap);
  }

  Future<void> updateLog(String matchId, LogEntry log) async {
    if (log.playerId == null || log.playerId!.isEmpty) {
      log.playerId = _findPlayerIdByNumber(log.playerNumber);
    }
    final logMap = log.toJson();
    logMap['match_id'] = matchId;
    await _matchDao.updateMatchLog(logMap);
  }

  Future<void> deleteLog(String logId) async {
    await _matchDao.deleteMatchLog(logId);
  }

  String? _findPlayerIdByNumber(String number) {
    final team = ref.read(teamStoreProvider).currentTeam;
    if (team == null) return null;
    final numField = team.schema.firstWhere((f) => f.type == FieldType.uniformNumber, orElse: () => team.schema.first);
    for (var item in team.items) {
      if (item.data[numField.id]?.toString() == number) {
        return item.id;
      }
    }
    return null;
  }

  Future<void> updateMatchInfo(String matchId, DateTime newDate, MatchType newType, {String? opponentName, String? opponentId, String? venueName, String? venueId}) async {
    final teamStore = ref.read(teamStoreProvider);
    final currentTeamId = teamStore.currentTeam?.id;
    if (currentTeamId == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(newDate);
    String? finalOpponentId = opponentId;
    String? finalVenueId = venueId;
    if (opponentName != null && opponentName.isNotEmpty && (finalOpponentId == null || finalOpponentId.isEmpty)) {
      finalOpponentId = await teamStore.ensureItemExists(opponentName, RosterCategory.opponent);
    }
    if (venueName != null && venueName.isNotEmpty && (finalVenueId == null || finalVenueId.isEmpty)) {
      finalVenueId = await teamStore.ensureItemExists(venueName, RosterCategory.venue);
    }
    String newOpponentName = opponentName ?? "";
    if (newOpponentName.isEmpty) {
      final allMatches = await _matchDao.getMatches(currentTeamId);
      final matchesOnTargetDate = allMatches.where((m) => m['date'] == dateStr && m['id'] != matchId).toList();
      final regex = RegExp(r'^試合-.* #(\d+)$');
      final existingNumbers = <int>{};
      for (var m in matchesOnTargetDate) {
        final op = m['opponent'] as String? ?? "";
        final match = regex.firstMatch(op);
        if (match != null) existingNumbers.add(int.parse(match.group(1)!));
      }
      int newNum = 1;
      while (existingNumbers.contains(newNum)) newNum++;
      newOpponentName = "試合-$dateStr #$newNum";
    }
    await _matchDao.updateMatchInfo(matchId: matchId, newDate: dateStr, newOpponent: newOpponentName, newOpponentId: finalOpponentId, newVenueName: venueName, newVenueId: finalVenueId, newMatchType: newType.index);
    await _loadSelectedMatchRecord(matchId);
  }

  Future<void> updateMatchResult(String matchId, MatchResult result, int? scoreOwn, int? scoreOpponent, bool isExtraTime, int? extraScoreOwn, int? extraScoreOpponent) async {
    final currentRecord = ref.read(selectedMatchRecordProvider);
    if (currentRecord == null || currentRecord.id != matchId) return;
    await _matchDao.updateMatchInfo(matchId: matchId, newDate: currentRecord.date, newOpponent: currentRecord.opponent, newOpponentId: currentRecord.opponentId, newVenueName: currentRecord.venueName, newVenueId: currentRecord.venueId, newMatchType: currentRecord.matchType.index, result: result.index, scoreOwn: scoreOwn, scoreOpponent: scoreOpponent, isExtraTime: isExtraTime ? 1 : 0, extraScoreOwn: extraScoreOwn, extraScoreOpponent: extraScoreOpponent);
    await _loadSelectedMatchRecord(matchId);
  }

  Future<void> updateMatchMembers(String matchId, List<String> playerNumbers) async {
    final team = ref.read(teamStoreProvider).currentTeam;
    if (team == null) return;
    final List<Map<String, String>> participations = [];
    final numField = team.schema.firstWhere((f) => f.type == FieldType.uniformNumber, orElse: () => team.schema.first);
    for (var num in playerNumbers) {
      String playerId = "";
      try {
        final item = team.items.firstWhere((i) => i.data[numField.id]?.toString() == num);
        playerId = item.id;
      } catch (_) {}
      participations.add({'player_number': num, 'player_id': playerId});
    }
    await _matchDao.updateMatchParticipations(matchId, participations);
  }

  Future<List<String>> getMatchMembers(String matchId) async {
    final rawList = await _matchDao.getMatchParticipations(matchId);
    return rawList.map((m) => m['player_number'] as String? ?? "").where((s) => s.isNotEmpty).toList();
  }

  Future<void> analyze({int? year, int? month, int? day, String? matchId, List<MatchType>? targetTypes}) async {
    try {
      state = const AsyncValue.loading();
      await Future.delayed(const Duration(milliseconds: 50));
      ref.read(selectedMatchRecordProvider.notifier).state = null;
      final teamStore = ref.read(teamStoreProvider);
      if (!teamStore.isLoaded) await teamStore.loadFromDb();
      final currentTeam = teamStore.currentTeam;
      if (currentTeam == null) {
        state = const AsyncValue.data([]);
        return;
      }
      final period = _determinePeriod(year, month, day, matchId);
      await _updateAvailableFilters(currentTeam.id, year, month, day, matchId);

      final rawActions = await _actionDao.getActionDefinitions(currentTeam.id);
      actionDefinitions = rawActions.map((d) => ActionDefinition.fromMap(d)).toList();

      if (matchId != null) {
        await _loadSelectedMatchRecord(matchId);
      }
      final resultList = await _calculateStats(currentTeam: currentTeam, startDateStr: period['start']!, endDateStr: period['end']!, matchId: matchId, targetTypes: targetTypes);
      state = AsyncValue.data(resultList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<PlayerStats>> fetchStatsForExport({int? year, int? month, int? day, String? matchId, List<MatchType>? targetTypes}) async {
    final teamStore = ref.read(teamStoreProvider);
    final currentTeam = teamStore.currentTeam;
    if (currentTeam == null) return [];
    final period = _determinePeriod(year, month, day, matchId);
    final rawActions = await _actionDao.getActionDefinitions(currentTeam.id);
    actionDefinitions = rawActions.map((d) => ActionDefinition.fromMap(d)).toList();
    return await _calculateStats(currentTeam: currentTeam, startDateStr: period['start']!, endDateStr: period['end']!, matchId: matchId, targetTypes: targetTypes);
  }

  Map<String, String> _determinePeriod(int? year, int? month, int? day, String? matchId) {
    String startDateStr;
    String endDateStr;
    final dateFormat = DateFormat('yyyy-MM-dd');
    if (matchId != null) { startDateStr = "2000-01-01"; endDateStr = "2099-12-31"; } else if (year == null) { startDateStr = "2000-01-01"; endDateStr = "2099-12-31"; } else if (month == null) { startDateStr = dateFormat.format(DateTime(year, 1, 1)); endDateStr = dateFormat.format(DateTime(year, 12, 31)); } else if (day == null) { startDateStr = dateFormat.format(DateTime(year, month, 1)); final nextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1); endDateStr = dateFormat.format(nextMonth.subtract(const Duration(days: 1))); } else { startDateStr = dateFormat.format(DateTime(year, month, day)); endDateStr = dateFormat.format(DateTime(year, month, day)); }
    return {'start': startDateStr, 'end': endDateStr};
  }

  Future<void> _updateAvailableFilters(String teamId, int? year, int? month, int? day, String? matchId) async {
    final allMatches = await _matchDao.getMatches(teamId);
    if (year == null) {
      final years = allMatches.map((m) { final dateStr = m['date'] as String?; return dateStr != null ? DateTime.tryParse(dateStr)?.year : null; }).whereType<int>().toSet().toList()..sort((a, b) => b.compareTo(a));
      ref.read(availableYearsProvider.notifier).state = years; ref.read(availableMonthsProvider.notifier).state = []; ref.read(availableDaysProvider.notifier).state = []; ref.read(availableMatchesProvider.notifier).state = {};
    } else if (month == null) {
      final months = allMatches.where((m) { final dateStr = m['date'] as String?; final date = dateStr != null ? DateTime.tryParse(dateStr) : null; return date != null && date.year == year; }).map((m) => DateTime.tryParse(m['date'] as String? ?? '')?.month).whereType<int>().toSet().toList()..sort((a, b) => b.compareTo(a));
      ref.read(availableMonthsProvider.notifier).state = months; ref.read(availableDaysProvider.notifier).state = []; ref.read(availableMatchesProvider.notifier).state = {};
    } else if (day == null) {
      final days = allMatches.where((m) { final dateStr = m['date'] as String?; final date = dateStr != null ? DateTime.tryParse(dateStr) : null; return date != null && date.year == year && date.month == month; }).map((m) => DateTime.tryParse(m['date'] as String? ?? '')?.day).whereType<int>().toSet().toList()..sort((a, b) => b.compareTo(a));
      ref.read(availableDaysProvider.notifier).state = days; ref.read(availableMatchesProvider.notifier).state = {};
    } else {
      if (year != null && month != null && day != null) {
        final matches = allMatches.where((m) { final dateStr = m['date'] as String?; final date = dateStr != null ? DateTime.tryParse(dateStr) : null; return date != null && date.year == year && date.month == month && date.day == day; });
        final matchMap = {for (var m in matches) m['id'] as String: m['opponent'] as String? ?? '(相手なし)'};
        ref.read(availableMatchesProvider.notifier).state = matchMap;
      }
    }
  }

  Future<void> _loadSelectedMatchRecord(String matchId) async {
    final matches = await _matchDao.getMatches(ref.read(teamStoreProvider).currentTeam!.id);
    final matchRow = matches.firstWhere((m) => m['id'] == matchId, orElse: () => {});
    if (matchRow.isEmpty) return;
    final logRows = await _matchDao.getMatchLogs(matchId);
    final logs = logRows.map((logRow) {
      return LogEntry(
        id: logRow['id'] as String,
        matchDate: matchRow['date'] as String? ?? '',
        opponent: matchRow['opponent'] as String? ?? '',
        gameTime: logRow['game_time'] as String,
        playerNumber: logRow['player_number'] as String,
        playerId: logRow['player_id'] as String?,
        action: logRow['action'] as String,
        subAction: logRow['sub_action'] as String?,
        subActionId: logRow['sub_action_id'] as String?, // ★追加
        type: LogType.values[logRow['log_type'] as int],
        result: ActionResult.values[logRow['result'] ?? 0],
      );
    }).toList();
    final record = MatchRecord(
      id: matchId, date: matchRow['date'] as String? ?? '', opponent: matchRow['opponent'] as String? ?? '', opponentId: matchRow['opponent_id'] as String?, venueName: matchRow['venue_name'] as String?, venueId: matchRow['venue_id'] as String?, logs: logs, matchType: MatchType.values[matchRow['match_type'] as int? ?? 0], result: MatchResult.values[matchRow['result'] ?? 0], scoreOwn: matchRow['score_own'], scoreOpponent: matchRow['score_opponent'], isExtraTime: (matchRow['is_extra_time'] ?? 0) == 1, extraScoreOwn: matchRow['extra_score_own'], extraScoreOpponent: matchRow['extra_score_opponent'],
    );
    ref.read(selectedMatchRecordProvider.notifier).state = record;
  }

  Future<List<PlayerStats>> _calculateStats({required Team currentTeam, required String startDateStr, required String endDateStr, String? matchId, List<MatchType>? targetTypes}) async {
    final Map<String, PlayerStats> statsMap = {};
    final numberToIdMap = <String, String>{};
    String? numberFieldId; String? courtNameFieldId; String? nameFieldId;
    for(var f in currentTeam.schema) { if(f.type == FieldType.uniformNumber) numberFieldId = f.id; if(f.type == FieldType.courtName) courtNameFieldId = f.id; if(f.type == FieldType.personName) nameFieldId = f.id; }
    for (var item in currentTeam.items) {
      final num = item.data[numberFieldId]?.toString() ?? "";
      String name = "";
      if (courtNameFieldId != null) name = item.data[courtNameFieldId]?.toString() ?? "";
      if (name.isEmpty && nameFieldId != null) { final n = item.data[nameFieldId]; if (n is Map) name = "${n['last'] ?? ''} ${n['first'] ?? ''}".trim(); }
      statsMap[item.id] = PlayerStats(playerId: item.id, playerNumber: num, playerName: name, matchesPlayed: 0, actions: {});
      if (num.isNotEmpty) numberToIdMap[num] = item.id;
    }
    final typeIndices = targetTypes?.map((t) => t.index).toList();
    final List<Map<String, dynamic>> rawLogs;
    if (matchId != null) { rawLogs = await _matchDao.getMatchLogs(matchId); } else { rawLogs = await _matchDao.getLogsInPeriod(currentTeam.id, startDateStr, endDateStr, typeIndices); }
    final Map<String, Set<String>> playerMatches = {};

    for (var log in rawLogs) {
      String pId = log['player_id'] as String? ?? "";
      final pNum = log['player_number'] as String? ?? "";
      if (pId.isEmpty && pNum.isEmpty) continue;
      if (pId.isEmpty && pNum.isNotEmpty && numberToIdMap.containsKey(pNum)) { pId = numberToIdMap[pNum]!; await _matchDao.updateLogPlayerId(log['id'] as String, pId); }
      String targetKey = pId.isNotEmpty ? pId : "UNKNOWN_$pNum";
      if (!statsMap.containsKey(targetKey)) {
        String displayName = "(未登録)";
        if (!targetKey.startsWith("UNKNOWN_")) displayName = "(削除済)";
        statsMap[targetKey] = PlayerStats(playerId: targetKey, playerNumber: pNum, playerName: displayName, actions: {});
      }
      final matchIdKey = log['match_id'] as String? ?? "";
      if (matchIdKey.isNotEmpty) { if (!playerMatches.containsKey(targetKey)) playerMatches[targetKey] = {}; playerMatches[targetKey]!.add(matchIdKey); }

      final action = log['action'] as String? ?? "";
      final subActionName = log['sub_action'] as String? ?? ""; // 集計は名前ベースで行う（IDだと変更に強いが、表示用には名前が必要なため）
      final resultVal = log['result'] as int? ?? 0;
      final result = ActionResult.values[resultVal];

      final currentStats = statsMap[targetKey]!;
      final actStats = currentStats.actions[action] ?? ActionStats(actionName: action);
      int success = actStats.successCount;
      int failure = actStats.failureCount;
      int total = actStats.totalCount;
      if (result == ActionResult.success) success++;
      if (result == ActionResult.failure) failure++;
      total++;

      // サブアクション集計
      final Map<String, int> subCounts = Map.from(actStats.subActionCounts);
      if (subActionName.isNotEmpty) {
        subCounts[subActionName] = (subCounts[subActionName] ?? 0) + 1;
      }

      final newActStats = actStats.copyWith(successCount: success, failureCount: failure, totalCount: total, subActionCounts: subCounts);
      final newActions = Map<String, ActionStats>.from(currentStats.actions);
      newActions[action] = newActStats;
      statsMap[targetKey] = currentStats.copyWith(actions: newActions);
    }

    final List<Map<String, dynamic>> participations;
    if (matchId != null) { participations = await _matchDao.getMatchParticipations(matchId); } else { participations = await _matchDao.getParticipationsInPeriod(currentTeam.id, startDateStr, endDateStr, typeIndices); }
    for (var p in participations) {
      String pId = p['player_id'] as String? ?? "";
      final pNum = p['player_number'] as String? ?? "";
      final mid = p['match_id'] as String? ?? "";
      if (mid.isEmpty) continue;
      if (pId.isEmpty && pNum.isNotEmpty && numberToIdMap.containsKey(pNum)) { pId = numberToIdMap[pNum]!; await _matchDao.updateParticipationPlayerId(mid, pNum, pId); }
      String targetKey = pId.isNotEmpty ? pId : "UNKNOWN_$pNum";
      if (!statsMap.containsKey(targetKey)) { statsMap[targetKey] = PlayerStats(playerId: targetKey, playerNumber: pNum, playerName: "(未登録)", actions: {}); }
      if (!playerMatches.containsKey(targetKey)) playerMatches[targetKey] = {};
      playerMatches[targetKey]!.add(mid);
    }

    final List<PlayerStats> resultList = statsMap.values.map((p) { return p.copyWith(matchesPlayed: playerMatches[p.playerId]?.length ?? 0); }).toList();
    resultList.sort((a, b) { final numA = int.tryParse(a.playerNumber); final numB = int.tryParse(b.playerNumber); if (numA != null && numB != null) return numA.compareTo(numB); if (numA != null) return -1; if (numB != null) return 1; return a.playerNumber.compareTo(b.playerNumber); });
    return resultList;
  }
}