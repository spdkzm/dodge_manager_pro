import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// ファイルパスは現在の構成に合わせて相対パスに変更
import 'team.dart';
import 'schema.dart';
import 'roster_item.dart';
import 'database_helper.dart';

class TeamStore extends ChangeNotifier {
  static final TeamStore _instance = TeamStore._internal();
  factory TeamStore() => _instance;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  TeamStore._internal() {
    loadFromDb();
  }

  List<Team> teams = [];
  String? currentTeamId;
  bool isLoaded = false;

  Team? get currentTeam {
    if (teams.isEmpty) return null;
    return teams.firstWhere(
          (t) => t.id == currentTeamId,
      orElse: () => teams.isNotEmpty ? teams.first : teams.first,
    );
  }

  // --- DB読み込み ---
  Future<void> loadFromDb() async {
    try {
      teams = await _dbHelper.getAllTeams();

      if (teams.isNotEmpty) {
        currentTeamId = teams.first.id;
      } else {
        // 初回起動（DBが空）ならデフォルト作成
        _createDefaultTeam();
      }
    } catch (e) {
      debugPrint("DB Load Error: $e");
      _createDefaultTeam();
    } finally {
      isLoaded = true;
      notifyListeners();
    }
  }

  // --- 初期データ生成 ---
  void _createDefaultTeam() {
    final defaultSchema = _createSystemFields();
    final defaultTeam = Team(
      id: const Uuid().v4(),
      name: 'Aチーム',
      schema: defaultSchema,
      items: [],
    );
    teams.add(defaultTeam);
    currentTeamId = defaultTeam.id;
    _dbHelper.insertTeam(defaultTeam); // DBへ保存
  }

  List<FieldDefinition> _createSystemFields() {
    return [
      // ★追加: 背番号をシステム標準項目として定義 (重複禁止: true推奨)
      FieldDefinition(label: '背番号', type: FieldType.uniformNumber, isSystem: true, isUnique: true),

      FieldDefinition(label: '氏名', type: FieldType.personName, isSystem: true),
      FieldDefinition(label: 'フリガナ', type: FieldType.personKana, isSystem: true),
      FieldDefinition(label: '生年月日', type: FieldType.date, isSystem: true),
      FieldDefinition(label: '年齢', type: FieldType.age, isSystem: true),
      FieldDefinition(label: '住所', type: FieldType.address, isSystem: true),
      FieldDefinition(label: '電話番号', type: FieldType.phone, isSystem: true),
    ];
  }

  // --- チーム操作 ---

  void addTeam(String name) {
    final newTeam = Team(
      id: const Uuid().v4(),
      name: name,
      schema: _createSystemFields(),
    );
    teams.add(newTeam);
    if (teams.length == 1) currentTeamId = newTeam.id;

    _dbHelper.insertTeam(newTeam); // DB保存
    notifyListeners();
  }

  void updateTeamName(Team team, String newName) {
    team.name = newName;
    _dbHelper.updateTeamName(team.id, newName); // DB更新
    notifyListeners();
  }

  void deleteTeam(Team team) {
    teams.remove(team);
    if (currentTeamId == team.id) {
      currentTeamId = teams.isNotEmpty ? teams.first.id : null;
    }
    _dbHelper.deleteTeam(team.id); // DB削除
    notifyListeners();
  }

  void selectTeam(String teamId) {
    currentTeamId = teamId;
    notifyListeners();
  }

  // --- スキーマ操作 ---

  void saveSchema(String teamId, List<FieldDefinition> newSchema) {
    final teamIndex = teams.indexWhere((t) => t.id == teamId);
    if (teamIndex != -1) {
      teams[teamIndex].schema = newSchema;
      _dbHelper.updateSchema(teamId, newSchema); // DB更新（スキーマ一括）
      notifyListeners();
    }
  }

  void addField(String teamId, FieldDefinition field) {
    final team = teams.firstWhere((t) => t.id == teamId);
    team.schema.add(field);
    _dbHelper.insertField(teamId, field); // DB追加
    notifyListeners();
  }

  void deleteField(String teamId, FieldDefinition field) {
    final team = teams.firstWhere((t) => t.id == teamId);
    team.schema.remove(field);
    _dbHelper.deleteField(field.id); // DB削除
    notifyListeners();
  }

  // ON/OFFの更新
  void updateField(String teamId, FieldDefinition field) {
    _dbHelper.updateFieldVisibility(field.id, field.isVisible); // DB更新
    notifyListeners();
  }

  void reorderSchema(String teamId, int oldIndex, int newIndex) {
    final team = teams.firstWhere((t) => t.id == teamId);
    if (oldIndex < newIndex) newIndex -= 1;
    final item = team.schema.removeAt(oldIndex);
    team.schema.insert(newIndex, item);

    _dbHelper.updateSchema(teamId, team.schema); // DB更新
    notifyListeners();
  }

  // --- 表示フィルター操作 ---

  void toggleViewColumn(String teamId, String fieldId) {
    final team = teams.firstWhere((t) => t.id == teamId);
    if (team.viewHiddenFields.contains(fieldId)) {
      team.viewHiddenFields.remove(fieldId);
    } else {
      team.viewHiddenFields.add(fieldId);
    }
    _dbHelper.updateViewHiddenFields(teamId, team.viewHiddenFields); // DB更新
    notifyListeners();
  }

  // --- データ操作 ---

  void addItem(String teamId, RosterItem item) {
    final team = teams.firstWhere((t) => t.id == teamId);
    team.items.add(item);
    _dbHelper.insertItem(teamId, item); // DB追加
    notifyListeners();
  }

  void updateItem() {
    notifyListeners();
  }

  void saveItem(String teamId, RosterItem item) {
    _dbHelper.insertItem(teamId, item); // DB上書き保存
    notifyListeners();
  }

  void deleteItem(String teamId, RosterItem item) {
    final team = teams.firstWhere((t) => t.id == teamId);
    team.items.remove(item);
    _dbHelper.deleteItem(item.id); // DB削除
    notifyListeners();
  }
}