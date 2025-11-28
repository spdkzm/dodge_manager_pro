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

// 存在する年リストを保持するプロバイダー
final availableYearsProvider = StateProvider<List<int>>((ref) => []);
// 存在する月リストを保持するプロバイダー (1〜12)
final availableMonthsProvider = StateProvider<List<int>>((ref) => []);
// 存在する日リストを保持するプロバイダー (1〜31)
final availableDaysProvider = StateProvider<List<int>>((ref) => []);
// 存在する試合IDと対戦相手名のマップを保持するプロバイダー (ID -> Name)
final availableMatchesProvider = StateProvider<Map<String, String>>((ref) => {});

// ★追加: 選択された試合のMatchRecordを保持するプロバイダー
final selectedMatchRecordProvider = StateProvider<MatchRecord?>((ref) => null);

final analysisControllerProvider = StateNotifierProvider<AnalysisController, AsyncValue<List<PlayerStats>>>((ref) {
  return AnalysisController(ref);
});

class AnalysisController extends StateNotifier<AsyncValue<List<PlayerStats>>> {
  final Ref ref;
  final MatchDao _matchDao = MatchDao();
  final ActionDao _actionDao = ActionDao();

  List<ActionDefinition> actionDefinitions = [];

  AnalysisController(this.ref) : super(const AsyncValue.loading());

  // ★修正: analyze メソッドに String? matchId を追加
  Future<void> analyze({int? year, int? month, int? day, String? matchId}) async {
    try {
      state = const AsyncValue.loading();
      ref.read(selectedMatchRecordProvider.notifier).state = null; // 毎回リセット

      final teamStore = ref.read(teamStoreProvider);
      if (!teamStore.isLoaded) await teamStore.loadFromDb();
      final currentTeam = teamStore.currentTeam;

      if (currentTeam == null) {
        state = const AsyncValue.data([]);
        return;
      }

      // 1. 期間設定 (年/月/日フィルタに対応)
      String startDateStr;
      String endDateStr;
      final dateFormat = DateFormat('yyyy-MM-dd');

      // matchIdが指定されている場合は日付フィルタは使用しない
      if (matchId != null) {
        startDateStr = "2000-01-01";
        endDateStr = "2099-12-31";
      } else if (year == null) {
        // 累計
        startDateStr = "2000-01-01";
        endDateStr = "2099-12-31";
      } else if (month == null) {
        // 年累計
        startDateStr = dateFormat.format(DateTime(year!, 1, 1));
        endDateStr = dateFormat.format(DateTime(year, 12, 31));
      } else if (day == null) {
        // 月累計
        startDateStr = dateFormat.format(DateTime(year!, month!, 1));

        // 翌月1日の前日を endDateStr とする
        final nextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month! + 1, 1);
        endDateStr = dateFormat.format(nextMonth.subtract(const Duration(days: 1)));
      } else {
        // 日累計
        startDateStr = dateFormat.format(DateTime(year!, month!, day!));
        endDateStr = dateFormat.format(DateTime(year, month, day));
      }

      // ★追加: 存在する年、月、日、試合を抽出 (フィルタリングの最上位階層でのみ実行)
      final allMatches = await _matchDao.getMatches(currentTeam.id);

      if (year == null) {
        // 年リスト抽出 (累計タブ選択時のみ実行)
        final years = allMatches
            .map((m) => DateTime.tryParse(m['date'] as String)?.year)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
        ref.read(availableYearsProvider.notifier).state = years;
        ref.read(availableMonthsProvider.notifier).state = [];
        ref.read(availableDaysProvider.notifier).state = [];
        ref.read(availableMatchesProvider.notifier).state = {};
      } else if (month == null) {
        // 月リスト抽出 (特定の年が選択され、かつ月が未選択/年累計の時のみ実行)
        final months = allMatches
            .where((m) => DateTime.tryParse(m['date'] as String)?.year == year)
            .map((m) => DateTime.tryParse(m['date'] as String)?.month)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
        ref.read(availableMonthsProvider.notifier).state = months;
        ref.read(availableDaysProvider.notifier).state = [];
        ref.read(availableMatchesProvider.notifier).state = {};
      } else if (day == null) {
        // 日リスト抽出 (特定の月が選択され、かつ日が未選択/月累計の時のみ実行)
        final days = allMatches
            .where((m) {
          final date = DateTime.tryParse(m['date'] as String);
          return date != null && date.year == year && date.month == month;
        })
            .map((m) => DateTime.tryParse(m['date'] as String)?.day)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
        ref.read(availableDaysProvider.notifier).state = days;
        ref.read(availableMatchesProvider.notifier).state = {};
      } else if (matchId == null) {
        // 試合リスト抽出 (特定の日が選択され、かつ試合が未選択/日累計の時のみ実行)
        final matches = allMatches
            .where((m) {
          final date = DateTime.tryParse(m['date'] as String);
          return date != null && date.year == year && date.month == month && date.day == day;
        });

        final matchMap = {
          for (var m in matches)
            m['id'] as String: m['opponent'] as String,
        };
        ref.read(availableMatchesProvider.notifier).state = matchMap;
      }

      // 2. アクション定義 (並び順用)
      final rawActions = await _actionDao.getActionDefinitions(currentTeam.id);
      actionDefinitions = rawActions.map((d) => ActionDefinition.fromMap(d)).toList();

      // 3. 全選手データの初期化
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
            if (n is Map) {
              // ★修正: name['last']とname['first']がnullの場合に備えて?? ''を追加 (エラー回避)
              name = "${n['last'] ?? ''} ${n['first'] ?? ''}".trim();
            }
          }
          rosterMap[num] = name;

          statsMap[num] = PlayerStats(
            playerId: num,
            playerNumber: num,
            playerName: name,
            matchesPlayed: 0,
            actions: {},
          );
        }
      }

      // ★追加: 特定の試合が選択されている場合、MatchRecordを構築する
      if (matchId != null) {
        final matchRow = allMatches.firstWhere((m) => m['id'] == matchId);
        final logRows = await _matchDao.getMatchLogs(matchId);

        final logs = logRows.map((logRow) {
          return LogEntry(
            id: logRow['id'] as String,
            // ★修正: matchRowから取得した日付と対戦相手がnullの場合に備えて?? ''を追加 (エラー回避)
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

        final record = MatchRecord(
          id: matchId,
          // ★修正: MatchRecord構築時にもnullチェックを追加 (エラー回避)
          date: matchRow['date'] as String? ?? '',
          opponent: matchRow['opponent'] as String? ?? '',
          logs: logs,
        );
        ref.read(selectedMatchRecordProvider.notifier).state = record;
      }

      // 4. 出場記録 (match_participations) による試合数カウント
      final List<Map<String, dynamic>> participations;
      if (matchId != null) {
        // 特定試合のParticipationsを抽出 (MatchRecord構築時に使用したログから抽出)
        final logs = ref.read(selectedMatchRecordProvider.notifier).state?.logs;
        if (logs != null) {
          final playerNumbers = logs.map((e) => e.playerNumber).toSet();
          participations = playerNumbers.map((pNum) => {'player_number': pNum, 'match_id': matchId}).toList();
        } else {
          participations = [];
        }
      } else {
        // 期間内のParticipationsを抽出
        participations = await _matchDao.getParticipationsInPeriod(currentTeam.id, startDateStr, endDateStr);
      }


      // 選手ごとの参加試合IDセット
      final Map<String, Set<String>> playerMatches = {};

      for (var p in participations) {
        final pNum = p['player_number'] as String? ?? "";
        final matchIdKey = p['match_id'] as String? ?? "";

        if (pNum.isNotEmpty && matchIdKey.isNotEmpty) {
          if (!playerMatches.containsKey(pNum)) playerMatches[pNum] = {};
          playerMatches[pNum]!.add(matchIdKey);

          // 名簿になくても出場記録にある場合のケア
          if (!statsMap.containsKey(pNum)) {
            statsMap[pNum] = PlayerStats(
                playerId: pNum, playerNumber: pNum, playerName: rosterMap[pNum] ?? "(不明)", matchesPlayed: 0, actions: {}
            );
          }
        }
      }

      // 5. ログ集計
      final List<Map<String, dynamic>> rawLogs;
      if (matchId != null) {
        // MatchRecord構築時に使用したログを再利用
        rawLogs = ref.read(selectedMatchRecordProvider.notifier).state?.logs.map((e) => e.toJson()).toList() ?? [];
      } else {
        rawLogs = await _matchDao.getLogsInPeriod(currentTeam.id, startDateStr, endDateStr);
      }

      for (var log in rawLogs) {
        final pNum = log['player_number'] as String? ?? "";
        if (pNum.isEmpty) continue;

        // ... (ログ集計ロジックは変更なし) ...
        if (!statsMap.containsKey(pNum)) {
          statsMap[pNum] = PlayerStats(playerId: pNum, playerNumber: pNum, playerName: "(未登録)", actions: {});
        }

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

      // 6. 最終整形
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