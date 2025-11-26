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
import '../presentation/pages/analysis_screen.dart';

final analysisControllerProvider = StateNotifierProvider<AnalysisController, AsyncValue<List<PlayerStats>>>((ref) {
  return AnalysisController(ref);
});

class AnalysisController extends StateNotifier<AsyncValue<List<PlayerStats>>> {
  final Ref ref;
  final MatchDao _matchDao = MatchDao();
  final ActionDao _actionDao = ActionDao();

  List<ActionDefinition> actionDefinitions = [];

  AnalysisController(this.ref) : super(const AsyncValue.loading());

  Future<void> analyze(AnalysisPeriod period, DateTime start, DateTime end) async {
    try {
      state = const AsyncValue.loading();

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

      if (period == AnalysisPeriod.total) {
        startDateStr = "2000-01-01";
        endDateStr = "2099-12-31";
      } else {
        startDateStr = dateFormat.format(start);
        endDateStr = dateFormat.format(end);
      }

      final rawActions = await _actionDao.getActionDefinitions(currentTeam.id);
      actionDefinitions = rawActions.map((d) => ActionDefinition.fromMap(d)).toList();

      final Map<String, PlayerStats> statsMap = {};

      String? numberFieldId;
      String? courtNameFieldId;
      String? nameFieldId;
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
            if (n is Map) name = "${n['last']} ${n['first']}";
          }
          statsMap[num] = PlayerStats(
            playerId: num,
            playerNumber: num,
            playerName: name,
            matchesPlayed: 0,
            actions: {},
          );
        }
      }

      // ★修正: 出場記録による試合数カウント
      final participations = await _matchDao.getParticipationsInPeriod(currentTeam.id, startDateStr, endDateStr);
      final Map<String, Set<String>> playerMatches = {};

      for (var p in participations) {
        final pNum = p['player_number'] as String;
        if (statsMap.containsKey(pNum)) {
          if (!playerMatches.containsKey(pNum)) playerMatches[pNum] = {};
          playerMatches[pNum]!.add(p['match_id']);
        }
      }

      final rawLogs = await _matchDao.getLogsInPeriod(currentTeam.id, startDateStr, endDateStr);

      for (var log in rawLogs) {
        final pNum = log['player_number'] as String;
        if (pNum.isEmpty) continue;

        if (!statsMap.containsKey(pNum)) {
          statsMap[pNum] = PlayerStats(playerId: pNum, playerNumber: pNum, playerName: "(未登録)", actions: {});
        }

        // ログがあるなら試合出場とみなす（念のため）
        if (!playerMatches.containsKey(pNum)) playerMatches[pNum] = {};
        playerMatches[pNum]!.add(log['match_id']);

        final action = log['action'] as String;
        final subAction = log['sub_action'] as String?;
        final resultVal = log['result'] as int? ?? 0;
        final result = ActionResult.values[resultVal];

        final currentStats = statsMap[pNum]!;
        final actStats = currentStats.actions[action] ?? ActionStats(actionName: action);

        int success = actStats.successCount;
        int failure = actStats.failureCount;
        int total = actStats.totalCount;

        final Map<String, int> subs = Map.from(actStats.subActionCounts);
        if (subAction != null && subAction.isNotEmpty) {
          subs[subAction] = (subs[subAction] ?? 0) + 1;
        }

        if (result == ActionResult.success) success++;
        if (result == ActionResult.failure) failure++;
        total++;

        final newActStats = actStats.copyWith(
          successCount: success,
          failureCount: failure,
          totalCount: total,
          subActionCounts: subs,
        );

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