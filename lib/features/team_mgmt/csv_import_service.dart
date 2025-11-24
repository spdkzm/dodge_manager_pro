import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dodge_manager_pro/features/team_mgmt/team.dart';
import 'package:dodge_manager_pro/features/team_mgmt/schema.dart';
import 'package:dodge_manager_pro/features/team_mgmt/roster_item.dart';
import 'package:dodge_manager_pro/features/team_mgmt/team_store.dart';
import 'package:uuid/uuid.dart';

// インポート結果の統計クラス
class ImportStats {
  int inserted = 0;
  int updated = 0;
  int unchanged = 0;
  int skipped = 0;
}

// カラムとスキーマのマッピング情報
class _ColMap {
  final FieldDefinition field;
  final String? subKey; // 複合項目の場合のキー (last, zip1 etc)
  _ColMap(this.field, [this.subKey]);
}

class CsvImportService {
  final TeamStore _store = TeamStore();

  Future<ImportStats?> pickAndImportCsv(Team team) async {
    try {
      // 1. ファイル選択
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) return null;

      final file = File(result.files.single.path!);
      final input = await file.readAsString();
      final List<List<dynamic>> rows = const CsvToListConverter().convert(input);

      if (rows.isEmpty) return ImportStats();

      // 2. ヘッダー解析とマッピング
      // ヘッダー行：[system_id, 氏名_姓, 氏名_名, 年齢, ...]
      final List<String> headers = rows.first.map((e) => e.toString().trim()).toList();

      int idColIndex = -1;
      final Map<int, _ColMap> columnMapping = {};

      for (int i = 0; i < headers.length; i++) {
        final h = headers[i];
        if (h == 'system_id') {
          idColIndex = i;
          continue;
        }

        // スキーマと照合
        for (var field in team.schema) {
          // 完全一致（単純項目）
          if (h == field.label) {
            columnMapping[i] = _ColMap(field);
            break;
          }
          // 接尾辞マッチ（複合項目）
          if (h.startsWith('${field.label}_')) {
            final suffix = h.substring('${field.label}_'.length);
            String? subKey;

            // ヘッダーのSuffixを内部キーに変換
            switch (field.type) {
              case FieldType.personName:
                if (suffix == '姓') subKey = 'last';
                if (suffix == '名') subKey = 'first';
                break;
              case FieldType.personKana:
                if (suffix == 'セイ') subKey = 'last';
                if (suffix == 'メイ') subKey = 'first';
                break;
              case FieldType.phone:
                if (suffix == '1') subKey = 'part1';
                if (suffix == '2') subKey = 'part2';
                if (suffix == '3') subKey = 'part3';
                break;
              case FieldType.address:
                if (suffix == '郵便1') subKey = 'zip1';
                if (suffix == '郵便2') subKey = 'zip2';
                if (suffix == '県') subKey = 'pref';
                if (suffix == '市町村') subKey = 'city';
                if (suffix == '建物') subKey = 'building';
                break;
              default: break;
            }

            if (subKey != null) {
              columnMapping[i] = _ColMap(field, subKey);
              break;
            }
          }
        }
      }

      // 3. データ処理
      final stats = ImportStats();
      final existingItemsMap = {for (var item in team.items) item.id: item};

      // 1行目はヘッダーなのでスキップ
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        // IDの取得（あれば）
        String? csvId;
        if (idColIndex != -1 && idColIndex < row.length) {
          final val = row[idColIndex].toString().trim();
          if (val.isNotEmpty) csvId = val;
        }

        // データの構築
        final Map<String, dynamic> newItemData = {};

        // まず複合項目のための空Mapを準備
        for (var mapping in columnMapping.values) {
          if (mapping.subKey != null) {
            if (!newItemData.containsKey(mapping.field.id)) {
              newItemData[mapping.field.id] = <String, dynamic>{};
            }
          }
        }

        // 値を埋め込む
        columnMapping.forEach((colIndex, mapping) {
          if (colIndex < row.length) {
            final rawVal = row[colIndex];
            final parsedVal = _parseValue(mapping.field, rawVal);

            if (mapping.subKey != null) {
              // 複合項目の場合、Mapの中にセット
              final map = newItemData[mapping.field.id] as Map<String, dynamic>;
              // nullなら空文字にしておく（Map内の値として扱いやすくするため）
              map[mapping.subKey!] = parsedVal ?? '';
            } else {
              // 単純項目の場合
              newItemData[mapping.field.id] = parsedVal;
            }
          }
        });

        // 登録判断
        if (csvId != null && existingItemsMap.containsKey(csvId)) {
          // --- 更新 (Update) ---
          final existingItem = existingItemsMap[csvId]!;

          if (_hasChanges(existingItem.data, newItemData, team.schema)) {
            // 変更あり -> 上書き
            existingItem.data = newItemData;
            // ※ここでsaveItemを呼ぶと大量件数で重くなるため、最後にまとめて保存するか、
            // TeamStoreに一括更新メソッドを作るのがベストだが、今回は個別に呼ぶ
            _store.saveItem(team.id, existingItem);
            stats.updated++;
          } else {
            // 変更なし
            stats.unchanged++;
          }
        } else {
          // --- 新規作成 (Insert) ---
          // IDがなければ新規発行、あれば（他チームからの移行等）それを使用
          final newItem = RosterItem(
              id: csvId ?? const Uuid().v4(),
              data: newItemData
          );
          _store.addItem(team.id, newItem);
          stats.inserted++;
        }
      }

      return stats;

    } catch (e) {
      throw Exception('インポートエラー: $e');
    }
  }

  /// 値のパース処理
  dynamic _parseValue(FieldDefinition field, dynamic value) {
    if (value == null) return null;
    String strVal = value.toString().trim();
    if (strVal.isEmpty) return null;

    switch (field.type) {
      case FieldType.number:
      case FieldType.age:
        return num.tryParse(strVal);

      case FieldType.date:
      // yyyy-MM-dd 前提
        try {
          return DateTime.parse(strVal.replaceAll('/', '-'));
        } catch (e) {
          return null;
        }

      default:
        return strVal;
    }
  }

  /// 変更検知ロジック
  bool _hasChanges(Map<String, dynamic> oldData, Map<String, dynamic> newData, List<FieldDefinition> schema) {
    for (var field in schema) {
      final oldVal = oldData[field.id];
      final newVal = newData[field.id];

      // 複合型(Map)の場合
      if (oldVal is Map && newVal is Map) {
        // 中身のキーを全比較
        // CSVから作られたMapは全てのキーを持っているとは限らないので、結合したキーで比較する
        // ここでは簡易的にtoString()比較、またはキーごとの比較を行う
        if (oldVal.toString() != newVal.toString()) return true;
      }
      // 単純型の場合
      else {
        // nullと空文字の扱いや、数値の型違い(int vs double)を吸収して比較
        String s1 = oldVal?.toString() ?? '';
        String s2 = newVal?.toString() ?? '';
        if (s1 != s2) return true;
      }
    }
    return false;
  }
}