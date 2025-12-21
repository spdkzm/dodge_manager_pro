// lib/features/team_mgmt/domain/uniform_number.dart
import 'package:uuid/uuid.dart';

class UniformNumber {
  final String id;
  final String teamId;
  final String playerId;
  final String number;
  final DateTime startDate;
  final DateTime? endDate;

  UniformNumber({
    String? id,
    required this.teamId,
    required this.playerId,
    required this.number,
    required this.startDate,
    this.endDate,
  }) : id = id ?? const Uuid().v4();

  // 期間の重複チェック用ロジック
  // 指定された期間 (checkStart ~ checkEnd) が、この背番号の期間と重複しているか判定
  bool overlapsWith(DateTime checkStart, DateTime? checkEnd) {
    // 期間A: this.startDate ~ this.endDate (nullは無限)
    // 期間B: checkStart ~ checkEnd (nullは無限)

    // Aの終了 < Bの開始 なら重複なし
    if (endDate != null && endDate!.isBefore(checkStart)) return false;

    // Bの終了 < Aの開始 なら重複なし
    if (checkEnd != null && checkEnd.isBefore(startDate)) return false;

    // それ以外は重複
    return true;
  }

  // 特定の日付時点で有効かどうか
  bool isActiveAt(DateTime date) {
    // 日付部分のみで比較するために正規化してもよいが、
    // ここでは単純な比較とする (startDate <= date <= endDate)
    if (date.isBefore(startDate)) return false;
    if (endDate != null && date.isAfter(endDate!)) return false;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'player_id': playerId,
      'number': number,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  factory UniformNumber.fromJson(Map<String, dynamic> json) {
    return UniformNumber(
      id: json['id'],
      teamId: json['team_id'],
      playerId: json['player_id'],
      number: json['number'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
    );
  }

  UniformNumber copyWith({
    String? id,
    String? teamId,
    String? playerId,
    String? number,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return UniformNumber(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      playerId: playerId ?? this.playerId,
      number: number ?? this.number,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}