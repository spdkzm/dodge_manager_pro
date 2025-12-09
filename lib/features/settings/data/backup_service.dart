// lib/features/settings/data/backup_service.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // --- バックアップ作成 (エクスポート) ---
  Future<String?> createBackup() async {
    try {
      final dbPath = await _dbHelper.getDbPath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception("データベースファイルが見つかりません");
      }

      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'dodge_manager_backup_$dateStr.db';

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'バックアップファイルの保存場所を選択',
          fileName: fileName,
          type: FileType.any,
        );

        if (outputFile != null) {
          await dbFile.copy(outputFile);
          return outputFile;
        }
      } else {
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}/$fileName';
        await dbFile.copy(tempPath);

        await Share.shareXFiles([XFile(tempPath)], text: 'Dodge Manager Pro バックアップ ($dateStr)');
        return "共有完了";
      }
    } catch (e) {
      throw Exception("バックアップ作成エラー: $e");
    }
    return null;
  }

  // --- バックアップから復元 (インポート) ---
  Future<bool> restoreBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result == null || result.files.single.path == null) return false;

      final sourcePath = result.files.single.path!;

      await _dbHelper.close();

      final dbPath = await _dbHelper.getDbPath();

      // ★修正: 不要なFileオブジェクト作成を削除
      await File(sourcePath).copy(dbPath);

      return true;
    } catch (e) {
      throw Exception("復元エラー: $e");
    }
  }
}