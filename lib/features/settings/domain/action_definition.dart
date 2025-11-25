// lib/features/settings/domain/action_definition.dart
import 'package:uuid/uuid.dart';

class ActionDefinition {
  final String id;
  String name;

  // ★変更: サブアクションをマップで管理
  // key: "default", "success", "failure"
  // value: List<String>
  Map<String, List<String>> subActionsMap;

  bool isSubRequired;
  int sortOrder;
  bool hasSuccess;
  bool hasFailure;

  ActionDefinition({
    String? id,
    required this.name,
    Map<String, List<String>>? subActionsMap,
    this.isSubRequired = false,
    this.sortOrder = 0,
    this.hasSuccess = false,
    this.hasFailure = false,
  }) : id = id ?? const Uuid().v4(),
        subActionsMap = subActionsMap ?? {'default': [], 'success': [], 'failure': []};

  // DB保存用
  Map<String, dynamic> toMap() {
    // subActionsMapはDBヘルパー側でJSONエンコードする
    return {
      'id': id,
      'name': name,
      'subActionsMap': subActionsMap,
      'isSubRequired': isSubRequired,
      'sortOrder': sortOrder,
      'hasSuccess': hasSuccess,
      'hasFailure': hasFailure,
    };
  }

  factory ActionDefinition.fromMap(Map<String, dynamic> map) {
    // DBから読み込んだMapを復元
    // 古いデータ構造(List)との互換性も考慮しつつ、基本はMapで扱う
    Map<String, List<String>> loadedMap = {'default': [], 'success': [], 'failure': []};

    if (map['subActionsMap'] is Map) {
      final m = map['subActionsMap'] as Map;
      loadedMap['default'] = List<String>.from(m['default'] ?? []);
      loadedMap['success'] = List<String>.from(m['success'] ?? []);
      loadedMap['failure'] = List<String>.from(m['failure'] ?? []);
    } else if (map['subActions'] is List) {
      // 旧仕様(List)の場合、defaultに入れる
      loadedMap['default'] = List<String>.from(map['subActions']);
    }

    return ActionDefinition(
      id: map['id'],
      name: map['name'],
      subActionsMap: loadedMap,
      isSubRequired: map['isSubRequired'] ?? false,
      sortOrder: map['sortOrder'] ?? 0,
      hasSuccess: map['hasSuccess'] ?? false,
      hasFailure: map['hasFailure'] ?? false,
    );
  }
}