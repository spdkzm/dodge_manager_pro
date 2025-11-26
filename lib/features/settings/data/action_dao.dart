import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';

class ActionDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> insertActionDefinition(String teamId, Map<String, dynamic> actionData) async {
    final db = await _dbHelper.database;
    await db.insert('action_definitions', {
      'id': actionData['id'],
      'team_id': teamId,
      'name': actionData['name'],
      'sub_actions': jsonEncode(actionData['subActionsMap']),
      'is_sub_required': (actionData['isSubRequired'] ?? false) ? 1 : 0,
      'sort_order': actionData['sortOrder'] ?? 0,
      'has_success': (actionData['hasSuccess'] ?? false) ? 1 : 0,
      'has_failure': (actionData['hasFailure'] ?? false) ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getActionDefinitions(String teamId) async {
    final db = await _dbHelper.database;
    final res = await db.query('action_definitions', where: 'team_id = ?', orderBy: 'sort_order ASC', whereArgs: [teamId]);
    return res.map((row) {
      final subActionsJson = row['sub_actions'] as String?;
      dynamic subActionsMap;
      if (subActionsJson != null) {
        try {
          subActionsMap = jsonDecode(subActionsJson);
        } catch (_) {
          subActionsMap = {'default': [], 'success': [], 'failure': []};
        }
      }

      return {
        'id': row['id'],
        'name': row['name'],
        'subActionsMap': subActionsMap,
        'isSubRequired': row['is_sub_required'] == 1,
        'hasSuccess': row['has_success'] == 1,
        'hasFailure': row['has_failure'] == 1,
      };
    }).toList();
  }
}