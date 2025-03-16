import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sitzungsverwaltung_gui/Admin/AntragsList.dart';
import 'package:sitzungsverwaltung_gui/Admin/TopsList.dart';
import 'package:sitzungsverwaltung_gui/Antrag.dart';
import 'package:sitzungsverwaltung_gui/OAuth.dart';
import 'package:sitzungsverwaltung_gui/Sitzung.dart';
import 'package:sitzungsverwaltung_gui/Top.dart';
import 'package:sitzungsverwaltung_gui/lib.dart';
import 'package:uuid/uuid_value.dart';

final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

class SitzungView extends StatefulWidget {
  final Sitzung sitzung;
  final UuidValue id;
  const SitzungView(this.id, this.sitzung, {super.key});

  @override
  State<SitzungView> createState() => SitzungsViewState(id, sitzung);
}

class SitzungsViewState extends State<SitzungView> {
  final UuidValue sitzungsid;
  final Sitzung sitzung;
  SitzungsViewState(this.sitzungsid, this.sitzung);
  late Future<List<TopWithAntraege>> futureTops;
  late Future<List<Antrag>> futureAntraege;

  final nameController = TextEditingController();
  String dropdownValue = "normal";

  final titleController = TextEditingController();
  final inhaltController = TextEditingController();
  final begruendungController = TextEditingController();
  final antragstextController = TextEditingController();
  final antragsSearchController = TextEditingController();
  var dragedIndex = -1;
  late Timer? _debounceTimer;

  bool showAllAntraege = false;
  static final GlobalKey<AntragsListViewState> antragsListKey =
      GlobalKey<AntragsListViewState>();
  static final GlobalKey<TopListViewState> topListKey =
      GlobalKey<TopListViewState>();

  @override
  void initState() {
    super.initState();
    _debounceTimer = Timer(Duration(milliseconds: 0), () {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isScreenWide = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Lib.darkTheme.colorScheme.surfaceDim,
          foregroundColor: Lib.darkTheme.textTheme.bodyMedium!.color,
          title: Row(children: [
            isScreenWide ? const Text('Sitzung View') : const Text(""),
            const SizedBox(width: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  foregroundColor: Lib.darkTheme.textTheme.bodyMedium!.color,
                  backgroundColor: const Color.fromRGBO(11, 80, 181, 1)),
              onPressed: () => showCreateTop(),
              child: const Text('Top Erstellen'),
            ),
          ]),
        ),
        body: Container(
            color: Lib.darkTheme.colorScheme.surface,
            child: Flex(
                direction: isScreenWide ? Axis.horizontal : Axis.vertical,
                children: [
                  Expanded(
                    child: TopListView(sitzungsid, sitzung, key: topListKey),
                  ),
                  Expanded(
                    child: AntragsListView(sitzungsid, sitzung,
                        key: antragsListKey),
                  )
                ])));
  }

  Future<void> addTop(String dropdownValue, String name, String inhalt) async {
    final token = await OAuth.getToken(context);
    await http.post(
        Uri.parse("https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8"
        },
        body: jsonEncode({
          "kind": dropdownValue,
          "name": name,
          "inhalt": inhalt,
        }));
    SitzungsViewState.topListKey.currentState?.refreshTops();
  }

  showCreateTop() {
    nameController.text = "";
    inhaltController.text = "";
    dropdownValue = "normal";
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => Dialog(
          backgroundColor: Lib.darkTheme.colorScheme.surface,
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
                  const Text("Name", style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(
                  height: 10,
                ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text("Inhalt", style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: inhaltController,
                      maxLines: 6,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Inhalt',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Kind', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: DropdownButton<String>(
                      dropdownColor: Lib.darkTheme.colorScheme.surface,
                      value: dropdownValue,
                      items: <String>[
                        'normal',
                        'regularia',
                        'bericht',
                        'verschiedenes'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          dropdownValue = value!;
                        });
                      },
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
                      onPressed: () {
                        Navigator.pop(context);
                        addTop(dropdownValue, nameController.text,
                            inhaltController.text);
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
}
