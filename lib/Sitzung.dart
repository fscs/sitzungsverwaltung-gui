import 'dart:convert';

import 'package:sitzungsverwaltung_gui/Top.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class Sitzung {
  final SitzungKind kind;
  final UuidValue id;
  final DateTime datetime;
  final String location;

  const Sitzung({
    required this.kind,
    required this.id,
    required this.datetime,
    required this.location,
  });

  factory Sitzung.fromJson(Map<String, dynamic> json) {
    return Sitzung(
      kind: SitzungKind.values.byName(json['kind']),
      id: UuidValue.fromString(json['id']),
      datetime: DateTime.parse(json['datetime']),
      location: json['location'] as String,
    );
  }

  static Future<List<Sitzung>> fetchSitzungen() async {
    final response =
        await http.get(Uri.parse('https://fscs.hhu.de/api/sitzungen/'));

    if (response.statusCode == 200) {
      var list = json.decode(response.body) as List;

      list.sort((a, b) {
        return DateTime.parse(b['datetime'])
            .compareTo(DateTime.parse(a['datetime']));
      });

      List<Sitzung> sitzungen = list.map((i) => Sitzung.fromJson(i)).toList();

      return sitzungen;
    } else {
      throw Exception('Failed to load Sitzung');
    }
  }

  static Future<List<TopWithAntraege>> fetchTopWithAntraege(uuid) async {
    final response =
        await http.get(Uri.parse('https://fscs.hhu.de/api/sitzungen/$uuid/'));

    if (response.statusCode == 200) {
      var list = json.decode(utf8.decode(response.bodyBytes))['tops'] as List;

      List<TopWithAntraege> tops =
          list.map((i) => TopWithAntraege.fromJson(i)).toList();

      return tops;
    } else {
      throw Exception('Failed to load Top');
    }
  }
}

enum SitzungKind { normal, vv, wahlvv, ersatz, konsti, dringlichkeit }
