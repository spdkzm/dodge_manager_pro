// lib/features/settings/data/action_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/action_definition.dart'; // ★追加
import 'action_dao.dart';

final actionRepositoryProvider = Provider<ActionRepository>((ref) {
  return ActionRepository(ActionDao());
});

class ActionRepository {
  final ActionDao _dao;

  ActionRepository(this._dao);

  // --- 参照系 ---

  Future<List<Map<String, dynamic>>> getActionDefinitions(String teamId) async {
    return _dao.getActionDefinitions(teamId);
  }

  // --- 更新系 (DAOのシグネチャに合わせて修正) ---

  /// 新規作成または更新 (DAO内でID有無チェックによる分岐があるため共通)
  Future<void> saveActionDefinition(String teamId, ActionDefinition action) async {
    await _dao.insertActionDefinition(teamId, action);
  }

  // エイリアス: 呼び出し元の修正を最小限にするため残すが、中身はsaveと同じ
  Future<void> insertActionDefinition(String teamId, ActionDefinition action) async {
    await _dao.insertActionDefinition(teamId, action);
  }

  Future<void> updateActionDefinition(String teamId, ActionDefinition action) async {
    await _dao.insertActionDefinition(teamId, action);
  }

  /*
  // DAOに削除メソッドがないため、必要であればDAOに追加してから有効化してください
  Future<void> deleteActionDefinition(String actionId) async {
    await _dao.deleteActionDefinition(actionId);
  }
  */

  Future<void> updateActionPositions(List<ActionDefinition> actions) async {
    await _dao.updateActionPositions(actions);
  }

  Future<void> updateActionOrder(List<ActionDefinition> actions) async {
    await _dao.updateActionOrder(actions);
  }
}