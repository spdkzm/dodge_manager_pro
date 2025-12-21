// lib/features/team_mgmt/data/uniform_number_dao.dart
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../domain/uniform_number.dart';

class UniformNumberDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // 背番号を登録
  Future<void> insertUniformNumber(UniformNumber uniformNumber) async {
    final db = await _dbHelper.database;
    await db.insert(
      'uniform_numbers',
      uniformNumber.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 背番号情報を更新
  Future<void> updateUniformNumber(UniformNumber uniformNumber) async {
    final db = await _dbHelper.database;
    await db.update(
      'uniform_numbers',
      uniformNumber.toJson(),
      where: 'id = ?',
      whereArgs: [uniformNumber.id],
    );
  }

  // 削除
  Future<void> deleteUniformNumber(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'uniform_numbers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // チーム内の全背番号履歴を取得
  Future<List<UniformNumber>> getUniformNumbersByTeam(String teamId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'uniform_numbers',
      where: 'team_id = ?',
      whereArgs: [teamId],
      orderBy: 'start_date DESC', // 新しい順
    );
    return maps.map((e) => UniformNumber.fromJson(e)).toList();
  }

  // 特定選手の背番号履歴を取得
  Future<List<UniformNumber>> getUniformNumbersByPlayer(String playerId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'uniform_numbers',
      where: 'player_id = ?',
      whereArgs: [playerId],
      orderBy: 'start_date DESC',
    );
    return maps.map((e) => UniformNumber.fromJson(e)).toList();
  }

  // 指定した日付時点で有効な背番号を取得 (選手単位)
  Future<UniformNumber?> getActiveUniformNumber(String playerId, DateTime date) async {
    final db = await _dbHelper.database;
    // 日付比較ロジック: start_date <= date AND (end_date IS NULL OR end_date >= date)
    // SQLiteの日付比較は文字列で行われるため、ISO8601形式で比較する
    final dateStr = date.toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'uniform_numbers',
      where: '''
        player_id = ? AND 
        start_date <= ? AND 
        (end_date IS NULL OR end_date >= ?)
      ''',
      whereArgs: [playerId, dateStr, dateStr],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return UniformNumber.fromJson(maps.first);
    }
    return null;
  }

  // 指定した日付時点で、チーム内でその背番号を使っているデータがあるか確認 (重複チェック用)
  // ただし、自分自身(excludeId)は除く
  Future<List<UniformNumber>> findOverlappingNumbers({
    required String teamId,
    required String number,
    required DateTime startDate,
    DateTime? endDate,
    String? excludeId,
  }) async {
    final db = await _dbHelper.database;

    // 期間重複のロジックをSQLで表現するのはやや複雑なため、
    // 同じ番号を持つデータを取得してからDart側で判定するか、
    // あるいは簡易的なクエリで絞り込む。
    // ここでは「同じチーム」かつ「同じ番号」のデータを全て取得し、ロジックで判定するアプローチをとる。

    final List<Map<String, dynamic>> maps = await db.query(
      'uniform_numbers',
      where: 'team_id = ? AND number = ?',
      whereArgs: [teamId, number],
    );

    final candidates = maps.map((e) => UniformNumber.fromJson(e)).toList();

    return candidates.where((existing) {
      if (excludeId != null && existing.id == excludeId) return false;
      return existing.overlapsWith(startDate, endDate);
    }).toList();
  }
}