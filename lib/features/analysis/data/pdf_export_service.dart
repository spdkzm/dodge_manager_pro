// lib/features/analysis/data/pdf_export_service.dart
import 'dart:typed_data';

import '../../settings/domain/action_definition.dart';
import '../domain/player_stats.dart';
import 'pdf_image_helper.dart';
import 'pdf_log_helper.dart';
import 'pdf_stats_helper.dart';

class PdfExportService {
  final PdfStatsHelper _statsHelper = PdfStatsHelper();
  final PdfImageHelper _imageHelper = PdfImageHelper();
  final PdfLogHelper _logHelper = PdfLogHelper();

  /// 成績集計表をPDFとして出力する
  Future<void> printStatsList({
    required String teamName,
    required String periodLabel,
    required List<PlayerStats> stats,
    required List<ActionDefinition> actionDefinitions,
  }) async {
    await _statsHelper.printStatsList(
      teamName: teamName,
      periodLabel: periodLabel,
      stats: stats,
      actionDefinitions: actionDefinitions,
    );
  }

  /// 複数の画像データを1つのPDFファイルとして印刷（1画像1ページ）
  Future<void> printMultipleImages({
    required String baseFileName,
    required List<Uint8List> images,
  }) async {
    await _imageHelper.printMultipleImages(
      baseFileName: baseFileName,
      images: images,
    );
  }

  /// 選手詳細の画像を並べて印刷（単一選手用）
  Future<void> printPlayerDetailImages({
    required String playerName,
    required int matchCount,
    required List<Uint8List> images,
  }) async {
    await _imageHelper.printPlayerDetailImages(
      playerName: playerName,
      matchCount: matchCount,
      images: images,
    );
  }

  /// 複数選手分の詳細を一括印刷
  Future<void> printMultiplePlayersDetails({
    required List<Map<String, dynamic>> playersData,
  }) async {
    await _imageHelper.printMultiplePlayersDetails(
      playersData: playersData,
    );
  }

  /// 試合ログをネイティブPDFとして出力する（段組みレイアウト対応）
  Future<void> printMatchLogsNative({
    required String baseFileName,
    required List<Map<String, dynamic>> printRequests,
  }) async {
    await _logHelper.printMatchLogsNative(
      baseFileName: baseFileName,
      printRequests: printRequests,
    );
  }
}