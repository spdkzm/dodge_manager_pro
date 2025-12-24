// lib/features/game_record/data/match_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'match_dao.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(MatchDao());
});

class MatchRepository {
  final MatchDao _dao;

  MatchRepository(this._dao);

  // --- 参照系 ---

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

  // --- 更新系 ---

  Future<void> insertMatchLog(String matchId, Map<String, dynamic> logMap) async {
    await _dao.insertMatchLog(matchId, logMap);
  }

  Future<void> updateMatchLog(Map<String, dynamic> logMap) async {
    await _dao.updateMatchLog(logMap);
  }

  Future<void> deleteMatchLog(String logId) async {
    await _dao.deleteMatchLog(logId);
  }

  // ★変更: 基本情報のみ更新
  Future<void> updateBasicInfo({
    required String matchId,
    required String date,
    required String opponent,
    String? opponentId,
    String? venueName,
    String? venueId,
    required int matchType,
    String? note,
    String? tournamentName, // 追加
    String? matchDivision,  // 追加
  }) async {
    await _dao.updateBasicInfo(
      matchId: matchId,
      date: date,
      opponent: opponent,
      opponentId: opponentId,
      venueName: venueName,
      venueId: venueId,
      matchType: matchType,
      note: note,
      tournamentName: tournamentName, // 追加
      matchDivision: matchDivision,   // 追加
    );
  }

  // ★変更: 勝敗結果のみ更新
  Future<void> updateMatchResult({
    required String matchId,
    required int result,
    int? scoreOwn,
    int? scoreOpponent,
    required int isExtraTime,
    int? extraScoreOwn,
    int? extraScoreOpponent,
  }) async {
    await _dao.updateMatchResult(
      matchId: matchId,
      result: result,
      scoreOwn: scoreOwn,
      scoreOpponent: scoreOpponent,
      isExtraTime: isExtraTime,
      extraScoreOwn: extraScoreOwn,
      extraScoreOpponent: extraScoreOpponent,
    );
  }

  /// ★追加: 内部記録日時のみ更新
  Future<void> updateMatchCreatedAt(String matchId, String newCreatedAt) async {
    await _dao.updateMatchCreatedAt(matchId, newCreatedAt);
  }

  Future<void> updateMatchParticipations(String matchId, List<Map<String, dynamic>> members) async {
    await _dao.updateMatchParticipations(matchId, members);
  }
}