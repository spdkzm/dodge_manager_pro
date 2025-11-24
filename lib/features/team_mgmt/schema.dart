import 'package:uuid/uuid.dart';

enum FieldType {
  text,       // テキスト
  number,     // 数値
  date,       // 日付
  personName, // 氏名
  personKana, // フリガナ
  address,    // 住所
  phone,      // 電話番号
  age,        // 年齢
}

class FieldDefinition {
  String id;
  String label;       // 項目名
  FieldType type;     // データ型
  bool isSystem;      // システム標準項目か
  bool isVisible;     // 表示するか

  bool useDropdown;   // プルダウンを使用するか
  bool isRange;       // 数値の場合：範囲指定か
  List<String> options; // プルダウンの選択肢
  int? minNum;        // 数値範囲：下限
  int? maxNum;        // 数値範囲：上限
  bool isUnique;      // 重複を禁止するか

  FieldDefinition({
    String? id,
    required this.label,
    this.type = FieldType.text,
    this.isSystem = false,
    this.isVisible = true,
    this.useDropdown = false,
    this.isRange = false,
    this.options = const [],
    this.minNum,
    this.maxNum,
    this.isUnique = false,
  }) : id = id ?? const Uuid().v4();

  FieldDefinition clone() {
    return FieldDefinition(
      id: id, label: label, type: type, isSystem: isSystem, isVisible: isVisible,
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
      useDropdown: json['useDropdown'] ?? false,
      isRange: json['isRange'] ?? false,
      options: List<String>.from(json['options'] ?? []),
      minNum: json['minNum'],
      maxNum: json['maxNum'],
      isUnique: json['isUnique'] ?? false,
    );
  }
}