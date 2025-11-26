import 'dart:convert';
import 'package:sqflite/sqflite.dart';

// Core
import '../../../core/database/database_helper.dart';

// Domain
import '../domain/team.dart';
import '../domain/schema.dart';
import '../domain/roster_item.dart';

class TeamDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> insertTeam(Team team) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('teams', {
        'id': team.id,
        'name': team.name,
        'view_hidden_fields': jsonEncode(team.viewHiddenFields),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      for (var field in team.schema) {
        await _insertField(txn, team.id, field);
      }
    });
  }

  Future<void> updateTeamName(String teamId, String name) async {
    final db = await _dbHelper.database;
    await db.update('teams', {'name': name}, where: 'id = ?', whereArgs: [teamId]);
  }

  Future<void> deleteTeam(String teamId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 関連データ削除
      await txn.delete('match_logs', where: 'match_id IN (SELECT id FROM matches WHERE team_id = ?)', whereArgs: [teamId]);
      await txn.delete('matches', where: 'team_id = ?', whereArgs: [teamId]);
      await txn.delete('action_definitions', where: 'team_id = ?', whereArgs: [teamId]);
      await txn.delete('items', where: 'team_id = ?', whereArgs: [teamId]);
      await txn.delete('fields', where: 'team_id = ?', whereArgs: [teamId]);
      await txn.delete('teams', where: 'id = ?', whereArgs: [teamId]);
    });
  }

  Future<List<Team>> getAllTeams() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> teamMaps = await db.query('teams');
    List<Team> teams = [];
    for (var map in teamMaps) {
      final teamId = map['id'] as String;
      final fieldMaps = await db.query('fields', where: 'team_id = ?', whereArgs: [teamId]);
      final schema = fieldMaps.map((f) => _mapToField(f)).toList();
      final itemMaps = await db.query('items', where: 'team_id = ?', whereArgs: [teamId]);
      final items = itemMaps.map((i) => _mapToItem(i)).toList();
      final hiddenFields = (jsonDecode(map['view_hidden_fields'] as String) as List).cast<String>();
      teams.add(Team(id: teamId, name: map['name'] as String, schema: schema, items: items, viewHiddenFields: hiddenFields));
    }
    return teams;
  }

  // Schema & Items
  Future<void> _insertField(Transaction txn, String teamId, FieldDefinition field) async {
    await txn.insert('fields', {
      'id': field.id, 'team_id': teamId, 'label': field.label, 'type': field.type.index,
      'is_system': field.isSystem ? 1 : 0, 'is_visible': field.isVisible ? 1 : 0,
      'use_dropdown': field.useDropdown ? 1 : 0, 'is_range': field.isRange ? 1 : 0,
      'options': jsonEncode(field.options), 'min_num': field.minNum, 'max_num': field.maxNum,
      'is_unique': field.isUnique ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertField(String teamId, FieldDefinition field) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async { await _insertField(txn, teamId, field); });
  }

  Future<void> deleteField(String fieldId) async {
    final db = await _dbHelper.database;
    await db.delete('fields', where: 'id = ?', whereArgs: [fieldId]);
  }

  Future<void> updateSchema(String teamId, List<FieldDefinition> schema) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('fields', where: 'team_id = ?', whereArgs: [teamId]);
      for (var field in schema) { await _insertField(txn, teamId, field); }
    });
  }

  Future<void> updateFieldVisibility(String fieldId, bool isVisible) async {
    final db = await _dbHelper.database;
    await db.update('fields', {'is_visible': isVisible ? 1 : 0}, where: 'id = ?', whereArgs: [fieldId]);
  }

  Future<void> updateViewHiddenFields(String teamId, List<String> hiddenFields) async {
    final db = await _dbHelper.database;
    await db.update('teams', {'view_hidden_fields': jsonEncode(hiddenFields)}, where: 'id = ?', whereArgs: [teamId]);
  }

  Future<void> insertItem(String teamId, RosterItem item) async {
    final db = await _dbHelper.database;
    final jsonStr = jsonEncode(item.toJson()['data']);
    await db.insert('items', {'id': item.id, 'team_id': teamId, 'data': jsonStr}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteItem(String itemId) async {
    final db = await _dbHelper.database;
    await db.delete('items', where: 'id = ?', whereArgs: [itemId]);
  }

  // Mappers
  FieldDefinition _mapToField(Map<String, dynamic> map) {
    return FieldDefinition(
      id: map['id'], label: map['label'], type: FieldType.values[map['type']],
      isSystem: map['is_system'] == 1, isVisible: map['is_visible'] == 1,
      useDropdown: map['use_dropdown'] == 1, isRange: map['is_range'] == 1,
      options: List<String>.from(jsonDecode(map['options'])),
      minNum: map['min_num'], maxNum: map['max_num'], isUnique: map['is_unique'] == 1,
    );
  }

  RosterItem _mapToItem(Map<String, dynamic> map) {
    final dataMap = jsonDecode(map['data']) as Map<String, dynamic>;
    return RosterItem.fromJson({'id': map['id'], 'data': dataMap});
  }
}