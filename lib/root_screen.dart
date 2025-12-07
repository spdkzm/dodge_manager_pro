// lib/root_screen.dart
import 'package:flutter/material.dart';

import 'features/game_record/presentation/pages/match_record_screen.dart';
import 'features/team_mgmt/presentation/pages/main_screen.dart';
import 'features/settings/presentation/pages/unified_settings_screen.dart';
import 'features/analysis/presentation/pages/analysis_screen.dart';
// ★修正: 正しいパスを指定
import 'features/match_info/presentation/pages/match_info_list_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MatchRecordScreen(),     // 0
    const AnalysisScreen(),        // 1
    const MatchInfoListScreen(),   // 2
    const MainScreen(),            // 3
    const UnifiedSettingsScreen(), // 4
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
              NavigationRailDestination(icon: Icon(Icons.sports_handball), label: Text('試合記録')),
              NavigationRailDestination(icon: Icon(Icons.analytics), label: Text('分析')),
              NavigationRailDestination(icon: Icon(Icons.map), label: Text('試合情報')),
              NavigationRailDestination(icon: Icon(Icons.people_alt), label: Text('チーム管理')),
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