// lib/features/settings/data/action_dao.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart'; // ※パスは環境に合わせて調整してください
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
      'has_success': (actionData['hasSuccess'] ?? false) ? 1 : 0,
      'has_failure': (actionData['hasFailure'] ?? false) ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getActionDefinitions(String teamId) async {
    final db = await _dbHelper.database;
    // sort_orderの昇順で取得
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
        'sortOrder': row['sort_order'] as int, // 追加
        'hasSuccess': row['has_success'] == 1,
        'hasFailure': row['has_failure'] == 1,
      };
    }).toList();
  }

  // ★追加: 並び順を一括更新するメソッド
  Future<void> updateActionOrder(List<ActionDefinition> actions) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (int i = 0; i < actions.length; i++) {
        final action = actions[i];
        // IDをキーにして、sort_order を現在のリストのインデックス(i)で更新
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