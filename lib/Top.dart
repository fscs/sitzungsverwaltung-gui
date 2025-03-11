import 'package:sitzungsverwaltung_gui/Antrag.dart';
import 'package:sitzungsverwaltung_gui/Person.dart';
import 'package:uuid/uuid.dart';

class Top {
  final UuidValue id;
  final TopKind kind;
  final String name;
  final int weight;

  const Top({
    required this.kind,
    required this.id,
    required this.name,
    required this.weight,
  });

  factory Top.fromJson(Map<String, dynamic> json) {
    return Top(
      kind: TopKind.values.byName(json['kind']),
      id: UuidValue.fromString(json['id']),
      name: json['name'] as String,
      weight: json['weight'] as int,
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
        kind: TopKind.values.byName(json['kind']),
        id: UuidValue.fromString(json['id']),
        name: json['name'] as String,
        inhalt: json['inhalt'] as String,
        weight: json['weight'] as int,
        antraege:
            (json['anträge'] as List).map((i) => Antrag.fromJson(i)).toList());
  }

  static Future<TopWithAntraege> fromJsonAsync(
      Map<String, dynamic> json) async {
    var antraegeList = await Future.wait(
      (json['anträge'] as List).map((i) => Antrag.fromJsonAsync(i)),
    );

    return TopWithAntraege(
        kind: TopKind.values.byName(json['kind']),
        id: UuidValue.fromString(json['id']),
        name: json['name'] as String,
        inhalt: json['inhalt'] as String,
        weight: json['weight'] as int,
        antraege: antraegeList);
  }
}

enum TopKind { regularia, bericht, normal, verschiedenes }
