// lib/root_screen.dart
import 'package:flutter/material.dart';
import 'features/game_record/match_record_screen.dart';
import 'features/team_mgmt/main_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  // 各機能のトップ画面
  final List<Widget> _screens = [
    const MatchRecordScreen(), // アプリ1
    const MainScreen(),        // アプリ2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左側のナビゲーションレール (タブレット向け)
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
              NavigationRailDestination(
                icon: Icon(Icons.people_alt),
                label: Text('チーム管理'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // メインコンテンツエリア
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}