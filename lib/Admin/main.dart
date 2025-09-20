import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sitzungsverwaltung_gui/sitzung.dart';
import 'package:sitzungsverwaltung_gui/Admin/SitzungView.dart';
import 'package:intl/intl.dart';
import 'package:sitzungsverwaltung_gui/lib.dart';
import 'package:sitzungsverwaltung_gui/api.dart' as api;
import 'package:timezone/timezone.dart' as tz;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final GlobalKey<SitzungListState> childKey = GlobalKey<SitzungListState>();
  late Future<List<LegislaturPeriode>> legislaturPeriodenFuture;

  @override
  void initState() {
    super.initState();

    legislaturPeriodenFuture = LegislaturPeriode.fetchLegislaturPerioden();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sitzungsverwaltung',
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!),
      home: Scaffold(
          appBar: AppBar(
            backgroundColor: Lib.darkTheme.colorScheme.surfaceDim,
            foregroundColor: Lib.darkTheme.textTheme.bodyMedium!.color,
            title: Row(children: [
              const Text('Sitzungen FS Informatik'),
              Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FutureBuilder(
                      future: legislaturPeriodenFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          var legislaturPerioden = snapshot.requireData;

                          return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  foregroundColor:
                                      Lib.darkTheme.textTheme.bodyMedium!.color,
                                  backgroundColor:
                                      const Color.fromRGBO(11, 80, 181, 1)),
                              child: const Text('+',
                                  style: TextStyle(fontSize: 20)),
                              onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (context) => SitzungDialog.creation(
                                        legislaturPerioden: legislaturPerioden,
                                        onSave: (newSitzung) async {
                                          var sitzung = await api.createSitzung(
                                              context,
                                              newSitzung.kind,
                                              newSitzung.datetime,
                                              newSitzung.location,
                                              newSitzung.antragsfrist,
                                              newSitzung.legislaturPeriode.id);

                                          childKey.currentState
                                              ?.addSitzung(sitzung);
                                        },
                                      )));
                        }

                        if (snapshot.hasError) {
                          return Text('${snapshot.error}');
                        }
                        // By default, show a loading spinner.
                        return const CircularProgressIndicator();
                      })),
            ]),
          ),
          body: Container(
              color: Lib.darkTheme.colorScheme.surface,
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: FutureBuilder(
                    future: Future.wait(
                        [Sitzung.fetchSitzungen(), legislaturPeriodenFuture]),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        var sitzungen =
                            snapshot.requireData[0] as List<Sitzung>;
                        var legislaturPerioden =
                            snapshot.requireData[1] as List<LegislaturPeriode>;

                        return SitzungList(
                            title: "Admin",
                            legislaturPerioden: legislaturPerioden,
                            initialSitzungen: sitzungen);
                      }

                      if (snapshot.hasError) {
                        return Text('${snapshot.error}');
                      }
                      // By default, show a loading spinner.
                      return const CircularProgressIndicator();
                    }),
              ))),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SitzungList extends StatefulWidget {
  final String title;
  final List<LegislaturPeriode> legislaturPerioden;
  final List<Sitzung> initialSitzungen;

  const SitzungList(
      {super.key,
      required this.title,
      required this.legislaturPerioden,
      required this.initialSitzungen});

  @override
  State<SitzungList> createState() => SitzungListState();
}

class SitzungListState extends State<SitzungList> {
  late List<Sitzung> sitzungen;

  void addSitzung(Sitzung sitzung) {
    setState(() {
      sitzungen.add(sitzung);
      sitzungen.sort((a, b) => b.datetime.compareTo(a.datetime));
    });
  }

  @override
  void initState() {
    super.initState();

    sitzungen = widget.initialSitzungen;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          Color itemColor = index % 2 == 0
              ? Lib.darkTheme.colorScheme.primary.withOpacity(0.5)
              : Lib.darkTheme.colorScheme.secondary.withOpacity(0.5);

          Sitzung sitzung = sitzungen[index];

          return Container(
              height: 50,
              color: itemColor,
              child: SitzungWidget(
                sitzung: sitzungen[index],
                legislaturPerioden: widget.legislaturPerioden,
                onDelete: () async {
                  await api.deleteSitzung(context, sitzung.id);

                  setState(() {
                    sitzungen.removeAt(index);
                  });
                },
                onSave: (newSitzung) async {
                  var updatedSitzung = await api.updateSitzung(
                      context,
                      sitzung.id,
                      newSitzung.kind,
                      newSitzung.datetime,
                      newSitzung.location,
                      newSitzung.antragsfrist,
                      newSitzung.legislaturPeriode.id);

                  setState(() {
                    sitzungen[index] = updatedSitzung;
                  });
                },
              ));
        },
        itemCount: sitzungen.length);
  }
}

class SitzungWidget extends StatelessWidget {
  final Sitzung sitzung;
  final List<LegislaturPeriode> legislaturPerioden;
  final AsyncCallback onDelete;
  final Future<void> Function(SitzungDialogResult) onSave;

  const SitzungWidget(
      {super.key,
      required this.sitzung,
      required this.legislaturPerioden,
      required this.onDelete,
      required this.onSave});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SitzungView(sitzung.id, sitzung)));
      },
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Lib.darkTheme.colorScheme.surfaceDim,
                      foregroundColor:
                          Lib.darkTheme.textTheme.bodyMedium!.color),
                  onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => SitzungDialog.update(
                          sitzung: sitzung,
                          legislaturPerioden: legislaturPerioden,
                          onSave: onSave,
                          onDelete: onDelete)),
                  child: const Text("EDIT"))),
          SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  sitzung.kind.name,
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
                    sitzung.datetime, tz.getLocation("Europe/Berlin")))),
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
                    sitzung.datetime, tz.getLocation("Europe/Berlin")))),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                style: Lib.darkTheme.textTheme.bodyMedium!
                    .copyWith(fontWeight: FontWeight.bold),
                sitzung.location,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class SitzungDialogResult {
  final DateTime datetime;
  final DateTime antragsfrist;
  final SitzungKind kind;
  final LegislaturPeriode legislaturPeriode;
  final String location;

  const SitzungDialogResult(
      {required this.datetime,
      required this.antragsfrist,
      required this.kind,
      required this.legislaturPeriode,
      required this.location});
}

class SitzungDialog extends StatefulWidget {
  final Widget? title;
  final Sitzung? sitzung;
  final List<LegislaturPeriode> legislaturPerioden;

  final Future<void> Function(SitzungDialogResult) onSave;
  final AsyncCallback? onDelete;

  const SitzungDialog.creation(
      {super.key,
      this.title,
      required this.legislaturPerioden,
      required this.onSave})
      : sitzung = null,
        onDelete = null;

  const SitzungDialog.update(
      {super.key,
      this.title,
      required this.sitzung,
      required this.legislaturPerioden,
      required this.onSave,
      required this.onDelete});

  @override
  State<StatefulWidget> createState() => SitzungDialogState();
}

class SitzungDialogState extends State<SitzungDialog> {
  final locationController = TextEditingController();

  late DateTime datetime;
  late DateTime antragsfrist;
  late SitzungKind kind;
  late LegislaturPeriode legislaturPeriode;

  @override
  void initState() {
    super.initState();

    var now = DateTime.now();

    datetime = widget.sitzung?.datetime ?? now;
    antragsfrist = widget.sitzung?.antragsfrist ?? now;
    kind = widget.sitzung?.kind ?? SitzungKind.normal;
    legislaturPeriode =
        widget.sitzung?.legislaturPeriode ?? widget.legislaturPerioden.first;
  }

  @override
  void dispose() {
    super.dispose();

    locationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) => SimpleDialog(
        title: widget.title,
        backgroundColor: Lib.darkTheme.colorScheme.surface,
        contentPadding: const EdgeInsets.all(16.0),
        children: <Widget>[
          const SizedBox(height: 10),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('Typ', style: TextStyle(color: Colors.white)),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: DropdownButton<SitzungKind>(
                dropdownColor: Lib.darkTheme.colorScheme.surface,
                value: kind,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                ),
                items: SitzungKind.values.map((SitzungKind value) {
                  return DropdownMenuItem<SitzungKind>(
                    value: value,
                    child: Text(value.name,
                        style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => kind = value!);
                },
              ),
            ),
            const Text('Legislatur', style: TextStyle(color: Colors.white)),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: DropdownButton<LegislaturPeriode>(
                value: legislaturPeriode,
                dropdownColor: Lib.darkTheme.colorScheme.surface,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                ),
                items: widget.legislaturPerioden
                    .map((var value) => DropdownMenuItem<LegislaturPeriode>(
                          value: value,
                          child: Text(value.name,
                              style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    legislaturPeriode = value!;
                  });
                },
              ),
            )
          ]),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Datum", style: TextStyle(color: Colors.white)),
              const SizedBox(width: 10),
              ElevatedButton(
                  onPressed: () async {
                    await showDatePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(3000),
                            initialDate: datetime)
                        .then((selectedDate) {
                      if (selectedDate != null) {
                        setState(() {
                          datetime = datetime.copyWith(
                              year: selectedDate.year,
                              month: selectedDate.month,
                              day: selectedDate.day);
                        });
                      }
                    });
                  },
                  child: Text(DateFormat('dd.MM.yyyy').format(
                      tz.TZDateTime.from(
                          datetime, tz.getLocation("Europe/Berlin"))))),
              const SizedBox(width: 10),
              const Text("Time", style: TextStyle(color: Colors.white)),
              const SizedBox(width: 10),
              ElevatedButton(
                  onPressed: () async => await showTimePicker(
                              initialEntryMode: TimePickerEntryMode.input,
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(datetime))
                          .then((selectedDate) {
                        if (selectedDate != null) {
                          setState(() {
                            datetime = datetime.copyWith(
                                hour: selectedDate.hour,
                                minute: selectedDate.minute);
                          });
                        }
                      }),
                  child: Text(DateFormat('HH:mm').format(tz.TZDateTime.from(
                      datetime, tz.getLocation("Europe/Berlin"))))),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Antragsfrist", style: TextStyle(color: Colors.white)),
              const SizedBox(width: 10),
              ElevatedButton(
                  onPressed: () async => await showDatePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(3000),
                          initialDate: antragsfrist)
                      // ignore: unnecessary_set_literal
                      .then((selectedDate) => {
                            if (selectedDate != null)
                              {
                                setState(() {
                                  antragsfrist = antragsfrist.copyWith(
                                      year: selectedDate.year,
                                      month: selectedDate.month,
                                      day: selectedDate.day);
                                })
                              }
                          }),
                  child: Text(DateFormat('dd.MM.yyyy').format(
                      tz.TZDateTime.from(
                          antragsfrist, tz.getLocation("Europe/Berlin"))))),
              const SizedBox(width: 10),
              const Text("Time", style: TextStyle(color: Colors.white)),
              const SizedBox(width: 10),
              ElevatedButton(
                  onPressed: () async => await showTimePicker(
                          initialEntryMode: TimePickerEntryMode.input,
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(antragsfrist))
                      // ignore: unnecessary_set_literal
                      .then((selectedDate) => {
                            if (selectedDate != null)
                              {
                                setState(() {
                                  antragsfrist = antragsfrist.copyWith(
                                    hour: selectedDate.hour,
                                    minute: selectedDate.minute,
                                  );
                                })
                              }
                          }),
                  child: Text(DateFormat('HH:mm').format(tz.TZDateTime.from(
                      antragsfrist, tz.getLocation("Europe/Berlin"))))),
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
                child:
                    const Text('Close', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () async {
                  await widget.onSave(SitzungDialogResult(
                      kind: kind,
                      datetime: datetime,
                      antragsfrist: antragsfrist,
                      legislaturPeriode: legislaturPeriode,
                      location: locationController.text));

                  if (!context.mounted) return;

                  Navigator.pop(
                    context,
                  );
                },
                child:
                    const Text('Save', style: TextStyle(color: Colors.white)),
              ),
              if (widget.sitzung != null)
                TextButton(
                  onPressed: () async {
                    if (widget.onDelete != null) {
                      await widget.onDelete!();
                    }

                    if (!context.mounted) return;

                    Navigator.pop(
                      context,
                    );
                  },
                  child: const Text('DELETE',
                      style: TextStyle(color: Colors.redAccent)),
                ),
            ],
          )
        ],
      ),
    );
  }
}
