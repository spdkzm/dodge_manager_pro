import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// Domain & Data
import '../domain/team.dart';
import '../domain/schema.dart';
import '../domain/roster_item.dart';
import '../data/team_dao.dart';

// ★追加: アプリ全体で共有するTeamStoreのプロバイダー
final teamStoreProvider = ChangeNotifierProvider<TeamStore>((ref) {
  return TeamStore();
});

class TeamStore extends ChangeNotifier {
  // ★削除: シングルトン関連のコード (_instance, factory)

  final TeamDao _teamDao = TeamDao();

  // コンストラクタ
  TeamStore() {
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

  Future<void> loadFromDb() async {
    try {
      teams = await _teamDao.getAllTeams();

      if (teams.isNotEmpty) {
        currentTeamId = teams.first.id;
      } else {
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
    _teamDao.insertTeam(defaultTeam);
  }

  List<FieldDefinition> _createSystemFields() {
    return [
      FieldDefinition(label: '背番号', type: FieldType.uniformNumber, isSystem: true, isUnique: true),
      FieldDefinition(label: 'コートネーム', type: FieldType.courtName, isSystem: true),

      FieldDefinition(label: '氏名', type: FieldType.personName, isSystem: true),
      FieldDefinition(label: 'フリガナ', type: FieldType.personKana, isSystem: true, isVisible: false),
      FieldDefinition(label: '生年月日', type: FieldType.date, isSystem: true, isVisible: false),
      FieldDefinition(label: '年齢', type: FieldType.age, isSystem: true, isVisible: false),
      FieldDefinition(label: '住所', type: FieldType.address, isSystem: true, isVisible: false),
      FieldDefinition(label: '電話番号', type: FieldType.phone, isSystem: true, isVisible: false),
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

    _teamDao.insertTeam(newTeam);
    notifyListeners();
  }

  void updateTeamName(Team team, String newName) {
    team.name = newName;
    _teamDao.updateTeamName(team.id, newName);
    notifyListeners();
  }

  void deleteTeam(Team team) {
    teams.remove(team);
    if (currentTeamId == team.id) {
      currentTeamId = teams.isNotEmpty ? teams.first.id : null;
    }
    _teamDao.deleteTeam(team.id);
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
      _teamDao.updateSchema(teamId, newSchema);
      notifyListeners();
    }
  }

  void addField(String teamId, FieldDefinition field) {
    final team = teams.firstWhere((t) => t.id == teamId);
    team.schema.add(field);
    _teamDao.insertField(teamId, field);
    notifyListeners();
  }

  void deleteField(String teamId, FieldDefinition field) {
    final team = teams.firstWhere((t) => t.id == teamId);
    team.schema.remove(field);
    _teamDao.deleteField(field.id);
    notifyListeners();
  }

  void updateField(String teamId, FieldDefinition field) {
    _teamDao.updateFieldVisibility(field.id, field.isVisible);
    notifyListeners();
  }

  void reorderSchema(String teamId, int oldIndex, int newIndex) {
    final team = teams.firstWhere((t) => t.id == teamId);
    if (oldIndex < newIndex) newIndex -= 1;
    final item = team.schema.removeAt(oldIndex);
    team.schema.insert(newIndex, item);

    _teamDao.updateSchema(teamId, team.schema);
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
    _teamDao.updateViewHiddenFields(teamId, team.viewHiddenFields);
    notifyListeners();
  }

  // --- データ操作 ---

  void addItem(String teamId, RosterItem item) {
    final team = teams.firstWhere((t) => t.id == teamId);
    team.items.add(item);
    _teamDao.insertItem(teamId, item);
    notifyListeners();
  }

  void updateItem() {
    notifyListeners();
  }

  void saveItem(String teamId, RosterItem item) {
    _teamDao.insertItem(teamId, item);
    notifyListeners();
  }

  void deleteItem(String teamId, RosterItem item) {
    final team = teams.firstWhere((t) => t.id == teamId);
    team.items.remove(item);
    _teamDao.deleteItem(item.id);
    notifyListeners();
  }
}