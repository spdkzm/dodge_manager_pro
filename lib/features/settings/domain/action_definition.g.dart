// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ActionDefinitionImpl _$$ActionDefinitionImplFromJson(
  Map<String, dynamic> json,
) => _$ActionDefinitionImpl(
  id: json['id'] as String? ?? '',
  name: json['name'] as String,
  subActionsMap:
      (json['subActionsMap'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ) ??
      const {'default': [], 'success': [], 'failure': []},
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
  'subActionsMap': instance.subActionsMap,
  'isSubRequired': instance.isSubRequired,
  'sortOrder': instance.sortOrder,
  'positionIndex': instance.positionIndex,
  'successPositionIndex': instance.successPositionIndex,
  'failurePositionIndex': instance.failurePositionIndex,
  'hasSuccess': instance.hasSuccess,
  'hasFailure': instance.hasFailure,
};
