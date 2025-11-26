import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// Game Record Domain & Data
import '../../../game_record/domain/models.dart';
import '../../../game_record/data/persistence.dart';


// ★変更: StatefulWidget -> HookWidget
class MatchEnvironmentScreen extends HookWidget {
  const MatchEnvironmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // State管理をHooksに置き換え
    final currentSettings = useState(AppSettings(squadNumbers: [], actions: []));
    final isLoading = useState(true);
    final gridColumns = useState(3);

    // コントローラーの自動管理
    final timeController = useTextEditingController();

    // 初期ロード (useEffectで1回だけ実行)
    useEffect(() {
      void load() async {
        final settings = await DataManager.loadSettings();
        currentSettings.value = settings;
        timeController.text = settings.matchDurationMinutes.toString();
        gridColumns.value = settings.gridColumns;
        isLoading.value = false;
      }
      load();
      return null;
    }, []);

    Future<void> saveSettings() async {
      final int? time = int.tryParse(timeController.text);
      if (time != null && time > 0) {
        currentSettings.value.matchDurationMinutes = time;
      }
      currentSettings.value.gridColumns = gridColumns.value;

      await DataManager.saveSettings(currentSettings.value);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設定を保存しました')),
        );
        Navigator.pop(context, true);
      }
    }

    if (isLoading.value) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('試合環境設定'),
        actions: [
          TextButton(
            onPressed: saveSettings,
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
            controller: timeController,
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
                  value: gridColumns.value.toDouble(),
                  min: 2,
                  max: 6,
                  divisions: 4,
                  label: "${gridColumns.value} 列",
                  onChanged: (val) {
                    gridColumns.value = val.toInt();
                  },
                ),
              ),
              Text("${gridColumns.value} 列", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                crossAxisCount: gridColumns.value,
                childAspectRatio: 2.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 6,
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