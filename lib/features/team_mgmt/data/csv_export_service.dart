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
import '../domain/roster_category.dart'; // ★追加
import '../../analysis/domain/player_stats.dart';
import '../../settings/domain/action_definition.dart';

class CsvExportService {

  // --- チーム名簿のエクスポート ---
  // ★修正: category引数を追加
  Future<void> exportTeamToCsv(Team team, {RosterCategory category = RosterCategory.player}) async {
    // カテゴリに応じたスキーマとアイテムを取得
    final schema = team.getSchema(category);
    final items = team.getItems(category);

    // ファイル名の接尾辞決定
    String suffix = "名簿";
    if (category == RosterCategory.opponent) suffix = "対戦相手";
    if (category == RosterCategory.venue) suffix = "会場";

    // 1. ヘッダー行
    final List<String> headers = ['system_id'];
    for (var field in schema) {
      headers.addAll(_generateHeaders(field));
    }

    // 2. データ行
    final List<List<dynamic>> rows = [];
    rows.add(headers);

    for (var item in items) {
      final List<dynamic> row = [];
      row.add(item.id);

      for (var field in schema) {
        final value = item.data[field.id];
        row.addAll(_expandValues(field, value));
      }
      rows.add(row);
    }

    await _saveCsvFile(rows, '${team.name}_$suffix');
  }

  // --- 集計データのエクスポート ---
  Future<void> exportAnalysisStats(
      String teamName,
      String periodLabel,
      List<PlayerStats> stats,
      List<ActionDefinition> definitions,
      ) async {

    // 1. ヘッダー作成
    final List<String> headers = ['背番号', 'コートネーム', '試合数'];

    final dataActionNames = <String>{};
    for (var p in stats) dataActionNames.addAll(p.actions.keys);

    final displayDefinitions = List<ActionDefinition>.from(definitions);
    final definedNames = definitions.map((d) => d.name).toSet();
    for (var name in dataActionNames) {
      if (!definedNames.contains(name)) {
        displayDefinitions.add(ActionDefinition(name: name));
      }
    }

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

    final sortedStats = List<PlayerStats>.from(stats);
    sortedStats.sort((a, b) => (int.tryParse(a.playerNumber) ?? 999).compareTo(int.tryParse(b.playerNumber) ?? 999));

    for (var p in sortedStats) {
      final List<dynamic> row = [];

      row.add(_formatValue(p.playerNumber));
      row.add(p.playerName);
      row.add(p.matchesPlayed);

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
    if (str.length > 1 && str.startsWith('0') && int.tryParse(str) != null) {
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
            _formatValue(val['zip1']),
            _formatValue(val['zip2']),
            val['pref'] ?? '',
            val['city'] ?? '',
            val['building'] ?? ''
          ];
        }
        return ['', '', '', '', ''];

      case FieldType.uniformNumber:
        return [_formatValue(val)];

      default:
        return [val.toString()];
    }
  }
}