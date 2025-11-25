// lib/features/settings/presentation/match_environment_screen.dart
import 'package:flutter/material.dart';
import '../../game_record/models.dart';
import '../../game_record/persistence.dart';

class MatchEnvironmentScreen extends StatefulWidget {
  const MatchEnvironmentScreen({super.key});

  @override
  State<MatchEnvironmentScreen> createState() => _MatchEnvironmentScreenState();
}

class _MatchEnvironmentScreenState extends State<MatchEnvironmentScreen> {
  // 初期値 (ロード待ちの間)
  AppSettings _currentSettings = AppSettings(squadNumbers: [], actions: []);
  bool _isLoading = true;

  final TextEditingController _timeController = TextEditingController();
  int _gridColumns = 3;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DataManager.loadSettings();
    setState(() {
      _currentSettings = settings;
      _timeController.text = settings.matchDurationMinutes.toString();
      _gridColumns = settings.gridColumns;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final int? time = int.tryParse(_timeController.text);
    if (time != null && time > 0) {
      _currentSettings.matchDurationMinutes = time;
    }
    _currentSettings.gridColumns = _gridColumns;

    // DataManagerを使って保存
    await DataManager.saveSettings(_currentSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('設定を保存しました')),
      );
      Navigator.pop(context, true); // trueを返して変更があったことを伝える
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('試合環境設定'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text("試合ルール", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _timeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "試合時間の長さ (分)",
              suffixText: "分",
              border: OutlineInputBorder(),
            ),
          ),

          const Divider(height: 40),

          const Text("表示設定", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("アクションボタンの列数"),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _gridColumns.toDouble(),
                  min: 2,
                  max: 6,
                  divisions: 4,
                  label: "$_gridColumns 列",
                  onChanged: (val) {
                    setState(() {
                      _gridColumns = val.toInt();
                    });
                  },
                ),
              ),
              Text("$_gridColumns 列", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          // プレビュー表示
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridColumns,
                childAspectRatio: 2.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 6, // ダミー
              itemBuilder: (context, index) => ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("Btn ${index + 1}"),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text("※プレビュー画面です", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}