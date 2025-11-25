// lib/features/game_record/models.dart
import 'dart:convert';

// アクションの結果
enum ActionResult {
  none,    // なし (ファールなど)
  success, // 成功
  failure, // 失敗
}

enum LogType { action, system }

// ★追加: UI表示用の拡張アクションアイテム (ここに移動)
class UIActionItem {
  String name;          // 表示名 (例: アタック成功)
  String parentName;    // 親名 (例: アタック)
  ActionResult fixedResult; // このボタンが押されたときの結果
  List<String> subActions;  // このボタン用のサブアクション
  bool isSubRequired;

  UIActionItem({
    required this.name,
    required this.parentName,
    required this.fixedResult,
    required this.subActions,
    required this.isSubRequired,
  });
}

class LogEntry {
  String id;
  String matchDate;
  String opponent;
  String gameTime;
  String playerNumber;
  String action;
  String? subAction;
  LogType type;
  ActionResult result;

  LogEntry({
    required this.id,
    required this.matchDate,
    required this.opponent,
    required this.gameTime,
    required this.playerNumber,
    required this.action,
    this.subAction,
    this.type = LogType.action,
    this.result = ActionResult.none,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'matchDate': matchDate,
    'opponent': opponent,
    'gameTime': gameTime,
    'playerNumber': playerNumber,
    'action': action,
    'subAction': subAction,
    'type': type.index,
    'result': result.index,
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      matchDate: json['matchDate'] ?? '',
      opponent: json['opponent'] ?? '',
      gameTime: json['gameTime'],
      playerNumber: json['playerNumber'],
      action: json['action'],
      subAction: json['subAction'],
      type: LogType.values[json['type'] ?? 0],
      result: ActionResult.values[json['result'] ?? 0],
    );
  }
}

class MatchRecord {
  String id;
  String date;
  String opponent;
  List<LogEntry> logs;

  MatchRecord({
    required this.id,
    required this.date,
    required this.opponent,
    required this.logs,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'opponent': opponent,
    'logs': logs.map((l) => l.toJson()).toList(),
  };

  factory MatchRecord.fromJson(Map<String, dynamic> json) {
    return MatchRecord(
      id: json['id'],
      date: json['date'],
      opponent: json['opponent'],
      logs: (json['logs'] as List).map((l) => LogEntry.fromJson(l)).toList(),
    );
  }
}

class ActionItem {
  String name;
  List<String> subActions;
  bool isSubRequired;
  bool hasSuccess;
  bool hasFailure;

  ActionItem({
    required this.name,
    this.subActions = const [],
    this.isSubRequired = false,
    this.hasSuccess = false,
    this.hasFailure = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'subActions': subActions, 'isSubRequired': isSubRequired,
    'hasSuccess': hasSuccess, 'hasFailure': hasFailure,
  };

  factory ActionItem.fromJson(Map<String, dynamic> json) => ActionItem(
    name: json['name'],
    subActions: List<String>.from(json['subActions'] ?? []),
    isSubRequired: json['isSubRequired'] ?? false,
    hasSuccess: json['hasSuccess'] ?? false,
    hasFailure: json['hasFailure'] ?? false,
  );
}

class AppSettings {
  List<String> squadNumbers;
  List<ActionItem> actions;
  int matchDurationMinutes;
  int gridColumns;
  String lastOpponent;

  AppSettings({
    required this.squadNumbers,
    required this.actions,
    this.matchDurationMinutes = 5,
    this.gridColumns = 3,
    this.lastOpponent = "練習試合",
  });

  Map<String, dynamic> toJson() => {
    'squadNumbers': squadNumbers,
    'actions': actions.map((a) => a.toJson()).toList(),
    'matchDurationMinutes': matchDurationMinutes,
    'gridColumns': gridColumns,
    'lastOpponent': lastOpponent,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    List<ActionItem> loadedActions = [];
    if (json['actions'] != null) {
      if ((json['actions'] as List).isNotEmpty && json['actions'][0] is String) {
        loadedActions = (json['actions'] as List).map((e) => ActionItem(name: e)).toList();
      } else {
        loadedActions = (json['actions'] as List).map((e) => ActionItem.fromJson(e)).toList();
      }
    }
    return AppSettings(
      squadNumbers: List<String>.from(json['squadNumbers'] ?? []),
      actions: loadedActions,
      matchDurationMinutes: json['matchDurationMinutes'] ?? 5,
      gridColumns: json['gridColumns'] ?? 3,
      lastOpponent: json['lastOpponent'] ?? "練習試合",
    );
  }
}