import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sitzungsverwaltung_gui/OAuth.dart';
import 'package:sitzungsverwaltung_gui/Sitzung.dart';
import 'package:sitzungsverwaltung_gui/SitzungView.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

void main() {
  runApp(const Sitzungsverwaltung());
}

class Sitzungsverwaltung extends StatelessWidget {
  const Sitzungsverwaltung({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sitzungsverwaltung',
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(title: 'Main'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});
  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late List<Widget> _contents;
  late Future<List<Sitzung>> futureSitzung;
  final locationController = TextEditingController();
  var date = DateTime.now();
  String dropdownValue = "normal";

  @override
  void initState() {
    super.initState();

    tz.initializeTimeZones();

    futureSitzung = Sitzung.fetchSitzungen();
    futureSitzung.then((sitzungen) => {
          _contents = List.generate(sitzungen.length, (index) {
            Color color;
            if (index % 2 == 0) {
              color = Colors.white;
            } else {
              color = Colors.grey;
            }

            return Column(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SitzungView(sitzungen[index].id)));
                  },
                  child: Container(
                    height: 50,
                    color: color,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Text(
                              '${DateFormat("dd.MM.yyyy HH:mm").format((tz.TZDateTime.from(sitzungen[index].datetime, tz.getLocation("Europe/Berlin"))))}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Text(
                              '${sitzungen[index].kind.name}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 8, bottom: 4),
                          child: Text(
                            '>',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          })
        });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var backgroundColor = const Color.fromARGB(255, 243, 242, 248);

    date = DateTime.now();
    date = DateTime.now();
    dropdownValue = "normal";
    locationController.text = "";

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(title: const Text('Sitzungen FS Informatik'), actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Sitzung',
            onPressed: () => showDialog<String>(
              context: context,
              builder: (BuildContext context) => StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) => Dialog(
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
                          const Text('Kind'),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 300,
                            child: DropdownButton<String>(
                              value: dropdownValue,
                              items: <String>[
                                'normal',
                                'vv',
                                'konsti',
                                'ersatz',
                                'dringlichkeit',
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
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
                            const Text("Datum"),
                            const SizedBox(width: 10),
                            ElevatedButton(
                                onPressed: () async => await showDatePicker(
                                        context: context,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(3000),
                                        initialDate: date)
                                    // ignore: unnecessary_set_literal
                                    .then((selectedDate) => {
                                          if (selectedDate != null)
                                            {
                                              setState(() {
                                                date = selectedDate;
                                              })
                                            }
                                        }),
                                child: Text(
                                    DateFormat('dd.MM.yyyy').format(date))),
                            SizedBox(width: 10),
                            const Text("Time"),
                            const SizedBox(width: 10),
                            ElevatedButton(
                                onPressed: () async => await showTimePicker(
                                        initialEntryMode:
                                            TimePickerEntryMode.input,
                                        context: context,
                                        initialTime:
                                            TimeOfDay.fromDateTime(date))
                                    // ignore: unnecessary_set_literal
                                    .then((selectedDate) => {
                                          if (selectedDate != null)
                                            {
                                              setState(() {
                                                date = DateTime(
                                                    date.year,
                                                    date.month,
                                                    date.day,
                                                    selectedDate.hour,
                                                    selectedDate.minute);
                                              })
                                            }
                                        }),
                                child: Text(
                                    DateFormat('dd.MM.yyyy').format(date))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Text("Location"),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 300,
                            child: TextField(
                              controller: locationController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Location',
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
                              child: const Text('Close'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                addSitzung(dropdownValue, date,
                                    locationController.text);
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
        body: StreamBuilder<List<Sitzung>>(
            stream: futureSitzung.asStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Text("Reloading");
              }
              if (snapshot.hasData) {
                return ListView(
                    padding: const EdgeInsets.all(8), children: _contents);
              }
              if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const CircularProgressIndicator();
            }));
  }

  Future<void> addSitzung(
      String dropdownValue, DateTime date, String text) async {
    final token = await OAuth.getToken(context);

    final request = html.HttpRequest();
    request.open('POST', "https://fscs.hhu.de/api/sitzungen/");
    request.withCredentials = true;
    request.setRequestHeader("Authorization", "Bearer $token");
    request.send(jsonEncode({
      "kind": dropdownValue,
      "location": text,
      "datetime": date.toUtc().toIso8601String()
    }));
    await request.onLoadEnd.first;
    setState(() {
      futureSitzung = Sitzung.fetchSitzungen();
      futureSitzung.then((sitzungen) => {
            _contents = List.generate(sitzungen.length, (index) {
              Color color;
              if (index % 2 == 0) {
                color = Colors.white;
              } else {
                color = Colors.grey;
              }

              return Column(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  SitzungView(sitzungen[index].id)));
                    },
                    child: Container(
                      height: 50,
                      color: color,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 8, bottom: 4),
                              child: Text(
                                '${DateFormat("dd.MM.yyyy HH:mm").format((tz.TZDateTime.from(sitzungen[index].datetime, tz.getLocation("Europe/Berlin"))))}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 8, bottom: 4),
                            child: Text(
                              '>',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            })
          });
    });
  }
}
