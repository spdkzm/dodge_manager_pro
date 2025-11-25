// lib/features/team_mgmt/team_store.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'team.dart';
import 'schema.dart';
import 'roster_item.dart';
import 'data/team_dao.dart'; // ★変更: DAOをインポート

class TeamStore extends ChangeNotifier {
  static final TeamStore _instance = TeamStore._internal();
  factory TeamStore() => _instance;

  final TeamDao _teamDao = TeamDao(); // ★変更: Helper -> Dao

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

  Future<void> loadFromDb() async {
    try {
      teams = await _teamDao.getAllTeams(); // ★Dao使用

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
    _teamDao.insertTeam(defaultTeam); // ★Dao使用
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

    _teamDao.insertTeam(newTeam); // ★Dao使用
    notifyListeners();
  }

  void updateTeamName(Team team, String newName) {
    team.name = newName;
    _teamDao.updateTeamName(team.id, newName); // ★Dao使用
    notifyListeners();
  }

  void deleteTeam(Team team) {
    teams.remove(team);
    if (currentTeamId == team.id) {
      currentTeamId = teams.isNotEmpty ? teams.first.id : null;
    }
    _teamDao.deleteTeam(team.id); // ★Dao使用
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
      _teamDao.updateSchema(teamId, newSchema); // ★Dao使用
      notifyListeners();
    }
  }

  void addField(String teamId, FieldDefinition field) {
    final team = teams.firstWhere((t) => t.id == teamId);
    team.schema.add(field);
    _teamDao.insertField(teamId, field); // ★Dao使用
    notifyListeners();
  }

  void deleteField(String teamId, FieldDefinition field) {
    final team = teams.firstWhere((t) => t.id == teamId);
    team.schema.remove(field);
    _teamDao.deleteField(field.id); // ★Dao使用
    notifyListeners();
  }

  void updateField(String teamId, FieldDefinition field) {
    _teamDao.updateFieldVisibility(field.id, field.isVisible); // ★Dao使用
    notifyListeners();
  }

  void reorderSchema(String teamId, int oldIndex, int newIndex) {
    final team = teams.firstWhere((t) => t.id == teamId);
    if (oldIndex < newIndex) newIndex -= 1;
    final item = team.schema.removeAt(oldIndex);
    team.schema.insert(newIndex, item);

    _teamDao.updateSchema(teamId, team.schema); // ★Dao使用
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
    _teamDao.updateViewHiddenFields(teamId, team.viewHiddenFields); // ★Dao使用
    notifyListeners();
  }

  // --- データ操作 ---

  void addItem(String teamId, RosterItem item) {
    final team = teams.firstWhere((t) => t.id == teamId);
    team.items.add(item);
    _teamDao.insertItem(teamId, item); // ★Dao使用
    notifyListeners();
  }

  void updateItem() {
    notifyListeners();
  }

  void saveItem(String teamId, RosterItem item) {
    _teamDao.insertItem(teamId, item); // ★Dao使用
    notifyListeners();
  }

  void deleteItem(String teamId, RosterItem item) {
    final team = teams.firstWhere((t) => t.id == teamId);
    team.items.remove(item);
    _teamDao.deleteItem(item.id); // ★Dao使用
    notifyListeners();
  }
}