// lib/features/game_record/presentation/widgets/game_log_panel.dart
import 'package:flutter/material.dart';
import '../../domain/models.dart';

class GameLogPanel extends StatelessWidget {
  final List<LogEntry> logs;
  final Function(LogEntry log, int index) onLogTap;

  const GameLogPanel({
    super.key,
    required this.logs,
    required this.onLogTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: Colors.grey[200],
          child: const Text(
              "ログ (タップして編集)",
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];

              // システムログ
              if (log.type == LogType.system) {
                return Card(
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Text(log.gameTime, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace')),
                    title: Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onTap: () => onLogTap(log, index),
                  ),
                );
              }

              // アクションログ
              Color? resultColor;
              String resultStr = "";

              // ★修正: 成功=赤, 失敗=青
              if (log.result == ActionResult.success) {
                resultColor = Colors.red[50];  // 背景: 薄い赤
                resultStr = "(成功)";
              } else if (log.result == ActionResult.failure) {
                resultColor = Colors.blue[50]; // 背景: 薄い青
                resultStr = "(失敗)";
              }

              return Card(
                color: resultColor ?? Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Text(
                      log.gameTime,
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace')
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87, fontFamily: 'NotoSansJP'),
                      children: [
                        TextSpan(text: "#${log.playerNumber} ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        TextSpan(text: log.action),
                        // ★修正: 文字色も変更
                        TextSpan(
                            text: " $resultStr",
                            style: TextStyle(
                                color: log.result == ActionResult.success ? Colors.red : Colors.blue
                            )
                        ),
                        if (log.subAction != null)
                          TextSpan(text: " (${log.subAction})", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  onTap: () => onLogTap(log, index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}