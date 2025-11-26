// lib/features/game_record/presentation/pages/history_screen.dart
import 'package:flutter/material.dart';

import '../../../../features/team_mgmt/application/team_store.dart';
import '../../data/match_dao.dart';
import '../../domain/models.dart';
import 'match_detail_screen.dart'; // ★追加

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TeamStore _teamStore = TeamStore();
  final MatchDao _matchDao = MatchDao();
  List<MatchRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!_teamStore.isLoaded) {
      await _teamStore.loadFromDb();
    }
    final currentTeam = _teamStore.currentTeam;

    if (currentTeam == null) {
      setState(() {
        _isLoading = false;
        _records = [];
      });
      return;
    }

    try {
      final matchRows = await _matchDao.getMatches(currentTeam.id);
      List<MatchRecord> loadedRecords = [];

      for (var matchRow in matchRows) {
        final matchId = matchRow['id'] as String;
        final logRows = await _matchDao.getMatchLogs(matchId);

        final logs = logRows.map((logRow) {
          return LogEntry(
            id: logRow['id'] as String,
            matchDate: matchRow['date'] as String,
            opponent: matchRow['opponent'] as String,
            gameTime: logRow['game_time'] as String,
            playerNumber: logRow['player_number'] as String,
            action: logRow['action'] as String,
            subAction: logRow['sub_action'] as String?,
            type: LogType.values[logRow['log_type'] as int],
            result: ActionResult.values[logRow['result'] ?? 0],
          );
        }).toList();

        loadedRecords.add(MatchRecord(
          id: matchId,
          date: matchRow['date'] as String,
          opponent: matchRow['opponent'] as String,
          logs: logs,
        ));
      }

      setState(() {
        _records = loadedRecords;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint("History Load Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("試合記録一覧")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? const Center(child: Text("保存された記録はありません"))
          : ListView.builder(
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final record = _records[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                  "VS ${record.opponent}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
              ),
              subtitle: Text("${record.date}  /  記録数: ${record.logs.length}"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                // ★修正: 詳細画面へ遷移
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MatchDetailScreen(record: record),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}