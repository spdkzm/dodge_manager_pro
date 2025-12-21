// lib/features/team_mgmt/presentation/pages/uniform_number_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/team_store.dart';
import '../../domain/schema.dart';
import '../../domain/uniform_number.dart';
import '../../data/uniform_number_dao.dart';
import 'uniform_number_edit_screen.dart';

class UniformNumberScreen extends ConsumerStatefulWidget {
  const UniformNumberScreen({super.key});

  @override
  ConsumerState<UniformNumberScreen> createState() => _UniformNumberScreenState();
}

class _UniformNumberScreenState extends ConsumerState<UniformNumberScreen> {
  final UniformNumberDao _dao = UniformNumberDao();

  // 表示用データ保持クラス
  List<_PlayerRowData> _tableData = [];
  bool _isLoading = true;
  int _maxHistoryCount = 0; // 最大履歴数（列数決定用）

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final store = ref.read(teamStoreProvider);
    if (!store.isLoaded) {
      await store.loadFromDb();
    }

    final team = store.currentTeam;
    if (team == null) {
      setState(() => _isLoading = false);
      return;
    }

    // 1. 全履歴取得
    final allRecords = await _dao.getUniformNumbersByTeam(team.id);

    // 2. 選手リスト取得
    final players = team.items.toList();

    // 名前フィールド特定
    String? nameFieldId;
    for (var f in team.schema) {
      if (f.type == FieldType.personName) {
        nameFieldId = f.id;
        break;
      }
    }
    if (nameFieldId == null && team.schema.isNotEmpty) {
      nameFieldId = team.schema.first.id;
    }

    // 3. 行データの構築
    final now = DateTime.now();
    List<_PlayerRowData> rows = [];
    int maxHist = 0;

    for (var p in players) {
      // 名前解決
      String name = "未設定";
      if (nameFieldId != null) {
        final val = p.data[nameFieldId];
        if (val is Map) {
          name = "${val['last'] ?? ''} ${val['first'] ?? ''}".trim();
        } else if (val != null) {
          name = val.toString();
        }
      }
      if (name.isEmpty) name = "選手(ID:${p.id.substring(0, 4)})";

      // この選手の履歴を抽出＆ソート（開始日降順＝新しい順）
      final history = allRecords.where((r) => r.playerId == p.id).toList();
      history.sort((a, b) => b.startDate.compareTo(a.startDate));

      // 現在有効な背番号を探す
      UniformNumber? current;
      try {
        current = history.firstWhere((r) => r.isActiveAt(now));
      } catch (_) {}

      // 履歴リスト（現在は除く？いや、履歴には全部含めるのが表形式として自然だが、
      // 要件「現在の背番号｜名前｜前の背番号...」に従い、履歴列には「現在以外」を表示するか、
      // あるいは「履歴1」「履歴2」として機械的に表示するか。
      // ここでは「履歴1」= 最新の履歴（現在含む）、「履歴2」= その前... と並べるのが一般的。
      // しかし「現在の背番号」列が別にあるため、重複を避けるなら「履歴列」は「過去の履歴」とすべきだが、
      // わかりやすさのため、履歴列には「全ての履歴を新しい順」に表示する形をとる。

      if (history.length > maxHist) maxHist = history.length;

      rows.add(_PlayerRowData(
        playerId: p.id,
        name: name,
        currentNumber: current,
        history: history,
      ));
    }

    // 4. ソート: 現在の背番号昇順 > 名前順
    rows.sort((a, b) {
      final numA = a.currentNumber;
      final numB = b.currentNumber;

      if (numA != null && numB == null) return -1;
      if (numA == null && numB != null) return 1;

      if (numA != null && numB != null) {
        final intValA = int.tryParse(numA.number) ?? 9999;
        final intValB = int.tryParse(numB.number) ?? 9999;
        final compare = intValA.compareTo(intValB);
        if (compare != 0) return compare;
      }
      return a.name.compareTo(b.name);
    });

    setState(() {
      _tableData = rows;
      _maxHistoryCount = maxHist;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('背番号管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _tableData.isEmpty
          ? const Center(child: Text('選手データがありません'))
          : SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false, // 行タップ用
            headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
            columns: [
              const DataColumn(label: Text('現在の背番号', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('名前', style: TextStyle(fontWeight: FontWeight.bold))),
              // 履歴列を動的に生成
              for (int i = 0; i < _maxHistoryCount; i++)
                DataColumn(label: Text('履歴${i + 1}', style: const TextStyle(color: Colors.grey))),
            ],
            rows: _tableData.map((row) {
              return DataRow(
                onSelectChanged: (_) async {
                  // 編集画面へ遷移
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UniformNumberEditScreen(
                        playerId: row.playerId,
                        playerName: row.name,
                      ),
                    ),
                  );
                  _loadData(); // 戻ってきたらリロード
                },
                cells: [
                  // 現在の背番号
                  DataCell(
                    row.currentNumber != null
                        ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.indigo,
                      ),
                      child: Text(
                        row.currentNumber!.number,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                        : const Text('-'),
                  ),
                  // 名前
                  DataCell(Text(row.name)),
                  // 履歴セル
                  for (int i = 0; i < _maxHistoryCount; i++)
                    DataCell(
                      i < row.history.length
                          ? _buildHistoryCell(row.history[i])
                          : const Text(''),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCell(UniformNumber record) {
    final start = DateFormat('yyyy/MM/dd').format(record.startDate);
    final end = record.endDate != null ? DateFormat('yyyy/MM/dd').format(record.endDate!) : '継続中';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('#${record.number}', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$start ～ $end', style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _PlayerRowData {
  final String playerId;
  final String name;
  final UniformNumber? currentNumber;
  final List<UniformNumber> history;

  _PlayerRowData({
    required this.playerId,
    required this.name,
    this.currentNumber,
    required this.history,
  });
}