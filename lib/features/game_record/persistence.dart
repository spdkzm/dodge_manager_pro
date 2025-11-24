// lib/persistence.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class DataManager {
  static const String _keySettings = 'dodge_log_settings_v3';
  static const String _keyCurrentLogs = 'dodge_log_current_logs_v3'; // 編集中の一時データ
  static const String _keyHistory = 'dodge_log_history_v1'; // 確定した過去の試合

  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySettings, jsonEncode(settings.toJson()));
  }

  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keySettings);
    if (jsonString == null) {
      return AppSettings(
        squadNumbers: List.generate(20, (i) => '${i + 1}'),
        actions: [
          ActionItem(name: 'アタック成功', subActions: ['1'], isSubRequired: false),
          ActionItem(name: 'アタック失敗'),
          ActionItem(name: 'キャッチ成功'),
          ActionItem(name: 'キャッチ失敗'),
          ActionItem(name: 'パスミス'),
          ActionItem(name: 'ファール'),
        ],
        matchDurationMinutes: 5,
        gridColumns: 3,
      );
    }
    return AppSettings.fromJson(jsonDecode(jsonString));
  }

  // --- 一時保存（アプリが落ちたとき用） ---
  static Future<void> saveCurrentLogs(List<LogEntry> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = logs.map((log) => jsonEncode(log.toJson())).toList();
    await prefs.setStringList(_keyCurrentLogs, jsonList);
  }

  static Future<List<LogEntry>> loadCurrentLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyCurrentLogs);
    if (list == null) return [];
    return list.map((item) => LogEntry.fromJson(jsonDecode(item))).toList();
  }

  static Future<void> clearCurrentLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentLogs);
  }

  // --- 試合履歴（確定データ） ---
  static Future<void> saveMatchToHistory(MatchRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_keyHistory) ?? [];
    history.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_keyHistory, history);
  }

  static Future<List<MatchRecord>> loadMatchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_keyHistory) ?? [];
    // 新しい順に並べ替えたい場合はここでreverseなどする
    return history.map((item) => MatchRecord.fromJson(jsonDecode(item))).toList();
  }
}