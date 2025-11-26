// lib/features/analysis/domain/player_stats.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_stats.freezed.dart';

@freezed
class ActionStats with _$ActionStats {
  const factory ActionStats({
    required String actionName,
    @Default(0) int successCount,
    @Default(0) int failureCount,
    @Default(0) int totalCount,
    // ★追加: 詳細項目ごとのカウント (例: {"正面": 5, "横": 2})
    @Default({}) Map<String, int> subActionCounts,
  }) = _ActionStats;
}

@freezed
class PlayerStats with _$PlayerStats {
  const factory PlayerStats({
    required String playerId,
    required String playerNumber,
    required String playerName,
    @Default(0) int matchesPlayed,
    @Default({}) Map<String, ActionStats> actions,
  }) = _PlayerStats;
}

extension ActionStatsX on ActionStats {
  double get successRate {
    if (totalCount == 0) return 0.0;
    return (successCount / totalCount) * 100;
  }

  // ★追加: 1試合平均 (試合数を引数でもらう)
  double getPerGame(int matches) {
    if (matches == 0) return 0.0;
    return totalCount / matches;
  }
}