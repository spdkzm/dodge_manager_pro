// lib/features/match_info/presentation/pages/match_info_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../team_mgmt/domain/roster_category.dart';
import '../../../team_mgmt/presentation/pages/generic_roster_screen.dart'; // ★共通コンポーネント
// SchemaSettingsScreenのインポートは一旦未使用になるため削除しても良いですが、後で使う可能性があるため残します
import '../../../team_mgmt/presentation/pages/schema_settings_screen.dart';

class MatchInfoListScreen extends ConsumerWidget {
  const MatchInfoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('試合情報リスト'),
        // タブに依存していた actions (スキーマ設定) は一旦削除
      ),
      body: Row(
        children: [
          // --- 左側: 対戦相手リスト ---
          const Expanded(
            child: GenericRosterScreen(
              category: RosterCategory.opponent,
              showAppBar: false,
            ),
          ),

          // 中央の区切り線
          const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),

          // --- 右側: 会場リスト ---
          const Expanded(
            child: GenericRosterScreen(
              category: RosterCategory.venue,
              showAppBar: false,
            ),
          ),
        ],
      ),
    );
  }
}