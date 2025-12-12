// lib/features/game_record/data/match_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'match_dao.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(MatchDao());
});

class MatchRepository {
  final MatchDao _dao;

  MatchRepository(this._dao);

  // --- 参照系 (AnalysisController等で使用) ---

  Future<List<Map<String, dynamic>>> getMatches(String teamId) async {
    return _dao.getMatches(teamId);
  }

  Future<List<Map<String, dynamic>>> getMatchLogs(String matchId) async {
    return _dao.getMatchLogs(matchId);
  }

  Future<List<Map<String, dynamic>>> getMatchParticipations(String matchId) async {
    return _dao.getMatchParticipations(matchId);
  }

  // --- 高速集計用メソッド ---

  Future<List<Map<String, dynamic>>> getPlayerMatchCounts(
      String teamId, String startDate, String endDate,
      [List<int>? matchTypes, String? matchId]) async {
    return _dao.getPlayerMatchCounts(teamId, startDate, endDate, matchTypes, matchId);
  }

  Future<List<Map<String, dynamic>>> getAggregatedActionStats(
      String teamId, String startDate, String endDate,
      [List<int>? matchTypes, String? matchId]) async {
    return _dao.getAggregatedActionStats(teamId, startDate, endDate, matchTypes, matchId);
  }

  Future<List<Map<String, dynamic>>> getAggregatedSubActionStats(
      String teamId, String startDate, String endDate,
      [List<int>? matchTypes, String? matchId]) async {
    return _dao.getAggregatedSubActionStats(teamId, startDate, endDate, matchTypes, matchId);
  }

  // --- 更新系 (AnalysisController等で使用) ---

  Future<void> insertMatchLog(String matchId, Map<String, dynamic> logMap) async {
    await _dao.insertMatchLog(matchId, logMap);
  }

  Future<void> updateMatchLog(Map<String, dynamic> logMap) async {
    await _dao.updateMatchLog(logMap);
  }

  Future<void> deleteMatchLog(String logId) async {
    await _dao.deleteMatchLog(logId);
  }

  Future<void> updateMatchInfo({
    required String matchId,
    required String newDate,
    required String newOpponent,
    String? newOpponentId,
    String? newVenueName,
    String? newVenueId,
    required int newMatchType,
    int result = 0,
    int? scoreOwn,
    int? scoreOpponent,
    int isExtraTime = 0,
    int? extraScoreOwn,
    int? extraScoreOpponent,
  }) async {
    await _dao.updateMatchInfo(
      matchId: matchId,
      newDate: newDate,
      newOpponent: newOpponent,
      newOpponentId: newOpponentId,
      newVenueName: newVenueName,
      newVenueId: newVenueId,
      newMatchType: newMatchType,
      result: result,
      scoreOwn: scoreOwn,
      scoreOpponent: scoreOpponent,
      isExtraTime: isExtraTime,
      extraScoreOwn: extraScoreOwn,
      extraScoreOpponent: extraScoreOpponent,
    );
  }

  Future<void> updateMatchParticipations(String matchId, List<Map<String, String>> members) async {
    await _dao.updateMatchParticipations(matchId, members);
  }

// 必要に応じて他のDAOメソッドもここに追加して公開する
}