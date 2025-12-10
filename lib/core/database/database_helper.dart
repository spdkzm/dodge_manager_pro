// lib/core/database/database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  static const String _dbName = 'dodge_manager_v7.db';
  // ★修正: バージョンを6に上げる
  static const int _dbVersion = 6;

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
      onUpgrade: _onUpgrade,
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
        view_hidden_fields TEXT,
        player_id_map TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE fields(
        id TEXT PRIMARY KEY,
        team_id TEXT,
        label TEXT,
        type INTEGER,
        is_system INTEGER,
        is_visible INTEGER,
        is_required INTEGER DEFAULT 0,
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
        result INTEGER DEFAULT 0,
        score_own INTEGER,
        score_opponent INTEGER,
        is_extra_time INTEGER DEFAULT 0,
        extra_score_own INTEGER,
        extra_score_opponent INTEGER,
        created_at TEXT,
        FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
      )
    ''');

    // ★修正: player_id カラム追加
    await db.execute('''
      CREATE TABLE match_logs(
        id TEXT PRIMARY KEY,
        match_id TEXT,
        game_time TEXT,
        player_number TEXT,
        player_id TEXT, 
        action TEXT,
        sub_action TEXT,
        log_type INTEGER,
        result INTEGER,
        FOREIGN KEY(match_id) REFERENCES matches(id) ON DELETE CASCADE
      )
    ''');

    // ★修正: player_id カラム追加
    await db.execute('''
      CREATE TABLE match_participations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id TEXT,
        player_number TEXT,
        player_id TEXT,
        FOREIGN KEY(match_id) REFERENCES matches(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE fields ADD COLUMN category INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE items ADD COLUMN category INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE matches ADD COLUMN opponent_id TEXT");
      await db.execute("ALTER TABLE matches ADD COLUMN venue_name TEXT");
      await db.execute("ALTER TABLE matches ADD COLUMN venue_id TEXT");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE fields ADD COLUMN is_required INTEGER DEFAULT 0");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE matches ADD COLUMN result INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE matches ADD COLUMN score_own INTEGER");
      await db.execute("ALTER TABLE matches ADD COLUMN score_opponent INTEGER");
      await db.execute("ALTER TABLE matches ADD COLUMN is_extra_time INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE matches ADD COLUMN extra_score_own INTEGER");
      await db.execute("ALTER TABLE matches ADD COLUMN extra_score_opponent INTEGER");
    }
    if (oldVersion < 5) {
      final columns = await db.rawQuery("PRAGMA table_info(teams)");
      final hasColumn = columns.any((col) => col['name'] == 'player_id_map');
      if (!hasColumn) {
        await db.execute("ALTER TABLE teams ADD COLUMN player_id_map TEXT");
      }
    }
    // ★追加: v6への移行 (player_id追加)
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE match_logs ADD COLUMN player_id TEXT");
      await db.execute("ALTER TABLE match_participations ADD COLUMN player_id TEXT");
    }
  }

  Future<void> _onOpen(Database db) async {
    final result = await db.rawQuery("PRAGMA table_info(matches)");
    final hasMatchType = result.any((col) => col['name'] == 'match_type');
    if (!hasMatchType) {
      await db.execute("ALTER TABLE matches ADD COLUMN match_type INTEGER DEFAULT 0");
    }
  }
}