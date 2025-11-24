import 'package:uuid/uuid.dart';

class RosterItem {
  String id;
  Map<String, dynamic> data;

  RosterItem({
    String? id,
    Map<String, dynamic>? data,
  })  : id = id ?? const Uuid().v4(),
        data = data ?? {};

  Map<String, dynamic> toJson() {
    final serializedData = data.map((key, value) {
      if (value is DateTime) {
        return MapEntry(key, {'__type': 'Date', 'val': value.toIso8601String()});
      }
      return MapEntry(key, value);
    });

    return {
      'id': id,
      'data': serializedData,
    };
  }

  factory RosterItem.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as Map<String, dynamic>? ?? {};
    final parsedData = rawData.map((key, value) {
      if (value is Map && value['__type'] == 'Date') {
        return MapEntry(key, DateTime.parse(value['val']));
      }
      return MapEntry(key, value);
    });

    return RosterItem(
      id: json['id'],
      data: parsedData,
    );
  }
}