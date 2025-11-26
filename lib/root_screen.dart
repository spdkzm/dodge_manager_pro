import 'package:flutter/material.dart';

// 修正後のパス
import 'features/game_record/presentation/pages/match_record_screen.dart';
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
    const MainScreen(),            // タブ1: チーム管理 (旧アプリ2のホーム)
    const UnifiedSettingsScreen(), // タブ2: 統合設定 (★追加)
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
              // ★追加: 設定タブ
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('設定'),
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