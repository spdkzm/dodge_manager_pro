// lib/features/match_info/presentation/pages/match_info_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../team_mgmt/domain/roster_category.dart';
import '../../../team_mgmt/presentation/pages/generic_roster_screen.dart'; // ★共通コンポーネント
import '../../../team_mgmt/presentation/pages/schema_settings_screen.dart';

class MatchInfoListScreen extends ConsumerStatefulWidget {
  const MatchInfoListScreen({super.key});

  @override
  ConsumerState<MatchInfoListScreen> createState() => _MatchInfoListScreenState();
}

class _MatchInfoListScreenState extends ConsumerState<MatchInfoListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RosterCategory _currentCategory = RosterCategory.opponent;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentCategory = _tabController.index == 0 ? RosterCategory.opponent : RosterCategory.venue;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('試合情報リスト'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.indigo,
          tabs: const [
            Tab(text: '対戦相手'),
            Tab(text: '会場'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'schema') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SchemaSettingsScreen(targetCategory: _currentCategory)));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'schema', child: Row(children: [Icon(Icons.build, color: Colors.grey), SizedBox(width: 8), Text('項目の設計')])),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // AppBarは親画面(Scaffold)で持っているので false
          GenericRosterScreen(category: RosterCategory.opponent, showAppBar: false),
          GenericRosterScreen(category: RosterCategory.venue, showAppBar: false),
        ],
      ),
    );
  }
}