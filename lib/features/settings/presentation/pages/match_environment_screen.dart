// lib/features/settings/presentation/pages/match_environment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ★修正: パスを正しい階層に修正
import '../../../game_record/application/game_recorder_controller.dart';
import '../../../game_record/data/persistence.dart';

class MatchEnvironmentScreen extends ConsumerStatefulWidget {
  const MatchEnvironmentScreen({super.key});

  @override
  ConsumerState<MatchEnvironmentScreen> createState() => _MatchEnvironmentScreenState();
}

class _MatchEnvironmentScreenState extends ConsumerState<MatchEnvironmentScreen> {
  int _matchDuration = 5;
  bool _isResultRecordingEnabled = false;
  bool _isScoreRecordingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DataManager.loadSettings();
    if (mounted) {
      setState(() {
        _matchDuration = settings.matchDurationMinutes;
        _isResultRecordingEnabled = settings.isResultRecordingEnabled;
        _isScoreRecordingEnabled = settings.isScoreRecordingEnabled;
      });
    }
  }

  Future<void> _saveSettings() async {
    final controller = ref.read(gameRecorderProvider);
    controller.settings = controller.settings.copyWith(
      matchDurationMinutes: _matchDuration,
      isResultRecordingEnabled: _isResultRecordingEnabled,
      isScoreRecordingEnabled: _isScoreRecordingEnabled,
    );
    await DataManager.saveSettings(controller.settings);

    // 反映のためにリロード
    await controller.loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('設定を保存しました')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('試合環境設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('試合時間 (分)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Slider(
            value: _matchDuration.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: '$_matchDuration 分',
            onChanged: (val) {
              setState(() {
                _matchDuration = val.toInt();
              });
            },
          ),
          Center(child: Text('$_matchDuration 分', style: const TextStyle(fontSize: 16))),

          const Divider(height: 32),

          const Text('記録オプション', style: TextStyle(fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('勝敗・スコアを記録する'),
            subtitle: const Text('試合終了時に勝敗を記録できるようになります'),
            value: _isResultRecordingEnabled,
            onChanged: (val) {
              setState(() {
                _isResultRecordingEnabled = val;
                // 親がOFFなら子もOFFにする
                if (!val) _isScoreRecordingEnabled = false;
              });
            },
          ),
          if (_isResultRecordingEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: SwitchListTile(
                title: const Text('点数(スコア)を入力する'),
                subtitle: const Text('具体的な得点も記録します'),
                value: _isScoreRecordingEnabled,
                onChanged: (val) {
                  setState(() {
                    _isScoreRecordingEnabled = val;
                  });
                },
              ),
            ),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}