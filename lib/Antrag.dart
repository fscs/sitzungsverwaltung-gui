import 'dart:convert';

import 'package:sitzungsverwaltung_gui/Person.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class Antrag {
  final String antragstext;
  final String begruendung;
  final UuidValue id;
  final String title;
  final List<dynamic> creators;

  static List<Person> persons = [];

  const Antrag({
    required this.id,
    required this.title,
    required this.antragstext,
    required this.begruendung,
    required this.creators,
  });

  static Future<Antrag> fromJsonAsync(Map<String, dynamic> json2) async {
    // Using Future.wait to fetch all creators asynchronously

    if (persons.isEmpty) {
      var response =
          await http.get(Uri.parse('https://fscs.hhu.de/api/persons/'));
      if (response.statusCode == 200) {
        var list = json.decode(utf8.decode(response.bodyBytes)) as List;
        for (var person in list) {
          persons.add(Person.fromJson(person));
        }
      }
    }

    List<String> creators = [];
    for (var creator in json2['creators']) {
      persons.forEach((element) {
        if (element.id.toString() == creator) {
          creators.add("${element.firstName} ${element.lastName}");
        }
      });
    }

    return Antrag(
      id: UuidValue.fromString(json2['id']),
      title: json2['titel'] as String,
      antragstext: json2['antragstext'] as String,
      begruendung: json2['begründung'] as String,
      creators:
          creators.toSet().toList(), // List of creators after async fetching
    );
  }

  factory Antrag.fromJson(Map<String, dynamic> json) {
    return Antrag(
        id: UuidValue.fromString(json['id']),
        title: json['titel'] as String,
        antragstext: json['antragstext'] as String,
        begruendung: json['begründung'] as String,
        creators: json['creators'] as List<dynamic>);
  }

  static Future<List<Antrag>> fetchAntraege(bool all) async {
    var response;
    if (all) {
      response = await http.get(Uri.parse('https://fscs.hhu.de/api/anträge/'));
    } else {
      response =
          await http.get(Uri.parse('https://fscs.hhu.de/api/anträge/orphans/'));
    }

    if (response.statusCode == 200) {
      var list = json.decode(utf8.decode(response.bodyBytes)) as List;

      List<Antrag> antraege = [];

      for (var antrag in list) {
        antraege.add(await fromJsonAsync(antrag));
      }

      return antraege;
    } else {
      throw Exception('Failed to load Sitzung');
    }
  }
}
