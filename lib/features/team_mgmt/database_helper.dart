import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dodge_manager_pro/features/team_mgmt/team.dart';
import 'package:dodge_manager_pro/features/team_mgmt/schema.dart';
import 'package:dodge_manager_pro/features/team_mgmt/roster_item.dart';

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
    final path = join(dbPath, 'roster_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
    // 中身のデータ(Map)はJSON文字列としてまとめて保存する
    await db.execute('''
      CREATE TABLE items(
        id TEXT PRIMARY KEY,
        team_id TEXT,
        data TEXT,
        FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
      )
    ''');
  }

  // --- チーム操作 ---

  Future<void> insertTeam(Team team) async {
    final db = await database;
    await db.transaction((txn) async {
      // チーム本体
      await txn.insert(
        'teams',
        {
          'id': team.id,
          'name': team.name,
          'view_hidden_fields': jsonEncode(team.viewHiddenFields),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // 関連するスキーマも保存
      for (var field in team.schema) {
        await _insertField(txn, team.id, field);
      }
    });
  }

  Future<void> updateTeamName(String teamId, String name) async {
    final db = await database;
    await db.update(
      'teams',
      {'name': name},
      where: 'id = ?',
      whereArgs: [teamId],
    );
  }

  Future<void> deleteTeam(String teamId) async {
    final db = await database;
    // CASCADE設定が効かない場合があるため手動で子要素も消すのが安全
    await db.transaction((txn) async {
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

      // スキーマ取得
      final fieldMaps = await db.query('fields', where: 'team_id = ?', whereArgs: [teamId]);
      final schema = fieldMaps.map((f) => _mapToField(f)).toList();

      // アイテム取得
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

  // --- スキーマ操作 ---

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

  // 単体での追加（TeamStoreから呼ばれる）
  Future<void> insertField(String teamId, FieldDefinition field) async {
    final db = await database;
    await db.transaction((txn) async {
      await _insertField(txn, teamId, field);
    });
  }

  Future<void> deleteField(String fieldId) async {
    final db = await database;
    await db.delete('fields', where: 'id = ?', whereArgs: [fieldId]);
  }

  // スキーマ全体を更新（並び替え時など）
  Future<void> updateSchema(String teamId, List<FieldDefinition> schema) async {
    final db = await database;
    await db.transaction((txn) async {
      // 一旦全削除して入れ直すのが最も整合性がとりやすい
      await txn.delete('fields', where: 'team_id = ?', whereArgs: [teamId]);
      for (var field in schema) {
        await _insertField(txn, teamId, field);
      }
    });
  }

  Future<void> updateFieldVisibility(String fieldId, bool isVisible) async {
    final db = await database;
    await db.update(
      'fields',
      {'is_visible': isVisible ? 1 : 0},
      where: 'id = ?',
      whereArgs: [fieldId],
    );
  }

  // --- アイテム操作 ---

  Future<void> insertItem(String teamId, RosterItem item) async {
    final db = await database;
    // item.toJson()はデータ整形用だが、ここではDB保存用に再整形
    // RosterItem.toJson() はDateTimeをラップするので、それをそのまま文字列化する
    final jsonStr = jsonEncode(item.toJson()['data']);

    await db.insert(
      'items',
      {
        'id': item.id,
        'team_id': teamId,
        'data': jsonStr,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteItem(String itemId) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [itemId]);
  }

  // --- 表示フィルター操作 ---
  Future<void> updateViewHiddenFields(String teamId, List<String> hiddenFields) async {
    final db = await database;
    await db.update(
      'teams',
      {'view_hidden_fields': jsonEncode(hiddenFields)},
      where: 'id = ?',
      whereArgs: [teamId],
    );
  }

  // --- マッピング用ヘルパー ---

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
    // DBに保存されたJSON文字列をMapに戻す
    final dataMap = jsonDecode(map['data']) as Map<String, dynamic>;
    // RosterItem.fromJson のロジックを利用してDateTime等を復元
    return RosterItem.fromJson({'id': map['id'], 'data': dataMap});
  }
}