import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sitzungsverwaltung_gui/top.dart';
import 'package:uuid/uuid.dart';

class Sitzung {
  final SitzungKind kind;
  final UuidValue id;
  final DateTime datetime;
  final String location;
  final DateTime antragsfrist;
  final LegislaturPeriode legislaturPeriode;

  const Sitzung({
    required this.kind,
    required this.id,
    required this.datetime,
    required this.location,
    required this.antragsfrist,
    required this.legislaturPeriode,
  });

  factory Sitzung.fromJson(Map<String, dynamic> json) {
    return Sitzung(
        kind: SitzungKind.values.byName(json['kind']),
        id: UuidValue.fromString(json['id']),
        datetime: DateTime.parse(json['datetime']),
        location: json['location'] as String,
        antragsfrist: DateTime.parse(json['antragsfrist']),
        legislaturPeriode:
            LegislaturPeriode.fromJson(json['legislative_period']));
  }

  static Future<List<Sitzung>> fetchSitzungen() async {
    final response =
        await http.get(Uri.parse('${const String.fromEnvironment("API_BASE_URL")}api/sitzungen/'));

    if (response.statusCode == 200) {
      var list = json.decode(utf8.decode(response.bodyBytes)) as List;

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
        await http.get(Uri.parse('${const String.fromEnvironment("API_BASE_URL")}api/sitzungen/$uuid/'));

    if (response.statusCode == 200) {
      var list = json.decode(utf8.decode(response.bodyBytes))['tops'] as List;

      List<TopWithAntraege> tops = [];
      for (var i in list) {
        tops.add(await TopWithAntraege.fromJsonAsync(i));
      }

      return tops;
    } else {
      throw Exception('Failed to load Top');
    }
  }
}

enum SitzungKind { normal, vv, wahlvv, ersatz, konsti, dringlichkeit }

@immutable
class LegislaturPeriode {
  final UuidValue id;
  final String name;

  const LegislaturPeriode({required this.id, required this.name});

  factory LegislaturPeriode.fromJson(Map<String, dynamic> json) {
    return LegislaturPeriode(
        id: UuidValue.fromString(json['id']), name: json['name'] as String);
  }

  static Future<List<LegislaturPeriode>> fetchLegislaturPerioden() async {
    final response = await http
        .get(Uri.parse('${const String.fromEnvironment("API_BASE_URL")}api/legislative-periods/'));

    if (response.statusCode == 200) {
      var list = json.decode(utf8.decode(response.bodyBytes)) as List;

      List<LegislaturPeriode> periods =
          list.map((i) => LegislaturPeriode.fromJson(i)).toList();

      return periods;
    } else {
      throw Exception('Failed to load Legislatur Perioden');
    }
  }

  @override
  String toString() {
    return "$name: $id";
  }

  @override
  bool operator ==(Object other) {
    return other is LegislaturPeriode && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
