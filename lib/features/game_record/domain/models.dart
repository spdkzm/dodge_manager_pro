// lib/features/game_record/domain/models.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../settings/domain/action_definition.dart'; // SubActionDefinitionを利用

part 'models.freezed.dart';
part 'models.g.dart';

enum ActionResult { none, success, failure }
enum LogType { action, system }
enum MatchType { practiceMatch, official, practice }
enum MatchResult { none, win, lose, draw }

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

class MatchResultConverter implements JsonConverter<MatchResult, int> {
  const MatchResultConverter();
  @override
  MatchResult fromJson(int json) => MatchResult.values.length > json ? MatchResult.values[json] : MatchResult.none;
  @override
  int toJson(MatchResult object) => object.index;
}

@freezed
class UIActionItem with _$UIActionItem {
  const factory UIActionItem({
    required String name,
    required String parentName,
    required ActionResult fixedResult,
    // ★修正: 文字列ではなく定義オブジェクトを持つ
    required List<SubActionDefinition> subActions,
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
    String? playerId,
    required String action,
    String? subAction,
    // ★追加: ID
    String? subActionId,
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
    String? opponentId,
    String? venueName,
    String? venueId,
    required List<LogEntry> logs,
    @MatchTypeConverter() @Default(MatchType.practiceMatch) MatchType matchType,
    @MatchResultConverter() @Default(MatchResult.none) MatchResult result,
    int? scoreOwn,
    int? scoreOpponent,
    @Default(false) bool isExtraTime,
    int? extraScoreOwn,
    int? extraScoreOpponent,
  }) = _MatchRecord;

  factory MatchRecord.fromJson(Map<String, dynamic> json) => _$MatchRecordFromJson(json);
}

// AppSettings内での定義（デフォルト値用など）は簡易的なStringリストのままにするか、
// 設定画面でActionDefinitionをフルに使うため、ここではActionItemは古い互換用として残すか、削除推奨ですが
// 既存コード維持のため、ここは影響の少ない範囲で残します。
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
    @Default(false) bool isResultRecordingEnabled,
    @Default(false) bool isScoreRecordingEnabled,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}