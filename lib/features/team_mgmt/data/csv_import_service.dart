// lib/features/team_mgmt/data/csv_import_service.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../domain/team.dart';
import '../domain/schema.dart';
import '../domain/roster_item.dart';
import '../domain/roster_category.dart'; // ★追加
import 'team_dao.dart';

class ImportStats {
  int inserted = 0;
  int updated = 0;
  int unchanged = 0;
  int skipped = 0;
}

class _ColMap {
  final FieldDefinition field;
  final String? subKey;
  _ColMap(this.field, [this.subKey]);
}

class CsvImportService {
  final TeamDao _teamDao = TeamDao();

  Future<ImportStats?> pickAndImportCsv(Team team) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) return null;

      final file = File(result.files.single.path!);
      final input = await file.readAsString();
      final List<List<dynamic>> rows = const CsvToListConverter().convert(input);

      if (rows.isEmpty) return ImportStats();

      final List<String> headers = rows.first.map((e) => e.toString().trim()).toList();

      int idColIndex = -1;
      final Map<int, _ColMap> columnMapping = {};

      for (int i = 0; i < headers.length; i++) {
        final h = headers[i];
        if (h == 'system_id') {
          idColIndex = i;
          continue;
        }

        for (var field in team.schema) {
          if (h == field.label) {
            columnMapping[i] = _ColMap(field);
            break;
          }
          if (h.startsWith('${field.label}_')) {
            final suffix = h.substring('${field.label}_'.length);
            String? subKey;
            switch (field.type) {
              case FieldType.personName: if (suffix == '姓') subKey = 'last'; if (suffix == '名') subKey = 'first'; break;
              case FieldType.personKana: if (suffix == 'セイ') subKey = 'last'; if (suffix == 'メイ') subKey = 'first'; break;
              case FieldType.phone: if (suffix == '1') subKey = 'part1'; if (suffix == '2') subKey = 'part2'; if (suffix == '3') subKey = 'part3'; break;
              case FieldType.address: if (suffix == '郵便1') subKey = 'zip1'; if (suffix == '郵便2') subKey = 'zip2'; if (suffix == '県') subKey = 'pref'; if (suffix == '市町村') subKey = 'city'; if (suffix == '建物') subKey = 'building'; break;
              default: break;
            }
            if (subKey != null) {
              columnMapping[i] = _ColMap(field, subKey);
              break;
            }
          }
        }
      }

      final stats = ImportStats();
      final existingItemsMap = {for (var item in team.items) item.id: item};

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        String? csvId;
        if (idColIndex != -1 && idColIndex < row.length) {
          final val = row[idColIndex].toString().trim();
          if (val.isNotEmpty) csvId = val;
        }

        final Map<String, dynamic> newItemData = {};

        for (var mapping in columnMapping.values) {
          if (mapping.subKey != null) {
            if (!newItemData.containsKey(mapping.field.id)) {
              newItemData[mapping.field.id] = <String, dynamic>{};
            }
          }
        }

        columnMapping.forEach((colIndex, mapping) {
          if (colIndex < row.length) {
            final rawVal = row[colIndex];
            final parsedVal = _parseValue(mapping.field, rawVal);

            if (mapping.subKey != null) {
              final map = newItemData[mapping.field.id] as Map<String, dynamic>;
              map[mapping.subKey!] = parsedVal ?? '';
            } else {
              newItemData[mapping.field.id] = parsedVal;
            }
          }
        });

        if (csvId != null && existingItemsMap.containsKey(csvId)) {
          final existingItem = existingItemsMap[csvId]!;
          if (_hasChanges(existingItem.data, newItemData, team.schema)) {
            existingItem.data = newItemData;
            // ★修正: RosterCategory.player
            await _teamDao.insertItem(team.id, existingItem, RosterCategory.player);
            stats.updated++;
          } else {
            stats.unchanged++;
          }
        } else {
          final newItem = RosterItem(
              id: csvId ?? const Uuid().v4(),
              data: newItemData
          );
          // ★修正: RosterCategory.player
          await _teamDao.insertItem(team.id, newItem, RosterCategory.player);
          stats.inserted++;
        }
      }

      return stats;

    } catch (e) {
      throw Exception('インポートエラー: $e');
    }
  }

  dynamic _parseValue(FieldDefinition field, dynamic value) {
    if (value == null) return null;
    String strVal = value.toString().trim();
    if (strVal.isEmpty) return null;
    switch (field.type) {
      case FieldType.number:
      case FieldType.age:
        return num.tryParse(strVal);
      case FieldType.uniformNumber:
      case FieldType.courtName:
        return strVal;
      case FieldType.date:
        try {
          return DateTime.parse(strVal.replaceAll('/', '-'));
        } catch (e) {
          return null;
        }
      default:
        return strVal;
    }
  }

  bool _hasChanges(Map<String, dynamic> oldData, Map<String, dynamic> newData, List<FieldDefinition> schema) {
    for (var field in schema) {
      final oldVal = oldData[field.id];
      final newVal = newData[field.id];
      if (oldVal is Map && newVal is Map) {
        if (oldVal.toString() != newVal.toString()) return true;
      } else {
        String s1 = oldVal?.toString() ?? '';
        String s2 = newVal?.toString() ?? '';
        if (s1 != s2) return true;
      }
    }
    return false;
  }
}