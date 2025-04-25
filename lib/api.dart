import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sitzungsverwaltung_gui/oauth.dart';
import 'package:sitzungsverwaltung_gui/sitzung.dart';
import 'package:uuid/uuid.dart';

Future<Sitzung> createSitzung(
    BuildContext context,
    SitzungKind kind,
    DateTime date,
    String location,
    DateTime antragsfrist,
    UuidValue legislaturId) async {
  final token = await OAuth.getToken(context);

  var response =
      await http.post(Uri.parse("${const String.fromEnvironment("API_BASE_URL")}api/sitzungen/"),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            "kind": kind.name,
            "location": location,
            "datetime": date.toUtc().toIso8601String(),
            "antragsfrist": antragsfrist.toUtc().toIso8601String(),
            "legislative_period": legislaturId.toString()
          }));

  if (response.statusCode >= 201) {
    return json.decode(utf8.decode(response.bodyBytes)) as Sitzung;
  } else {
    throw Exception('Failed to create Sitzung');
  }
}

Future<Sitzung> updateSitzung(
    BuildContext context,
    UuidValue id,
    SitzungKind kind,
    DateTime date,
    String location,
    DateTime antragsfrist,
    UuidValue legislaturId) async {
  final token = await OAuth.getToken(context);

  var response = await http.patch(Uri.parse("${const String.fromEnvironment("API_BASE_URL")}api/sitzungen/$id/"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "kind": kind.name,
        "location": location,
        "datetime": date.toUtc().toIso8601String(),
        "antragsfrist": antragsfrist.toUtc().toIso8601String(),
        "legislative_period": legislaturId.toString()
      }));

  if (response.statusCode == 200) {
    return json.decode(utf8.decode(response.bodyBytes)) as Sitzung;
  } else {
    throw Exception('Failed to update Sitzung');
  }
}

Future<void> deleteSitzung(BuildContext context, UuidValue id) async {
  final token = await OAuth.getToken(context);
  await http.delete(Uri.parse("${const String.fromEnvironment("API_BASE_URL")}api/sitzungen/$id/"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      });
}
