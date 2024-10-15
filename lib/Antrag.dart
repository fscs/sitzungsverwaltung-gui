import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class Antrag {
  final String antragstext;
  final String begruendung;
  final UuidValue id;
  final String title;

  const Antrag({
    required this.id,
    required this.title,
    required this.antragstext,
    required this.begruendung,
  });

  factory Antrag.fromJson(Map<String, dynamic> json) {
    return Antrag(
      id: UuidValue.fromString(json['id']),
      title: json['titel'] as String,
      antragstext: json['antragstext'] as String,
      begruendung: json['begründung'] as String,
    );
  }

  static Future<List<Antrag>> fetchAntraege() async {
    final response =
        await http.get(Uri.parse('https://fscs.hhu.de/api/anträge/orphans/'));

    if (response.statusCode == 200) {
      var list = json.decode(utf8.decode(response.bodyBytes)) as List;

      List<Antrag> antraege = list.map((i) => Antrag.fromJson(i)).toList();

      return antraege;
    } else {
      throw Exception('Failed to load Sitzung');
    }
  }
}
