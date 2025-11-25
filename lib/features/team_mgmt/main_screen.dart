// lib/features/team_mgmt/main_screen.dart
import 'package:flutter/material.dart';
import 'player_list_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 下部タブでの切り替えを廃止し、直接「名簿一覧画面」を表示します
    return const PlayerListScreen();
  }
}