// lib/features/settings/domain/action_definition.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'action_definition.freezed.dart';
part 'action_definition.g.dart';

// ★変更: @unfreezed にする
@unfreezed
class ActionDefinition with _$ActionDefinition {
  factory ActionDefinition({ // const を削除
    @Default('') String id,
    required String name,
    @Default({'default': [], 'success': [], 'failure': []}) Map<String, List<String>> subActionsMap,
    @Default(false) bool isSubRequired,
    @Default(0) int sortOrder,
    @Default(false) bool hasSuccess,
    @Default(false) bool hasFailure,
  }) = _ActionDefinition;

  factory ActionDefinition.fromJson(Map<String, dynamic> json) => _$ActionDefinitionFromJson(json);

  factory ActionDefinition.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> modMap = Map.from(map);

    if (modMap['subActionsMap'] is! Map) {
      Map<String, List<String>> loadedMap = {'default': [], 'success': [], 'failure': []};
      if (map['subActions'] is List) {
        loadedMap['default'] = List<String>.from(map['subActions']);
      }
      modMap['subActionsMap'] = loadedMap;
    }

    if (modMap['id'] == null) {
      modMap['id'] = const Uuid().v4();
    }

    return ActionDefinition.fromJson(modMap);
  }
}

extension ActionDefinitionX on ActionDefinition {
  Map<String, dynamic> toMap() {
    return toJson();
  }
}