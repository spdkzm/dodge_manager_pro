// lib/features/settings/presentation/pages/player_deletion_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../team_mgmt/application/team_store.dart';
import '../../../team_mgmt/domain/roster_item.dart';
import '../../../team_mgmt/domain/roster_category.dart';
import '../../../team_mgmt/domain/schema.dart';

class PlayerDeletionScreen extends ConsumerStatefulWidget {
  const PlayerDeletionScreen({super.key});

  @override
  ConsumerState<PlayerDeletionScreen> createState() => _PlayerDeletionScreenState();
}

class _PlayerDeletionScreenState extends ConsumerState<PlayerDeletionScreen> {
  // 名前表示用のヘルパー
  String _getPlayerName(RosterItem item) {
    final team = ref.read(teamStoreProvider).currentTeam;
    if (team == null) return "Unknown";

    final schema = team.getSchema(RosterCategory.player);
    String? nameFieldId;
    String? courtNameFieldId;

    for (var f in schema) {
      if (f.type == FieldType.courtName) courtNameFieldId = f.id;
      if (f.type == FieldType.personName) nameFieldId = f.id;
    }

    String name = "";
    if (courtNameFieldId != null) {
      name = item.data[courtNameFieldId]?.toString() ?? "";
    }
    if (name.isEmpty && nameFieldId != null) {
      final val = item.data[nameFieldId];
      if (val is Map) {
        name = "${val['last'] ?? ''} ${val['first'] ?? ''}".trim();
      } else {
        name = val?.toString() ?? "";
      }
    }
    if (name.isEmpty) name = "No Name";
    return name;
  }

  void _confirmDelete(RosterItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('選手データの削除確認'),
        content: Text('選手 "${_getPlayerName(item)}" を削除しますか？\n\n'
            'この操作は元に戻せません。\n'
            '削除すると、過去の試合記録や分析データからもこの選手のIDは失われます。',
            style: const TextStyle(color: Colors.red)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletePlayer(item);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('完全に削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlayer(RosterItem item) async {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    if (currentTeam == null) return;

    try {
      store.deleteItem(currentTeam.id, item, category: RosterCategory.player);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('選手データを削除しました。')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('削除エラー: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(teamStoreProvider);
    final currentTeam = store.currentTeam;

    if (!store.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (currentTeam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('選手データの削除')),
        body: const Center(child: Text("チームが選択されていません")),
      );
    }

    final players = currentTeam.getItems(RosterCategory.player);

    return Scaffold(
      appBar: AppBar(title: const Text('選手データの削除')),
      body: players.isEmpty
          ? const Center(child: Text("登録されている選手がいません"))
          : ListView.separated(
        itemCount: players.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final player = players[index];
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(_getPlayerName(player), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("ID: ${player.id}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => _confirmDelete(player),
            ),
          );
        },
      ),
    );
  }
}