// lib/features/settings/presentation/pages/match_environment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../game_record/domain/models.dart';
import '../../../game_record/data/persistence.dart';

class MatchEnvironmentScreen extends HookWidget {
  const MatchEnvironmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentSettings = useState(AppSettings(squadNumbers: [], actions: []));
    final isLoading = useState(true);
    final timeController = useTextEditingController();

    useEffect(() {
      void load() async {
        final settings = await DataManager.loadSettings();
        currentSettings.value = settings;
        timeController.text = settings.matchDurationMinutes.toString();
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
      await DataManager.saveSettings(currentSettings.value);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('設定を保存しました')));
        Navigator.pop(context, true);
      }
    }

    if (isLoading.value) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('試合環境設定'),
        actions: [TextButton(onPressed: saveSettings, child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text("試合ルール", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: timeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "試合時間の長さ (分)", suffixText: "分", border: OutlineInputBorder()),
          ),
          // 列数設定は削除
        ],
      ),
    );
  }
}