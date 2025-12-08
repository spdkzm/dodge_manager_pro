// lib/features/team_mgmt/presentation/pages/player_list_screen.dart
import 'package:flutter/material.dart';
import '../../domain/roster_category.dart';
import 'generic_roster_screen.dart'; // ★共通コンポーネント

class PlayerListScreen extends StatelessWidget {
  const PlayerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 選手カテゴリを指定して共通画面を呼び出す
    return const GenericRosterScreen(
      category: RosterCategory.player,
      showAppBar: true, // メイン画面なのでAppBarを表示
    );
  }
}