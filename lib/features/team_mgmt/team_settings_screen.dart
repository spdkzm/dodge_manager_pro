import 'package:flutter/material.dart';
import 'package:dodge_manager_pro/features/team_mgmt/team_management_screen.dart';
import 'package:dodge_manager_pro/features/team_mgmt/schema_settings_screen.dart';
import 'package:dodge_manager_pro/features/team_mgmt/team_store.dart';
import 'package:dodge_manager_pro/features/team_mgmt/csv_export_service.dart';
import 'package:dodge_manager_pro/features/team_mgmt/csv_import_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleExport(BuildContext context) async {
    final store = TeamStore();
    final currentTeam = store.currentTeam;

    if (currentTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('チームが選択されていません')),
      );
      return;
    }

    try {
      final csvService = CsvExportService();
      await csvService.exportTeamToCsv(currentTeam);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エクスポートに失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    final store = TeamStore();
    final currentTeam = store.currentTeam;

    if (currentTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('インポート先のチームが選択されていません')),
      );
      return;
    }

    try {
      final importService = CsvImportService();
      // 結果のStatsを受け取る
      final stats = await importService.pickAndImportCsv(currentTeam);

      if (context.mounted) {
        if (stats == null) {
          // キャンセル
        } else {
          // ▼▼▼ 詳細な結果ダイアログを表示 ▼▼▼
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
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$count 件',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.group_work),
            title: const Text('チーム管理'),
            subtitle: const Text('チームの作成・削除'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeamManagementScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('名簿の項目設計'),
            subtitle: const Text('項目の追加・型定義・並び替え'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SchemaSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('CSVエクスポート'),
            subtitle: const Text('現在のチームデータを共有'),
            trailing: const Icon(Icons.upload_file),
            onTap: () => _handleExport(context),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('CSVインポート'),
            subtitle: const Text('CSVファイルからデータを追加'),
            trailing: const Icon(Icons.file_download),
            onTap: () => _handleImport(context),
          ),
        ],
      ),
    );
  }
}