// lib/features/team_mgmt/domain/roster_category.dart

enum RosterCategory {
  player,   // 0: 選手
  opponent, // 1: 対戦相手
  venue;    // 2: 会場

  // DB保存用の整数値を返すプロパティ
  int get id => index;

  // 整数値からEnumへ変換するファクトリ
  static RosterCategory fromId(int id) {
    if (id >= 0 && id < RosterCategory.values.length) {
      return RosterCategory.values[id];
    }
    return RosterCategory.player; // デフォルト
  }
}