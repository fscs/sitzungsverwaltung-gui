import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sitzungsverwaltung_gui/OAuth.dart';
import 'package:sitzungsverwaltung_gui/Sitzung.dart';
import 'package:sitzungsverwaltung_gui/Admin/SitzungView.dart';
import 'package:intl/intl.dart';
import 'package:sitzungsverwaltung_gui/lib.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid_value.dart';

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
      home: const AdminMainPage(title: 'Main'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key, required this.title});
  final String title;

  @override
  State<AdminMainPage> createState() => AdminMainPageState();
}

class AdminMainPageState extends State<AdminMainPage> {
  late List<Widget> _contents;
  late Future<List<Sitzung>> futureSitzung;
  final locationController = TextEditingController();
  var date = DateTime.now();
  var antragsfristdate = DateTime.now();
  String dropdownValue = "normal";

  @override
  void initState() {
    super.initState();

    tz.initializeTimeZones();

    futureSitzung = Sitzung.fetchSitzungen();
    futureSitzung.then((sitzungen) => {_contents = fetchSitzungen(sitzungen)});
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    date = DateTime.now();
    date = DateTime.now();
    dropdownValue = "normal";
    locationController.text = "";

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Lib.darkTheme.colorScheme.surfaceDim,
          foregroundColor: Lib.darkTheme.textTheme.bodyMedium!.color,
          title: Row(children: [
            const Text('Sitzungen FS Informatik'),
            Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      foregroundColor:
                          Lib.darkTheme.textTheme.bodyMedium!.color,
                      backgroundColor: const Color.fromRGBO(11, 80, 181, 1)),
                  child: const Text('+', style: TextStyle(fontSize: 20)),
                  onPressed: () => showAddSitzungDialog(),
                )),
          ]),
        ),
        body: Container(
            color: Lib.darkTheme.colorScheme.surface,
            alignment: Alignment.center,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: StreamBuilder<List<Sitzung>>(
                    stream: futureSitzung.asStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Text("Reloading");
                      }
                      if (snapshot.hasData) {
                        return ListView(
                            padding: const EdgeInsets.all(8),
                            children: _contents);
                      }
                      if (snapshot.hasError) {
                        return Text('${snapshot.error}');
                      }

                      // By default, show a loading spinner.
                      return const CircularProgressIndicator();
                    }))));
  }

  Future<void> addSitzung(String dropdownValue, DateTime date, String text,
      DateTime antragsfristdate) async {
    final token = await OAuth.getToken(context);

    await http.post(Uri.parse("https://fscs.hhu.de/api/sitzungen/"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "kind": dropdownValue,
          "location": text,
          "datetime": date.toUtc().toIso8601String(),
          "antragsfrist": antragsfristdate.toUtc().toIso8601String()
        }));

    setState(() {
      futureSitzung = Sitzung.fetchSitzungen();
      futureSitzung
          .then((sitzungen) => {_contents = fetchSitzungen(sitzungen)});
    });
  }

  showEditSitzungDialog(UuidValue id, DateTime datetime, String location,
      SitzungKind kind, DateTime antragsfristdate) {
    date = datetime;
    dropdownValue = kind.name;
    locationController.text = location;

    return showDialog<String>(
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
                  const Text('Kind', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: DropdownButton<String>(
                      dropdownColor: Lib.darkTheme.colorScheme.surface,
                      value: dropdownValue,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                      items: <String>[
                        'normal',
                        'vv',
                        'konsti',
                        'ersatz',
                        'dringlichkeit',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: const TextStyle(color: Colors.white)),
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
                    const Text("Datum", style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        onPressed: () async => await showDatePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(3000),
                                initialDate: (tz.TZDateTime.from(
                                    date, tz.getLocation("Europe/Berlin"))))
                            // ignore: unnecessary_set_literal
                            .then((selectedDate) => {
                                  if (selectedDate != null)
                                    {
                                      setState(() {
                                        date = selectedDate;
                                      })
                                    }
                                }),
                        child: Text(DateFormat('dd.MM.yyyy').format(
                            tz.TZDateTime.from(
                                date, tz.getLocation("Europe/Berlin"))))),
                    const SizedBox(width: 10),
                    const Text("Time", style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        onPressed: () async => await showTimePicker(
                                initialEntryMode: TimePickerEntryMode.input,
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                    tz.TZDateTime.from(
                                        date, tz.getLocation("Europe/Berlin"))))
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
                        child: Text(DateFormat('HH:mm').format(
                            tz.TZDateTime.from(
                                date, tz.getLocation("Europe/Berlin"))))),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Antragsfrist",
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        onPressed: () async => await showDatePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(3000),
                                initialDate: (tz.TZDateTime.from(
                                    antragsfristdate,
                                    tz.getLocation("Europe/Berlin"))))
                            // ignore: unnecessary_set_literal
                            .then((selectedDate) => {
                                  if (selectedDate != null)
                                    {
                                      setState(() {
                                        antragsfristdate = selectedDate;
                                      })
                                    }
                                }),
                        child: Text(DateFormat('dd.MM.yyyy').format(
                            tz.TZDateTime.from(antragsfristdate,
                                tz.getLocation("Europe/Berlin"))))),
                    const SizedBox(width: 10),
                    const Text("Time", style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        onPressed: () async => await showTimePicker(
                                initialEntryMode: TimePickerEntryMode.input,
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                    tz.TZDateTime.from(antragsfristdate,
                                        tz.getLocation("Europe/Berlin"))))
                            // ignore: unnecessary_set_literal
                            .then((selectedDate) => {
                                  if (selectedDate != null)
                                    {
                                      setState(() {
                                        antragsfristdate = DateTime(
                                            antragsfristdate.year,
                                            antragsfristdate.month,
                                            antragsfristdate.day,
                                            selectedDate.hour,
                                            selectedDate.minute);
                                      })
                                    }
                                }),
                        child: Text(DateFormat('HH:mm').format(
                            tz.TZDateTime.from(antragsfristdate,
                                tz.getLocation("Europe/Berlin"))))),
                  ],
                ),
                const SizedBox(height: 20),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text("Location", style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: locationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Location',
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
                      onPressed: () {
                        Navigator.pop(context);
                        editSitzung(id, dropdownValue, date,
                            locationController.text, antragsfristdate);
                      },
                      child: const Text('Save',
                          style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        deleteSitzung(id);
                      },
                      child: const Text('DELETE',
                          style: TextStyle(color: Colors.redAccent)),
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

  List<Widget> fetchSitzungen(List<Sitzung> sitzungen) {
    return List.generate(sitzungen.length, (index) {
      Color itemColor = index % 2 == 0
          ? Lib.darkTheme.colorScheme.primary.withOpacity(0.5)
          : Lib.darkTheme.colorScheme.secondary.withOpacity(0.5);

      return Column(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SitzungView(sitzungen[index].id, sitzungen[index])));
            },
            child: Container(
              height: 50,
              color: itemColor,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Lib.darkTheme.colorScheme.surfaceDim,
                              foregroundColor:
                                  Lib.darkTheme.textTheme.bodyMedium!.color),
                          onPressed: () => showEditSitzungDialog(
                              sitzungen[index].id,
                              sitzungen[index].datetime,
                              sitzungen[index].location,
                              sitzungen[index].kind,
                              sitzungen[index].antragsfrist),
                          child: const Text("EDIT"))),
                  SizedBox(
                      width: 100,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Text(
                          sitzungen[index].kind.name,
                          style: Lib.darkTheme.textTheme.bodyMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      )),
                  SizedBox(
                    width: 80,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        style: Lib.darkTheme.textTheme.bodyMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                        DateFormat("HH:mm").format((tz.TZDateTime.from(
                            sitzungen[index].datetime,
                            tz.getLocation("Europe/Berlin")))),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        style: Lib.darkTheme.textTheme.bodyMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                        DateFormat("dd.MM.yyyy").format((tz.TZDateTime.from(
                            sitzungen[index].datetime,
                            tz.getLocation("Europe/Berlin")))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        style: Lib.darkTheme.textTheme.bodyMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                        sitzungen[index].location,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Future<void> editSitzung(UuidValue id, String dropdownValue, DateTime date,
      String text, DateTime antragsfristdate) async {
    final token = await OAuth.getToken(context);

    await http.patch(Uri.parse("https://fscs.hhu.de/api/sitzungen/$id/"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "kind": dropdownValue,
          "location": text,
          "datetime": date.toUtc().toIso8601String(),
          "antragsfrist": antragsfristdate.toUtc().toIso8601String()
        }));

    setState(() {
      futureSitzung = Sitzung.fetchSitzungen();
      futureSitzung
          .then((sitzungen) => {_contents = fetchSitzungen(sitzungen)});
    });
  }

  showAddSitzungDialog() {
    date = DateTime.now();
    dropdownValue = "normal";
    locationController.text = "";
    antragsfristdate = DateTime.now();

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
                  const Text('Kind', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: DropdownButton<String>(
                      dropdownColor: Lib.darkTheme.colorScheme.surface,
                      value: dropdownValue,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                      items: <String>[
                        'normal',
                        'vv',
                        'konsti',
                        'ersatz',
                        'dringlichkeit',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: const TextStyle(color: Colors.white)),
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
                    const Text("Datum", style: TextStyle(color: Colors.white)),
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
                        child: Text(DateFormat('dd.MM.yyyy').format(date))),
                    const SizedBox(width: 10),
                    const Text("Time", style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        onPressed: () async => await showTimePicker(
                                initialEntryMode: TimePickerEntryMode.input,
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(date))
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
                        child: Text(DateFormat('HH:mm').format(date))),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Antragsfrist",
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        onPressed: () async => await showDatePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(3000),
                                initialDate: antragsfristdate)
                            // ignore: unnecessary_set_literal
                            .then((selectedDate) => {
                                  if (selectedDate != null)
                                    {
                                      setState(() {
                                        antragsfristdate = selectedDate;
                                      })
                                    }
                                }),
                        child: Text(
                            DateFormat('dd.MM.yyyy').format(antragsfristdate))),
                    const SizedBox(width: 10),
                    const Text("Time", style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        onPressed: () async => await showTimePicker(
                                initialEntryMode: TimePickerEntryMode.input,
                                context: context,
                                initialTime:
                                    TimeOfDay.fromDateTime(antragsfristdate))
                            // ignore: unnecessary_set_literal
                            .then((selectedDate) => {
                                  if (selectedDate != null)
                                    {
                                      setState(() {
                                        antragsfristdate = DateTime(
                                            antragsfristdate.year,
                                            antragsfristdate.month,
                                            antragsfristdate.day,
                                            selectedDate.hour,
                                            selectedDate.minute);
                                      })
                                    }
                                }),
                        child:
                            Text(DateFormat('HH:mm').format(antragsfristdate))),
                  ],
                ),
                const SizedBox(height: 20),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text("Location", style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: locationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Location',
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
                      onPressed: () {
                        Navigator.pop(context);
                        addSitzung(dropdownValue, date, locationController.text,
                            antragsfristdate);
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

  Future<void> deleteSitzung(UuidValue id) async {
    final token = await OAuth.getToken(context);
    await http.delete(Uri.parse("https://fscs.hhu.de/api/sitzungen/$id/"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        });

    setState(() {
      futureSitzung = Sitzung.fetchSitzungen();
      futureSitzung
          .then((sitzungen) => {_contents = fetchSitzungen(sitzungen)});
    });
  }
}
