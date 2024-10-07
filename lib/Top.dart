import 'package:sitzungsverwaltung_gui/Antrag.dart';
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
  final int weight;
  final List<Antrag> antraege;

  const TopWithAntraege({
    required this.kind,
    required this.id,
    required this.name,
    required this.weight,
    required this.antraege,
  });

  factory TopWithAntraege.fromJson(Map<String, dynamic> json) {
    return TopWithAntraege(
        kind: TopKind.values.byName(json['kind']),
        id: UuidValue.fromString(json['id']),
        name: json['name'] as String,
        weight: json['weight'] as int,
        antraege:
            (json['anträge'] as List).map((i) => Antrag.fromJson(i)).toList());
  }
}

enum TopKind { regularia, bericht, normal, verschiedenes }
