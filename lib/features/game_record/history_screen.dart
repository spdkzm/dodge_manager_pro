// lib/history_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models.dart';
import 'persistence.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<MatchRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await DataManager.loadMatchHistory();
    // 日付の新しい順（降順）にソート
    list.sort((a, b) => b.id.compareTo(a.id));
    setState(() {
      _records = list;
      _isLoading = false;
    });
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
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              title: Text("${record.date}  VS ${record.opponent}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("記録数: ${record.logs.length}"),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 800), // 最低幅を確保
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
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
                          color: isSystem ? MaterialStateProperty.all(Colors.grey[100]) : null,
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