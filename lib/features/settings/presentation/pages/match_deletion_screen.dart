// lib/features/settings/presentation/pages/match_deletion_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../game_record/data/match_dao.dart';
import '../../../team_mgmt/application/team_store.dart';

class MatchDeletionScreen extends ConsumerStatefulWidget {
  const MatchDeletionScreen({super.key});

  @override
  ConsumerState<MatchDeletionScreen> createState() => _MatchDeletionScreenState();
}

class _MatchDeletionScreenState extends ConsumerState<MatchDeletionScreen> {
  final MatchDao _matchDao = MatchDao();
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  String? _currentTeamId;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final store = ref.read(teamStoreProvider);
    if (!store.isLoaded) await store.loadFromDb();

    final currentTeam = store.currentTeam;

    if (currentTeam != null && mounted) {
      _currentTeamId = currentTeam.id;
      final rawMatches = await _matchDao.getMatches(_currentTeamId!);

      // 日付降順でソートされているので、そのまま使用
      setState(() {
        _matches = rawMatches;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmDelete(Map<String, dynamic> match) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('試合結果の削除確認'),
        content: Text('試合 "${match['opponent']}" (${match['date']}) の記録を完全に削除しますか？\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteMatch(match['id'] as String);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('完全に削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMatch(String matchId) async {
    if (_currentTeamId == null) return;

    setState(() => _isLoading = true);

    try {
      await _matchDao.deleteMatch(matchId);
      await _loadMatches(); // リストを再ロード
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('試合記録を削除しました。')));
      }
    } catch (e) {
      debugPrint("Match Deletion Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('削除中にエラーが発生しました。'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('試合結果の削除')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
          ? const Center(child: Text("削除可能な試合記録がありません。"))
          : ListView.separated(
        itemCount: _matches.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final match = _matches[index];
          final date = match['date'] as String;
          final opponent = match['opponent'] as String? ?? 'N/A';

          return ListTile(
            title: Text(opponent, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("日付: ${DateFormat('yyyy/MM/dd').format(DateTime.tryParse(date) ?? DateTime.now())}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => _confirmDelete(match),
            ),
          );
        },
      ),
    );
  }
}