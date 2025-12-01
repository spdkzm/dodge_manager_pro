// lib/core/database/database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
    // バージョンは変えずに、起動時にカラムチェックを行う方式で安全に移行します
    final path = join(dbPath, 'dodge_manager_v7.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: _onOpen, // ★追加: DBを開いた時にマイグレーションチェック
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. チーム
    await db.execute('''
      CREATE TABLE teams(
        id TEXT PRIMARY KEY,
        name TEXT,
        view_hidden_fields TEXT
      )
    ''');

    // 2. フィールド
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

    // 3. アイテム
    await db.execute('''
      CREATE TABLE items(
        id TEXT PRIMARY KEY,
        team_id TEXT,
        data TEXT,
        FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
      )
    ''');

    // 4. アクション定義
    await db.execute('''
      CREATE TABLE action_definitions(
        id TEXT PRIMARY KEY,
        team_id TEXT,
        name TEXT,
        sub_actions TEXT, 
        is_sub_required INTEGER,
        sort_order INTEGER,
        position_index INTEGER,
        success_position_index INTEGER,
        failure_position_index INTEGER,
        has_success INTEGER,
        has_failure INTEGER,
        FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
      )
    ''');

    // 5. 試合結果
    await db.execute('''
      CREATE TABLE matches(
        id TEXT PRIMARY KEY,
        team_id TEXT,
        opponent TEXT,
        date TEXT,
        match_type INTEGER DEFAULT 0, -- ★追加: 試合種別 (0=練習試合)
        created_at TEXT,
        FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
      )
    ''');

    // 6. 試合ログ
    await db.execute('''
      CREATE TABLE match_logs(
        id TEXT PRIMARY KEY,
        match_id TEXT,
        game_time TEXT,
        player_number TEXT,
        action TEXT,
        sub_action TEXT,
        log_type INTEGER,
        result INTEGER,
        FOREIGN KEY(match_id) REFERENCES matches(id) ON DELETE CASCADE
      )
    ''');

    // 7. 試合出場記録
    await db.execute('''
      CREATE TABLE match_participations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id TEXT,
        player_number TEXT,
        FOREIGN KEY(match_id) REFERENCES matches(id) ON DELETE CASCADE
      )
    ''');
  }

  // ★追加: 既存DBへのカラム追加処理
  Future<void> _onOpen(Database db) async {
    // matchesテーブルに match_type カラムがあるか確認
    final result = await db.rawQuery("PRAGMA table_info(matches)");
    final hasMatchType = result.any((col) => col['name'] == 'match_type');

    if (!hasMatchType) {
      // カラムがなければ追加 (デフォルト0 = 練習試合)
      await db.execute("ALTER TABLE matches ADD COLUMN match_type INTEGER DEFAULT 0");
    }
  }
}