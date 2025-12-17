// lib/features/analysis/presentation/widgets/player_detail_dialog.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../domain/player_stats.dart';
import '../../../settings/domain/action_definition.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/pdf_export_service.dart';
import 'action_detail_column.dart';

class PlayerDetailDialog extends StatefulWidget {
  final PlayerStats player;
  final List<ActionDefinition> definitions;

  const PlayerDetailDialog({
    super.key,
    required this.player,
    required this.definitions,
  });

  @override
  State<PlayerDetailDialog> createState() => _PlayerDetailDialogState();
}

class _PlayerDetailDialogState extends State<PlayerDetailDialog> {
  final GlobalKey _printKey = GlobalKey();

  // 印刷処理用の状態管理
  bool _isPrinting = false;
  MapEntry<ActionDefinition, ActionStats?>? _currentPrintingEntry;

  Future<void> _handlePrint() async {
    if (_isPrinting) return;

    try {
      setState(() {
        _isPrinting = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("印刷データを生成中..."), duration: Duration(seconds: 2)),
        );
      }

      // 既存のフィルタリングロジックと同じ条件で印刷対象リストを作成
      // 1. 実績がある (totalCount > 0)
      // 2. かつ、サブアクション(内訳)の定義がある (subActions.isNotEmpty)
      final printingActions = widget.definitions.map((def) {
        final stat = widget.player.actions[def.name];
        return MapEntry(def, stat);
      }).where((entry) {
        final def = entry.key;
        final stat = entry.value;
        return (stat != null && stat.totalCount > 0) && def.subActions.isNotEmpty;
      }).toList();

      if (printingActions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("印刷するデータがありません")),
          );
        }
        return;
      }

      final List<Uint8List> images = [];

      // 1つずつ順番に描画してキャプチャ
      for (final entry in printingActions) {
        if (!mounted) break;

        setState(() {
          _currentPrintingEntry = entry;
        });

        // 描画完了を待機 (フレーム確定待ち)
        await Future.delayed(const Duration(milliseconds: 100));

        final boundary = _printKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          // 高解像度でキャプチャ (縮小印刷しても綺麗に見えるように3倍)
          final image = await boundary.toImage(pixelRatio: 3.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            images.add(byteData.buffer.asUint8List());
          }
        }
      }

      if (images.isNotEmpty && mounted) {
        await PdfExportService().printPlayerDetailImages(
          playerName: "${widget.player.playerNumber} ${widget.player.playerName}",
          matchCount: widget.player.matchesPlayed, // ★追加: 試合数を渡す
          images: images,
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("印刷エラー: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
          _currentPrintingEntry = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 既存のフィルタリングロジック（そのまま維持）
    // 1. 実績がある (totalCount > 0)
    // 2. かつ、サブアクション(内訳)の定義がある (subActions.isNotEmpty)
    final displayActions = widget.definitions.map((def) {
      final stat = widget.player.actions[def.name];
      return MapEntry(def, stat);
    }).where((entry) {
      final def = entry.key;
      final stat = entry.value;
      return (stat != null && stat.totalCount > 0) && def.subActions.isNotEmpty;
    }).toList();

    final size = MediaQuery.of(context).size;
    final dialogHeight = min(size.height * 0.85, 800.0);

    return Stack(
      children: [
        // メインのダイアログ表示（既存構造を維持）
        AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          contentPadding: const EdgeInsets.all(0),
          clipBehavior: Clip.antiAlias,

          title: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle, size: 40, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "#${widget.player.playerNumber} ${widget.player.playerName}",
                          style: AppTextStyles.titleLarge,
                        ),
                        Text(
                          "${widget.player.matchesPlayed} 試合出場",
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(),
            ],
          ),

          content: SizedBox(
            width: double.maxFinite,
            height: 700, // 既存コードの値を維持
            child: displayActions.isEmpty
                ? const Center(child: Text("表示するデータがありません"))
                : Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: displayActions.map((entry) {
                    return ActionDetailColumn(
                      definition: entry.key,
                      stats: entry.value,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          actions: [
            // 印刷ボタンを追加
            if (!_isPrinting)
              TextButton.icon(
                onPressed: _handlePrint,
                icon: const Icon(Icons.print, size: 18),
                label: const Text("詳細を印刷"),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("閉じる"),
            ),
          ],
        ),

        // 印刷用・裏側レンダリングエリア
        // 画面外に配置し、1つずつ描画する
        if (_isPrinting && _currentPrintingEntry != null)
          Positioned(
            left: 0,
            top: 0,
            child: Transform.translate(
              offset: const Offset(0, -20000), // 画面外へ飛ばす
              child: RepaintBoundary(
                key: _printKey,
                child: Material(
                  color: Colors.white,
                  // SizedBoxでサイズを固定し、Unbounded Heightエラーを解消
                  child: SizedBox(
                    width: 350, // ActionDetailColumnの規定幅
                    height: 800, // 高さを固定してExpandedが計算できるようにする
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ActionDetailColumn(
                        definition: _currentPrintingEntry!.key,
                        stats: _currentPrintingEntry!.value,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}