import 'dart:convert';

import 'package:sitzungsverwaltung_gui/oauth.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class Person {
  final String fullName;
  final UuidValue id;

  const Person({
    required this.fullName,
    required this.id,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      fullName: json['full_name'] as String,
      id: UuidValue.fromString(json['id']),
    );
  }

  static Future<String> fetchPersonNameByUuid(String uuid) async {
    final token = await OAuth.refreshToken();
    var response = await http.get(
        Uri.parse("https://fscs.hhu.de/api/persons/$uuid"),
        headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      var person =
          Person.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      return person.fullName;
    } else {
      throw Exception('Failed to load Person');
    }
  }
}
