// lib/features/team_mgmt/data/csv_export_service.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

// Domain
import '../domain/team.dart';
import '../domain/schema.dart';
import '../../analysis/domain/player_stats.dart';
import '../../settings/domain/action_definition.dart';

class CsvExportService {

  // --- チーム名簿のエクスポート ---
  Future<void> exportTeamToCsv(Team team) async {
    // 1. ヘッダー行
    final List<String> headers = ['system_id'];
    for (var field in team.schema) {
      headers.addAll(_generateHeaders(field));
    }

    // 2. データ行
    final List<List<dynamic>> rows = [];
    rows.add(headers);

    for (var item in team.items) {
      final List<dynamic> row = [];
      row.add(item.id);

      for (var field in team.schema) {
        final value = item.data[field.id];
        row.addAll(_expandValues(field, value));
      }
      rows.add(row);
    }

    await _saveCsvFile(rows, '${team.name}_名簿');
  }

  // --- 集計データのエクスポート (★追加) ---
  Future<void> exportAnalysisStats(
      String teamName,
      String periodLabel, // "2025年", "10月", "vs 〇〇" など
      List<PlayerStats> stats,
      List<ActionDefinition> definitions,
      ) async {

    // 1. ヘッダー作成
    final List<String> headers = ['背番号', 'コートネーム', '試合数'];

    // 現在のデータに含まれるアクション名を取得
    final dataActionNames = <String>{};
    for (var p in stats) dataActionNames.addAll(p.actions.keys);

    // 定義済み + データにのみあるアクション
    final displayDefinitions = List<ActionDefinition>.from(definitions);
    final definedNames = definitions.map((d) => d.name).toSet();
    for (var name in dataActionNames) {
      if (!definedNames.contains(name)) {
        displayDefinitions.add(ActionDefinition(name: name));
      }
    }

    // カラム構造の定義
    for (var action in displayDefinitions) {
      if (action.hasSuccess && action.hasFailure) {
        headers.add('${action.name}(成功)');
        headers.add('${action.name}(失敗)');
        headers.add('${action.name}(成功率)');
      } else if (action.hasSuccess) {
        headers.add('${action.name}(成功)');
      } else if (action.hasFailure) {
        headers.add('${action.name}(失敗)');
      } else {
        headers.add('${action.name}(数)');
      }
    }

    // 2. データ行作成
    final List<List<dynamic>> rows = [];
    rows.add(headers);

    // 背番号順ソート
    final sortedStats = List<PlayerStats>.from(stats);
    sortedStats.sort((a, b) => (int.tryParse(a.playerNumber) ?? 999).compareTo(int.tryParse(b.playerNumber) ?? 999));

    for (var p in sortedStats) {
      final List<dynamic> row = [];

      // 基本情報 (0落ち対策を適用)
      row.add(_formatValue(p.playerNumber));
      row.add(p.playerName);
      row.add(p.matchesPlayed);

      // アクション情報
      for (var action in displayDefinitions) {
        final stat = p.actions[action.name];

        if (action.hasSuccess && action.hasFailure) {
          row.add(stat?.successCount ?? 0);
          row.add(stat?.failureCount ?? 0);
          row.add(stat != null && stat.totalCount > 0 ? "${stat.successRate.toStringAsFixed(1)}%" : "-");
        } else if (action.hasSuccess) {
          row.add(stat?.successCount ?? 0);
        } else if (action.hasFailure) {
          row.add(stat?.failureCount ?? 0);
        } else {
          row.add(stat?.totalCount ?? 0);
        }
      }
      rows.add(row);
    }

    await _saveCsvFile(rows, '${teamName}_集計_$periodLabel');
  }

  // --- 共通: ファイル保存処理 ---
  Future<void> _saveCsvFile(List<List<dynamic>> rows, String baseName) async {
    final String csvData = const ListToCsvConverter().convert(rows);
    // BOMを追加してExcelでの文字化けを防ぐ
    final String bomCsv = '\uFEFF$csvData';

    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final safeName = baseName.replaceAll(RegExp(r'[^\w\s\u3040-\u30FF\u3400-\u4DBF\u4E00-\u9FFF]'), '_');
    final fileName = '${safeName}_$dateStr.csv';

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'CSVファイルの保存',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputFile != null) {
        if (!outputFile.toLowerCase().endsWith('.csv')) {
          outputFile = '$outputFile.csv';
        }
        final file = File(outputFile);
        await file.writeAsString(bomCsv);
      }
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName';
      final file = File(path);
      await file.writeAsString(bomCsv);
      await Share.shareXFiles([XFile(path)], text: baseName);
    }
  }

  // --- ヘルパー: 0落ち対策フォーマット ---
  dynamic _formatValue(dynamic value) {
    if (value == null) return '';
    final str = value.toString();

    // 数字のみで構成され、かつ "0" から始まる文字列 (例: "090...", "0043...")
    // ただし "0" 単体は除く
    if (str.length > 1 && str.startsWith('0') && int.tryParse(str) != null) {
      // Excelの数式として出力することで、強制的に文字列として扱わせる
      return '="$str"';
    }
    return str;
  }

  List<String> _generateHeaders(FieldDefinition field) {
    final lbl = field.label;
    switch (field.type) {
      case FieldType.personName: return ['${lbl}_姓', '${lbl}_名'];
      case FieldType.personKana: return ['${lbl}_セイ', '${lbl}_メイ'];
      case FieldType.phone:      return ['${lbl}_1', '${lbl}_2', '${lbl}_3'];
      case FieldType.address:    return ['${lbl}_郵便1', '${lbl}_郵便2', '${lbl}_県', '${lbl}_市町村', '${lbl}_建物'];
      default:                   return [lbl];
    }
  }

  List<dynamic> _expandValues(FieldDefinition field, dynamic val) {
    if (val == null) {
      // 空の場合もカラム数を合わせる
      switch (field.type) {
        case FieldType.personName:
        case FieldType.personKana: return ['', ''];
        case FieldType.phone:      return ['', '', ''];
        case FieldType.address:    return ['', '', '', '', ''];
        default:                   return [''];
      }
    }

    switch (field.type) {
      case FieldType.date:
        if (val is DateTime) return [DateFormat('yyyy-MM-dd').format(val)];
        return [val.toString()];

      case FieldType.personName:
      case FieldType.personKana:
        if (val is Map) return [val['last'] ?? '', val['first'] ?? ''];
        return ['', ''];

      case FieldType.phone:
        if (val is Map) {
          // 電話番号の各パーツに0落ち対策
          return [
            _formatValue(val['part1']),
            _formatValue(val['part2']),
            _formatValue(val['part3'])
          ];
        }
        return ['', '', ''];

      case FieldType.address:
        if (val is Map) {
          return [
            _formatValue(val['zip1']), // 郵便番号上3桁
            _formatValue(val['zip2']), // 郵便番号下4桁 (0043等に対応)
            val['pref'] ?? '',
            val['city'] ?? '',
            val['building'] ?? ''
          ];
        }
        return ['', '', '', '', ''];

      case FieldType.uniformNumber:
      // 背番号に0落ち対策
        return [_formatValue(val)];

      default:
        return [val.toString()];
    }
  }
}