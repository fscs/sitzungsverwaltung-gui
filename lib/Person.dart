import 'dart:convert';

import 'package:sitzungsverwaltung_gui/OAuth.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class Person {
  final String firstName;
  final String lastName;
  final UuidValue id;

  const Person({
    required this.firstName,
    required this.lastName,
    required this.id,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
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
      return "${person.firstName} ${person.lastName}";
    } else {
      throw Exception('Failed to load Person');
    }
  }
}
