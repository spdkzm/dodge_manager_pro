// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LogEntryImpl _$$LogEntryImplFromJson(Map<String, dynamic> json) =>
    _$LogEntryImpl(
      id: json['id'] as String,
      matchDate: json['matchDate'] as String,
      opponent: json['opponent'] as String,
      gameTime: json['gameTime'] as String,
      playerNumber: json['playerNumber'] as String,
      playerId: json['playerId'] as String?,
      action: json['action'] as String,
      subAction: json['subAction'] as String?,
      subActionId: json['subActionId'] as String?,
      type: json['type'] == null
          ? LogType.action
          : const LogTypeConverter().fromJson((json['type'] as num).toInt()),
      result: json['result'] == null
          ? ActionResult.none
          : const ActionResultConverter().fromJson(
              (json['result'] as num).toInt(),
            ),
    );

Map<String, dynamic> _$$LogEntryImplToJson(_$LogEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'matchDate': instance.matchDate,
      'opponent': instance.opponent,
      'gameTime': instance.gameTime,
      'playerNumber': instance.playerNumber,
      'playerId': instance.playerId,
      'action': instance.action,
      'subAction': instance.subAction,
      'subActionId': instance.subActionId,
      'type': const LogTypeConverter().toJson(instance.type),
      'result': const ActionResultConverter().toJson(instance.result),
    };

_$MatchRecordImpl _$$MatchRecordImplFromJson(
  Map<String, dynamic> json,
) => _$MatchRecordImpl(
  id: json['id'] as String,
  date: json['date'] as String,
  opponent: json['opponent'] as String,
  opponentId: json['opponentId'] as String?,
  venueName: json['venueName'] as String?,
  venueId: json['venueId'] as String?,
  logs: (json['logs'] as List<dynamic>)
      .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  matchType: json['matchType'] == null
      ? MatchType.practiceMatch
      : const MatchTypeConverter().fromJson((json['matchType'] as num).toInt()),
  result: json['result'] == null
      ? MatchResult.none
      : const MatchResultConverter().fromJson((json['result'] as num).toInt()),
  scoreOwn: (json['scoreOwn'] as num?)?.toInt(),
  scoreOpponent: (json['scoreOpponent'] as num?)?.toInt(),
  isExtraTime: json['isExtraTime'] as bool? ?? false,
  extraScoreOwn: (json['extraScoreOwn'] as num?)?.toInt(),
  extraScoreOpponent: (json['extraScoreOpponent'] as num?)?.toInt(),
);

Map<String, dynamic> _$$MatchRecordImplToJson(_$MatchRecordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'opponent': instance.opponent,
      'opponentId': instance.opponentId,
      'venueName': instance.venueName,
      'venueId': instance.venueId,
      'logs': instance.logs,
      'matchType': const MatchTypeConverter().toJson(instance.matchType),
      'result': const MatchResultConverter().toJson(instance.result),
      'scoreOwn': instance.scoreOwn,
      'scoreOpponent': instance.scoreOpponent,
      'isExtraTime': instance.isExtraTime,
      'extraScoreOwn': instance.extraScoreOwn,
      'extraScoreOpponent': instance.extraScoreOpponent,
    };

_$ActionItemImpl _$$ActionItemImplFromJson(Map<String, dynamic> json) =>
    _$ActionItemImpl(
      name: json['name'] as String,
      subActions:
          (json['subActions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isSubRequired: json['isSubRequired'] as bool? ?? false,
      hasSuccess: json['hasSuccess'] as bool? ?? false,
      hasFailure: json['hasFailure'] as bool? ?? false,
    );

Map<String, dynamic> _$$ActionItemImplToJson(_$ActionItemImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'subActions': instance.subActions,
      'isSubRequired': instance.isSubRequired,
      'hasSuccess': instance.hasSuccess,
      'hasFailure': instance.hasFailure,
    };

_$AppSettingsImpl _$$AppSettingsImplFromJson(
  Map<String, dynamic> json,
) => _$AppSettingsImpl(
  squadNumbers: (json['squadNumbers'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  actions: (json['actions'] as List<dynamic>)
      .map((e) => ActionItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  matchDurationMinutes: (json['matchDurationMinutes'] as num?)?.toInt() ?? 5,
  gridColumns: (json['gridColumns'] as num?)?.toInt() ?? 3,
  lastOpponent: json['lastOpponent'] as String? ?? "練習試合",
  isResultRecordingEnabled: json['isResultRecordingEnabled'] as bool? ?? false,
  isScoreRecordingEnabled: json['isScoreRecordingEnabled'] as bool? ?? false,
);

Map<String, dynamic> _$$AppSettingsImplToJson(_$AppSettingsImpl instance) =>
    <String, dynamic>{
      'squadNumbers': instance.squadNumbers,
      'actions': instance.actions,
      'matchDurationMinutes': instance.matchDurationMinutes,
      'gridColumns': instance.gridColumns,
      'lastOpponent': instance.lastOpponent,
      'isResultRecordingEnabled': instance.isResultRecordingEnabled,
      'isScoreRecordingEnabled': instance.isScoreRecordingEnabled,
    };
