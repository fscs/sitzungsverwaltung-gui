import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

import 'package:drag_and_drop_lists/drag_and_drop_list_interface.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sitzungsverwaltung_gui/Admin/TopsList.dart';
import 'package:sitzungsverwaltung_gui/Antrag.dart';
import 'package:sitzungsverwaltung_gui/OAuth.dart';
import 'package:sitzungsverwaltung_gui/Sitzung.dart';
import 'package:sitzungsverwaltung_gui/Top.dart';
import 'package:sitzungsverwaltung_gui/lib.dart';
import 'package:uuid/uuid_value.dart';

final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

class AntragsListView extends StatefulWidget {
  final Sitzung sitzung;
  final UuidValue id;
  const AntragsListView(this.id, this.sitzung, {super.key});

  @override
  State<AntragsListView> createState() => AntragsListViewState(id, sitzung);
}

class AntragsListViewState extends State<AntragsListView> {
  final UuidValue sitzungsid;
  final Sitzung sitzung;
  AntragsListViewState(this.sitzungsid, this.sitzung);
  late List<DragAndDropList> _contents;
  static late Widget _contentsAntraege;
  late Future<List<TopWithAntraege>> futureTops;
  static late Future<List<Antrag>> futureAntraege;

  final nameController = TextEditingController();
  String dropdownValue = "normal";

  final titleController = TextEditingController();
  final begruendungController = TextEditingController();
  final antragstextController = TextEditingController();
  static final antragsSearchController = TextEditingController();
  static var dragedIndex = -1;
  late Timer? _debounceTimer;

  static bool showAllAntraege = false;

  @override
  void initState() {
    super.initState();

    futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
    futureTops.then((tops) => {_contents = fetchTops(tops)});

    futureAntraege = Antrag.fetchAntraege(showAllAntraege);
    futureAntraege
        .then((antraege) => {_contentsAntraege = fetchAntraege(antraege)});
    _debounceTimer = Timer(Duration(milliseconds: 0), () {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  refreshAntraege() {
    setState(() {
      futureAntraege = Antrag.fetchAntraege(showAllAntraege);
      futureAntraege
          .then((antraege) => {_contentsAntraege = fetchAntraege(antraege)});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
        child: Column(children: [
          Row(children: [
            SizedBox(
                width: 200,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: Text(
                        'Zugewisen',
                        style: TextStyle(
                            color: Lib.darkTheme.textTheme.bodyMedium!.color),
                      ),
                      leading: Radio<bool>(
                        value: true,
                        groupValue: showAllAntraege,
                        onChanged: (bool? value) {
                          setState(() {
                            showAllAntraege = value!;
                            futureAntraege =
                                Antrag.fetchAntraege(showAllAntraege);
                            futureAntraege.then((antraege) =>
                                {_contentsAntraege = fetchAntraege(antraege)});
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: Text(
                        'Nicht Zugewisen',
                        style: TextStyle(
                            color: Lib.darkTheme.textTheme.bodyMedium!.color),
                      ),
                      leading: Radio<bool>(
                        value: false,
                        groupValue: showAllAntraege,
                        onChanged: (bool? value) {
                          setState(() {
                            showAllAntraege = value!;
                            futureAntraege =
                                Antrag.fetchAntraege(showAllAntraege);
                            futureAntraege.then((antraege) =>
                                {_contentsAntraege = fetchAntraege(antraege)});
                          });
                        },
                      ),
                    ),
                  ],
                )),
            Expanded(
                child: TextField(
              controller: antragsSearchController,
              onChanged: (text) {
                // Cancel any existing timer
                _debounceTimer?.cancel();

                // Start a new timer to wait for the user to stop typing
                _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                  // This block will run after 500ms of inactivity
                  setState(() {
                    futureAntraege = Antrag.fetchAntraege(showAllAntraege);
                    futureAntraege.then((antraege) {
                      setState(() {
                        _contentsAntraege = fetchAntraege(antraege);
                      });
                    });
                  });
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Search',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            )),
          ]),
          Expanded(
            child: FutureBuilder<List<Antrag>>(
                future: futureAntraege,
                builder: (context, secondSnapshot) {
                  if (secondSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (secondSnapshot.hasError) {
                    return Center(
                        child: Text('Error: ${secondSnapshot.error}'));
                  } else {
                    return _contentsAntraege;
                  }
                }),
          ),
        ]));
  }

  Future<void> updateAntragApi(int oldItemIndex, int oldListIndex,
      int newItemIndex, int newListIndex) async {
    var tops = await Sitzung.fetchTopWithAntraege(sitzungsid);

    var antrag = tops[oldListIndex].antraege[oldItemIndex].id;
    var topOld = tops[oldListIndex].id;
    var topNew = tops[newListIndex].id;

    final token = await OAuth.getToken(context);

    await http.delete(
        Uri.parse(
            "https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/$topOld/assoc/"),
        headers: {"Authorization": "Bearer $token"},
        body: jsonEncode({"antrag_id": "$antrag"}));

    await http.patch(
        Uri.parse(
            "https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/$topNew/assoc/"),
        headers: {"Authorization": "Bearer $token"},
        body: jsonEncode({"antrag_id": "$antrag"}));
  }

  Future<void> updateTopApi(int oldListIndex, int newListIndex) async {
    var tops = await Sitzung.fetchTopWithAntraege(sitzungsid);

    tops[oldListIndex].weight = newListIndex + 1;
    tops[newListIndex].weight = oldListIndex + 1;

    for (var top in tops) {
      final token = await OAuth.getToken(context);

      await http.patch(
          Uri.parse(
              "https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/${top.id}/"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json; charset=UTF-8"
          },
          body: jsonEncode({"weight": top.weight}));
    }
    setState(() {
      futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
      futureTops.then((tops) => {_contents = fetchTops(tops)});
    });
  }

  Future<void> addTop(String dropdownValue, String text) async {
    final token = await OAuth.getToken(context);
    await http.post(
        Uri.parse("https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8"
        },
        body: jsonEncode({
          "kind": dropdownValue,
          "name": text,
          "inhalt": "",
        }));

    setState(() {
      futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
      futureTops.then((tops) => {_contents = fetchTops(tops)});
    });
  }

  showCreateTop() {
    nameController.text = "";
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
                        addTop(dropdownValue, nameController.text);
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

  showEditTop(UuidValue uuid, String name, TopKind kind) {
    nameController.text = name;
    dropdownValue = kind.name;
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
                const SizedBox(height: 20),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Kind', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: DropdownButton<String>(
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
                        editTop(uuid, dropdownValue, nameController.text);
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

  Future<void> addAntrag(
      TextEditingController titleController,
      TextEditingController begruendungController,
      TextEditingController antragstextController) async {
    final token = await OAuth.getToken(context);
    var username = await getUsernameFromAccessToken();
    final antragsteller = await getIDByUsername(username);
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
    setState(() {
      futureAntraege = Antrag.fetchAntraege(showAllAntraege);
      futureAntraege
          .then((antraege) => {_contentsAntraege = fetchAntraege(antraege)});
    });
  }

  Future<void> addAntragToTop(int listIndex) async {
    var tops = await Sitzung.fetchTopWithAntraege(sitzungsid);
    var antrag = await Antrag.fetchAntraege(showAllAntraege);
    var antragId = antrag[dragedIndex].id;
    var top = tops[listIndex].id;
    final token = await OAuth.getToken(context);
    await http.patch(
        Uri.parse(
            "https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/$top/assoc/"),
        headers: {"Authorization": "Bearer $token"},
        body: jsonEncode({"antrag_id": "$antragId"}));

    setState(() {
      futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
      futureTops.then((tops) => {_contents = fetchTops(tops)});

      futureAntraege = Antrag.fetchAntraege(showAllAntraege);
      futureAntraege
          .then((antraege) => {_contentsAntraege = fetchAntraege(antraege)});
    });
  }

  List<DragAndDropList> fetchTops(List<TopWithAntraege> tops) {
    return List.generate(tops.length, (index) {
      return DragAndDropList(
          decoration: BoxDecoration(
            color: Lib.darkTheme.colorScheme.surfaceDim,
          ),
          header: Column(
            children: <Widget>[
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 8, bottom: 2),
                    child: Text(
                      'Top ${index + 2}: ${tops[index].name}',
                      style: Lib.darkTheme.textTheme.bodyMedium!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8, right: 4),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Lib
                                  .darkTheme.colorScheme.secondary
                                  .withOpacity(0.5),
                              foregroundColor:
                                  Lib.darkTheme.textTheme.bodyMedium!.color),
                          onPressed: () => showEditTop(tops[index].id,
                              tops[index].name, tops[index].kind),
                          child: const Text("EDIT"))),
                ],
              ),
            ],
          ),
          children: List.generate(tops[index].antraege.length, (index2) {
            Color itemColor = index2 % 2 == 0
                ? Lib.darkTheme.colorScheme.primary.withOpacity(0.5)
                : Lib.darkTheme.colorScheme.secondary.withOpacity(0.5);
            return DragAndDropItem(
                child: Container(
              color: itemColor,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Lib.darkTheme.colorScheme.surfaceDim,
                            foregroundColor:
                                Lib.darkTheme.textTheme.bodyMedium!.color),
                        onPressed: () => showEditAntrag(
                            tops[index].antraege[index2].id,
                            tops[index].antraege[index2].title,
                            tops[index].antraege[index2].begruendung,
                            tops[index].antraege[index2].antragstext,
                            tops[index].id,
                            "tops"),
                        child: const Text("EDIT")),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        tops[index].antraege[index2].title,
                        style: Lib.darkTheme.textTheme.bodyMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Row(
                          children:
                              tops[index].antraege[index2].creators.map((text) {
                            return Text(text,
                                style: TextStyle(
                                    color: Lib.darkTheme.textTheme.bodyMedium!
                                        .color));
                          }).toList(),
                        )),
                  ),
                  SizedBox(
                      width: 100,
                      child: Padding(
                          padding: const EdgeInsets.only(right: 10, bottom: 4),
                          child: Builder(builder: (context) {
                            if (tops[index]
                                    .antraege[index2]
                                    .createdAt
                                    .compareTo(sitzung.antragsfrist) <
                                0) {
                              return Text(
                                  dateFormat.format(
                                      tops[index].antraege[index2].createdAt),
                                  style: TextStyle(
                                      color: Lib.darkTheme.textTheme.bodyMedium!
                                          .color));
                            } else {
                              return Text(
                                  dateFormat.format(
                                      tops[index].antraege[index2].createdAt),
                                  style: const TextStyle(
                                    color: Colors.red,
                                  ));
                            }
                          }))),
                ],
              ),
            ));
          }));
    });
  }

  fetchAntraege(List<Antrag> antraege) {
    if (antraege.isEmpty) {
      return Center(
          child: Text("Keine Anträge",
              style: Lib.darkTheme.textTheme.bodyMedium!));
    }
    bool isScreenWide = MediaQuery.sizeOf(context).width >= 600;
    return ListView.builder(
        itemCount: antraege.length,
        itemBuilder: (context, index) {
          Color itemColor = index % 2 == 0
              ? Lib.darkTheme.colorScheme.primary.withOpacity(0.5)
              : Lib.darkTheme.colorScheme.secondary.withOpacity(0.5);
          return Container(
            color: itemColor,
            height: 50,
            child: isScreenWide
                ? Draggable<DragAndDropItem>(
                    onDragStarted: () {
//get index of dragged
                      dragedIndex = index;
                    },
                    data: DragAndDropItem(
                        child: SizedBox(
                      height: 50,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Text(
                              antraege[index].title,
                              style: Lib.darkTheme.textTheme.bodyMedium!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )),
                    feedback: Text(antraege[index].title,
                        style: Lib.darkTheme.textTheme.bodyMedium!
                            .copyWith(fontWeight: FontWeight.bold)),
                    child: Row(children: [
                      Padding(
                          padding: const EdgeInsets.only(left: 8, right: 4),
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Lib.darkTheme.colorScheme.surfaceDim,
                                  foregroundColor: Lib
                                      .darkTheme.textTheme.bodyMedium!.color),
                              onPressed: () => showEditAntrag(
                                  antraege[index].id,
                                  antraege[index].title,
                                  antraege[index].begruendung,
                                  antraege[index].antragstext,
                                  UuidValue.fromString(""),
                                  "antraege"),
                              child: const Text("EDIT"))),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 4),
                          child: Text(
                            antraege[index].title,
                            style: Lib.darkTheme.textTheme.bodyMedium!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Row(
                              children: antraege[index].creators.map((text) {
                                return Expanded(
                                    child: Text(text,
                                        style: TextStyle(
                                            color: Lib.darkTheme.textTheme
                                                .bodyMedium!.color)));
                              }).toList(),
                            )),
                      ),
                      SizedBox(
                        width: 100,
                        child: Padding(
                            padding:
                                const EdgeInsets.only(right: 10, bottom: 4),
                            child: Builder(builder: (context) {
                              if (antraege[index]
                                      .createdAt
                                      .compareTo(sitzung.antragsfrist) <
                                  0) {
                                return Text(
                                    dateFormat
                                        .format(antraege[index].createdAt),
                                    style: TextStyle(
                                        color: Lib.darkTheme.textTheme
                                            .bodyMedium!.color));
                              } else {
                                return Text(
                                    dateFormat
                                        .format(antraege[index].createdAt),
                                    style: const TextStyle(
                                      color: Colors.red,
                                    ));
                              }
                            })),
                      )
                    ]),
                  )
                : LongPressDraggable<DragAndDropItem>(
                    onDragStarted: () {
//get index of dragged
                      dragedIndex = index;
                    },
                    data: DragAndDropItem(
                        child: Container(
                      height: 50,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Text(
                              antraege[index].title,
                              style: Lib.darkTheme.textTheme.bodyMedium!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )),
                    feedback: Text(
                      antraege[index].title,
                      style: Lib.darkTheme.textTheme.bodyMedium!
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    child: Row(children: [
                      Padding(
                          padding: const EdgeInsets.only(left: 8, right: 4),
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Lib.darkTheme.colorScheme.surfaceDim,
                                  foregroundColor: Lib
                                      .darkTheme.textTheme.bodyMedium!.color),
                              onPressed: () => showEditAntrag(
                                  antraege[index].id,
                                  antraege[index].title,
                                  antraege[index].begruendung,
                                  antraege[index].antragstext,
                                  UuidValue.fromString(""),
                                  "antraege"),
                              child: const Text("EDIT"))),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 4),
                          child: Text(
                            antraege[index].title,
                            style: Lib.darkTheme.textTheme.bodyMedium!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Row(
                              children: antraege[index].creators.map((text) {
                                return Text(text,
                                    style: TextStyle(
                                        color: Lib.darkTheme.textTheme
                                            .bodyMedium!.color));
                                ;
                              }).toList(),
                            )),
                      ),
                      SizedBox(
                        width: 100,
                        child: Padding(
                            padding:
                                const EdgeInsets.only(right: 10, bottom: 4),
                            child: Builder(builder: (context) {
                              if (antraege[index]
                                      .createdAt
                                      .compareTo(sitzung.antragsfrist) <
                                  0) {
                                return Text(
                                    dateFormat
                                        .format(antraege[index].createdAt),
                                    style: TextStyle(
                                        color: Lib.darkTheme.textTheme
                                            .bodyMedium!.color));
                              } else {
                                return Text(
                                    dateFormat
                                        .format(antraege[index].createdAt),
                                    style: const TextStyle(
                                      color: Colors.red,
                                    ));
                              }
                            })),
                      )
                    ]),
                  ),
          );
        });
  }

  Future<void> editTop(
      UuidValue topid, String dropdownValue, String text) async {
    final token = await OAuth.getToken(context);
    await http.patch(
        Uri.parse("https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/$topid/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8"
        },
        body: jsonEncode({
          "kind": dropdownValue,
          "name": text,
        }));
    setState(() {
      futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
      futureTops.then((tops) => {_contents = fetchTops(tops)});
    });
  }

  Future<void> editAntrag(UuidValue antragid, String titel, String begruendung,
      String antragstext) async {
    final token = await OAuth.getToken(context);
    await http.patch(Uri.parse("https://fscs.hhu.de/api/anträge/$antragid/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8"
        },
        body: jsonEncode({
          "titel": titel,
          "begründung": begruendung,
          "antragstext": antragstext,
        }));
    setState(() {
      futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
      futureTops.then((tops) => {_contents = fetchTops(tops)});

      futureAntraege = Antrag.fetchAntraege(showAllAntraege);
      futureAntraege
          .then((antraege) => {_contentsAntraege = fetchAntraege(antraege)});
    });
  }

  showEditAntrag(UuidValue id, String title, String begruendung,
      String antragstext, UuidValue topid, String callPoint) {
    titleController.text = title;
    begruendungController.text = begruendung;
    antragstextController.text = antragstext;

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
                      style: const TextStyle(color: Colors.white),
                      maxLines: 6,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Begeündung',
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
                      style: const TextStyle(color: Colors.white),
                      maxLines: 6,
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
                      onPressed: () {
                        Navigator.pop(context);
                        editAntrag(
                            id,
                            titleController.text,
                            begruendungController.text,
                            antragstextController.text);
                      },
                      child: const Text('Save',
                          style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        deleteAntrag(id);
                      },
                      child: const Text('DELETE',
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                    if (callPoint == "tops")
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          deleteAntragAssoc(topid, id);
                        },
                        child: const Text('DELETE ASSOCIATION',
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

  Future<void> deleteAntrag(UuidValue id) async {
    final token = await OAuth.getToken(context);
    await http
        .delete(Uri.parse("https://fscs.hhu.de/api/anträge/$id/"), headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json; charset=UTF-8"
    });

    setState(() {
      futureAntraege = Antrag.fetchAntraege(showAllAntraege);
      futureAntraege
          .then((antraege) => {_contentsAntraege = fetchAntraege(antraege)});
      futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
      futureTops.then((tops) => {_contents = fetchTops(tops)});
    });
  }

  Future<void> deleteAntragAssoc(UuidValue topid, UuidValue id) async {
    final token = await OAuth.getToken(context);
    await http.delete(
        Uri.parse(
            "https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/$topid/assoc/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8"
        },
        body: jsonEncode({"antrag_id": "$id"}));

    setState(() {
      futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
      futureTops.then((tops) => {_contents = fetchTops(tops)});

      futureAntraege = Antrag.fetchAntraege(showAllAntraege);
      futureAntraege
          .then((antraege) => {_contentsAntraege = fetchAntraege(antraege)});
    });
  }

  Future<UuidValue> getIDByUsername(username) async {
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

  Future<String> getUsernameFromAccessToken() async {
    final token = await OAuth.getToken(context);
    var jwt = parseJwt(token);
    return jwt["preferred_username"];
  }

  Map<String, dynamic> parseJwt(String token) {
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

  String _decodeBase64(String str) {
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
