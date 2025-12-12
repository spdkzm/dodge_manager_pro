// lib/features/settings/data/action_dao.dart

import '../../../core/database/database_helper.dart';
import '../domain/action_definition.dart';

class ActionDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // アクション定義の保存（親と子の同期）
  Future<void> insertActionDefinition(String teamId, ActionDefinition action) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. 親テーブル (action_definitions) の更新/挿入
      // replaceではなく、存在確認してUPDATE/INSERT
      final List<Map<String, dynamic>> existing = await txn.query(
        'action_definitions',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [action.id],
      );

      final parentValues = {
        'id': action.id,
        'team_id': teamId,
        'name': action.name,
        // sub_actions(JSON)カラムは廃止されたので入れない、あるいは空文字
        'sub_actions': '',
        'is_sub_required': action.isSubRequired ? 1 : 0,
        'sort_order': action.sortOrder,
        'position_index': action.positionIndex,
        'success_position_index': action.successPositionIndex,
        'failure_position_index': action.failurePositionIndex,
        'has_success': action.hasSuccess ? 1 : 0,
        'has_failure': action.hasFailure ? 1 : 0,
      };

      if (existing.isNotEmpty) {
        await txn.update('action_definitions', parentValues, where: 'id = ?', whereArgs: [action.id]);
      } else {
        await txn.insert('action_definitions', parentValues);
      }

      // 2. 子テーブル (sub_action_definitions) の同期
      // 既存の子を取得
      final existingSubs = await txn.query(
          'sub_action_definitions',
          where: 'action_id = ?',
          whereArgs: [action.id]
      );
      final existingSubIds = existingSubs.map((e) => e['id'] as String).toSet();

      final currentSubIds = action.subActions.map((s) => s.id).toSet();

      // 削除対象: DBにはあるが、今のリストにはないID
      final toDelete = existingSubIds.difference(currentSubIds);
      for (var delId in toDelete) {
        // ★重要: ログで使われている場合は削除を止めるか、NULLにするか？
        // 今回は「設定からの削除」＝「論理的には消去」だが、ログの整合性を守るなら
        // 外部キー制約(ON DELETE CASCADE)に任せず、ログのIDをNULLにするなどの配慮が必要かもしれない。
        // ここでは単純に定義を削除する（ログにはIDが残るが、結合できなくなるだけ）
        await txn.delete('sub_action_definitions', where: 'id = ?', whereArgs: [delId]);
      }

      // 挿入・更新対象
      for (var sub in action.subActions) {
        final subValues = {
          'id': sub.id,
          'action_id': action.id,
          'name': sub.name,
          'category': sub.category,
          'sort_order': sub.sortOrder,
        };

        if (existingSubIds.contains(sub.id)) {
          await txn.update('sub_action_definitions', subValues, where: 'id = ?', whereArgs: [sub.id]);
        } else {
          await txn.insert('sub_action_definitions', subValues);
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> getActionDefinitions(String teamId) async {
    final db = await _dbHelper.database;

    // 親取得
    final parents = await db.query(
        'action_definitions',
        where: 'team_id = ?',
        orderBy: 'sort_order ASC',
        whereArgs: [teamId]
    );

    if (parents.isEmpty) return [];

    // 子取得
    final parentIds = parents.map((p) => p['id']).toList();
    // whereIn句の構築
    final placeholders = List.filled(parentIds.length, '?').join(',');
    final subs = await db.query(
      'sub_action_definitions',
      where: 'action_id IN ($placeholders)',
      orderBy: 'sort_order ASC',
      whereArgs: parentIds,
    );

    // 親ごとに子をグルーピング
    final Map<String, List<SubActionDefinition>> subMap = {};
    for (var row in subs) {
      final pId = row['action_id'] as String;
      if (!subMap.containsKey(pId)) subMap[pId] = [];

      subMap[pId]!.add(SubActionDefinition(
        id: row['id'] as String,
        name: row['name'] as String,
        category: row['category'] as String,
        sortOrder: row['sort_order'] as int,
      ));
    }

    // 結合して返す
    return parents.map((row) {
      final pId = row['id'] as String;
      final subList = subMap[pId] ?? [];

      return {
        'id': row['id'],
        'name': row['name'],
        // JSONではなくオブジェクトリストを渡す
        'subActions': subList.map((s) => s.toJson()).toList(),
        'isSubRequired': row['is_sub_required'] == 1,
        'sortOrder': row['sort_order'] as int,
        'positionIndex': row['position_index'] as int? ?? 0,
        'successPositionIndex': row['success_position_index'] as int? ?? 0,
        'failurePositionIndex': row['failure_position_index'] as int? ?? 0,
        'hasSuccess': row['has_success'] == 1,
        'hasFailure': row['has_failure'] == 1,
      };
    }).toList();
  }

  // 位置情報更新 (変更なし)
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

  // 並び順更新 (変更なし)
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