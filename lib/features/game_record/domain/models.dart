// lib/features/game_record/domain/models.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum ActionResult { none, success, failure }
enum LogType { action, system }
enum MatchType { practiceMatch, official, practice }

class ActionResultConverter implements JsonConverter<ActionResult, int> {
  const ActionResultConverter();
  @override
  ActionResult fromJson(int json) => ActionResult.values.length > json ? ActionResult.values[json] : ActionResult.none;
  @override
  int toJson(ActionResult object) => object.index;
}

class LogTypeConverter implements JsonConverter<LogType, int> {
  const LogTypeConverter();
  @override
  LogType fromJson(int json) => LogType.values.length > json ? LogType.values[json] : LogType.action;
  @override
  int toJson(LogType object) => object.index;
}

class MatchTypeConverter implements JsonConverter<MatchType, int> {
  const MatchTypeConverter();
  @override
  MatchType fromJson(int json) => MatchType.values.length > json ? MatchType.values[json] : MatchType.practiceMatch;
  @override
  int toJson(MatchType object) => object.index;
}

@freezed
class UIActionItem with _$UIActionItem {
  const factory UIActionItem({
    required String name,
    required String parentName,
    required ActionResult fixedResult,
    required List<String> subActions,
    required bool isSubRequired,
    @Default(false) bool hasSuccess,
    @Default(false) bool hasFailure,
  }) = _UIActionItem;
}

@unfreezed
class LogEntry with _$LogEntry {
  factory LogEntry({
    required String id,
    required String matchDate,
    required String opponent,
    required String gameTime,
    required String playerNumber,
    required String action,
    String? subAction,
    @LogTypeConverter() @Default(LogType.action) LogType type,
    @ActionResultConverter() @Default(ActionResult.none) ActionResult result,
  }) = _LogEntry;

  factory LogEntry.fromJson(Map<String, dynamic> json) => _$LogEntryFromJson(json);
}

@freezed
class MatchRecord with _$MatchRecord {
  const factory MatchRecord({
    required String id,
    required String date,
    required String opponent,
    // ★追加: ID紐付け用
    String? opponentId,
    String? venueName,
    String? venueId,
    required List<LogEntry> logs,
    @MatchTypeConverter() @Default(MatchType.practiceMatch) MatchType matchType,
  }) = _MatchRecord;

  factory MatchRecord.fromJson(Map<String, dynamic> json) => _$MatchRecordFromJson(json);
}

@freezed
class ActionItem with _$ActionItem {
  const factory ActionItem({
    required String name,
    @Default([]) List<String> subActions,
    @Default(false) bool isSubRequired,
    @Default(false) bool hasSuccess,
    @Default(false) bool hasFailure,
  }) = _ActionItem;

  factory ActionItem.fromJson(Map<String, dynamic> json) => _$ActionItemFromJson(json);
}

@unfreezed
class AppSettings with _$AppSettings {
  factory AppSettings({
    required List<String> squadNumbers,
    required List<ActionItem> actions,
    @Default(5) int matchDurationMinutes,
    @Default(3) int gridColumns,
    @Default("練習試合") String lastOpponent,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(_migrateOldData(json));

  static Map<String, dynamic> _migrateOldData(Map<String, dynamic> json) {
    if (json['actions'] is List && (json['actions'] as List).isNotEmpty) {
      final list = json['actions'] as List;
      if (list[0] is String) {
        final convertedActions = list.map((e) => {'name': e}).toList();
        final newJson = Map<String, dynamic>.from(json);
        newJson['actions'] = convertedActions;
        return newJson;
      }
    }
    return json;
  }
}