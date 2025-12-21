// lib/features/team_mgmt/application/team_store.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/team.dart';
import '../domain/schema.dart';
import '../domain/roster_item.dart';
import '../domain/roster_category.dart';
import '../data/team_dao.dart';
import '../../game_record/data/match_dao.dart';

final teamStoreProvider = ChangeNotifierProvider<TeamStore>((ref) {
  return TeamStore();
});

class TeamStore extends ChangeNotifier {
  final TeamDao _teamDao = TeamDao();
  final MatchDao _matchDao = MatchDao(); // ignore: unused_field

  bool _isCleanupDone = false;

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

        if (!_isCleanupDone) {
          for (var team in teams) {
            await _cleanupDuplicateSystemFields(team, RosterCategory.opponent);
            await _cleanupDuplicateSystemFields(team, RosterCategory.venue);
            // ★追加: 既存の「背番号」フィールドをスキーマから削除する
            await _removeLegacyUniformNumberField(team);
          }
          _isCleanupDone = true;
        }

        for (var team in teams) {
          if (team.opponentSchema.isEmpty) {
            _initOpponentSchema(team);
            for (var f in team.opponentSchema) {
              await _teamDao.insertField(team.id, f, RosterCategory.opponent);
            }
          }
          if (team.venueSchema.isEmpty) {
            _initVenueSchema(team);
            for (var f in team.venueSchema) {
              await _teamDao.insertField(team.id, f, RosterCategory.venue);
            }
          }
        }
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

  // ★追加: 旧来の背番号フィールド(FieldType.uniformNumber)を削除する処理
  Future<void> _removeLegacyUniformNumberField(Team team) async {
    final schema = team.getSchema(RosterCategory.player);
    final toRemove = <FieldDefinition>[];

    for (var field in schema) {
      if (field.type == FieldType.uniformNumber) {
        toRemove.add(field);
      }
    }

    for (var field in toRemove) {
      team.schema.remove(field);
      await _teamDao.deleteField(field.id);
    }
  }

  Future<void> _cleanupDuplicateSystemFields(Team team, RosterCategory category) async {
    final schema = team.getSchema(category);
    final seenLabels = <String>{};
    final toRemove = <FieldDefinition>[];

    for (var field in schema) {
      if (field.isSystem) {
        if (seenLabels.contains(field.label)) {
          toRemove.add(field);
        } else {
          seenLabels.add(field.label);
        }
      }
    }

    for (var field in toRemove) {
      if (category == RosterCategory.opponent) {
        team.opponentSchema.remove(field);
      } else if (category == RosterCategory.venue) {
        team.venueSchema.remove(field);
      }
      await _teamDao.deleteField(field.id);
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
    _initOpponentSchema(defaultTeam);
    _initVenueSchema(defaultTeam);
    teams.add(defaultTeam);
    currentTeamId = defaultTeam.id;
    _teamDao.insertTeam(defaultTeam);
  }

  List<FieldDefinition> _createSystemFields() {
    return [
      // ★修正: 背番号(uniformNumber)を削除
      FieldDefinition(label: 'コートネーム', type: FieldType.courtName, isSystem: true, isRequired: true),
      FieldDefinition(label: '氏名', type: FieldType.personName, isSystem: true, isRequired: true),
      FieldDefinition(label: 'フリガナ', type: FieldType.personKana, isSystem: true, isVisible: false),
      FieldDefinition(label: '生年月日', type: FieldType.date, isSystem: true, isVisible: false),
      FieldDefinition(label: '年齢', type: FieldType.age, isSystem: true, isVisible: false),
      FieldDefinition(label: '住所', type: FieldType.address, isSystem: true, isVisible: false),
      FieldDefinition(label: '電話番号', type: FieldType.phone, isSystem: true, isVisible: false),
    ];
  }

  void _initOpponentSchema(Team team) { team.opponentSchema = [ FieldDefinition(label: 'チーム名', type: FieldType.text, isSystem: true, isUnique: true, isRequired: true), ]; }
  void _initVenueSchema(Team team) { team.venueSchema = [ FieldDefinition(label: '会場名', type: FieldType.text, isSystem: true, isUnique: true, isRequired: true), ]; }
  void addTeam(String name) { final newTeam = Team( id: const Uuid().v4(), name: name, schema: _createSystemFields(), ); _initOpponentSchema(newTeam); _initVenueSchema(newTeam); teams.add(newTeam); if (teams.length == 1) currentTeamId = newTeam.id; _teamDao.insertTeam(newTeam); notifyListeners(); }
  void updateTeamName(Team team, String newName) { team.name = newName; _teamDao.updateTeamName(team.id, newName); notifyListeners(); }
  void deleteTeam(Team team) { teams.remove(team); if (currentTeamId == team.id) { currentTeamId = teams.isNotEmpty ? teams.first.id : null; } _teamDao.deleteTeam(team.id); notifyListeners(); }
  void selectTeam(String teamId) { currentTeamId = teamId; notifyListeners(); }
  void saveSchema(String teamId, List<FieldDefinition> newSchema, {RosterCategory category = RosterCategory.player}) { final team = teams.firstWhere((t) => t.id == teamId); team.setSchema(category, newSchema); _teamDao.updateSchema(teamId, newSchema, category); notifyListeners(); }
  void toggleViewColumn(String teamId, String fieldId) { final team = teams.firstWhere((t) => t.id == teamId); if (team.viewHiddenFields.contains(fieldId)) { team.viewHiddenFields.remove(fieldId); } else { team.viewHiddenFields.add(fieldId); } _teamDao.updateViewHiddenFields(teamId, team.viewHiddenFields); notifyListeners(); }
  void addItem(String teamId, RosterItem item, {RosterCategory category = RosterCategory.player}) { final team = teams.firstWhere((t) => t.id == teamId); team.getItems(category).add(item); _teamDao.insertItem(teamId, item, category); notifyListeners(); }
  void saveItem(String teamId, RosterItem item, {RosterCategory category = RosterCategory.player}) { _teamDao.insertItem(teamId, item, category); notifyListeners(); }
  void deleteItem(String teamId, RosterItem item, {RosterCategory category = RosterCategory.player}) { final team = teams.firstWhere((t) => t.id == teamId); team.getItems(category).remove(item); _teamDao.deleteItem(item.id); notifyListeners(); }
  Future<String> ensureItemExists(String name, RosterCategory category) async { final team = currentTeam; if (team == null || name.trim().isEmpty) return ""; final items = team.getItems(category); final schema = team.getSchema(category); if (schema.isEmpty) return ""; final nameField = schema.firstWhere((f) => f.label.contains("名") || f.type == FieldType.text, orElse: () => schema.first); for (var item in items) { final val = item.data[nameField.id]?.toString() ?? ""; if (val == name) { return item.id; } } final newItem = RosterItem(data: {nameField.id: name}); addItem(team.id, newItem, category: category); return newItem.id; }
  Future<int> checkMatchInfoUsage(RosterCategory category, String name) async { final teamId = currentTeamId; if (teamId == null) return 0; if (category == RosterCategory.opponent) { return await _matchDao.countOpponentNameUsage(teamId, name); } else if (category == RosterCategory.venue) { return await _matchDao.countVenueNameUsage(teamId, name); } return 0; }
  Future<void> updateMatchInfoName(RosterCategory category, String oldName, String newName) async { final teamId = currentTeamId; if (teamId == null) return; if (category == RosterCategory.opponent) { await _matchDao.updateOpponentName(teamId, oldName, newName); } else if (category == RosterCategory.venue) { await _matchDao.updateVenueName(teamId, oldName, newName); } }
}