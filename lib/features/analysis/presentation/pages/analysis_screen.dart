// lib/features/analysis/presentation/pages/analysis_screen.dart
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/analysis_controller.dart';
import '../../../game_record/domain/models.dart';
import '../../../team_mgmt/application/team_store.dart';

import '../../../settings/domain/action_definition.dart';
import '../../domain/player_stats.dart';
import '../../data/pdf_export_service.dart';

import '../widgets/analysis_stats_tab.dart';
import '../widgets/analysis_log_tab.dart';
import '../widgets/analysis_info_tab.dart';
import '../widgets/analysis_members_tab.dart';
import '../widgets/analysis_print_view.dart';
import '../widgets/action_detail_column.dart';

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

  MatchRecord? _printingMatchRecord;

  bool _isPrintingAllPlayers = false;
  PlayerStats? _currentPrintingPlayer;
  MapEntry<ActionDefinition, ActionStats?>? _currentPrintingEntry;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActionOrder();
    });
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
    if (_isPrintingAllPlayers) return;

    final store = ref.read(teamStoreProvider);
    final currentTeam = store.currentTeam;
    final asyncStats = ref.read(analysisControllerProvider);
    final stats = asyncStats.valueOrNull;

    final isLogTab = _selectedMatchId != null && _tabController.index == 1;
    final matchRecord = ref.read(selectedMatchRecordProvider);
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
    }
    else {
      if (stats == null || stats.isEmpty || !stats.any((s) => s.matchesPlayed > 0)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("印刷するデータがありません")));
        return;
      }
    }

    if (isLogTab) {
      try {
        final Map<String, String> nameMap = {};
        if (stats != null) {
          for (var p in stats) {
            nameMap[p.playerNumber] = p.playerName;
          }
        }

        await PdfExportService().printMatchLogsNative(
          baseFileName: "${currentTeam.name}_ログ_${matchRecord!.opponent}",
          printRequests: [{
            'record': matchRecord,
            'nameMap': nameMap,
          }],
        );

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("印刷エラー: $e"), backgroundColor: Colors.red));
        }
      }
    }
    else {
      final List<SimpleDialogOption> options = [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'stats'),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("成績集計表を印刷", style: TextStyle(fontSize: 16)),
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'players_details'),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("全選手の詳細を印刷", style: TextStyle(fontSize: 16)),
          ),
        ),
      ];

      if (isDailyView) {
        options.add(
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'daily_logs'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text("全試合のログを印刷", style: TextStyle(fontSize: 16)),
            ),
          ),
        );
      }

      final selectedType = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text("印刷メニュー"),
          children: options,
        ),
      );

      if (selectedType == null) return;

      if (selectedType == 'daily_logs') {
        await _handlePrintDailyLogs(currentTeam.name);
        return;
      }

      if (selectedType == 'players_details') {
        if (stats != null) {
          await _handlePrintAllPlayerDetails(stats);
        }
        return;
      }

      if (selectedType == 'stats' && stats != null) {
        try {
          final filteredStats = stats.where((s) => s.matchesPlayed > 0).toList();
          filteredStats.sort((a, b) => (int.tryParse(a.playerNumber) ?? 999).compareTo(int.tryParse(b.playerNumber) ?? 999));

          if (filteredStats.isEmpty) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("印刷対象のデータがありません")));
            return;
          }

          final actionDefs = ref.read(analysisControllerProvider.notifier).actionDefinitions;

          await PdfExportService().printStatsList(
            teamName: currentTeam.name,
            periodLabel: _getCurrentPeriodLabel(),
            stats: filteredStats,
            actionDefinitions: actionDefs,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("印刷エラー: $e"), backgroundColor: Colors.red));
          }
        }
      }
    }
  }

  Future<void> _handlePrintAllPlayerDetails(List<PlayerStats> stats) async {
    try {
      setState(() {
        _isPrintingAllPlayers = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("選手詳細データを生成中..."), duration: Duration(seconds: 2)),
        );
      }

      final targetPlayers = stats.where((p) => p.matchesPlayed > 0).toList();
      targetPlayers.sort((a, b) => (int.tryParse(a.playerNumber) ?? 999).compareTo(int.tryParse(b.playerNumber) ?? 999));

      if (targetPlayers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("印刷対象の選手がいません")));
        }
        return;
      }

      final definitions = ref.read(analysisControllerProvider.notifier).actionDefinitions;
      final List<Map<String, dynamic>> allPlayersData = [];

      for (final player in targetPlayers) {
        if (!mounted) break;

        setState(() {
          _currentPrintingPlayer = player;
        });

        final List<Uint8List> playerImages = [];

        final printingActions = definitions.map((def) {
          final stat = player.actions[def.name];
          return MapEntry(def, stat);
        }).where((entry) {
          final def = entry.key;
          final stat = entry.value;
          return (stat != null && stat.totalCount > 0) && def.subActions.isNotEmpty;
        }).toList();

        for (final entry in printingActions) {
          if (!mounted) break;

          setState(() {
            _currentPrintingEntry = entry;
          });

          await Future.delayed(const Duration(milliseconds: 100));

          final boundary = _printKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
          if (boundary != null) {
            final image = await boundary.toImage(pixelRatio: 3.0);
            final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
            if (byteData != null) {
              playerImages.add(byteData.buffer.asUint8List());
            }
          }
        }

        allPlayersData.add({
          'name': "${player.playerNumber} ${player.playerName}",
          'matchCount': player.matchesPlayed,
          'images': playerImages,
        });
      }

      if (allPlayersData.isNotEmpty && mounted) {
        await PdfExportService().printMultiplePlayersDetails(playersData: allPlayersData);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("印刷可能なデータがありません")));
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("印刷エラー: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrintingAllPlayers = false;
          _currentPrintingPlayer = null;
          _currentPrintingEntry = null;
        });
      }
    }
  }

  Future<void> _handlePrintDailyLogs(String teamName) async {
    try {
      if (_selectedYear == null || _selectedMonth == null || _selectedDay == null) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDFを生成中...")));

      final controller = ref.read(analysisControllerProvider.notifier);

      final records = await controller.fetchMatchRecordsByDate(
          _selectedYear!, _selectedMonth!, _selectedDay!
      );

      if (records.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("印刷対象の試合がありません")));
        return;
      }

      final dailyStats = await controller.fetchStatsForExport(
        year: _selectedYear, month: _selectedMonth, day: _selectedDay,
      );
      final Map<String, String> nameMap = {};
      for (var p in dailyStats) {
        nameMap[p.playerNumber] = p.playerName;
      }

      final List<Map<String, dynamic>> requests = records.map((r) => {
        'record': r,
        'nameMap': nameMap,
      }).toList();

      final dateStr = "${_selectedYear}年${_selectedMonth}月${_selectedDay}日";
      await PdfExportService().printMatchLogsNative(
        baseFileName: "${teamName}_試合ログ_$dateStr",
        printRequests: requests,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("印刷エラー: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _showFilterDialog() {
    final types = MatchType.values;
    final tempSelected = List<MatchType>.from(_selectedMatchTypes.isEmpty ? types : _selectedMatchTypes);
    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
            title: const Text("集計フィルタ"),
            // ★修正: SizedBoxでダイアログのサイズを制御できるようにしました
            content: SizedBox(
              width: 300, // ここで幅を指定できます
              height: 400, // 高さを固定したい場合はコメントアウトを外して指定してください
              child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: types.map((type) {
                      final isChecked = tempSelected.contains(type);
                      return CheckboxListTile(
                          title: Text(_getMatchTypeName(type)),
                          value: isChecked,
                          onChanged: (val) {
                            setStateDialog(() {
                              if (val == true) {
                                tempSelected.add(type);
                              } else {
                                tempSelected.remove(type);
                              }
                            });
                          });
                    }).toList()),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("キャンセル")),
              ElevatedButton(onPressed: () {
                setState(() {
                  if (tempSelected.length == types.length || tempSelected.isEmpty) {
                    _selectedMatchTypes = [];
                  } else {
                    _selectedMatchTypes = tempSelected;
                  }
                });
                Navigator.pop(ctx);
                _runAnalysis();
              }, child: const Text("適用"))
            ]);
      });
    });
  }

  String _getMatchTypeName(MatchType type) {
    switch (type) {
      case MatchType.official: return "大会/公式戦";
      case MatchType.practiceMatch: return "練習試合";
      case MatchType.practice: return "練習";
      case MatchType.formationPractice: return "フォーメーション練習";
    }
  }

  IconData _getMatchTypeIcon(MatchType type) {
    switch (type) {
      case MatchType.official: return Icons.emoji_events;
      case MatchType.practiceMatch: return Icons.handshake;
      case MatchType.practice: return Icons.sports_handball;
      case MatchType.formationPractice: return Icons.grid_view;
    }
  }

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
    final isDailyView = _selectedYear != null && _selectedMonth != null && _selectedDay != null && _selectedMatchId == null;
    final isPrintableTab = isStatsTab || isLogTab || isDailyView;

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
                    child:
                    _isPrintingAllPlayers && _currentPrintingEntry != null && _currentPrintingPlayer != null
                        ? SizedBox(
                      width: 350,
                      height: 800,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: ActionDetailColumn(
                          definition: _currentPrintingEntry!.key,
                          stats: _currentPrintingEntry!.value,
                        ),
                      ),
                    )
                        : const SizedBox(),
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