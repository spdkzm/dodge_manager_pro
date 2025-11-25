import 'package:uuid/uuid.dart';

class ActionDefinition {
  final String id;
  String name;
  List<String> subActions;
  bool isSubRequired;
  int sortOrder;

  ActionDefinition({
    String? id,
    required this.name,
    this.subActions = const [],
    this.isSubRequired = false,
    this.sortOrder = 0,
  }) : id = id ?? const Uuid().v4();

  // DB保存用 Map変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subActions': subActions, // DatabaseHelper側でJSONエンコードする想定
      'isSubRequired': isSubRequired,
      'sortOrder': sortOrder,
    };
  }

  // DB読み込み用 Factory
  factory ActionDefinition.fromMap(Map<String, dynamic> map) {
    return ActionDefinition(
      id: map['id'],
      name: map['name'],
      subActions: (map['subActions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isSubRequired: map['isSubRequired'] ?? false,
      sortOrder: map['sortOrder'] ?? 0, // sort_order等はDBHelperで整形済み想定
    );
  }
}