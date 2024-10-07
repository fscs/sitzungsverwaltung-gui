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
}
