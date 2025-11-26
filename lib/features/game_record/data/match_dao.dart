// lib/features/game_record/data/match_dao.dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart'; // パスは環境に合わせて調整

class MatchDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> insertMatchWithLogs(String teamId, Map<String, dynamic> matchData, List<Map<String, dynamic>> logs) async {
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
          'action': log['action'],
          'sub_action': log['subAction'],
          'log_type': log['type'],
          'result': log['result'],
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

  // ★追加: 指定期間内の全ログを取得 (集計用)
  // matchesテーブルとmatch_logsテーブルを結合して取得
  Future<List<Map<String, dynamic>>> getLogsInPeriod(String teamId, String startDate, String endDate) async {
    final db = await _dbHelper.database;

    // SQL: 指定チームの、指定期間内の試合に紐づくログを全て取得
    final sql = '''
      SELECT 
        l.*, 
        m.date as match_date, 
        m.opponent 
      FROM match_logs l
      INNER JOIN matches m ON l.match_id = m.id
      WHERE m.team_id = ? AND m.date BETWEEN ? AND ?
    ''';

    return await db.rawQuery(sql, [teamId, startDate, endDate]);
  }
}