import 'package:uuid/uuid.dart';
import 'schema.dart';
import 'roster_item.dart';

class Team {
  String id;
  String name;
  List<FieldDefinition> schema;
  List<RosterItem> items;
  List<String> viewHiddenFields;

  Team({
    String? id,
    required this.name,
    List<FieldDefinition>? schema,
    List<RosterItem>? items,
    List<String>? viewHiddenFields,
  })  : id = id ?? const Uuid().v4(),
        schema = schema ?? [],
        items = items ?? [],
        viewHiddenFields = viewHiddenFields ?? [];

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