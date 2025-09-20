import 'package:sitzungsverwaltung_gui/antrag.dart';
import 'package:uuid/uuid.dart';

class Top {
  final UuidValue id;
  final TopKind kind;
  final String name;
  final int weight;
  final String inhalt;

  const Top(
      {required this.kind,
      required this.id,
      required this.name,
      required this.weight,
      required this.inhalt});

  factory Top.fromJson(Map<String, dynamic> json) {
    return Top(
      kind: TopKind.values.byName(json['typ']),
      id: UuidValue.fromString(json['id']),
      name: json['name'] as String,
      weight: json['weight'] as int,
      inhalt: json['inhalt'] as String,
    );
  }
}

class TopWithAntraege {
  final UuidValue id;
  final TopKind kind;
  final String name;
  final String inhalt;
  int weight;
  final List<Antrag> antraege;

  TopWithAntraege({
    required this.kind,
    required this.id,
    required this.name,
    required this.weight,
    required this.antraege,
    required this.inhalt,
  });

  factory TopWithAntraege.fromJson(Map<String, dynamic> json) {
    return TopWithAntraege(
        kind: TopKind.values.byName(json['typ']),
        id: UuidValue.fromString(json['id']),
        name: json['name'] as String,
        inhalt: json['inhalt'] as String,
        weight: json['weight'] as int,
        antraege:
            (json['antraege'] as List).map((i) => Antrag.fromJson(i)).toList());
  }

  static Future<TopWithAntraege> fromJsonAsync(
      Map<String, dynamic> json) async {
    var antraegeList = await Future.wait(
      (json['antraege'] as List).map((i) => Antrag.fromJsonAsync(i)),
    );

    return TopWithAntraege(
        kind: TopKind.values.byName(json['typ']),
        id: UuidValue.fromString(json['id']),
        name: json['name'] as String,
        inhalt: json['inhalt'] as String,
        weight: json['weight'] as int,
        antraege: antraegeList);
  }
}

enum TopKind { regularia, bericht, normal, verschiedenes }
