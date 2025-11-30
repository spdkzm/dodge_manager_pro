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
      // 1. 試合ヘッダ保存
      await txn.insert('matches', {
        'id': matchData['id'],
        'team_id': teamId,
        'opponent': matchData['opponent'],
        'date': matchData['date'],
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. ログ保存
      // ★修正: LogEntry.toJson() が生成するキャメルケースのキーを使って値を取り出す
      for (var log in logs) {
        await txn.insert('match_logs', {
          'id': log['id'],
          'match_id': matchData['id'],
          'game_time': log['gameTime'],       // 修正: game_time -> gameTime
          'player_number': log['playerNumber'], // 修正: player_number -> playerNumber
          // NULLの場合は空文字列を保存 (データ永続性)
          'action': log['action'] ?? '',
          'sub_action': log['subAction'],     // 修正: sub_action -> subAction
          'log_type': log['type'],            // 修正: log_type -> type (models.g.dartの定義に合わせる)
          'result': log['result'],            // resultはそのまま
        });
      }

      // 3. 出場記録保存
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

  // 試合の完全削除メソッド
  Future<void> deleteMatch(String matchId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('match_logs', where: 'match_id = ?', whereArgs: [matchId]);
      await txn.delete('match_participations', where: 'match_id = ?', whereArgs: [matchId]);
      await txn.delete('matches', where: 'id = ?', whereArgs: [matchId]);
    });
  }

  // 集計用: 期間内の全ログ取得
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

  // 集計用: 期間内の出場記録取得 (試合数カウントの基準)
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