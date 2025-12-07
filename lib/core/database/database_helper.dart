// lib/core/database/database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  static const String _dbName = 'dodge_manager_v7.db';
  // ★修正: バージョンを2に上げる
  static const int _dbVersion = 2;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // ★追加: マイグレーション
      onOpen: _onOpen,
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _database = null;
  }

  Future<String> getDbPath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _dbName);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE teams(
        id TEXT PRIMARY KEY,
        name TEXT,
        view_hidden_fields TEXT
      )
    ''');

    // ★修正: categoryカラムを追加 (0:選手, 1:対戦相手, 2:会場)
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
        category INTEGER DEFAULT 0, 
        FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
      )
    ''');

    // ★修正: categoryカラムを追加
    await db.execute('''
      CREATE TABLE items(
        id TEXT PRIMARY KEY,
        team_id TEXT,
        data TEXT,
        category INTEGER DEFAULT 0,
        FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
      )
    ''');

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

    // ★修正: opponent_id, venue_name, venue_id を追加
    await db.execute('''
      CREATE TABLE matches(
        id TEXT PRIMARY KEY,
        team_id TEXT,
        opponent TEXT,
        opponent_id TEXT,
        venue_name TEXT,
        venue_id TEXT,
        date TEXT,
        match_type INTEGER DEFAULT 0,
        created_at TEXT,
        FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
      )
    ''');

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

    await db.execute('''
      CREATE TABLE match_participations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id TEXT,
        player_number TEXT,
        FOREIGN KEY(match_id) REFERENCES matches(id) ON DELETE CASCADE
      )
    ''');
  }

  // ★追加: マイグレーション処理
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // fieldsテーブルにcategory追加
      await db.execute("ALTER TABLE fields ADD COLUMN category INTEGER DEFAULT 0");
      // itemsテーブルにcategory追加
      await db.execute("ALTER TABLE items ADD COLUMN category INTEGER DEFAULT 0");
      // matchesテーブルにカラム追加
      await db.execute("ALTER TABLE matches ADD COLUMN opponent_id TEXT");
      await db.execute("ALTER TABLE matches ADD COLUMN venue_name TEXT");
      await db.execute("ALTER TABLE matches ADD COLUMN venue_id TEXT");
    }
  }

  Future<void> _onOpen(Database db) async {
    // 念のためmatch_typeのカラムチェック（古いバージョンからの移行用）
    final result = await db.rawQuery("PRAGMA table_info(matches)");
    final hasMatchType = result.any((col) => col['name'] == 'match_type');
    if (!hasMatchType) {
      await db.execute("ALTER TABLE matches ADD COLUMN match_type INTEGER DEFAULT 0");
    }
  }
}