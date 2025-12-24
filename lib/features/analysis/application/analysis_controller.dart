// lib/features/analysis/application/analysis_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../game_record/data/match_repository.dart';
import '../../settings/data/action_repository.dart';
import '../../team_mgmt/application/team_store.dart';
import '../../team_mgmt/domain/schema.dart';
import '../../team_mgmt/domain/roster_category.dart';
import '../../game_record/domain/models.dart';
import '../../settings/domain/action_definition.dart';
import '../domain/player_stats.dart';
import '../../team_mgmt/domain/team.dart';
import '../../team_mgmt/data/uniform_number_dao.dart';
import '../../team_mgmt/domain/uniform_number.dart';

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
  late final MatchRepository _matchRepository;
  late final ActionRepository _actionRepository;
  final UniformNumberDao _uniformDao = UniformNumberDao();

  List<ActionDefinition> actionDefinitions = [];

  AnalysisController(this.ref) : super(const AsyncValue.loading()) {
    _matchRepository = ref.read(matchRepositoryProvider);
    _actionRepository = ref.read(actionRepositoryProvider);
  }

  Future<void> addLog(String matchId, LogEntry log) async {
    // ログ追加時の背番号解決は、本来記録画面で行われるべきだが、
    // ここで補完する場合も最新の背番号ロジックを使う必要がある。
    // 簡易的にログ上の番号を信じる実装とする。
    final logMap = log.toJson();
    await _matchRepository.insertMatchLog(matchId, logMap);
  }

  Future<void> updateLog(String matchId, LogEntry log) async {
    final logMap = log.toJson();
    logMap['match_id'] = matchId;
    await _matchRepository.updateMatchLog(logMap);
  }

  Future<void> deleteLog(String logId) async {
    await _matchRepository.deleteMatchLog(logId);
  }

  Future<void> updateMatchInfo(String matchId, DateTime newDate, MatchType newType, {String? opponentName, String? opponentId, String? venueName, String? venueId, String? note}) async {
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
      final allMatches = await _matchRepository.getMatches(currentTeamId);
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

    final currentRecord = ref.read(selectedMatchRecordProvider);
    String? noteToSave = note ?? currentRecord?.note;

    await _matchRepository.updateBasicInfo(
        matchId: matchId,
        date: dateStr,
        opponent: newOpponentName,
        opponentId: finalOpponentId,
        venueName: venueName,
        venueId: finalVenueId,
        matchType: newType.index,
        note: noteToSave
    );

    await _loadSelectedMatchRecord(matchId);
  }

  /// 内部記録日時（created_at）を更新する
  Future<void> updateMatchCreationTime(String matchId, DateTime newTime) async {
    await _matchRepository.updateMatchCreatedAt(matchId, newTime.toIso8601String());
    // データを再読み込み
    await _loadSelectedMatchRecord(matchId);
  }

  Future<void> updateMatchResult(String matchId, MatchResult result, int? scoreOwn, int? scoreOpponent, bool isExtraTime, int? extraScoreOwn, int? extraScoreOpponent) async {
    await _matchRepository.updateMatchResult(
        matchId: matchId,
        result: result.index,
        scoreOwn: scoreOwn,
        scoreOpponent: scoreOpponent,
        isExtraTime: isExtraTime ? 1 : 0,
        extraScoreOwn: extraScoreOwn,
        extraScoreOpponent: extraScoreOpponent
    );
    await _loadSelectedMatchRecord(matchId);
  }

  Future<void> updateMatchMembers(String matchId, List<String> court, List<String> bench, List<String> absent) async {
    final team = ref.read(teamStoreProvider).currentTeam;
    if (team == null) return;

    // メンバー更新時、背番号からIDを逆引きするロジック
    // ここでは背番号とIDの対応表を、その試合日時点のデータで作成する必要がある
    // まず試合日を取得
    final matchRecord = await fetchMatchRecordById(matchId);
    if (matchRecord == null) return;

    final matchDate = DateTime.tryParse(matchRecord.date) ?? DateTime.now();
    final allUniforms = await _uniformDao.getUniformNumbersByTeam(team.id);

    // ID逆引き用マップ (Number -> ID)
    final numToIdMap = <String, String>{};
    for (var u in allUniforms) {
      // 試合日時点で有効なもの
      if (u.isActiveAt(matchDate)) {
        numToIdMap[u.number] = u.playerId;
      }
    }

    final List<Map<String, dynamic>> participations = [];

    void add(List<String> list, int status) {
      for (var num in list) {
        final playerId = numToIdMap[num] ?? ""; // IDが見つからなければ空文字（あるいはログ整合性のため要検討）
        participations.add({'player_number': num, 'player_id': playerId, 'status': status});
      }
    }

    add(court, 0);
    add(bench, 1);
    add(absent, 2);

    await _matchRepository.updateMatchParticipations(matchId, participations);
  }

  // IDからMatchRecordを単発取得するヘルパー
  Future<MatchRecord?> fetchMatchRecordById(String matchId) async {
    final team = ref.read(teamStoreProvider).currentTeam;
    if (team == null) return null;
    final matches = await _matchRepository.getMatches(team.id);
    final matchRow = matches.firstWhere((m) => m['id'] == matchId, orElse: () => {});
    if (matchRow.isEmpty) return null;
    return await _buildMatchRecordFromRow(matchId, matchRow);
  }

  Future<Map<String, int>> getMatchMemberStatus(String matchId) async {
    final rawList = await _matchRepository.getMatchParticipations(matchId);
    final Map<String, int> result = {};
    for (var m in rawList) {
      final num = m['player_number'] as String? ?? "";
      final status = m['status'] as int? ?? 0;
      if (num.isNotEmpty) {
        result[num] = status;
      }
    }
    return result;
  }

  Future<List<String>> getMatchMembers(String matchId) async {
    final statusMap = await getMatchMemberStatus(matchId);
    return statusMap.entries.where((e) => e.value == 0).map((e) => e.key).toList();
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

      final rawActions = await _actionRepository.getActionDefinitions(currentTeam.id);
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

    final rawActions = await _actionRepository.getActionDefinitions(currentTeam.id);
    actionDefinitions = rawActions.map((d) => ActionDefinition.fromMap(d)).toList();

    return await _calculateStats(currentTeam: currentTeam, startDateStr: period['start']!, endDateStr: period['end']!, matchId: matchId, targetTypes: targetTypes);
  }

  Future<List<MatchRecord>> fetchMatchRecordsByDate(int year, int month, int day) async {
    final currentTeam = ref.read(teamStoreProvider).currentTeam;
    if (currentTeam == null) return [];

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(year, month, day));
    final allMatches = await _matchRepository.getMatches(currentTeam.id);

    // ★修正: 日計ログ出力時、作成日時順（古い順）にソートする
    final matchesOnDate = allMatches.where((m) => m['date'] == dateStr).toList();
    matchesOnDate.sort((a, b) {
      final tA = a['created_at'] as String? ?? '';
      final tB = b['created_at'] as String? ?? '';
      return tA.compareTo(tB);
    });

    final List<MatchRecord> records = [];
    for (var matchRow in matchesOnDate) {
      final matchId = matchRow['id'] as String;
      final record = await _buildMatchRecordFromRow(matchId, matchRow);
      records.add(record);
    }
    return records;
  }

  Map<String, String> _determinePeriod(int? year, int? month, int? day, String? matchId) {
    String startDateStr;
    String endDateStr;
    final dateFormat = DateFormat('yyyy-MM-dd');
    if (matchId != null) { startDateStr = "2000-01-01"; endDateStr = "2099-12-31"; } else if (year == null) { startDateStr = "2000-01-01"; endDateStr = "2099-12-31"; } else if (month == null) { startDateStr = dateFormat.format(DateTime(year, 1, 1)); endDateStr = dateFormat.format(DateTime(year, 12, 31)); } else if (day == null) { startDateStr = dateFormat.format(DateTime(year, month, 1)); final nextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1); endDateStr = dateFormat.format(nextMonth.subtract(const Duration(days: 1))); } else { startDateStr = dateFormat.format(DateTime(year, month, day)); endDateStr = dateFormat.format(DateTime(year, month, day)); }
    return {'start': startDateStr, 'end': endDateStr};
  }

  Future<void> _updateAvailableFilters(String teamId, int? year, int? month, int? day, String? matchId) async {
    final allMatches = await _matchRepository.getMatches(teamId);
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
        // ★修正: 日計表示時、作成日時順（古い順）にソートしてリスト表示する
        var matches = allMatches.where((m) {
          final dateStr = m['date'] as String?;
          final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
          return date != null && date.year == year && date.month == month && date.day == day;
        }).toList();

        matches.sort((a, b) {
          final tA = a['created_at'] as String? ?? '';
          final tB = b['created_at'] as String? ?? '';
          return tA.compareTo(tB); // 昇順（古い順）
        });

        final matchMap = {for (var m in matches) m['id'] as String: m['opponent'] as String? ?? '(相手なし)'};
        ref.read(availableMatchesProvider.notifier).state = matchMap;
      }
    }
  }

  Future<void> _loadSelectedMatchRecord(String matchId) async {
    final matches = await _matchRepository.getMatches(ref.read(teamStoreProvider).currentTeam!.id);
    final matchRow = matches.firstWhere((m) => m['id'] == matchId, orElse: () => {});
    if (matchRow.isEmpty) return;
    final record = await _buildMatchRecordFromRow(matchId, matchRow);
    ref.read(selectedMatchRecordProvider.notifier).state = record;
  }

  Future<MatchRecord> _buildMatchRecordFromRow(String matchId, Map<String, dynamic> matchRow) async {
    final logRows = await _matchRepository.getMatchLogs(matchId);
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
        subActionId: logRow['sub_action_id'] as String?,
        type: LogType.values[logRow['log_type'] as int],
        result: ActionResult.values[logRow['result'] ?? 0],
      );
    }).toList();

    return MatchRecord(
      id: matchId,
      date: matchRow['date'] as String? ?? '',
      opponent: matchRow['opponent'] as String? ?? '',
      opponentId: matchRow['opponent_id'] as String?,
      venueName: matchRow['venue_name'] as String?,
      venueId: matchRow['venue_id'] as String?,
      logs: logs,
      matchType: MatchType.values[matchRow['match_type'] as int? ?? 0],
      result: MatchResult.values[matchRow['result'] ?? 0],
      scoreOwn: matchRow['score_own'],
      scoreOpponent: matchRow['score_opponent'],
      isExtraTime: (matchRow['is_extra_time'] ?? 0) == 1,
      extraScoreOwn: matchRow['extra_score_own'],
      extraScoreOpponent: matchRow['extra_score_opponent'],
      note: matchRow['note'] as String?,
      createdAt: matchRow['created_at'] as String?,
    );
  }

  Future<List<PlayerStats>> _calculateStats({required Team currentTeam, required String startDateStr, required String endDateStr, String? matchId, List<MatchType>? targetTypes}) async {
    final Map<String, PlayerStats> statsMap = {};

    // 名簿データの背番号フィールドを使わず、UniformNumberDaoを使用
    // 期間の「終了日」時点での背番号を、その選手の表示用番号として採用する
    final targetDate = DateTime.parse(endDateStr);
    final allUniforms = await _uniformDao.getUniformNumbersByTeam(currentTeam.id);

    // 名前のフィールドを探す
    String? courtNameFieldId; String? nameFieldId;
    for(var f in currentTeam.schema) {
      if(f.type == FieldType.courtName) courtNameFieldId = f.id;
      if(f.type == FieldType.personName) nameFieldId = f.id;
    }

    for (var item in currentTeam.items) {
      // 終了日時点で有効な背番号を取得
      UniformNumber? activeNum;
      try {
        activeNum = allUniforms.firstWhere((u) => u.playerId == item.id && u.isActiveAt(targetDate));
      } catch (_) {
        activeNum = null;
      }

      final num = activeNum?.number ?? ""; // なければ空

      String name = "";
      if (courtNameFieldId != null) name = item.data[courtNameFieldId]?.toString() ?? "";
      if (name.isEmpty && nameFieldId != null) { final n = item.data[nameFieldId]; if (n is Map) name = "${n['last'] ?? ''} ${n['first'] ?? ''}".trim(); }

      // 選手全員分を初期化（背番号がない選手も含む）
      statsMap[item.id] = PlayerStats(playerId: item.id, playerNumber: num, playerName: name, matchesPlayed: 0, actions: {});
    }

    final typeIndices = targetTypes?.map((t) => t.index).toList();

    // 試合数の集計
    final matchCounts = await _matchRepository.getPlayerMatchCounts(
        currentTeam.id, startDateStr, endDateStr, typeIndices, matchId
    );

    for (var row in matchCounts) {
      final pId = row['player_id'] as String? ?? "";
      final pNum = row['player_number'] as String? ?? "";
      final count = row['match_count'] as int;

      String targetKey = pId.isNotEmpty ? pId : "UNKNOWN_$pNum";

      if (statsMap.containsKey(targetKey)) {
        // マッチした選手がいれば、試合数を更新
        // (背番号は期間終了日時点のものを優先するが、ログにしか存在しない選手の場合はログの番号を使う)
        statsMap[targetKey] = statsMap[targetKey]!.copyWith(matchesPlayed: count);
      } else {
        // 名簿にない（削除された選手など）場合
        statsMap[targetKey] = PlayerStats(playerId: targetKey, playerNumber: pNum, playerName: "(未登録)", matchesPlayed: count, actions: {});
      }
    }

    // アクションごとの集計
    final actionStatsRows = await _matchRepository.getAggregatedActionStats(
        currentTeam.id, startDateStr, endDateStr, typeIndices, matchId
    );

    for (var row in actionStatsRows) {
      final pId = row['player_id'] as String? ?? "";
      final pNum = row['player_number'] as String? ?? "";
      final action = row['action'] as String;
      final resultVal = row['result'] as int;
      final count = row['count'] as int;
      final result = ActionResult.values[resultVal];

      String targetKey = pId.isNotEmpty ? pId : "UNKNOWN_$pNum";
      if (!statsMap.containsKey(targetKey)) {
        statsMap[targetKey] = PlayerStats(playerId: targetKey, playerNumber: pNum, playerName: "(未登録)", matchesPlayed: 0, actions: {});
      }

      final currentStats = statsMap[targetKey]!;
      final actStats = currentStats.actions[action] ?? ActionStats(actionName: action);

      int success = actStats.successCount;
      int failure = actStats.failureCount;
      int total = actStats.totalCount;

      if (result == ActionResult.success) success += count;
      if (result == ActionResult.failure) failure += count;
      total += count;

      final newActStats = actStats.copyWith(successCount: success, failureCount: failure, totalCount: total);
      final newActions = Map<String, ActionStats>.from(currentStats.actions);
      newActions[action] = newActStats;
      statsMap[targetKey] = currentStats.copyWith(actions: newActions);
    }

    // サブアクション集計
    final subActionRows = await _matchRepository.getAggregatedSubActionStats(
        currentTeam.id, startDateStr, endDateStr, typeIndices, matchId
    );

    for (var row in subActionRows) {
      final pId = row['player_id'] as String? ?? "";
      final pNum = row['player_number'] as String? ?? "";
      final action = row['action'] as String;
      final subAction = row['sub_action'] as String;
      final count = row['count'] as int;

      String targetKey = pId.isNotEmpty ? pId : "UNKNOWN_$pNum";
      if (!statsMap.containsKey(targetKey)) continue;

      final currentStats = statsMap[targetKey]!;
      final actStats = currentStats.actions[action];
      if (actStats == null) continue;

      final newSubCounts = Map<String, int>.from(actStats.subActionCounts);
      newSubCounts[subAction] = (newSubCounts[subAction] ?? 0) + count;

      final newActStats = actStats.copyWith(subActionCounts: newSubCounts);
      final newActions = Map<String, ActionStats>.from(currentStats.actions);
      newActions[action] = newActStats;
      statsMap[targetKey] = currentStats.copyWith(actions: newActions);
    }

    final List<PlayerStats> resultList = statsMap.values.toList();
    // 背番号でソート
    resultList.sort((a, b) { final numA = int.tryParse(a.playerNumber); final numB = int.tryParse(b.playerNumber); if (numA != null && numB != null) return numA.compareTo(numB); if (numA != null) return -1; if (numB != null) return 1; return a.playerNumber.compareTo(b.playerNumber); });
    return resultList;
  }
}