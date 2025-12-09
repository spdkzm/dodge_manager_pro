// lib/features/game_record/data/match_dao.dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

class MatchDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // --- 試合とログの新規作成 ---
  Future<void> insertMatchWithLogs(
      String teamId,
      Map<String, dynamic> matchData,
      List<Map<String, dynamic>> logs,
      List<String> participations
      ) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('matches', {
        'id': matchData['id'],
        'team_id': teamId,
        'opponent': matchData['opponent'],
        'opponent_id': matchData['opponent_id'],
        'venue_name': matchData['venue_name'],
        'venue_id': matchData['venue_id'],
        'date': matchData['date'],
        'match_type': matchData['match_type'] ?? 0,
        // ★追加: 勝敗・スコア
        'result': matchData['result'] ?? 0,
        'score_own': matchData['score_own'],
        'score_opponent': matchData['score_opponent'],
        'is_extra_time': matchData['is_extra_time'] ?? 0,
        'extra_score_own': matchData['extra_score_own'],
        'extra_score_opponent': matchData['extra_score_opponent'],
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      for (var log in logs) {
        await txn.insert('match_logs', {
          'id': log['id'],
          'match_id': matchData['id'],
          'game_time': log['gameTime'],
          'player_number': log['playerNumber'],
          'action': log['action'] ?? '',
          'sub_action': log['subAction'],
          'log_type': log['type'],
          'result': log['result'],
        });
      }

      for (var playerNum in participations) {
        await txn.insert('match_participations', {
          'match_id': matchData['id'],
          'player_number': playerNum,
        });
      }
    });
  }

  // --- ログ単体の操作 ---
  Future<void> insertMatchLog(String matchId, Map<String, dynamic> logMap) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('match_logs', {
        'id': logMap['id'],
        'match_id': matchId,
        'game_time': logMap['gameTime'],
        'player_number': logMap['playerNumber'],
        'action': logMap['action'],
        'sub_action': logMap['subAction'],
        'log_type': logMap['type'],
        'result': logMap['result'],
      });
      final existing = await txn.query('match_participations', where: 'match_id = ? AND player_number = ?', whereArgs: [matchId, logMap['playerNumber']]);
      if (existing.isEmpty) {
        await txn.insert('match_participations', {'match_id': matchId, 'player_number': logMap['playerNumber']});
      }
    });
  }

  Future<void> updateMatchLog(Map<String, dynamic> logMap) async {
    final db = await _dbHelper.database;
    await db.update('match_logs', {
      'game_time': logMap['gameTime'],
      'player_number': logMap['playerNumber'],
      'action': logMap['action'],
      'sub_action': logMap['subAction'],
      'log_type': logMap['type'],
      'result': logMap['result'],
    }, where: 'id = ?', whereArgs: [logMap['id']]);

    if (logMap['match_id'] != null) {
      final existing = await db.query('match_participations', where: 'match_id = ? AND player_number = ?', whereArgs: [logMap['match_id'], logMap['playerNumber']]);
      if (existing.isEmpty) {
        await db.insert('match_participations', {'match_id': logMap['match_id'], 'player_number': logMap['playerNumber']});
      }
    }
  }

  Future<void> deleteMatchLog(String logId) async {
    final db = await _dbHelper.database;
    await db.delete('match_logs', where: 'id = ?', whereArgs: [logId]);
  }

  // --- 試合情報の更新 (引数拡張版) ---
  Future<void> updateMatchInfo({
    required String matchId,
    required String newDate,
    required String newOpponent,
    String? newOpponentId,
    String? newVenueName,
    String? newVenueId,
    required int newMatchType,
    // ★追加: 勝敗・スコア関連
    int result = 0,
    int? scoreOwn,
    int? scoreOpponent,
    int isExtraTime = 0,
    int? extraScoreOwn,
    int? extraScoreOpponent,
  }) async {
    final db = await _dbHelper.database;
    await db.update('matches', {
      'date': newDate,
      'opponent': newOpponent,
      'opponent_id': newOpponentId,
      'venue_name': newVenueName,
      'venue_id': newVenueId,
      'match_type': newMatchType,
      // ★追加
      'result': result,
      'score_own': scoreOwn,
      'score_opponent': scoreOpponent,
      'is_extra_time': isExtraTime,
      'extra_score_own': extraScoreOwn,
      'extra_score_opponent': extraScoreOpponent,
    }, where: 'id = ?', whereArgs: [matchId]);
  }

  Future<void> updateMatchParticipations(String matchId, List<String> playerNumbers) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('match_participations', where: 'match_id = ?', whereArgs: [matchId]);
      for (var num in playerNumbers) {
        await txn.insert('match_participations', {
          'match_id': matchId,
          'player_number': num,
        });
      }
    });
  }

  Future<void> updateActionNameInLogs(String teamId, String oldName, String newName) async {
    final db = await _dbHelper.database;
    await db.rawUpdate('''
      UPDATE match_logs
      SET action = ?
      WHERE action = ? AND match_id IN (
        SELECT id FROM matches WHERE team_id = ?
      )
    ''', [newName, oldName, teamId]);
  }

  Future<int> countSubActionUsage(String teamId, String actionName, String subActionName) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM match_logs
      WHERE action = ? AND sub_action = ? AND match_id IN (
        SELECT id FROM matches WHERE team_id = ?
      )
    ''', [actionName, subActionName, teamId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateSubActionNameInLogs(String teamId, String actionName, String oldSubName, String newSubName) async {
    final db = await _dbHelper.database;
    await db.rawUpdate('''
      UPDATE match_logs
      SET sub_action = ?
      WHERE action = ? AND sub_action = ? AND match_id IN (
        SELECT id FROM matches WHERE team_id = ?
      )
    ''', [newSubName, actionName, oldSubName, teamId]);
  }

  Future<int> countOpponentNameUsage(String teamId, String name) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) FROM matches WHERE team_id = ? AND opponent = ?',
        [teamId, name]
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateOpponentName(String teamId, String oldName, String newName) async {
    final db = await _dbHelper.database;
    await db.update(
        'matches',
        {'opponent': newName},
        where: 'team_id = ? AND opponent = ?',
        whereArgs: [teamId, oldName]
    );
  }

  Future<int> countVenueNameUsage(String teamId, String name) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) FROM matches WHERE team_id = ? AND venue_name = ?',
        [teamId, name]
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateVenueName(String teamId, String oldName, String newName) async {
    final db = await _dbHelper.database;
    await db.update(
        'matches',
        {'venue_name': newName},
        where: 'team_id = ? AND venue_name = ?',
        whereArgs: [teamId, oldName]
    );
  }

  // --- 取得系 ---
  Future<List<Map<String, dynamic>>> getMatches(String teamId) async {
    final db = await _dbHelper.database;
    return await db.query('matches', where: 'team_id = ?', orderBy: 'date DESC, created_at DESC', whereArgs: [teamId]);
  }

  Future<List<Map<String, dynamic>>> getMatchLogs(String matchId) async {
    final db = await _dbHelper.database;
    return await db.query('match_logs', where: 'match_id = ?', orderBy: 'game_time DESC', whereArgs: [matchId]);
  }

  Future<List<String>> getMatchParticipations(String matchId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
        'match_participations',
        columns: ['player_number'],
        where: 'match_id = ?',
        whereArgs: [matchId]
    );
    return result.map((row) => row['player_number'] as String).toList();
  }

  Future<void> deleteMatch(String matchId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('match_logs', where: 'match_id = ?', whereArgs: [matchId]);
      await txn.delete('match_participations', where: 'match_id = ?', whereArgs: [matchId]);
      await txn.delete('matches', where: 'id = ?', whereArgs: [matchId]);
    });
  }

  Future<List<Map<String, dynamic>>> getLogsInPeriod(
      String teamId, String startDate, String endDate,
      [List<int>? matchTypes]) async {
    final db = await _dbHelper.database;
    String typeCondition = "";
    if (matchTypes != null && matchTypes.isNotEmpty) {
      typeCondition = "AND m.match_type IN (${matchTypes.join(',')})";
    }
    final sql = '''
      SELECT 
        l.*, 
        m.date as match_date, 
        m.opponent,
        m.match_type
      FROM match_logs l
      LEFT JOIN matches m ON l.match_id = m.id
      WHERE m.team_id = ? AND m.date BETWEEN ? AND ?
      $typeCondition
    ''';
    return await db.rawQuery(sql, [teamId, startDate, endDate]);
  }

  Future<List<Map<String, dynamic>>> getParticipationsInPeriod(
      String teamId, String startDate, String endDate,
      [List<int>? matchTypes]) async {
    final db = await _dbHelper.database;
    String typeCondition = "";
    if (matchTypes != null && matchTypes.isNotEmpty) {
      typeCondition = "AND m.match_type IN (${matchTypes.join(',')})";
    }
    final sql = '''
      SELECT 
        p.player_number,
        p.match_id,
        m.match_type
      FROM match_participations p
      INNER JOIN matches m ON p.match_id = m.id
      WHERE m.team_id = ? AND m.date BETWEEN ? AND ?
      $typeCondition
    ''';
    return await db.rawQuery(sql, [teamId, startDate, endDate]);
  }
}