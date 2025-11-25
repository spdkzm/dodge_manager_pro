import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// 相対パスインポート
import 'team.dart';
import 'schema.dart';

class CsvExportService {

  Future<void> exportTeamToCsv(Team team) async {
    // 1. ヘッダー行の作成
    final List<String> headers = ['system_id']; // ID列を先頭に固定

    for (var field in team.schema) {
      headers.addAll(_generateHeaders(field));
    }

    // 2. データ行の作成
    final List<List<dynamic>> rows = [];
    rows.add(headers);

    for (var item in team.items) {
      final List<dynamic> row = [];
      // IDを追加
      row.add(item.id);

      // 各フィールドの値を展開して追加
      for (var field in team.schema) {
        final value = item.data[field.id];
        row.addAll(_expandValues(field, value));
      }
      rows.add(row);
    }

    // 3. CSV生成と保存
    final String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final safeTeamName = team.name.replaceAll(RegExp(r'[^\w\s\u3040-\u30FF\u3400-\u4DBF\u4E00-\u9FFF]'), '_');
    final path = '${directory.path}/${safeTeamName}_$dateStr.csv';

    final file = File(path);
    await file.writeAsString('\uFEFF$csvData'); // BOM付きUTF-8

    await Share.shareXFiles([XFile(path)], text: '${team.name}の名簿データ');
  }

  // フィールドタイプごとのヘッダー名生成
  List<String> _generateHeaders(FieldDefinition field) {
    final lbl = field.label;
    switch (field.type) {
      case FieldType.personName: return ['${lbl}_姓', '${lbl}_名'];
      case FieldType.personKana: return ['${lbl}_セイ', '${lbl}_メイ'];
      case FieldType.phone:      return ['${lbl}_1', '${lbl}_2', '${lbl}_3'];
      case FieldType.address:    return ['${lbl}_郵便1', '${lbl}_郵便2', '${lbl}_県', '${lbl}_市町村', '${lbl}_建物'];
      default:                   return [lbl]; // その他は1列
    }
  }

  // フィールドタイプごとの値展開
  List<dynamic> _expandValues(FieldDefinition field, dynamic val) {
    // nullの場合はカラム数分だけ空文字を入れる
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
        if (val is Map) return [val['part1'] ?? '', val['part2'] ?? '', val['part3'] ?? ''];
        return ['', '', ''];

      case FieldType.address:
        if (val is Map) {
          return [
            val['zip1'] ?? '',
            val['zip2'] ?? '',
            val['pref'] ?? '',
            val['city'] ?? '',
            val['building'] ?? ''
          ];
        }
        return ['', '', '', '', ''];

      default:
        return [val.toString()];
    }
  }
}