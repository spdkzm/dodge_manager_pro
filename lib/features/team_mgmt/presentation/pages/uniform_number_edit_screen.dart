// lib/features/team_mgmt/presentation/pages/uniform_number_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/team_store.dart';
import '../../domain/uniform_number.dart';
import '../../data/uniform_number_dao.dart';

class UniformNumberEditDialog extends ConsumerStatefulWidget {
  final String playerId;
  final String playerName;

  const UniformNumberEditDialog({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  @override
  ConsumerState<UniformNumberEditDialog> createState() => _UniformNumberEditDialogState();
}

class _UniformNumberEditDialogState extends ConsumerState<UniformNumberEditDialog> {
  final UniformNumberDao _dao = UniformNumberDao();
  final _formKey = GlobalKey<FormState>();

  // 状態管理
  bool _isLoading = true;
  List<UniformNumber> _history = [];

  // 編集モード用
  bool _isEditing = false;
  UniformNumber? _editingTarget; // nullの場合は新規追加

  // フォームコントローラ
  late TextEditingController _numberCtrl;
  late DateTime _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _numberCtrl = TextEditingController();
    _loadHistory();
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final records = await _dao.getUniformNumbersByPlayer(widget.playerId);
    // 日付降順（新しい順）
    records.sort((a, b) => b.startDate.compareTo(a.startDate));

    if (mounted) {
      setState(() {
        _history = records;
        _isLoading = false;
        // リストに戻ったときはフォーム状態をリセット
        _isEditing = false;
        _editingTarget = null;
      });
    }
  }

  // 新規追加モード開始
  void _startAdd() {
    _numberCtrl.text = '';
    _startDate = DateTime.now();
    _endDate = null;

    setState(() {
      _editingTarget = null;
      _isEditing = true;
    });
  }

  // 編集モード開始
  void _startEdit(UniformNumber record) {
    _numberCtrl.text = record.number;
    _startDate = record.startDate;
    _endDate = record.endDate;

    setState(() {
      _editingTarget = record;
      _isEditing = true;
    });
  }

  // 編集・追加キャンセル
  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editingTarget = null;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final store = ref.read(teamStoreProvider);
    final team = store.currentTeam;
    if (team == null) return;

    // 重複チェック
    final overlaps = await _dao.findOverlappingNumbers(
      teamId: team.id,
      number: _numberCtrl.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      excludeId: _editingTarget?.id, // 新規の場合はnullなので全件チェック、更新時は自分を除外
    );

    if (overlaps.isNotEmpty) {
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

    final newRecord = UniformNumber(
      id: _editingTarget?.id,
      teamId: team.id,
      playerId: widget.playerId,
      number: _numberCtrl.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
    );

    if (_editingTarget != null) {
      // 更新
      await _dao.updateUniformNumber(newRecord);
    } else {
      // 新規追加
      await _dao.insertUniformNumber(newRecord);
    }

    // リスト再読み込みして一覧に戻る
    await _loadHistory();
  }

  Future<void> _delete() async {
    final record = _editingTarget;
    // 新規追加中、またはIDがない場合は処理しない
    if (record == null || record.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この履歴を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dao.deleteUniformNumber(record.id!);
      await _loadHistory(); // 削除後、リストに戻る
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
              _isEditing
                  ? (_editingTarget == null ? '新しい背番号を追加' : '${widget.playerName} の編集')
                  : '${widget.playerName} の背番号履歴'
          ),
          // リスト表示時のみ追加ボタンを表示
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.indigo, size: 28),
              onPressed: _startAdd,
              tooltip: '追加',
            ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 400, // 高さを固定して安定させる
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isEditing
            ? _buildEditForm()
            : _buildHistoryList(),
      ),
      actions: _isEditing ? _buildEditActions() : _buildListActions(),
    );
  }

  // --- リスト表示モード ---
  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('背番号の履歴がありません'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _startAdd,
              icon: const Icon(Icons.add),
              label: const Text('最初の背番号を登録'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _history.length,
      separatorBuilder: (ctx, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _history[index];
        final start = DateFormat('yyyy/MM/dd').format(item.startDate);
        final end = item.endDate != null ? DateFormat('yyyy/MM/dd').format(item.endDate!) : '継続中';
        final isActive = item.isActiveAt(DateTime.now());

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isActive ? Colors.indigo : Colors.grey.shade400,
            foregroundColor: Colors.white,
            child: Text(item.number, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text('背番号 ${item.number}'),
          subtitle: Text('$start 〜 $end'),
          trailing: const Icon(Icons.edit, size: 20, color: Colors.grey),
          onTap: () => _startEdit(item),
        );
      },
    );
  }

  List<Widget> _buildListActions() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('閉じる'),
      ),
    ];
  }

  // --- 編集モード ---
  Widget _buildEditForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 背番号入力
            TextFormField(
              controller: _numberCtrl,
              decoration: const InputDecoration(
                labelText: '背番号',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              validator: (v) => (v == null || v.trim().isEmpty) ? '背番号を入力してください' : null,
            ),
            const SizedBox(height: 24),

            const Text('適用期間', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),

            // 開始日
            ListTile(
              title: const Text('適用開始日'),
              subtitle: Text(DateFormat('yyyy/MM/dd').format(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              contentPadding: EdgeInsets.zero,
              dense: true,
              onTap: () => _pickDate(isStart: true),
            ),
            const Divider(),

            // 終了日
            ListTile(
              title: const Text('適用終了日（任意）'),
              subtitle: Text(_endDate != null ? DateFormat('yyyy/MM/dd').format(_endDate!) : '指定なし（継続）'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() => _endDate = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today),
                ],
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
              onTap: () => _pickDate(isStart: false),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEditActions() {
    final isNew = _editingTarget == null;
    return [
      // 左端: 削除 (新規作成時は非表示)
      isNew
          ? const SizedBox.shrink()
          : TextButton.icon(
        onPressed: _delete,
        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
        label: const Text('削除', style: TextStyle(color: Colors.red)),
      ),
      // 右側: キャンセル・保存
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: _cancelEdit,
            child: const Text('キャンセル'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    ];
  }
}