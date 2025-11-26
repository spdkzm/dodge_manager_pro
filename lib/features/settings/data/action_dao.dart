// lib/features/settings/data/action_dao.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../domain/action_definition.dart';

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
      'position_index': actionData['positionIndex'] ?? 0,
      // ★追加
      'success_position_index': actionData['successPositionIndex'] ?? 0,
      'failure_position_index': actionData['failurePositionIndex'] ?? 0,
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
        'sortOrder': row['sort_order'] as int,
        'positionIndex': row['position_index'] as int? ?? 0,
        // ★追加
        'successPositionIndex': row['success_position_index'] as int? ?? 0,
        'failurePositionIndex': row['failure_position_index'] as int? ?? 0,
        'hasSuccess': row['has_success'] == 1,
        'hasFailure': row['has_failure'] == 1,
      };
    }).toList();
  }

  // 位置情報の一括更新 (3つのポジションを更新)
  Future<void> updateActionPositions(List<ActionDefinition> actions) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final action in actions) {
        await txn.update(
          'action_definitions',
          {
            'position_index': action.positionIndex,
            'success_position_index': action.successPositionIndex,
            'failure_position_index': action.failurePositionIndex,
          },
          where: 'id = ?',
          whereArgs: [action.id],
        );
      }
    });
  }

  Future<void> updateActionOrder(List<ActionDefinition> actions) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (int i = 0; i < actions.length; i++) {
        final action = actions[i];
        await txn.update(
          'action_definitions',
          {'sort_order': i},
          where: 'id = ?',
          whereArgs: [action.id],
        );
      }
    });
  }
}