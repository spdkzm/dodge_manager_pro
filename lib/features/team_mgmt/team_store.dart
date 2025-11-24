import 'package:flutter/material.dart';
import 'package:dodge_manager_pro/features/team_mgmt/team.dart';
import 'package:dodge_manager_pro/features/team_mgmt/schema.dart';
import 'package:dodge_manager_pro/features/team_mgmt/roster_item.dart';
import 'package:dodge_manager_pro/features/team_mgmt/database_helper.dart'; // 変更
import 'package:uuid/uuid.dart';

class TeamStore extends ChangeNotifier {
  static final TeamStore _instance = TeamStore._internal();
  factory TeamStore() => _instance;

  final DatabaseHelper _dbHelper = DatabaseHelper(); // DBヘルパー

  TeamStore._internal() {
    loadFromDb(); // DBからロード
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
    // fieldオブジェクトは参照渡しですでに変更されている前提
    _dbHelper.updateFieldVisibility(field.id, field.isVisible); // DB更新
    notifyListeners();
  }

  void reorderSchema(String teamId, int oldIndex, int newIndex) {
    final team = teams.firstWhere((t) => t.id == teamId);
    if (oldIndex < newIndex) newIndex -= 1;
    final item = team.schema.removeAt(oldIndex);
    team.schema.insert(newIndex, item);

    _dbHelper.updateSchema(teamId, team.schema); // DB更新（順序保存のため一括）
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
    // UI側でオブジェクトの中身を直接書き換えている場合があるため、
    // 厳密には変更があったItemを特定して _dbHelper.insertItem(..., replace) すべきだが、
    // ここでは簡易的にStoreへの通知のみで、Itemの保存は個別に呼ばれる想定にするか、
    // または編集画面の保存時に addItem ではなく updateItemToDb のようなメソッドを呼ぶ形が望ましい。
    // ※ 今回のUI実装では _showItemDialog 内で updateItem() を呼んでいる。
    // そのため、以下のように修正する。

    // 注意: UI側の _showItemDialog で `item!.data = tempData` した後に呼ばれる。
    // しかし、どのアイテムが変更されたか引数がないため、実用上は UI側で saveItem(item) を呼ぶ形に変えるのがベスト。
    // 今回は「変更通知」としての役割のみ残し、保存はUI側で `saveItem` を呼ぶようにメソッドを追加する。
    notifyListeners();
  }

  // ▼▼▼ 追加：既存アイテムの保存用メソッド ▼▼▼
  void saveItem(String teamId, RosterItem item) {
    // メモリ上の更新は参照渡しですでに終わっている前提
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