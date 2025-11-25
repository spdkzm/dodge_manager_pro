// lib/features/team_mgmt/database_helper.dart
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// 相対パスインポート
import 'team.dart';
import 'schema.dart';
import 'roster_item.dart';

// Phase 2で追加するモデル（簡易定義）
// ※本格的なモデルクラスは後ほど models.dart 等で整備しますが、
// ここではDB操作に必要なMap変換の受け口として想定します。

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dodge_manager_v2.db'); // バージョン変更に伴いファイル名も一新推奨

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // --- 既存: チーム管理用テーブル ---

    // 1. チームテーブル
    await db.execute('''
      CREATE TABLE teams(
        id TEXT PRIMARY KEY,
        name TEXT,
        view_hidden_fields TEXT
      )
    ''');

    // 2. 項目定義（スキーマ）テーブル
    await db.execute('''
      CREATE TABLE fields(
        id TEXT PRIMARY KEY,
        team_id TEXT,
        label TEXT,
        type INTEGER,
        is_system INTEGER,
        is_visible INTEGER,
        use_dropdown INTEGER,
        is_range INTEGER,
        options TEXT,
        min_num INTEGER,
        max_num INTEGER,
        is_unique INTEGER,
        FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
      )
    ''');

    // 3. データ（アイテム）テーブル
    await db.execute('''
      CREATE TABLE items(
        id TEXT PRIMARY KEY,
        team_id TEXT,
        data TEXT,
        FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
      )
    ''');

    // --- Phase 2 追加: 試合記録・設定用テーブル ---

    // 4. アクション定義テーブル (旧 ActionItem)
    // チームごとに「アタック」「パス」などの定義を持てるようにする
    await db.execute('''
      CREATE TABLE action_definitions(
        id TEXT PRIMARY KEY,
        team_id TEXT,
        name TEXT,
        sub_actions TEXT, 
        is_sub_required INTEGER,
        sort_order INTEGER,
        FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
      )
    ''');

    // 5. 試合結果テーブル (MatchRecord)
    await db.execute('''
      CREATE TABLE matches(
        id TEXT PRIMARY KEY,
        team_id TEXT,
        opponent TEXT,
        date TEXT,
        created_at TEXT,
        FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
      )
    ''');

    // 6. 試合ログ詳細テーブル (LogEntry)
    await db.execute('''
      CREATE TABLE match_logs(
        id TEXT PRIMARY KEY,
        match_id TEXT,
        game_time TEXT,
        player_number TEXT,
        action TEXT,
        sub_action TEXT,
        log_type INTEGER,
        FOREIGN KEY(match_id) REFERENCES matches(id) ON DELETE CASCADE
      )
    ''');
  }

  // ==========================================
  //  既存メソッド (チーム・スキーマ・アイテム)
  // ==========================================

  Future<void> insertTeam(Team team) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'teams',
        {
          'id': team.id,
          'name': team.name,
          'view_hidden_fields': jsonEncode(team.viewHiddenFields),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (var field in team.schema) {
        await _insertField(txn, team.id, field);
      }
    });
  }

  Future<void> updateTeamName(String teamId, String name) async {
    final db = await database;
    await db.update('teams', {'name': name}, where: 'id = ?', whereArgs: [teamId]);
  }

  Future<void> deleteTeam(String teamId) async {
    final db = await database;
    await db.transaction((txn) async {
      // 関連データも削除 (Cascade設定済みだが念のため)
      await txn.delete('match_logs', where: 'match_id IN (SELECT id FROM matches WHERE team_id = ?)', whereArgs: [teamId]);
      await txn.delete('matches', where: 'team_id = ?', whereArgs: [teamId]);
      await txn.delete('action_definitions', where: 'team_id = ?', whereArgs: [teamId]);
      await txn.delete('items', where: 'team_id = ?', whereArgs: [teamId]);
      await txn.delete('fields', where: 'team_id = ?', whereArgs: [teamId]);
      await txn.delete('teams', where: 'id = ?', whereArgs: [teamId]);
    });
  }

  Future<List<Team>> getAllTeams() async {
    final db = await database;
    final List<Map<String, dynamic>> teamMaps = await db.query('teams');

    List<Team> teams = [];
    for (var map in teamMaps) {
      final teamId = map['id'] as String;

      final fieldMaps = await db.query('fields', where: 'team_id = ?', whereArgs: [teamId]);
      final schema = fieldMaps.map((f) => _mapToField(f)).toList();

      final itemMaps = await db.query('items', where: 'team_id = ?', whereArgs: [teamId]);
      final items = itemMaps.map((i) => _mapToItem(i)).toList();

      final hiddenFields = (jsonDecode(map['view_hidden_fields'] as String) as List).cast<String>();

      teams.add(Team(
        id: teamId,
        name: map['name'] as String,
        schema: schema,
        items: items,
        viewHiddenFields: hiddenFields,
      ));
    }
    return teams;
  }

  // --- スキーマ操作ヘルパー ---
  Future<void> _insertField(Transaction txn, String teamId, FieldDefinition field) async {
    await txn.insert(
      'fields',
      {
        'id': field.id,
        'team_id': teamId,
        'label': field.label,
        'type': field.type.index,
        'is_system': field.isSystem ? 1 : 0,
        'is_visible': field.isVisible ? 1 : 0,
        'use_dropdown': field.useDropdown ? 1 : 0,
        'is_range': field.isRange ? 1 : 0,
        'options': jsonEncode(field.options),
        'min_num': field.minNum,
        'max_num': field.maxNum,
        'is_unique': field.isUnique ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 公開メソッド
  Future<void> insertField(String teamId, FieldDefinition field) async {
    final db = await database;
    await db.transaction((txn) async { await _insertField(txn, teamId, field); });
  }

  Future<void> deleteField(String fieldId) async {
    final db = await database;
    await db.delete('fields', where: 'id = ?', whereArgs: [fieldId]);
  }

  Future<void> updateSchema(String teamId, List<FieldDefinition> schema) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('fields', where: 'team_id = ?', whereArgs: [teamId]);
      for (var field in schema) {
        await _insertField(txn, teamId, field);
      }
    });
  }

  Future<void> updateFieldVisibility(String fieldId, bool isVisible) async {
    final db = await database;
    await db.update('fields', {'is_visible': isVisible ? 1 : 0}, where: 'id = ?', whereArgs: [fieldId]);
  }

  Future<void> updateViewHiddenFields(String teamId, List<String> hiddenFields) async {
    final db = await database;
    await db.update('teams', {'view_hidden_fields': jsonEncode(hiddenFields)}, where: 'id = ?', whereArgs: [teamId]);
  }

  // --- アイテム操作 ---
  Future<void> insertItem(String teamId, RosterItem item) async {
    final db = await database;
    final jsonStr = jsonEncode(item.toJson()['data']);
    await db.insert(
      'items',
      {'id': item.id, 'team_id': teamId, 'data': jsonStr},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteItem(String itemId) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [itemId]);
  }

  // ==========================================
  //  Phase 2 追加メソッド: アクション定義
  // ==========================================

  Future<void> insertActionDefinition(String teamId, Map<String, dynamic> actionData) async {
    final db = await database;
    await db.insert('action_definitions', {
      'id': actionData['id'],
      'team_id': teamId,
      'name': actionData['name'],
      'sub_actions': jsonEncode(actionData['subActions'] ?? []),
      'is_sub_required': (actionData['isSubRequired'] ?? false) ? 1 : 0,
      'sort_order': actionData['sortOrder'] ?? 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getActionDefinitions(String teamId) async {
    final db = await database;
    final res = await db.query('action_definitions', where: 'team_id = ?', orderBy: 'sort_order ASC', whereArgs: [teamId]);
    return res.map((row) {
      return {
        'id': row['id'],
        'name': row['name'],
        'subActions': jsonDecode(row['sub_actions'] as String),
        'isSubRequired': row['is_sub_required'] == 1,
      };
    }).toList();
  }

  // ==========================================
  //  Phase 2 追加メソッド: 試合記録 (保存)
  // ==========================================

  /// 試合結果とログを一括保存する
  /// [matchData]: 試合ヘッダ情報 (id, opponent, date...)
  /// [logs]: ログリスト (List of Maps)
  Future<void> insertMatchWithLogs(String teamId, Map<String, dynamic> matchData, List<Map<String, dynamic>> logs) async {
    final db = await database;
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
      for (var log in logs) {
        await txn.insert('match_logs', {
          'id': log['id'],
          'match_id': matchData['id'],
          'game_time': log['gameTime'],
          'player_number': log['playerNumber'],
          'action': log['action'],
          'sub_action': log['subAction'], // null許容
          'log_type': log['type'], // 0 or 1
        });
      }
    });
  }

  /// チームごとの全試合履歴を取得 (概要のみ)
  Future<List<Map<String, dynamic>>> getMatches(String teamId) async {
    final db = await database;
    // 日付降順
    return await db.query('matches', where: 'team_id = ?', orderBy: 'date DESC, created_at DESC', whereArgs: [teamId]);
  }

  /// 特定の試合のログ詳細を取得
  Future<List<Map<String, dynamic>>> getMatchLogs(String matchId) async {
    final db = await database;
    // 時系列順 (ID作成順と仮定、またはgame_timeでソートが必要なら適宜)
    // ここでは保存順(通常は時系列)で取得
    return await db.query('match_logs', where: 'match_id = ?', whereArgs: [matchId]);
  }

  // ==========================================
  //  マッピング用ヘルパー
  // ==========================================

  FieldDefinition _mapToField(Map<String, dynamic> map) {
    return FieldDefinition(
      id: map['id'],
      label: map['label'],
      type: FieldType.values[map['type']],
      isSystem: map['is_system'] == 1,
      isVisible: map['is_visible'] == 1,
      useDropdown: map['use_dropdown'] == 1,
      isRange: map['is_range'] == 1,
      options: List<String>.from(jsonDecode(map['options'])),
      minNum: map['min_num'],
      maxNum: map['max_num'],
      isUnique: map['is_unique'] == 1,
    );
  }

  RosterItem _mapToItem(Map<String, dynamic> map) {
    final dataMap = jsonDecode(map['data']) as Map<String, dynamic>;
    return RosterItem.fromJson({'id': map['id'], 'data': dataMap});
  }
}