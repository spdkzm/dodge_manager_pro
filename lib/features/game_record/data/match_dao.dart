// lib/features/game_record/data/match_dao.dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

class MatchDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // --- 既存のCRUDメソッド ---

  Future<void> insertMatchWithLogs(
      String teamId,
      Map<String, dynamic> matchData,
      List<Map<String, dynamic>> logs,
      List<Map<String, String>> participations
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
          'player_id': log['playerId'],
          'action': log['action'] ?? '',
          'sub_action': log['subAction'],
          'sub_action_id': log['subActionId'],
          'log_type': log['type'],
          'result': log['result'],
        });
      }

      for (var p in participations) {
        await txn.insert('match_participations', {
          'match_id': matchData['id'],
          'player_number': p['player_number'],
          'player_id': p['player_id'],
        });
      }
    });
  }

  Future<void> insertMatchLog(String matchId, Map<String, dynamic> logMap) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('match_logs', {
        'id': logMap['id'],
        'match_id': matchId,
        'game_time': logMap['gameTime'],
        'player_number': logMap['playerNumber'],
        'player_id': logMap['playerId'],
        'action': logMap['action'],
        'sub_action': logMap['subAction'],
        'sub_action_id': logMap['subActionId'],
        'log_type': logMap['type'],
        'result': logMap['result'],
      });

      final pid = logMap['playerId'];
      final pNum = logMap['playerNumber'];
      List<Map<String, Object?>> existing;
      if (pid != null && pid.isNotEmpty) {
        existing = await txn.query('match_participations', where: 'match_id = ? AND player_id = ?', whereArgs: [matchId, pid]);
      } else {
        existing = await txn.query('match_participations', where: 'match_id = ? AND player_number = ?', whereArgs: [matchId, pNum]);
      }
      if (existing.isEmpty) {
        await txn.insert('match_participations', {
          'match_id': matchId,
          'player_number': pNum,
          'player_id': pid,
        });
      }
    });
  }

  Future<void> updateMatchLog(Map<String, dynamic> logMap) async {
    final db = await _dbHelper.database;
    await db.update('match_logs', {
      'game_time': logMap['gameTime'],
      'player_number': logMap['playerNumber'],
      'player_id': logMap['playerId'],
      'action': logMap['action'],
      'sub_action': logMap['subAction'],
      'sub_action_id': logMap['subActionId'],
      'log_type': logMap['type'],
      'result': logMap['result'],
    }, where: 'id = ?', whereArgs: [logMap['id']]);
  }

  Future<void> deleteMatchLog(String logId) async {
    final db = await _dbHelper.database;
    await db.delete('match_logs', where: 'id = ?', whereArgs: [logId]);
  }

  Future<void> updateMatchInfo({
    required String matchId,
    // matchIdParam を削除
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
    final db = await _dbHelper.database;
    await db.update('matches', {
      'date': newDate,
      'opponent': newOpponent,
      'opponent_id': newOpponentId,
      'venue_name': newVenueName,
      'venue_id': newVenueId,
      'match_type': newMatchType,
      'result': result,
      'score_own': scoreOwn,
      'score_opponent': scoreOpponent,
      'is_extra_time': isExtraTime,
      'extra_score_own': extraScoreOwn,
      'extra_score_opponent': extraScoreOpponent,
    }, where: 'id = ?', whereArgs: [matchId]);
  }

  Future<void> updateMatchParticipations(String matchId, List<Map<String, String>> members) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('match_participations', where: 'match_id = ?', whereArgs: [matchId]);
      for (var m in members) {
        await txn.insert('match_participations', {
          'match_id': matchId,
          'player_number': m['player_number'],
          'player_id': m['player_id'],
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
    await db.update('matches', {'opponent': newName}, where: 'team_id = ? AND opponent = ?', whereArgs: [teamId, oldName]);
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
    await db.update('matches', {'venue_name': newName}, where: 'team_id = ? AND venue_name = ?', whereArgs: [teamId, oldName]);
  }

  Future<List<Map<String, dynamic>>> getMatches(String teamId) async {
    final db = await _dbHelper.database;
    return await db.query('matches', where: 'team_id = ?', orderBy: 'date DESC, created_at DESC', whereArgs: [teamId]);
  }

  Future<List<Map<String, dynamic>>> getMatchLogs(String matchId) async {
    final db = await _dbHelper.database;
    return await db.query('match_logs', where: 'match_id = ?', orderBy: 'game_time DESC', whereArgs: [matchId]);
  }

  Future<List<Map<String, dynamic>>> getMatchParticipations(String matchId) async {
    final db = await _dbHelper.database;
    return await db.query(
        'match_participations',
        columns: ['player_number', 'player_id', 'match_id'],
        where: 'match_id = ?',
        whereArgs: [matchId]
    );
  }

  Future<void> deleteMatch(String matchId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('match_logs', where: 'match_id = ?', whereArgs: [matchId]);
      await txn.delete('match_participations', where: 'match_id = ?', whereArgs: [matchId]);
      await txn.delete('matches', where: 'id = ?', whereArgs: [matchId]);
    });
  }

  Future<List<Map<String, dynamic>>> getLogsInPeriod(String teamId, String startDate, String endDate, [List<int>? matchTypes]) async {
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

  Future<List<Map<String, dynamic>>> getParticipationsInPeriod(String teamId, String startDate, String endDate, [List<int>? matchTypes]) async {
    final db = await _dbHelper.database;
    String typeCondition = "";
    if (matchTypes != null && matchTypes.isNotEmpty) {
      typeCondition = "AND m.match_type IN (${matchTypes.join(',')})";
    }
    final sql = '''
      SELECT 
        p.player_number,
        p.player_id,
        p.match_id,
        m.match_type
      FROM match_participations p
      INNER JOIN matches m ON p.match_id = m.id
      WHERE m.team_id = ? AND m.date BETWEEN ? AND ?
      $typeCondition
    ''';
    return await db.rawQuery(sql, [teamId, startDate, endDate]);
  }

  Future<void> updateLogPlayerId(String logId, String playerId) async {
    final db = await _dbHelper.database;
    await db.update('match_logs', {'player_id': playerId}, where: 'id = ?', whereArgs: [logId]);
  }

  Future<void> updateParticipationPlayerId(String matchId, String playerNumber, String playerId) async {
    final db = await _dbHelper.database;
    await db.update('match_participations', {'player_id': playerId}, where: 'match_id = ? AND player_number = ?', whereArgs: [matchId, playerNumber]);
  }

  // --- ★以下、高速集計用メソッド ---

  // 1. 選手ごとの試合数集計
  Future<List<Map<String, dynamic>>> getPlayerMatchCounts(
      String teamId, String startDate, String endDate,
      [List<int>? matchTypes, String? matchId]) async {
    final db = await _dbHelper.database;

    String whereClause;
    List<dynamic> args;

    if (matchId != null) {
      whereClause = "m.id = ?";
      args = [matchId];
    } else {
      whereClause = "m.team_id = ? AND m.date BETWEEN ? AND ?";
      args = [teamId, startDate, endDate];
    }

    String typeCondition = "";
    if (matchTypes != null && matchTypes.isNotEmpty) {
      typeCondition = "AND m.match_type IN (${matchTypes.join(',')})";
    }

    final sql = '''
      SELECT
        p.player_id,
        p.player_number,
        COUNT(DISTINCT p.match_id) as match_count
      FROM match_participations p
      JOIN matches m ON p.match_id = m.id
      WHERE $whereClause
      $typeCondition
      GROUP BY p.player_id, p.player_number
    ''';
    return await db.rawQuery(sql, args);
  }

  // 2. アクション集計 (成功/失敗/合計)
  Future<List<Map<String, dynamic>>> getAggregatedActionStats(
      String teamId, String startDate, String endDate,
      [List<int>? matchTypes, String? matchId]) async {
    final db = await _dbHelper.database;

    String whereClause;
    List<dynamic> args;

    if (matchId != null) {
      whereClause = "m.id = ?";
      args = [matchId];
    } else {
      whereClause = "m.team_id = ? AND m.date BETWEEN ? AND ?";
      args = [teamId, startDate, endDate];
    }

    String typeCondition = "";
    if (matchTypes != null && matchTypes.isNotEmpty) {
      typeCondition = "AND m.match_type IN (${matchTypes.join(',')})";
    }

    // ★修正: log_type = 0 (通常ログ) のみ集計
    final sql = '''
      SELECT
        l.player_id,
        l.player_number,
        l.action,
        l.result,
        COUNT(*) as count
      FROM match_logs l
      JOIN matches m ON l.match_id = m.id
      WHERE $whereClause
      $typeCondition
      AND l.log_type = 0
      GROUP BY l.player_id, l.player_number, l.action, l.result
    ''';
    return await db.rawQuery(sql, args);
  }

  // 3. サブアクション集計
  Future<List<Map<String, dynamic>>> getAggregatedSubActionStats(
      String teamId, String startDate, String endDate,
      [List<int>? matchTypes, String? matchId]) async {
    final db = await _dbHelper.database;

    String whereClause;
    List<dynamic> args;

    if (matchId != null) {
      whereClause = "m.id = ?";
      args = [matchId];
    } else {
      whereClause = "m.team_id = ? AND m.date BETWEEN ? AND ?";
      args = [teamId, startDate, endDate];
    }

    String typeCondition = "";
    if (matchTypes != null && matchTypes.isNotEmpty) {
      typeCondition = "AND m.match_type IN (${matchTypes.join(',')})";
    }

    // ★修正: log_type = 0 (通常ログ) のみ集計
    final sql = '''
      SELECT
        l.player_id,
        l.player_number,
        l.action,
        l.sub_action,
        COUNT(*) as count
      FROM match_logs l
      JOIN matches m ON l.match_id = m.id
      WHERE $whereClause
      $typeCondition
      AND l.log_type = 0
      AND l.sub_action IS NOT NULL AND l.sub_action != ''
      GROUP BY l.player_id, l.player_number, l.action, l.sub_action
    ''';
    return await db.rawQuery(sql, args);
  }
}