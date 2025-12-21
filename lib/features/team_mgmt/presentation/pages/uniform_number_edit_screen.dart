// lib/features/team_mgmt/presentation/pages/uniform_number_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/team_store.dart';
import '../../domain/uniform_number.dart';
import '../../data/uniform_number_dao.dart';

class UniformNumberEditScreen extends ConsumerStatefulWidget {
  final String playerId;
  final String playerName;

  const UniformNumberEditScreen({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  @override
  ConsumerState<UniformNumberEditScreen> createState() => _UniformNumberEditScreenState();
}

class _UniformNumberEditScreenState extends ConsumerState<UniformNumberEditScreen> {
  final UniformNumberDao _dao = UniformNumberDao();
  List<UniformNumber> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    // 該当選手の履歴を取得し、日付降順でソート
    final records = await _dao.getUniformNumbersByPlayer(widget.playerId);
    records.sort((a, b) => b.startDate.compareTo(a.startDate)); // 新しい順

    setState(() {
      _history = records;
      _isLoading = false;
    });
  }

  // 追加・編集ダイアログ
  void _showEditDialog({UniformNumber? record}) {
    final store = ref.read(teamStoreProvider);
    final team = store.currentTeam;
    if (team == null) return;

    final isEditing = record != null;
    final numberCtrl = TextEditingController(text: record?.number ?? '');

    // 開始日: 新規なら今日、編集なら既存値
    DateTime startDate = record?.startDate ?? DateTime.now();
    // 終了日: 新規ならnull、編集なら既存値
    DateTime? endDate = record?.endDate;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // 日付選択時の初期値を今日にするヘルパー
            Future<void> pickDate({required bool isStart}) async {
              final initial = isStart
                  ? startDate
                  : (endDate ?? DateTime.now()); // ★修正: 終了日選択時はデフォルト今日

              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                setStateDialog(() {
                  if (isStart) {
                    startDate = picked;
                  } else {
                    endDate = picked;
                  }
                });
              }
            }

            return AlertDialog(
              title: Text(isEditing ? '背番号履歴の編集' : '新しい背番号を追加'),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: numberCtrl,
                          decoration: const InputDecoration(labelText: '背番号'),
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.trim().isEmpty) ? '背番号を入力してください' : null,
                        ),
                        const SizedBox(height: 16),

                        // 開始日
                        ListTile(
                          title: const Text('適用開始日'),
                          subtitle: Text(DateFormat('yyyy/MM/dd').format(startDate)),
                          trailing: const Icon(Icons.calendar_today),
                          contentPadding: EdgeInsets.zero,
                          onTap: () => pickDate(isStart: true),
                        ),

                        // 終了日
                        ListTile(
                          title: const Text('適用終了日（任意）'),
                          subtitle: Text(endDate != null ? DateFormat('yyyy/MM/dd').format(endDate!) : '指定なし（継続）'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (endDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => setStateDialog(() => endDate = null),
                                ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                          contentPadding: EdgeInsets.zero,
                          onTap: () => pickDate(isStart: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('削除確認'),
                          content: const Text('この履歴を削除しますか？'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _dao.deleteUniformNumber(record.id);
                        if (mounted) Navigator.pop(context); // Close Dialog
                        _loadHistory(); // Reload List
                      }
                    },
                    child: const Text('削除', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      // 重複チェック
                      final overlaps = await _dao.findOverlappingNumbers(
                        teamId: team.id,
                        number: numberCtrl.text.trim(),
                        startDate: startDate,
                        endDate: endDate,
                        excludeId: record?.id,
                      );

                      // 本人の別履歴との重複もあり得るので、エラーメッセージを調整
                      // findOverlappingNumbersは「同じ番号」かつ「期間重複」をチェックしている。
                      // ここでは「他の人」だけでなく「自分自身の別の期間」もチェック対象に含めるべきだが、
                      // 現状のDAO実装は「teamIdとnumber」で検索しているため、
                      // 「自分が別の番号を使っている期間」との重複はチェックされない（背番号が変わるなら期間重複してても論理矛盾ではないが、物理的にはありえない）。
                      // 一旦、DAOのロジック通り「同じ背番号を誰かが使っている期間」との重複を防ぐ。

                      if (overlaps.isNotEmpty) {
                        // 重複あり
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('期間または番号が他の記録と重複しています'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      // 自分自身の履歴内で、期間が重複しているかチェック（背番号が違っても、体は一つなので期間重複はNGとする場合）
                      // ここでは簡易的に「同じ番号の重複」のみDAOで弾いているが、厳密には
                      // 「この選手が同時期に別の番号を持つ」ことも防ぐべきかもしれない。
                      // 今回の要件には明記されていないが、一般的にはNG。
                      // 追加チェックを行う。
                      bool periodOverlap = false;
                      for (var h in _history) {
                        if (h.id == record?.id) continue; // 自分自身（編集対象）は除く
                        if (h.overlapsWith(startDate, endDate)) {
                          periodOverlap = true;
                          break;
                        }
                      }
                      if (periodOverlap) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('この選手の他の背番号履歴と期間が重複しています'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      final newRecord = UniformNumber(
                        id: record?.id,
                        teamId: team.id,
                        playerId: widget.playerId,
                        number: numberCtrl.text.trim(),
                        startDate: startDate,
                        endDate: endDate,
                      );

                      if (isEditing) {
                        await _dao.updateUniformNumber(newRecord);
                      } else {
                        await _dao.insertUniformNumber(newRecord);
                      }

                      if (mounted) Navigator.pop(context);
                      _loadHistory();
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.playerName} の背番号履歴'),
        actions: [
          // ★修正: 追加機能をAppBarのアイコンに配置
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(),
            tooltip: '新しい背番号を追加',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('背番号の履歴がありません'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showEditDialog(),
              child: const Text('背番号を追加する'),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          final start = DateFormat('yyyy/MM/dd').format(item.startDate);
          final end = item.endDate != null ? DateFormat('yyyy/MM/dd').format(item.endDate!) : '継続中';

          // 現在有効かどうか
          final isActive = item.isActiveAt(DateTime.now());

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isActive ? Colors.indigo : Colors.grey,
                child: Text(item.number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text('#${item.number}'),
              subtitle: Text('$start 〜 $end'),
              trailing: const Icon(Icons.edit),
              onTap: () => _showEditDialog(record: item),
            ),
          );
        },
      ),
    );
  }
}