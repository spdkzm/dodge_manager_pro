// lib/features/settings/presentation/pages/unified_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../team_mgmt/presentation/pages/team_management_screen.dart';
import '../../../team_mgmt/presentation/pages/schema_settings_screen.dart';
import '../../../team_mgmt/data/csv_export_service.dart';
import '../../../team_mgmt/data/csv_import_service.dart';
import '../../../team_mgmt/application/team_store.dart';

import 'action_settings_screen.dart';
import 'match_environment_screen.dart';
import 'button_layout_settings_screen.dart';
import 'match_deletion_screen.dart'; // ★追加

class UnifiedSettingsScreen extends ConsumerWidget {
  const UnifiedSettingsScreen({super.key});

  // --- CSVインポート処理 ---
  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;

    if (currentTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('インポート先のチームが選択されていません')),
      );
      return;
    }

    try {
      final importService = CsvImportService();
      final stats = await importService.pickAndImportCsv(currentTeam);

      if (context.mounted) {
        if (stats == null) {
          // キャンセル
        } else {
          // 完了後に画面を更新するためデータをリロード
          await store.loadFromDb();

          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('インポート完了'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow('新規追加', stats.inserted, Colors.green),
                  _buildStatRow('更新（上書き）', stats.updated, Colors.blue),
                  _buildStatRow('変更なし', stats.unchanged, Colors.grey),
                  const Divider(),
                  Text(
                    '合計: ${stats.inserted + stats.updated + stats.unchanged} 件',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('インポートエラー'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
    }
  }

  // --- CSVエクスポート処理 ---
  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    final store = ref.read(teamStoreProvider);
    if (store.currentTeam != null) {
      try {
        await CsvExportService().exportTeamToCsv(store.currentTeam!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSVを出力しました')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('$count 件', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
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
          _buildSectionHeader(context, 'データ管理'), // セクション名変更

          // ★追加: 試合削除機能
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('試合結果の削除', style: TextStyle(color: Colors.red)),
            subtitle: const Text('過去の試合記録を一覧から完全に削除します (元に戻せません)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchDeletionScreen())),
          ),

          const Divider(),
          _buildSectionHeader(context, 'チーム・名簿管理'), // セクション名変更

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
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('CSV エクスポート'),
            subtitle: const Text('現在のチームデータを共有'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _handleExport(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('CSV インポート'),
            subtitle: const Text('CSVファイルからデータを追加・更新'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _handleImport(context, ref),
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