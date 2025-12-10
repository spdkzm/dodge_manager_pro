// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubActionDefinitionImpl _$$SubActionDefinitionImplFromJson(
  Map<String, dynamic> json,
) => _$SubActionDefinitionImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  category: json['category'] as String,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$SubActionDefinitionImplToJson(
  _$SubActionDefinitionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'category': instance.category,
  'sortOrder': instance.sortOrder,
};

_$ActionDefinitionImpl _$$ActionDefinitionImplFromJson(
  Map<String, dynamic> json,
) => _$ActionDefinitionImpl(
  id: json['id'] as String? ?? '',
  name: json['name'] as String,
  subActions:
      (json['subActions'] as List<dynamic>?)
          ?.map((e) => SubActionDefinition.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  isSubRequired: json['isSubRequired'] as bool? ?? false,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  positionIndex: (json['positionIndex'] as num?)?.toInt() ?? 0,
  successPositionIndex: (json['successPositionIndex'] as num?)?.toInt() ?? 0,
  failurePositionIndex: (json['failurePositionIndex'] as num?)?.toInt() ?? 0,
  hasSuccess: json['hasSuccess'] as bool? ?? false,
  hasFailure: json['hasFailure'] as bool? ?? false,
);

Map<String, dynamic> _$$ActionDefinitionImplToJson(
  _$ActionDefinitionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'subActions': instance.subActions,
  'isSubRequired': instance.isSubRequired,
  'sortOrder': instance.sortOrder,
  'positionIndex': instance.positionIndex,
  'successPositionIndex': instance.successPositionIndex,
  'failurePositionIndex': instance.failurePositionIndex,
  'hasSuccess': instance.hasSuccess,
  'hasFailure': instance.hasFailure,
};
