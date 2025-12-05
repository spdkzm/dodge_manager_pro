// lib/features/settings/presentation/pages/unified_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../team_mgmt/presentation/pages/team_management_screen.dart';
import '../../../team_mgmt/presentation/pages/schema_settings_screen.dart';
import 'action_settings_screen.dart';
import 'match_environment_screen.dart';
import 'button_layout_settings_screen.dart';
import 'match_deletion_screen.dart';
import '../../data/backup_service.dart'; // ★追加

class UnifiedSettingsScreen extends ConsumerWidget {
  const UnifiedSettingsScreen({super.key});

  // ★追加: バックアップ作成
  Future<void> _handleBackup(BuildContext context) async {
    try {
      await BackupService().createBackup();
      // モバイルのShare完了検知は難しいため、PC版保存時のみ完了メッセージを出す等の分岐も可
      // ここではエラーがなければ良しとする
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ★追加: バックアップ復元
  Future<void> _handleRestore(BuildContext context) async {
    // 1. 警告ダイアログ
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
        // 2. 完了後の再起動案内
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('復元完了'),
            content: const Text('データの復元が完了しました。\n整合性を保つため、一度アプリを終了して再起動してください。'),
            actions: [
              TextButton(
                onPressed: () {
                  // アプリによっては exit(0) で強制終了させる手もあるが、
                  // ストア審査等を考慮し、ユーザーに閉じてもらうのが安全
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
          // ★追加: バックアップ・復元
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