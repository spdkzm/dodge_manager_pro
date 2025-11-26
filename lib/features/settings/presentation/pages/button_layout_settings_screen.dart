// lib/features/settings/presentation/pages/button_layout_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../team_mgmt/application/team_store.dart';
import '../../data/action_dao.dart';
import '../../domain/action_definition.dart';
import '../../../game_record/data/persistence.dart';
import '../../../game_record/domain/models.dart'; // AppSettings

// 配置用の中間アイテムクラス
class DraggableLayoutItem {
  final String parentId;
  final String name;
  final String type; // 'normal', 'success', 'failure'
  final Color color;

  DraggableLayoutItem({
    required this.parentId,
    required this.name,
    required this.type,
    required this.color,
  });
}

class ButtonLayoutSettingsScreen extends ConsumerStatefulWidget {
  const ButtonLayoutSettingsScreen({super.key});

  @override
  ConsumerState<ButtonLayoutSettingsScreen> createState() => _ButtonLayoutSettingsScreenState();
}

class _ButtonLayoutSettingsScreenState extends ConsumerState<ButtonLayoutSettingsScreen> {
  final ActionDao _actionDao = ActionDao();

  // グリッドの状態: インデックス -> 配置アイテム
  final Map<int, DraggableLayoutItem> _gridSlots = {};

  // 元のアクション定義リスト (保存時にIDで参照して更新する)
  List<ActionDefinition> _originalActions = [];

  AppSettings _appSettings = AppSettings(squadNumbers: [], actions: []);
  int _columns = 3;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    // 1. 列数設定のロード
    final settings = await DataManager.loadSettings();
    _appSettings = settings;
    _columns = settings.gridColumns;

    // 2. アクション定義のロード
    final store = ref.read(teamStoreProvider);
    if (!store.isLoaded) await store.loadFromDb();
    final currentTeam = store.currentTeam;

    if (currentTeam != null) {
      final raw = await _actionDao.getActionDefinitions(currentTeam.id);
      _originalActions = raw.map((d) => ActionDefinition.fromMap(d)).toList();

      // 3. アクションを配置アイテムに分解してグリッドに配置
      for (var action in _originalActions) {
        // A. 成功も失敗もない場合 -> 通常ボタン
        if (!action.hasSuccess && !action.hasFailure) {
          _placeItem(
            action.positionIndex,
            DraggableLayoutItem(parentId: action.id, name: action.name, type: 'normal', color: Colors.white),
          );
        }
        else {
          // B. 成功ボタンがある場合
          if (action.hasSuccess) {
            _placeItem(
              action.successPositionIndex,
              DraggableLayoutItem(parentId: action.id, name: "${action.name}(成功)", type: 'success', color: Colors.red.shade50),
            );
          }
          // C. 失敗ボタンがある場合
          if (action.hasFailure) {
            _placeItem(
              action.failurePositionIndex,
              DraggableLayoutItem(parentId: action.id, name: "${action.name}(失敗)", type: 'failure', color: Colors.blue.shade50),
            );
          }
        }
      }
    }

    setState(() => _isLoading = false);
  }

  // 空きスロットを探して配置するヘルパー
  void _placeItem(int preferredIndex, DraggableLayoutItem item) {
    // 指定位置が空いていればそこに置く
    if (!_gridSlots.containsKey(preferredIndex)) {
      _gridSlots[preferredIndex] = item;
    } else {
      // 空いてなければ、0から探して空いている最初の場所に置く
      int newPos = 0;
      while (_gridSlots.containsKey(newPos)) newPos++;
      _gridSlots[newPos] = item;
    }
  }

  // ★追加: 隙間を詰めて再配置する処理 (列数変更時に呼ぶ)
  void _compactItems() {
    // 現在のアイテムをインデックス順にソートして取得
    final sortedItems = _gridSlots.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    _gridSlots.clear();

    // 0から詰めて再配置
    for (int i = 0; i < sortedItems.length; i++) {
      _gridSlots[i] = sortedItems[i].value;
    }
  }

  Future<void> _save() async {
    // 1. グリッドの状態から ActionDefinition を更新
    // まず全アクションの位置情報をリセット（配置されなかったボタン対策）
    final Map<String, ActionDefinition> updatesMap = {
      for (var a in _originalActions) a.id: a
    };

    _gridSlots.forEach((index, item) {
      final action = updatesMap[item.parentId];
      if (action != null) {
        if (item.type == 'normal') {
          action.positionIndex = index;
        } else if (item.type == 'success') {
          action.successPositionIndex = index;
        } else if (item.type == 'failure') {
          action.failurePositionIndex = index;
        }
      }
    });

    // 2. DB更新
    await _actionDao.updateActionPositions(updatesMap.values.toList());

    // 3. 列数の保存
    _appSettings.gridColumns = _columns;
    await DataManager.saveSettings(_appSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("レイアウトを保存しました")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // グリッドの最大サイズ計算
    int maxIndex = 0;
    if (_gridSlots.isNotEmpty) {
      maxIndex = _gridSlots.keys.reduce((a, b) => a > b ? a : b);
    }
    int totalSlots = ((maxIndex + 1) / _columns).ceil() * _columns;
    // 最低でも5行分は確保
    if (totalSlots < _columns * 5) totalSlots = _columns * 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ボタン配置カスタマイズ"),
        actions: [
          TextButton(onPressed: _save, child: const Text("保存", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
        ],
      ),
      body: Column(
        children: [
          // 設定バー
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text("列数: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Slider(
                    value: _columns.toDouble(),
                    min: 2, max: 6, divisions: 4,
                    label: "$_columns 列",
                    onChanged: (val) {
                      setState(() {
                        int newCols = val.toInt();
                        // ★修正: 列数が変わったら、隙間を詰めて再配置する
                        if (newCols != _columns) {
                          _columns = newCols;
                          _compactItems();
                        }
                      });
                    },
                  ),
                ),
                Text("$_columns 列", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),

          // グリッドエディタ
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _columns,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: totalSlots,
              itemBuilder: (context, index) {
                final item = _gridSlots[index];

                return DragTarget<DraggableLayoutItem>(
                  onWillAccept: (data) => true,
                  onAccept: (data) {
                    setState(() {
                      // 移動元のインデックスを探して削除
                      int oldIndex = -1;
                      _gridSlots.forEach((key, val) {
                        if (val.parentId == data.parentId && val.type == data.type) {
                          oldIndex = key;
                        }
                      });

                      if (oldIndex != -1) _gridSlots.remove(oldIndex);

                      // スワップ処理
                      if (item != null) {
                        if (oldIndex != -1) {
                          _gridSlots[oldIndex] = item;
                        }
                      }

                      _gridSlots[index] = data;
                    });
                  },
                  builder: (context, candidates, rejects) {
                    final isHovered = candidates.isNotEmpty;

                    if (item == null) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: isHovered ? Colors.blue : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: isHovered ? Colors.blue.withOpacity(0.1) : Colors.white,
                        ),
                        child: Center(child: Icon(Icons.add, color: Colors.grey.shade300)),
                      );
                    }

                    return Draggable<DraggableLayoutItem>(
                      data: item,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: 120, height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Colors.indigo,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)]
                          ),
                          child: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      childWhenDragging: Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8), color: Colors.grey.shade200),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.indigo),
                          borderRadius: BorderRadius.circular(8),
                          color: item.color,
                        ),
                        alignment: Alignment.center,
                        child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}