import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

import 'package:drag_and_drop_lists/drag_and_drop_list_interface.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:sitzungsverwaltung_gui/Antrag.dart';
import 'package:sitzungsverwaltung_gui/OAuth.dart';
import 'package:sitzungsverwaltung_gui/Sitzung.dart';
import 'package:sitzungsverwaltung_gui/Top.dart';
import 'package:uuid/uuid_value.dart';

class Lib {
  static final titleController = TextEditingController();
  static final begruendungController = TextEditingController();
  static final antragstextController = TextEditingController();

  static final ThemeData darkTheme = ThemeData(
      colorScheme: const ColorScheme.dark(
          primary: Color.fromRGBO(119, 119, 119, 1),
          secondary: Color.fromRGBO(85, 85, 85, 1),
          surface: Color.fromRGBO(50, 50, 50, 1),
          surfaceDim: Color.fromRGBO(40, 40, 40, 1)),
      textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      buttonTheme:
          const ButtonThemeData(buttonColor: Color.fromRGBO(11, 80, 181, 1)));

  static showCreateAntrag(context) async {
    titleController.text = "";
    begruendungController.text = "";
    antragstextController.text = "";

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => Dialog(
          backgroundColor: darkTheme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  height: 10,
                ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text("Titel", style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Titel',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text("Begründung",
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: begruendungController,
                      maxLines: 6,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Begründung',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text("Antragstext",
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: antragstextController,
                      maxLines: 6,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Antragstext',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close',
                          style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (titleController.text.isEmpty ||
                            begruendungController.text.isEmpty ||
                            antragstextController.text.isEmpty) {
                          html.window.alert("Bitte alle Felder ausfüllen");
                          return;
                        }
                        Navigator.pop(context);
                        await addAntrag(titleController, begruendungController,
                            antragstextController, context);
                      },
                      child: const Text('Save',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> addAntrag(
      TextEditingController titleController,
      TextEditingController begruendungController,
      TextEditingController antragstextController,
      BuildContext context) async {
    final token = await OAuth.getToken(context);
    var username = await getUsernameFromAccessToken(context);
    final antragsteller = await getIDByUsername(username, context);
    await http.post(Uri.parse("https://fscs.hhu.de/api/anträge/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8"
        },
        body: jsonEncode({
          "titel": titleController.text,
          "begründung": begruendungController.text,
          "antragstext": antragstextController.text,
          "antragssteller": [antragsteller.toString()]
        }));
  }

  static Future<UuidValue> getIDByUsername(
      username, BuildContext context) async {
    final token = await OAuth.getToken(context);
    var response = await http.get(
        Uri.parse("https://fscs.hhu.de/api/persons/by-username/$username"),
        headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      return UuidValue.fromString(jsonDecode(response.body)["id"]);
    } else {
      throw Exception('Failed to load ID');
    }
  }

  static Future<String> getUsernameFromAccessToken(BuildContext context) async {
    final token = await OAuth.getToken(context);
    var jwt = parseJwt(token);
    return jwt["preferred_username"];
  }

  static Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('invalid payload');
    }

    return payloadMap;
  }

  static String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }

    return utf8.decode(base64Url.decode(output));
  }
}
