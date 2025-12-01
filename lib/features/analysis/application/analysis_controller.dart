// lib/features/analysis/application/analysis_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../game_record/data/match_dao.dart';
import '../../team_mgmt/application/team_store.dart';
import '../../team_mgmt/domain/schema.dart';
import '../../game_record/domain/models.dart';
import '../../settings/data/action_dao.dart';
import '../../settings/domain/action_definition.dart';
import '../domain/player_stats.dart';

// プロバイダー定義 (変更なし)
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

  // ★追加: ログ操作メソッド
  Future<void> addLog(String matchId, LogEntry log) async {
    final logMap = log.toJson();
    await _matchDao.insertMatchLog(matchId, logMap);
  }

  Future<void> updateLog(String matchId, LogEntry log) async {
    final logMap = log.toJson();
    logMap['match_id'] = matchId; // 更新時の整合性チェック用
    await _matchDao.updateMatchLog(logMap);
  }

  Future<void> deleteLog(String logId) async {
    await _matchDao.deleteMatchLog(logId);
  }

  // analyzeメソッド (変更なし)
  Future<void> analyze({int? year, int? month, int? day, String? matchId}) async {
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

      String startDateStr;
      String endDateStr;
      final dateFormat = DateFormat('yyyy-MM-dd');

      if (matchId != null) {
        startDateStr = "2000-01-01";
        endDateStr = "2099-12-31";
      } else if (year == null) {
        startDateStr = "2000-01-01";
        endDateStr = "2099-12-31";
      } else if (month == null) {
        startDateStr = dateFormat.format(DateTime(year, 1, 1));
        endDateStr = dateFormat.format(DateTime(year, 12, 31));
      } else if (day == null) {
        startDateStr = dateFormat.format(DateTime(year, month, 1));
        final nextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
        endDateStr = dateFormat.format(nextMonth.subtract(const Duration(days: 1)));
      } else {
        startDateStr = dateFormat.format(DateTime(year, month, day));
        endDateStr = dateFormat.format(DateTime(year, month, day));
      }

      final allMatches = await _matchDao.getMatches(currentTeam.id);

      if (year == null) {
        final years = allMatches.map((m) {
          final dateStr = m['date'] as String?;
          return dateStr != null ? DateTime.tryParse(dateStr)?.year : null;
        }).whereType<int>().toSet().toList()..sort((a, b) => b.compareTo(a));
        ref.read(availableYearsProvider.notifier).state = years;
        ref.read(availableMonthsProvider.notifier).state = [];
        ref.read(availableDaysProvider.notifier).state = [];
        ref.read(availableMatchesProvider.notifier).state = {};
      } else if (month == null) {
        final months = allMatches.where((m) {
          final dateStr = m['date'] as String?;
          final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
          return date != null && date.year == year;
        }).map((m) => DateTime.tryParse(m['date'] as String? ?? '')?.month).whereType<int>().toSet().toList()..sort((a, b) => b.compareTo(a));
        ref.read(availableMonthsProvider.notifier).state = months;
        ref.read(availableDaysProvider.notifier).state = [];
        ref.read(availableMatchesProvider.notifier).state = {};
      } else if (day == null) {
        final days = allMatches.where((m) {
          final dateStr = m['date'] as String?;
          final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
          return date != null && date.year == year && date.month == month;
        }).map((m) => DateTime.tryParse(m['date'] as String? ?? '')?.day).whereType<int>().toSet().toList()..sort((a, b) => b.compareTo(a));
        ref.read(availableDaysProvider.notifier).state = days;
        ref.read(availableMatchesProvider.notifier).state = {};
      } else if (matchId == null) {
        final matches = allMatches.where((m) {
          final dateStr = m['date'] as String?;
          final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
          return date != null && date.year == year && date.month == month && date.day == day;
        });
        final matchMap = {for (var m in matches) m['id'] as String: m['opponent'] as String? ?? '(相手なし)'};
        ref.read(availableMatchesProvider.notifier).state = matchMap;
      }

      final rawActions = await _actionDao.getActionDefinitions(currentTeam.id);
      actionDefinitions = rawActions.map((d) => ActionDefinition.fromMap(d)).toList();

      final Map<String, PlayerStats> statsMap = {};
      final rosterMap = <String, String>{};

      String? numberFieldId; String? courtNameFieldId; String? nameFieldId;
      for(var f in currentTeam.schema) {
        if(f.type == FieldType.uniformNumber) numberFieldId = f.id;
        if(f.type == FieldType.courtName) courtNameFieldId = f.id;
        if(f.type == FieldType.personName) nameFieldId = f.id;
      }

      for (var item in currentTeam.items) {
        final num = item.data[numberFieldId]?.toString() ?? "";
        if (num.isNotEmpty) {
          String name = "";
          if (courtNameFieldId != null) name = item.data[courtNameFieldId]?.toString() ?? "";
          if (name.isEmpty && nameFieldId != null) {
            final n = item.data[nameFieldId];
            if (n is Map) name = "${n['last'] ?? ''} ${n['first'] ?? ''}".trim();
          }
          rosterMap[num] = name;
          statsMap[num] = PlayerStats(playerId: num, playerNumber: num, playerName: name, matchesPlayed: 0, actions: {});
        }
      }

      if (matchId != null) {
        final matchRow = allMatches.firstWhere((m) => m['id'] == matchId);
        final logRows = await _matchDao.getMatchLogs(matchId); // 修正済みのgetMatchLogs

        final logs = logRows.map((logRow) {
          return LogEntry(
            id: logRow['id'] as String,
            matchDate: matchRow['date'] as String? ?? '',
            opponent: matchRow['opponent'] as String? ?? '',
            gameTime: logRow['game_time'] as String,
            playerNumber: logRow['player_number'] as String,
            action: logRow['action'] as String,
            subAction: logRow['sub_action'] as String?,
            type: LogType.values[logRow['log_type'] as int],
            result: ActionResult.values[logRow['result'] ?? 0],
          );
        }).toList();

        final record = MatchRecord(id: matchId, date: matchRow['date'] as String? ?? '', opponent: matchRow['opponent'] as String? ?? '', logs: logs);
        ref.read(selectedMatchRecordProvider.notifier).state = record;
      }

      final List<Map<String, dynamic>> participations;
      if (matchId != null) {
        final logs = ref.read(selectedMatchRecordProvider.notifier).state?.logs;
        if (logs != null) {
          final playerNumbers = logs.map((e) => e.playerNumber).toSet();
          participations = playerNumbers.map((pNum) => {'player_number': pNum, 'match_id': matchId}).toList();
        } else {
          participations = [];
        }
      } else {
        participations = await _matchDao.getParticipationsInPeriod(currentTeam.id, startDateStr, endDateStr);
      }

      final Map<String, Set<String>> playerMatches = {};
      for (var p in participations) {
        final pNum = p['player_number'] as String? ?? "";
        final matchIdKey = p['match_id'] as String? ?? "";
        if (pNum.isNotEmpty && matchIdKey.isNotEmpty) {
          if (!playerMatches.containsKey(pNum)) playerMatches[pNum] = {};
          playerMatches[pNum]!.add(matchIdKey);
          if (!statsMap.containsKey(pNum)) {
            statsMap[pNum] = PlayerStats(playerId: pNum, playerNumber: pNum, playerName: rosterMap[pNum] ?? "(不明)", matchesPlayed: 0, actions: {});
          }
        }
      }

      final List<Map<String, dynamic>> rawLogs;
      if (matchId != null) {
        rawLogs = await _matchDao.getMatchLogs(matchId);
      } else {
        rawLogs = await _matchDao.getLogsInPeriod(currentTeam.id, startDateStr, endDateStr);
      }

      for (var log in rawLogs) {
        final pNum = log['player_number'] as String? ?? "";
        if (pNum.isEmpty) continue;

        if (!statsMap.containsKey(pNum)) statsMap[pNum] = PlayerStats(playerId: pNum, playerNumber: pNum, playerName: "(未登録)", actions: {});

        final matchIdKey = log['match_id'] as String? ?? "";
        if (matchIdKey.isNotEmpty) {
          if (!playerMatches.containsKey(pNum)) playerMatches[pNum] = {};
          playerMatches[pNum]!.add(matchIdKey);
        }

        final action = log['action'] as String? ?? "";
        final subAction = log['sub_action'] as String?;
        final resultVal = log['result'] as int? ?? 0;
        final result = ActionResult.values[resultVal];

        final currentStats = statsMap[pNum]!;
        final actStats = currentStats.actions[action] ?? ActionStats(actionName: action);

        int success = actStats.successCount;
        int failure = actStats.failureCount;
        int total = actStats.totalCount;
        final Map<String, int> subs = Map.from(actStats.subActionCounts);
        if (subAction != null && subAction.isNotEmpty) subs[subAction] = (subs[subAction] ?? 0) + 1;

        if (result == ActionResult.success) success++;
        if (result == ActionResult.failure) failure++;
        total++;

        final newActStats = actStats.copyWith(successCount: success, failureCount: failure, totalCount: total, subActionCounts: subs);
        final newActions = Map<String, ActionStats>.from(currentStats.actions);
        newActions[action] = newActStats;
        statsMap[pNum] = currentStats.copyWith(actions: newActions);
      }

      final List<PlayerStats> resultList = statsMap.values.map((p) {
        return p.copyWith(matchesPlayed: playerMatches[p.playerNumber]?.length ?? 0);
      }).toList();

      resultList.sort((a, b) => (int.tryParse(a.playerNumber) ?? 999).compareTo(int.tryParse(b.playerNumber) ?? 999));
      state = AsyncValue.data(resultList);

    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}