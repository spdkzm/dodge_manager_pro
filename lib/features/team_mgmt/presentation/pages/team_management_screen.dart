import 'package:flutter/material.dart';
import 'package:dodge_manager_pro/features/team_mgmt/application/team_store.dart';
import 'package:dodge_manager_pro/features/team_mgmt/domain/team.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final TeamStore _store = TeamStore();

  void _showTeamDialog({Team? team}) {
    final isEditing = team != null;
    final nameController = TextEditingController(text: team?.name ?? '');

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
                    // ▼▼▼ 修正: team!.name -> team.name ▼▼▼
                    _store.updateTeamName(team, name);
                  } else {
                    _store.addTeam(name);
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('チーム削除'),
        content: Text('チーム「${team.name}」を削除しますか？\n所属するデータもすべて消えます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              _store.deleteTeam(team);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('チーム管理'),
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, child) {
          if (_store.teams.isEmpty) {
            return const Center(
              child: Text('チームがありません\n右下のボタンから作成してください'),
            );
          }
          return ListView.separated(
            itemCount: _store.teams.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final team = _store.teams[index];
              return ListTile(
                leading: const Icon(Icons.group),
                title: Text(team.name),
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTeamDialog(),
        label: const Text('チーム作成'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}