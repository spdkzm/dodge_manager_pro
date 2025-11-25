import 'package:flutter/material.dart';

class GameTimerBar extends StatelessWidget {
  final bool isRunning;
  final bool hasMatchStarted;
  final VoidCallback onStart;
  final VoidCallback onStop; // タイム処理
  final VoidCallback onEnd;

  const GameTimerBar({
    super.key,
    required this.isRunning,
    required this.hasMatchStarted,
    required this.onStart,
    required this.onStop,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.blueGrey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildButton("開始", Colors.green, onStart, !hasMatchStarted),
          const SizedBox(width: 8),
          _buildButton("タイム", Colors.orange, onStop, isRunning),
          const SizedBox(width: 8),
          _buildButton("再開", Colors.blue, onStart, hasMatchStarted && !isRunning),
          const SizedBox(width: 8),
          _buildButton("終了", Colors.red, onEnd, hasMatchStarted),
        ],
      ),
    );
  }

  Widget _buildButton(String label, Color color, VoidCallback onPressed, bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(60, 36),
      ),
      child: Text(label),
    );
  }
}