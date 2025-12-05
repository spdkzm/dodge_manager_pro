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
      // 1. 現在のDBファイルのパスを取得
      final dbPath = await _dbHelper.getDbPath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception("データベースファイルが見つかりません");
      }

      // 2. 出力ファイル名の生成
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'dodge_manager_backup_$dateStr.db';

      // 3. プラットフォーム別の保存処理
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // デスクトップ: 保存ダイアログ
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'バックアップファイルの保存場所を選択',
          fileName: fileName,
          type: FileType.any, // .db 拡張子用
        );

        if (outputFile != null) {
          await dbFile.copy(outputFile);
          return outputFile;
        }
      } else {
        // モバイル: 一時フォルダにコピーしてShare
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
      // 1. ファイル選択
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result == null || result.files.single.path == null) return false;

      final sourcePath = result.files.single.path!;

      // 簡易チェック: 拡張子やサイズ (必要なら)
      // if (!sourcePath.endsWith('.db')) throw Exception("無効なファイル形式です");

      // 2. データベース接続を閉じる (重要)
      await _dbHelper.close();

      // 3. ファイルの上書き
      final dbPath = await _dbHelper.getDbPath();
      final dbFile = File(dbPath);

      // 元のファイルを一応バックアップするか？ -> 今回は「上書き」仕様なのでそのまま
      await File(sourcePath).copy(dbPath);

      // 4. アプリ再起動を促すため、ここでは接続を再開しない
      // (再開してもメモリ上のキャッシュと不整合が起きる可能性があるため)

      return true;
    } catch (e) {
      throw Exception("復元エラー: $e");
    }
  }
}