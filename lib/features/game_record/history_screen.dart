// lib/features/game_record/history_screen.dart
import 'package:flutter/material.dart';

import '../../features/team_mgmt/team_store.dart';
// import '../../features/team_mgmt/database_helper.dart'; // 削除
import 'data/match_dao.dart'; // ★変更: DAOインポート

import 'models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TeamStore _teamStore = TeamStore();
  final MatchDao _matchDao = MatchDao(); // ★追加
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
      // ★変更: DAO使用
      final matchRows = await _matchDao.getMatches(currentTeam.id);

      List<MatchRecord> loadedRecords = [];

      for (var matchRow in matchRows) {
        final matchId = matchRow['id'] as String;
        // ★変更: DAO使用
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
            result: ActionResult.values[logRow['result'] ?? 0], // result対応
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("試合記録一覧 (DB)")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? const Center(child: Text("保存された記録はありません"))
          : ListView.builder(
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final record = _records[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              title: Text("${record.date}  VS ${record.opponent}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("記録数: ${record.logs.length}"),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 800),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                      columns: const [
                        DataColumn(label: Text("背番号")),
                        DataColumn(label: Text("時間")),
                        DataColumn(label: Text("親カテゴリ")),
                        DataColumn(label: Text("子カテゴリ")),
                        DataColumn(label: Text("タイプ")),
                      ],
                      rows: record.logs.map((log) {
                        final isSystem = log.type == LogType.system;
                        return DataRow(
                          color: isSystem ? WidgetStateProperty.all(Colors.grey[100]) : null,
                          cells: [
                            DataCell(Text(log.playerNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(log.gameTime, style: const TextStyle(fontFamily: 'monospace'))),
                            DataCell(Text(log.action, style: TextStyle(fontWeight: isSystem ? FontWeight.bold : FontWeight.normal))),
                            DataCell(Text(log.subAction ?? "-")),
                            DataCell(Text(isSystem ? "進行" : "プレー")),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}