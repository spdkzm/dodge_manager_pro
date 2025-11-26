// lib/features/game_record/presentation/pages/match_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';

class MatchDetailScreen extends StatefulWidget {
  final MatchRecord record;

  const MatchDetailScreen({super.key, required this.record});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // フィルター関連の変数は削除しました

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("VS ${widget.record.opponent}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.record.date, style: const TextStyle(fontSize: 12)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: "ログ (詳細)"),
            Tab(icon: Icon(Icons.analytics), text: "集計 (スタッツ)"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  // --- タブ1: ログ詳細ビュー ---
  Widget _buildLogTab() {
    // フィルタリングせず、全てのログを表示
    final logs = widget.record.logs;

    return Column(
      children: [
        // フィルターバーを削除し、件数表示のみ残す（あるいは削除しても良いが、件数はあると便利なのでシンプルに表示）
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          alignment: Alignment.centerRight,
          child: Text("全 ${logs.length} 件", style: const TextStyle(color: Colors.grey)),
        ),
        const Divider(height: 1),

        // ヘッダー行
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[200],
          child: const Row(
            children: [
              SizedBox(width: 60, child: Text("時間", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 80, child: Text("選手", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text("プレー内容", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 1, child: Text("詳細", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 50, child: Text("操作", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
            ],
          ),
        ),

        // ログリスト
        Expanded(
          child: ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogRow(log);
            },
          ),
        ),
      ],
    );
  }

  // ログ1行の表示
  Widget _buildLogRow(LogEntry log) {
    // システムログ
    if (log.type == LogType.system) {
      return Container(
        color: Colors.grey[50],
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            "${log.gameTime}  -  ${log.action}  -",
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      );
    }

    // 通常ログ（色分けなし）
    String resultText = "";
    if (log.result == ActionResult.success) {
      resultText = "(成功)";
    } else if (log.result == ActionResult.failure) {
      resultText = "(失敗)";
    }

    return Container(
      color: Colors.white, // 背景色は白固定
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 時間
          SizedBox(
            width: 60,
            child: Text(log.gameTime, style: const TextStyle(fontFamily: 'monospace', color: Colors.black54)),
          ),
          // 選手
          SizedBox(
            width: 80,
            child: Text("#${log.playerNumber}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          // プレー内容（アクション名 + 結果テキスト）
          Expanded(
            flex: 2,
            child: Text(
              "${log.action} $resultText",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
          // 詳細
          Expanded(
            flex: 1,
            child: Text(log.subAction ?? "-", style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          // 操作
          SizedBox(
            width: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("編集機能は今後実装予定")));
                  },
                  child: const Icon(Icons.edit, size: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("集計機能は開発中です", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}