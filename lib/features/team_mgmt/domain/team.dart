// lib/features/team_mgmt/domain/team.dart
import 'package:uuid/uuid.dart';
import 'schema.dart';
import 'roster_item.dart';

class Team {
  String id;
  String name;

  // 選手用 (Category 0)
  List<FieldDefinition> schema;
  List<RosterItem> items;

  // ★追加: 対戦相手用 (Category 1)
  List<FieldDefinition> opponentSchema;
  List<RosterItem> opponentItems;

  // ★追加: 会場用 (Category 2)
  List<FieldDefinition> venueSchema;
  List<RosterItem> venueItems;

  List<String> viewHiddenFields;

  Team({
    String? id,
    required this.name,
    List<FieldDefinition>? schema,
    List<RosterItem>? items,
    List<FieldDefinition>? opponentSchema,
    List<RosterItem>? opponentItems,
    List<FieldDefinition>? venueSchema,
    List<RosterItem>? venueItems,
    List<String>? viewHiddenFields,
  })  : id = id ?? const Uuid().v4(),
        schema = schema ?? [],
        items = items ?? [],
        opponentSchema = opponentSchema ?? [],
        opponentItems = opponentItems ?? [],
        venueSchema = venueSchema ?? [],
        venueItems = venueItems ?? [],
        viewHiddenFields = viewHiddenFields ?? [];

  // ヘルパー: カテゴリごとのリストを取得
  List<FieldDefinition> getSchema(int category) {
    if (category == 1) return opponentSchema;
    if (category == 2) return venueSchema;
    return schema;
  }

  List<RosterItem> getItems(int category) {
    if (category == 1) return opponentItems;
    if (category == 2) return venueItems;
    return items;
  }

  // ヘルパー: カテゴリごとのリストをセット（更新用）
  void setSchema(int category, List<FieldDefinition> newSchema) {
    if (category == 1) {
      opponentSchema = newSchema;
    } else if (category == 2) {
      venueSchema = newSchema;
    } else {
      schema = newSchema;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'schema': schema.map((e) => e.toJson()).toList(),
    'items': items.map((e) => e.toJson()).toList(),
    // ※簡略化のため、JSON変換時は主要データのみ、またはDBから再構築する前提で運用
    'viewHiddenFields': viewHiddenFields,
  };

  factory Team.fromJson(Map<String, dynamic> json) {
    // ※ DAOでDBから構築するため、この簡易コンストラクタは基本的な変換のみ行う
    return Team(
      id: json['id'],
      name: json['name'],
      schema: (json['schema'] as List<dynamic>?)
          ?.map((e) => FieldDefinition.fromJson(e))
          .toList() ?? [],
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => RosterItem.fromJson(e))
          .toList() ?? [],
      viewHiddenFields: (json['viewHiddenFields'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }
}