// lib/features/team_mgmt/domain/schema.dart
import 'package:uuid/uuid.dart';

enum FieldType {
  text,
  number,
  date,
  personName,
  personKana,
  address,
  phone,
  age,
  uniformNumber,
  courtName,
}

class FieldDefinition {
  String id;
  String label;
  FieldType type;
  bool isSystem;
  bool isVisible;
  bool isRequired; // ★追加: 必須項目フラグ

  bool useDropdown;
  bool isRange;
  List<String> options;
  int? minNum;
  int? maxNum;
  bool isUnique;

  FieldDefinition({
    String? id,
    required this.label,
    this.type = FieldType.text,
    this.isSystem = false,
    this.isVisible = true,
    this.isRequired = false, // ★デフォルトfalse
    this.useDropdown = false,
    this.isRange = false,
    this.options = const [],
    this.minNum,
    this.maxNum,
    this.isUnique = false,
  }) : id = id ?? const Uuid().v4();

  FieldDefinition clone() {
    return FieldDefinition(
      id: id, label: label, type: type, isSystem: isSystem,
      isVisible: isVisible, isRequired: isRequired, // ★追加
      useDropdown: useDropdown, isRange: isRange, options: List.from(options),
      minNum: minNum, maxNum: maxNum, isUnique: isUnique,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type.index,
    'isSystem': isSystem,
    'isVisible': isVisible,
    'isRequired': isRequired, // ★追加
    'useDropdown': useDropdown,
    'isRange': isRange,
    'options': options,
    'minNum': minNum,
    'maxNum': maxNum,
    'isUnique': isUnique,
  };

  factory FieldDefinition.fromJson(Map<String, dynamic> json) {
    return FieldDefinition(
      id: json['id'],
      label: json['label'],
      type: FieldType.values[json['type'] ?? 0],
      isSystem: json['isSystem'] ?? false,
      isVisible: json['isVisible'] ?? true,
      isRequired: json['isRequired'] ?? false, // ★追加
      useDropdown: json['useDropdown'] ?? false,
      isRange: json['isRange'] ?? false,
      options: List<String>.from(json['options'] ?? []),
      minNum: json['minNum'],
      maxNum: json['maxNum'],
      isUnique: json['isUnique'] ?? false,
    );
  }
}