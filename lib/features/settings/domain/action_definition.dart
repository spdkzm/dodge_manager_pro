// lib/features/settings/domain/action_definition.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'action_definition.freezed.dart';
part 'action_definition.g.dart';

@freezed
class SubActionDefinition with _$SubActionDefinition {
  const factory SubActionDefinition({
    required String id,
    required String name,
    required String category, // 'success', 'failure', 'default'
    @Default(0) int sortOrder,
  }) = _SubActionDefinition;

  factory SubActionDefinition.fromJson(Map<String, dynamic> json) => _$SubActionDefinitionFromJson(json);
}

@unfreezed
class ActionDefinition with _$ActionDefinition {
  factory ActionDefinition({
    @Default('') String id,
    required String name,
    // ★修正: マップ廃止、リスト化
    @Default([]) List<SubActionDefinition> subActions,
    @Default(false) bool isSubRequired,
    @Default(0) int sortOrder,
    @Default(0) int positionIndex,
    @Default(0) int successPositionIndex,
    @Default(0) int failurePositionIndex,
    @Default(false) bool hasSuccess,
    @Default(false) bool hasFailure,
  }) = _ActionDefinition;

  factory ActionDefinition.fromJson(Map<String, dynamic> json) => _$ActionDefinitionFromJson(json);

  factory ActionDefinition.fromMap(Map<String, dynamic> map) {
    // DBのカラム構造とは異なるため、DAO側で結合処理を行うが、
    // ここでは基本的なマッピングを行う
    final modMap = Map<String, dynamic>.from(map);
    if (modMap['id'] == null) modMap['id'] = const Uuid().v4();
    if (modMap['name'] == null) modMap['name'] = '';

    // subActions は DAO側でリストとして注入される想定
    if (modMap['subActions'] == null) modMap['subActions'] = [];

    return ActionDefinition.fromJson(modMap);
  }
}

extension ActionDefinitionX on ActionDefinition {
  Map<String, dynamic> toMap() {
    return toJson();
  }

  // カテゴリごとの取得ヘルパー
  List<SubActionDefinition> getSubActions(String category) {
    return subActions.where((s) => s.category == category).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}