// lib/root_screen.dart
import 'package:flutter/material.dart';

import 'features/game_record/presentation/pages/match_record_screen.dart';
import 'features/team_mgmt/presentation/pages/main_screen.dart';
import 'features/team_mgmt/presentation/pages/uniform_number_screen.dart'; // ★追加
import 'features/settings/presentation/pages/unified_settings_screen.dart';
import 'features/analysis/presentation/pages/analysis_screen.dart';
import 'features/match_info/presentation/pages/match_info_list_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MatchRecordScreen(),     // 0: 記録
    const AnalysisScreen(),        // 1: 集計
    const MatchInfoListScreen(),   // 2: リスト
    const MainScreen(),            // 3: 名簿
    const UniformNumberScreen(),   // 4: 背番号 (★追加)
    const UnifiedSettingsScreen(), // 5: 設定
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
              NavigationRailDestination(icon: Icon(Icons.sports_handball), label: Text('記録')),
              NavigationRailDestination(icon: Icon(Icons.analytics), label: Text('集計')),
              NavigationRailDestination(icon: Icon(Icons.map), label: Text('リスト')),
              NavigationRailDestination(icon: Icon(Icons.people_alt), label: Text('名簿')),
              NavigationRailDestination(icon: Icon(Icons.format_list_numbered), label: Text('背番号')), // ★追加
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text('設定')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}