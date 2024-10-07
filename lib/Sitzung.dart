import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class Sitzung {
  final SitzungKind kind;
  final List<int> id;
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
      id: Uuid.parse(json['id']),
      datetime: DateTime.parse(json['datetime']),
      location: json['location'] as String,
    );
  }

  static Future<List<Sitzung>> fetchSitzungen() async {
    final response =
        await http.get(Uri.parse('https://fscs.hhu.de/api/sitzungen/'));

    if (response.statusCode == 200) {
      var list = json.decode(response.body) as List;

      List<Sitzung> sitzungen = list.map((i) => Sitzung.fromJson(i)).toList();

      return sitzungen;
    } else {
      throw Exception('Failed to load Sitzung');
    }
  }
}

enum SitzungKind { normal, vv, wahlvv, ersatz, konsti, dringlichkeit }
