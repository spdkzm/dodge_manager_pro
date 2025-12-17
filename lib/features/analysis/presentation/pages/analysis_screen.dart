// lib/features/analysis/presentation/pages/analysis_screen.dart
import 'dart:ui' as ui;
import 'dart:typed_data'; // Uint8List用
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/analysis_controller.dart';
import '../../../game_record/domain/models.dart';
import '../../../team_mgmt/application/team_store.dart';
import '../../../settings/data/action_dao.dart';
import '../../data/pdf_export_service.dart';

import '../widgets/analysis_stats_tab.dart';
import '../widgets/analysis_log_tab.dart';
import '../widgets/analysis_info_tab.dart';
import '../widgets/analysis_members_tab.dart';
import '../widgets/analysis_print_view.dart';
import '../widgets/analysis_log_print_view.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});
  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> with TickerProviderStateMixin {
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;
  String? _selectedMatchId;
  bool _isInitialLoadComplete = false;
  late TabController _tabController;

  List<MatchType> _selectedMatchTypes = [];
  final GlobalKey _printKey = GlobalKey();

  // 連続印刷中に表示する用の一時的なMatchRecord
  MatchRecord? _printingMatchRecord;

  @override
  void initState() {
    super.initState();
    // タブ数は4つ (集計, ログ, 試合情報, 出場メンバー)
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActionOrder();
    });
    // タブ切り替え時（スワイプ含む）にUIを再描画してプリントボタンの状態を更新する
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialLoadComplete) {
      Future.microtask(() {
        _runAnalysis();
        if (mounted) setState(() => _isInitialLoadComplete = true);
      });
    }
  }

  Future<void> _loadActionOrder() async {
    final store = ref.read(teamStoreProvider);
    if (!store.isLoaded) await store.loadFromDb();
  }

  void _runAnalysis() {
    ref.read(analysisControllerProvider.notifier).analyze(
        year: _selectedYear, month: _selectedMonth, day: _selectedDay, matchId: _selectedMatchId,
        targetTypes: _selectedMatchTypes.isEmpty ? null : _selectedMatchTypes
    );
  }

  // ★追加: 試合情報のラベル生成ロジックを共通化
  String _formatMatchLabel(MatchRecord record) {
    String dateStr = record.date;
    try {
      final d = DateTime.parse(record.date.replaceAll('/', '-'));
      dateStr = DateFormat('yyyy年M月d日').format(d);
    } catch (_) {}

    String label = "$dateStr vs ${record.opponent}";
    if (record.venueName != null && record.venueName!.isNotEmpty) {
      label += " @${record.venueName}";
    }
    if (record.note != null && record.note!.isNotEmpty) {
      label += "  ${record.note}";
    }
    return label;
  }

  String _getCurrentPeriodLabel() {
    if (_selectedMatchId != null) {
      final record = ref.read(selectedMatchRecordProvider);
      if (record != null) {
        // ★変更: 共通メソッドを使用
        return _formatMatchLabel(record);
      }
      return "試合集計";
    }

    if (_selectedYear == null) return "全期間 成績集計";
    if (_selectedMonth == null) return "$_selectedYear年 年計";
    if (_selectedDay == null) return "$_selectedYear年$_selectedMonth月 月計";
    return "$_selectedYear年$_selectedMonth月$_selectedDay日 日計";
  }

  Future<void> _handlePrint() async {
    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    final asyncStats = ref.read(analysisControllerProvider);
    final stats = asyncStats.valueOrNull;

    final isLogTab = _selectedMatchId != null && _tabController.index == 1;
    final matchRecord = ref.read(selectedMatchRecordProvider);
    // 日計表示中かどうか
    final isDailyView = _selectedYear != null && _selectedMonth != null && _selectedDay != null && _selectedMatchId == null;

    if (currentTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("印刷するデータがありません")));
      return;
    }

    if (isLogTab) {
      if (matchRecord == null || matchRecord.logs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("印刷するログがありません")));
        return;
      }
    } else {
      if (stats == null || stats.isEmpty || !stats.any((s) => s.matchesPlayed > 0)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("印刷するデータがありません")));
        return;
      }
    }

    // 日計画面かつボタン押下時にダイアログで分岐
    if (isDailyView) {
      final selectedType = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text("印刷メニュー"),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'stats'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("成績集計表を印刷", style: TextStyle(fontSize: 16)),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'logs'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("全試合のログを印刷", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      );

      if (selectedType == null) return;

      if (selectedType == 'logs') {
        await _handlePrintDailyLogs(currentTeam.name);
        return;
      }
      // 'stats' の場合はそのまま下の処理へ進む
    }

    // --- 以下、通常の1枚印刷処理 ---
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _printKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("印刷用データの生成に失敗しました");
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      await PdfExportService().printStatsImage(
        teamName: currentTeam.name,
        imageBytes: pngBytes,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("印刷エラー: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // 日計の全ログを連続印刷する処理
  Future<void> _handlePrintDailyLogs(String teamName) async {
    try {
      if (_selectedYear == null || _selectedMonth == null || _selectedDay == null) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ログ画像を生成中...しばらくお待ちください")));

      // 1. その日の全試合レコードを取得
      final records = await ref.read(analysisControllerProvider.notifier).fetchMatchRecordsByDate(
          _selectedYear!, _selectedMonth!, _selectedDay!
      );

      if (records.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("印刷対象の試合がありません")));
        return;
      }

      final List<Uint8List> images = [];

      // 2. 1試合ずつ表示を切り替えてキャプチャ
      for (final record in records) {
        if (!mounted) break;
        setState(() {
          _printingMatchRecord = record;
        });

        // 描画完了を待つ
        await Future.delayed(const Duration(milliseconds: 150));

        final boundary = _printKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 2.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            images.add(byteData.buffer.asUint8List());
          }
        }
      }

      // 3. 表示を元に戻す
      if (mounted) {
        setState(() {
          _printingMatchRecord = null;
        });
      }

      if (images.isEmpty) {
        throw Exception("画像の生成に失敗しました");
      }

      // 4. PDF生成サービスへ
      final dateStr = "${_selectedYear}年${_selectedMonth}月${_selectedDay}日";
      await PdfExportService().printMultipleImages(
        baseFileName: "${teamName}_試合ログ_$dateStr",
        images: images,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("印刷エラー: $e"), backgroundColor: Colors.red));
        // エラー時も表示状態をリセット
        setState(() {
          _printingMatchRecord = null;
        });
      }
    }
  }

  void _showFilterDialog() {
    final types = MatchType.values;
    final tempSelected = List<MatchType>.from(_selectedMatchTypes.isEmpty ? types : _selectedMatchTypes);
    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(title: const Text("集計フィルタ"), content: Column(mainAxisSize: MainAxisSize.min, children: types.map((type) {
          final isChecked = tempSelected.contains(type);
          return CheckboxListTile(title: Text(_getMatchTypeName(type)), value: isChecked, onChanged: (val) {
            setStateDialog(() {
              if (val == true) {
                tempSelected.add(type);
              } else {
                tempSelected.remove(type);
              }
            });
          });
        }).toList()), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")), ElevatedButton(onPressed: () {
          setState(() {
            if (tempSelected.length == types.length || tempSelected.isEmpty) {
              _selectedMatchTypes = [];
            } else {
              _selectedMatchTypes = tempSelected;
            }
          });
          Navigator.pop(ctx);
          _runAnalysis();
        }, child: const Text("適用"))]);
      });
    });
  }

  String _getMatchTypeName(MatchType type) { switch (type) { case MatchType.official: return "大会/公式戦"; case MatchType.practiceMatch: return "練習試合"; case MatchType.practice: return "練習"; } }
  IconData _getMatchTypeIcon(MatchType type) { switch (type) { case MatchType.official: return Icons.emoji_events; case MatchType.practiceMatch: return Icons.handshake; case MatchType.practice: return Icons.sports_handball; } }

  void _showAddMenu() {
    showModalBottomSheet(context: context, builder: (ctx) {
      return SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            leading: const Icon(Icons.playlist_add, color: Colors.indigo),
            title: const Text('プレーログを追加'),
            onTap: () {
              Navigator.pop(ctx);
              if (_selectedMatchId != null) {
                showEditLogDialog(context, ref, _selectedMatchId!, onUpdate: _runAnalysis);
              }
            }),
        ListTile(
            leading: const Icon(Icons.emoji_events, color: Colors.orange),
            title: const Text('試合結果を記録・修正'),
            onTap: () {
              Navigator.pop(ctx);
              final record = ref.read(selectedMatchRecordProvider);
              if (record != null) {
                showResultEditDialog(context, ref, record, onUpdate: _runAnalysis);
              }
            })
      ]));
    });
  }

  Widget _buildVerticalTabs<T>({ required List<T?> items, required T? selectedItem, required String Function(T?) labelBuilder, required Function(T?) onSelect, required double width, required Color color, }) { return Container(width: width, color: color, child: ListView.builder(padding: const EdgeInsets.symmetric(vertical: 8), itemCount: items.length, itemBuilder: (context, index) { final item = items[index]; final isSelected = item == selectedItem; return Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: TextButton(style: TextButton.styleFrom(backgroundColor: isSelected ? Colors.indigo.shade100 : Colors.transparent, foregroundColor: isSelected ? Colors.indigo : Colors.black87, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12)), onPressed: () => onSelect(item), child: Text(labelBuilder(item), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12), overflow: TextOverflow.ellipsis))); })); }

  @override
  Widget build(BuildContext context) {
    final teamStore = ref.watch(teamStoreProvider); final currentTeam = teamStore.currentTeam;
    ref.listen(teamStoreProvider, (previous, next) { if (previous?.currentTeam?.id != next.currentTeam?.id) { setState(() { _selectedYear = null; _selectedMonth = null; _selectedDay = null; _selectedMatchId = null; }); _runAnalysis(); } });

    final asyncStats = ref.watch(analysisControllerProvider); final matchRecord = ref.watch(selectedMatchRecordProvider);

    final availableYears = ref.watch(availableYearsProvider); final availableMonths = ref.watch(availableMonthsProvider); final availableDays = ref.watch(availableDaysProvider); final availableMatches = ref.watch(availableMatchesProvider);
    final yearTabs = [null, ...availableYears]; final monthTabs = [null, ...availableMonths]; final dayTabs = [null, ...availableDays]; final matchTabs = [null, ...availableMatches.keys];
    final isLogTabVisible = _selectedMatchId != null && _tabController.index == 1;

    final isStatsTab = _selectedMatchId == null || _tabController.index == 0;
    final isLogTab = _selectedMatchId != null && _tabController.index == 1;
    // 日計選択時も印刷可能とする
    final isDailyView = _selectedYear != null && _selectedMonth != null && _selectedDay != null && _selectedMatchId == null;
    final isPrintableTab = isStatsTab || isLogTab || isDailyView;

    // 印刷ボタンが押せるかどうかの判定（日計の場合はStatsがあればOKとする）
    final bool canPrint = isStatsTab || isDailyView
        ? (asyncStats.valueOrNull?.isNotEmpty == true)
        : (isLogTab && matchRecord != null && matchRecord.logs.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (_selectedMatchId != null && matchRecord != null) Row(children: [Icon(_getMatchTypeIcon(matchRecord.matchType), size: 16, color: Colors.black54), const SizedBox(width: 4), Text(availableMatches[_selectedMatchId] ?? "試合", style: const TextStyle(fontSize: 16)), const SizedBox(width: 8), const Icon(Icons.calendar_today, size: 14, color: Colors.black54), const SizedBox(width: 4), Text(matchRecord.date, style: const TextStyle(fontSize: 12, color: Colors.black54))]) else ...[const Text("データ分析", style: TextStyle(fontSize: 16)), Text(currentTeam?.name ?? "", style: const TextStyle(fontSize: 12, color: Colors.black54))]]),
        actions: [
          IconButton(icon: Icon(Icons.filter_alt, color: _selectedMatchTypes.isNotEmpty ? Colors.indigo : Colors.grey), tooltip: "種別フィルタ", onPressed: _showFilterDialog),
          if (isPrintableTab)
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: "印刷",
              onPressed: canPrint ? _handlePrint : null,
            ),

          IconButton(icon: const Icon(Icons.refresh), onPressed: _runAnalysis)
        ],
      ),
      body: Stack(
        children: [
          Row(children: [_buildVerticalTabs<int>(items: yearTabs, selectedItem: _selectedYear, labelBuilder: (y) => y == null ? '全期間' : '$y年', onSelect: (y) { setState(() { _selectedYear = y; _selectedMonth = null; _selectedDay = null; _selectedMatchId = null; }); _runAnalysis(); }, width: 90, color: Colors.grey[50]!), if (_selectedYear != null) _buildVerticalTabs<int>(items: monthTabs, selectedItem: _selectedMonth, labelBuilder: (m) => m == null ? '年計' : '$m月', onSelect: (m) { setState(() { _selectedMonth = m; _selectedDay = null; _selectedMatchId = null; }); _runAnalysis(); }, width: 60, color: Colors.grey[100]!), if (_selectedMonth != null) _buildVerticalTabs<int>(items: dayTabs, selectedItem: _selectedDay, labelBuilder: (d) => d == null ? '月計' : '$d日', onSelect: (d) { setState(() { _selectedDay = d; _selectedMatchId = null; }); _runAnalysis(); }, width: 60, color: Colors.grey[200]!), if (_selectedDay != null) _buildVerticalTabs<String>(items: matchTabs, selectedItem: _selectedMatchId, labelBuilder: (id) => id == null ? '日計' : (availableMatches[id] ?? '試合'), onSelect: (id) { setState(() { _selectedMatchId = id; }); _runAnalysis(); }, width: 140, color: Colors.grey[300]!), const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: Column(children: [
              if (_selectedMatchId != null) Container(color: Colors.grey[50], child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.indigo, unselectedLabelColor: Colors.grey, indicatorColor: Colors.indigo,
                  onTap: (idx) {
                    setState((){});
                  },
                  tabs: const [
                    Tab(icon: Icon(Icons.analytics, size: 18), text: "集計"),
                    Tab(icon: Icon(Icons.list, size: 18), text: "ログ"),
                    Tab(icon: Icon(Icons.info_outline, size: 18), text: "試合情報"),
                    Tab(icon: Icon(Icons.people, size: 18), text: "出場メンバー"),
                  ]
              )),
              const Divider(height: 1),
              Expanded(child: _selectedMatchId != null ? TabBarView(
                  controller: _tabController,
                  children: [
                    AnalysisStatsTab(asyncStats: asyncStats),
                    AnalysisLogTab(asyncStats: asyncStats, onUpdate: _runAnalysis),
                    AnalysisInfoTab(matchId: _selectedMatchId!, onUpdate: _runAnalysis),
                    AnalysisMembersTab(matchId: _selectedMatchId!, onUpdate: _runAnalysis),
                  ]
              ) : AnalysisStatsTab(asyncStats: asyncStats))
            ]))]),

          Positioned(
            left: 0,
            top: 0,
            child: Transform.translate(
              offset: const Offset(0, -20000),
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  key: _printKey,
                  child: Material(
                    color: Colors.white,
                    // 印刷用データの切り替えロジック
                    child: _printingMatchRecord != null
                        ? (asyncStats.hasValue // 連続印刷中に使うStatsは、その日の集計データ(全選手リスト用)で代用
                        ? AnalysisLogPrintView(
                      matchRecord: _printingMatchRecord!,
                      playerStats: asyncStats.value!,
                      teamName: currentTeam?.name ?? "",
                      // ★変更: 共通メソッドで詳細なラベルを生成
                      periodLabel: _formatMatchLabel(_printingMatchRecord!),
                    )
                        : const SizedBox())
                        : (isLogTab
                        ? (matchRecord != null && asyncStats.hasValue
                        ? AnalysisLogPrintView(
                      matchRecord: matchRecord,
                      playerStats: asyncStats.value!,
                      teamName: currentTeam?.name ?? "",
                      periodLabel: _getCurrentPeriodLabel(),
                    )
                        : const SizedBox())
                        : Container(
                      color: Colors.white,
                      child: AnalysisPrintView(
                        asyncStats: asyncStats,
                        teamName: currentTeam?.name ?? "",
                        periodLabel: _getCurrentPeriodLabel(),
                      ),
                    )),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isLogTabVisible ? FloatingActionButton(onPressed: _showAddMenu, child: const Icon(Icons.add)) : null,
    );
  }
}