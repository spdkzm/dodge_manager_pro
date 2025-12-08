// lib/features/team_mgmt/presentation/pages/team_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerStatefulWidget用
import '../../application/team_store.dart';
import '../../domain/team.dart';

class TeamManagementScreen extends ConsumerStatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  ConsumerState<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends ConsumerState<TeamManagementScreen> {
  // Storeはref.read/watchで取得するためローカルインスタンスは不要

  void _showTeamDialog({Team? team}) {
    final isEditing = team != null;
    final nameController = TextEditingController(text: team?.name ?? '');
    final store = ref.read(teamStoreProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'チーム名を変更' : '新しいチームを作成'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'チーム名'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  if (isEditing) {
                    store.updateTeamName(team, name);
                  } else {
                    store.addTeam(name);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? '保存' : '作成'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTeam(Team team) {
    final store = ref.read(teamStoreProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('チーム削除'),
        content: Text('チーム「${team.name}」を削除しますか？\n所属するデータもすべて消えます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              store.deleteTeam(team);
              Navigator.pop(ctx);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(teamStoreProvider); // 状態を監視

    return Scaffold(
      appBar: AppBar(
        title: const Text('チーム管理'),
      ),
      body: store.teams.isEmpty
          ? const Center(
        child: Text('チームがありません\n右下のボタンから作成してください'),
      )
          : Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.indigo.shade50,
            child: const Text(
              "タップして操作対象のチームを切り替えます",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: store.teams.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final team = store.teams[index];
                final isSelected = team.id == store.currentTeam?.id;

                return ListTile(
                  // 選択中は色を変える
                  tileColor: isSelected ? Colors.indigo.shade50 : null,
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Colors.indigo : Colors.grey,
                  ),
                  title: Text(
                    team.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.indigo : Colors.black87,
                    ),
                  ),
                  subtitle: Text('データ数: ${team.items.length}件'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showTeamDialog(team: team),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTeam(team),
                      ),
                    ],
                  ),
                  onTap: () {
                    // タップで選択チームを切り替え
                    store.selectTeam(team.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('「${team.name}」を選択しました')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTeamDialog(),
        label: const Text('チーム作成'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}