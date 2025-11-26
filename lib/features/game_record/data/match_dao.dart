// lib/features/game_record/data/match_dao.dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

class MatchDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ★変更: participations (出場選手リスト) を受け取る
  Future<void> insertMatchWithLogs(
      String teamId,
      Map<String, dynamic> matchData,
      List<Map<String, dynamic>> logs,
      List<String> participations // 背番号リスト
      ) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. 試合ヘッダ
      await txn.insert('matches', {
        'id': matchData['id'],
        'team_id': teamId,
        'opponent': matchData['opponent'],
        'date': matchData['date'],
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. ログ
      for (var log in logs) {
        await txn.insert('match_logs', {
          'id': log['id'],
          'match_id': matchData['id'],
          'game_time': log['gameTime'],
          'player_number': log['player_number'],
          'action': log['action'],
          'sub_action': log['subAction'],
          'log_type': log['type'],
          'result': log['result'],
        });
      }

      // 3. ★追加: 出場記録
      for (var playerNum in participations) {
        await txn.insert('match_participations', {
          'match_id': matchData['id'],
          'player_number': playerNum,
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getMatches(String teamId) async {
    final db = await _dbHelper.database;
    return await db.query('matches', where: 'team_id = ?', orderBy: 'date DESC, created_at DESC', whereArgs: [teamId]);
  }

  Future<List<Map<String, dynamic>>> getMatchLogs(String matchId) async {
    final db = await _dbHelper.database;
    return await db.query('match_logs', where: 'match_id = ?', whereArgs: [matchId]);
  }

  Future<List<Map<String, dynamic>>> getLogsInPeriod(String teamId, String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT l.*, m.date as match_date, m.opponent 
      FROM match_logs l
      INNER JOIN matches m ON l.match_id = m.id
      WHERE m.team_id = ? AND m.date BETWEEN ? AND ?
    ''';
    return await db.rawQuery(sql, [teamId, startDate, endDate]);
  }

  // ★追加: 指定期間の出場記録を取得
  Future<List<Map<String, dynamic>>> getParticipationsInPeriod(String teamId, String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT p.player_number, p.match_id
      FROM match_participations p
      INNER JOIN matches m ON p.match_id = m.id
      WHERE m.team_id = ? AND m.date BETWEEN ? AND ?
    ''';
    return await db.rawQuery(sql, [teamId, startDate, endDate]);
  }
}