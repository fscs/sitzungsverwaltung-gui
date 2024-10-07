import 'package:sitzungsverwaltung_gui/Sitzung.dart';
import 'package:sitzungsverwaltung_gui/Top.dart';
import 'package:uuid/uuid.dart';

class SitzungWithTops {
  final SitzungKind kind;
  final Uuid id;
  final DateTime datetime;
  final String location;
  final List<Top> tops;

  const SitzungWithTops({
    required this.kind,
    required this.id,
    required this.datetime,
    required this.location,
    required this.tops,
  });

  factory SitzungWithTops.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'kind': SitzungKind kind,
        'id': Uuid id,
        'datetime': DateTime datetime,
        'location': String location,
        'tops': List<Top> tops,
      } =>
        SitzungWithTops(
          kind: kind,
          id: id,
          datetime: datetime,
          location: location,
          tops: tops,
        ),
      _ => throw const FormatException('Failed to load SitzungWithTops.'),
    };
  }
}
