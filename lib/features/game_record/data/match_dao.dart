// lib/features/game_record/data/match_dao.dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

class MatchDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

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
        'date': matchData['date'],
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

      final existing = await txn.query('match_participations',
          where: 'match_id = ? AND player_number = ?',
          whereArgs: [matchId, logMap['playerNumber']]);
      if (existing.isEmpty) {
        await txn.insert('match_participations', {
          'match_id': matchId,
          'player_number': logMap['playerNumber'],
        });
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
      final existing = await db.query('match_participations',
          where: 'match_id = ? AND player_number = ?',
          whereArgs: [logMap['match_id'], logMap['playerNumber']]);
      if (existing.isEmpty) {
        await db.insert('match_participations', {
          'match_id': logMap['match_id'],
          'player_number': logMap['playerNumber'],
        });
      }
    }
  }

  Future<void> deleteMatchLog(String logId) async {
    final db = await _dbHelper.database;
    await db.delete('match_logs', where: 'id = ?', whereArgs: [logId]);
  }

  // ★変更: 日付と対戦相手名（試合名）を同時に更新
  Future<void> updateMatchDateAndOpponent(String matchId, String newDate, String newOpponent) async {
    final db = await _dbHelper.database;
    await db.update(
        'matches',
        {'date': newDate, 'opponent': newOpponent},
        where: 'id = ?',
        whereArgs: [matchId]
    );
  }

  Future<List<Map<String, dynamic>>> getMatches(String teamId) async {
    final db = await _dbHelper.database;
    return await db.query('matches', where: 'team_id = ?', orderBy: 'date DESC, created_at DESC', whereArgs: [teamId]);
  }

  Future<List<Map<String, dynamic>>> getMatchLogs(String matchId) async {
    final db = await _dbHelper.database;
    return await db.query('match_logs', where: 'match_id = ?', orderBy: 'game_time DESC', whereArgs: [matchId]);
  }

  Future<void> deleteMatch(String matchId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('match_logs', where: 'match_id = ?', whereArgs: [matchId]);
      await txn.delete('match_participations', where: 'match_id = ?', whereArgs: [matchId]);
      await txn.delete('matches', where: 'id = ?', whereArgs: [matchId]);
    });
  }

  Future<List<Map<String, dynamic>>> getLogsInPeriod(String teamId, String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT 
        l.*, 
        m.date as match_date, 
        m.opponent 
      FROM match_logs l
      LEFT JOIN matches m ON l.match_id = m.id
      WHERE m.team_id = ? AND m.date BETWEEN ? AND ?
    ''';
    return await db.rawQuery(sql, [teamId, startDate, endDate]);
  }

  Future<List<Map<String, dynamic>>> getParticipationsInPeriod(String teamId, String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT 
        p.player_number,
        p.match_id
      FROM match_participations p
      INNER JOIN matches m ON p.match_id = m.id
      WHERE m.team_id = ? AND m.date BETWEEN ? AND ?
    ''';
    return await db.rawQuery(sql, [teamId, startDate, endDate]);
  }
}