// lib/root_screen.dart
import 'package:flutter/material.dart';

// 各機能の画面をインポート
import 'features/game_record/presentation/pages/match_record_screen.dart';
import 'features/game_record/presentation/pages/history_screen.dart'; // ★追加: 履歴画面
import 'features/team_mgmt/presentation/pages/main_screen.dart';
import 'features/settings/presentation/pages/unified_settings_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  // 各機能のトップ画面
  final List<Widget> _screens = [
    const MatchRecordScreen(),     // タブ0: 試合記録
    const HistoryScreen(),         // タブ1: 試合履歴 (★追加)
    const MainScreen(),            // タブ2: チーム管理
    const UnifiedSettingsScreen(), // タブ3: 設定
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.sports_handball),
                label: Text('試合記録'),
              ),
              // ★追加: 履歴タブ
              NavigationRailDestination(
                icon: Icon(Icons.history),
                label: Text('履歴'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_alt),
                label: Text('チーム管理'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('設定'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}