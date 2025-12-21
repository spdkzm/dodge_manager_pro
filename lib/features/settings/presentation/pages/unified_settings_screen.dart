// lib/features/settings/presentation/pages/unified_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'match_deletion_screen.dart';
import 'player_deletion_screen.dart'; // ★追加
import '../../data/backup_service.dart';
import '../../../team_mgmt/presentation/pages/team_management_screen.dart'; // ★追加

class UnifiedSettingsScreen extends ConsumerWidget {
  const UnifiedSettingsScreen({super.key});

  // バックアップ作成
  Future<void> _handleBackup(BuildContext context) async {
    try {
      await BackupService().createBackup();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // バックアップ復元
  Future<void> _handleRestore(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('バックアップから復元'),
        content: const Text(
          '警告: 現在のアプリ内データはすべて削除され、選択したバックアップファイルの内容に上書きされます。\n\n'
              'この操作は元に戻せません。\nよろしいですか？',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('上書きして復元'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await BackupService().restoreBackup();

      if (success && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('復元完了'),
            content: const Text('データの復元が完了しました。\n整合性を保つため、一度アプリを終了して再起動してください。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('復元エラー: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          // ★追加: チーム・選手管理セクション
          _buildSectionHeader(context, 'チーム・選手管理'),
          ListTile(
            leading: const Icon(Icons.group_work, color: Colors.indigo),
            title: const Text('チームの管理'),
            subtitle: const Text('チームの追加、切替、名称変更'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamManagementScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.person_remove, color: Colors.red),
            title: const Text('選手データの削除', style: TextStyle(color: Colors.red)),
            subtitle: const Text('登録済みの選手データを削除します'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerDeletionScreen())),
          ),

          _buildSectionHeader(context, 'データ管理'),

          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('試合結果の削除', style: TextStyle(color: Colors.red)),
            subtitle: const Text('過去の試合記録を一覧から完全に削除します'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchDeletionScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.save_alt, color: Colors.indigo),
            title: const Text('全データバックアップ'),
            subtitle: const Text('現在のデータをファイルとして保存'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _handleBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore_page, color: Colors.orange),
            title: const Text('バックアップから復元'),
            subtitle: const Text('データを上書きして復元 (※注意)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _handleRestore(context),
          ),
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