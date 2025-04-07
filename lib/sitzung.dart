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

  static Future<Sitzung> buildFromJson(Map<String, dynamic> json) async {
    return Sitzung(
        kind: SitzungKind.values.byName(json['kind']),
        id: UuidValue.fromString(json['id']),
        datetime: DateTime.parse(json['datetime']),
        location: json['location'] as String,
        antragsfrist: DateTime.parse(json['antragsfrist']),
        legislaturPeriode: await LegislaturPeriode.fetch(
            UuidValue.fromString(json['legislative_period_id'])));
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

      List<Sitzung> sitzungen =
          await Future.wait(list.map((i) => Sitzung.buildFromJson(i)));

      return sitzungen;
    } else {
      throw Exception('Failed to load Sitzung');
    }
  }

  static Future<List<TopWithAntraege>> fetchTopWithAntraege(uuid) async {
    final response =
        await http.get(Uri.parse('https://fscs.hhu.de/api/sitzungen/$uuid/'));

    if (response.statusCode == 200) {
      var list = json.decode(response.body)['tops'] as List;

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

  static Future<LegislaturPeriode> fetch(UuidValue id) async {
    final response = await http
        .get(Uri.parse('https://fscs.hhu.de/api/legislative-periods/$id'));

    if (response.statusCode == 200) {
      return LegislaturPeriode.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load legislatur periode');
    }
  }

  static Future<List<LegislaturPeriode>> fetchLegislaturPerioden() async {
    final response = await http
        .get(Uri.parse('https://fscs.hhu.de/api/legislative-periods/'));

    if (response.statusCode == 200) {
      var list = json.decode(response.body) as List;

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
