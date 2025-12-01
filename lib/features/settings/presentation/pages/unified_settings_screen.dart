// lib/features/settings/presentation/pages/unified_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../team_mgmt/presentation/pages/team_management_screen.dart';
import '../../../team_mgmt/presentation/pages/schema_settings_screen.dart';
import 'action_settings_screen.dart';
import 'match_environment_screen.dart';
import 'button_layout_settings_screen.dart';
import 'match_deletion_screen.dart';

class UnifiedSettingsScreen extends ConsumerWidget {
  const UnifiedSettingsScreen({super.key});

  // CSV関連のメソッド(_handleImport, _handleExport)は削除

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          _buildSectionHeader(context, '試合・アクション'),
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('ボタン配置と列数'),
            subtitle: const Text('アクションボタンの配置場所と列数をカスタマイズ'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ButtonLayoutSettingsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.touch_app),
            title: const Text('アクションの定義'),
            subtitle: const Text('ボタンの名称や詳細項目を編集 (DB保存)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActionSettingsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('試合環境設定'),
            subtitle: const Text('試合時間 (分)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchEnvironmentScreen())),
          ),

          const Divider(),
          _buildSectionHeader(context, 'データ管理'),

          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('試合結果の削除', style: TextStyle(color: Colors.red)),
            subtitle: const Text('過去の試合記録を一覧から完全に削除します'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchDeletionScreen())),
          ),

          const Divider(),
          _buildSectionHeader(context, 'チーム・名簿管理'),

          ListTile(
            leading: const Icon(Icons.group_work),
            title: const Text('チーム管理'),
            subtitle: const Text('チームの作成・削除・切り替え'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamManagementScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('名簿の項目設計'),
            subtitle: const Text('項目の追加・型定義・並び替え'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SchemaSettingsScreen())),
          ),
          // ★削除: CSVエクスポート・インポートのタイル
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.grey.shade50,
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}