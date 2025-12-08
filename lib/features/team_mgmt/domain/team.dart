// lib/features/team_mgmt/domain/team.dart
import 'package:uuid/uuid.dart';
import 'schema.dart';
import 'roster_item.dart';
import 'roster_category.dart'; // ★追加

class Team {
  String id;
  String name;

  // 選手用 (Category 0)
  List<FieldDefinition> schema;
  List<RosterItem> items;

  // 対戦相手用 (Category 1)
  List<FieldDefinition> opponentSchema;
  List<RosterItem> opponentItems;

  // 会場用 (Category 2)
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

  // ★修正: int -> RosterCategory
  List<FieldDefinition> getSchema(RosterCategory category) {
    switch (category) {
      case RosterCategory.opponent: return opponentSchema;
      case RosterCategory.venue: return venueSchema;
      case RosterCategory.player: return schema;
    }
  }

  // ★修正: int -> RosterCategory
  List<RosterItem> getItems(RosterCategory category) {
    switch (category) {
      case RosterCategory.opponent: return opponentItems;
      case RosterCategory.venue: return venueItems;
      case RosterCategory.player: return items;
    }
  }

  // ★修正: int -> RosterCategory
  void setSchema(RosterCategory category, List<FieldDefinition> newSchema) {
    switch (category) {
      case RosterCategory.opponent:
        opponentSchema = newSchema;
        break;
      case RosterCategory.venue:
        venueSchema = newSchema;
        break;
      case RosterCategory.player:
        schema = newSchema;
        break;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'schema': schema.map((e) => e.toJson()).toList(),
    'items': items.map((e) => e.toJson()).toList(),
    'viewHiddenFields': viewHiddenFields,
  };

  factory Team.fromJson(Map<String, dynamic> json) {
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