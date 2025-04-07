import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

import 'package:drag_and_drop_lists/drag_and_drop_list_interface.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sitzungsverwaltung_gui/Admin/AntragsList.dart';
import 'package:sitzungsverwaltung_gui/Admin/SitzungView.dart';
import 'package:sitzungsverwaltung_gui/antrag.dart';
import 'package:sitzungsverwaltung_gui/oauth.dart';
import 'package:sitzungsverwaltung_gui/sitzung.dart';
import 'package:sitzungsverwaltung_gui/top.dart';
import 'package:sitzungsverwaltung_gui/lib.dart';
import 'package:uuid/uuid_value.dart';

final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

class TopListView extends StatefulWidget {
  final Sitzung sitzung;
  final UuidValue id;
  const TopListView(this.id, this.sitzung, {super.key});

  @override
  State<TopListView> createState() => TopListViewState(id, sitzung);
}

class TopListViewState extends State<TopListView> {
  final UuidValue sitzungsid;
  final Sitzung sitzung;
  TopListViewState(this.sitzungsid, this.sitzung);
  late List<DragAndDropList> _contents;
  static late Future<List<TopWithAntraege>> futureTops;

  final nameController = TextEditingController();
  final inhaltController = TextEditingController();
  String dropdownValue = "normal";

  final titleController = TextEditingController();
  final begruendungController = TextEditingController();
  final antragstextController = TextEditingController();
  final antragsSearchController = TextEditingController();
  var dragedIndex = -1;
  late Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
    futureTops.then((tops) => {_contents = fetchTops(tops)});

    _debounceTimer = Timer(Duration(milliseconds: 0), () {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  refreshTops() {
    setState(() {
      futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
      futureTops.then((tops) => {_contents = fetchTops(tops)});
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TopWithAntraege>>(
        stream: futureTops.asStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return DragAndDropLists(
                children: _contents,
                onItemReorder: _onItemReorder,
                onListReorder: _onListReorder,
                onItemAdd: _onItemAdd,
                onListAdd: _onListAdd,
                listPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                itemDecorationWhileDragging: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 3,
                      offset: const Offset(0, 0), // changes position of shadow
                    ),
                  ],
                ),
                listInnerDecoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                lastItemTargetHeight: 8,
                addLastItemTargetHeightToTop: true,
                lastListTargetSize: 40,
                listDragHandle: const DragHandle(
                  verticalAlignment: DragHandleVerticalAlignment.top,
                  child: Padding(
                    padding: EdgeInsets.only(top: 11, right: 10),
                    child: Icon(
                      Icons.menu,
                      color: Colors.white,
                    ),
                  ),
                ),
                itemDragHandle: const DragHandle(
                  child: Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.menu, color: Colors.white70),
                  ),
                ));
          }
        });
  }

  _onItemReorder(
      int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    setState(() {
      var movedItem = _contents[oldListIndex].children.removeAt(oldItemIndex);
      _contents[newListIndex].children.insert(newItemIndex, movedItem);

      updateAntragApi(oldItemIndex, oldListIndex, newItemIndex, newListIndex);
    });
  }

  _onListReorder(int oldListIndex, int newListIndex) {
    setState(() {
      var movedList = _contents.removeAt(oldListIndex);
      _contents.insert(newListIndex, movedList);
      updateTopApi(oldListIndex, newListIndex);
    });
  }

  _onItemAdd(DragAndDropItem newItem, int listIndex, int itemIndex) {
    setState(() {
      if (itemIndex == -1) {
        _contents[listIndex].children.add(newItem);
      } else {
        _contents[listIndex].children.insert(itemIndex, newItem);
      }
      addAntragToTop(listIndex);
    });
  }

  _onListAdd(DragAndDropListInterface newList, int listIndex) {
    setState(() {
      if (listIndex == -1) {
        _contents.add(newList as DragAndDropList);
      } else {
        _contents.insert(listIndex, newList as DragAndDropList);
      }
    });
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

    setState(() {
      futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
      futureTops.then((tops) => {_contents = fetchTops(tops)});
    });
  }

  showEditTop(UuidValue uuid, String name, TopKind kind, String inhalt) {
    nameController.text = name;
    inhaltController.text = inhalt;
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
                const SizedBox(height: 10),
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
                        editTop(uuid, dropdownValue, nameController.text,
                            inhaltController.text);
                      },
                      child: const Text('Save',
                          style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        deleteTop(uuid);
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
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

  Future<void> addAntragToTop(int listIndex) async {
    var tops = await Sitzung.fetchTopWithAntraege(sitzungsid);
    var antrag =
        await Antrag.fetchAntraege(AntragsListViewState.showAllAntraege);
    var antragId = antrag[AntragsListViewState.dragedIndex].id;
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

      SitzungsViewState.antragsListKey.currentState?.refreshAntraege();
    });
  }

  List<DragAndDropList> fetchTops(List<TopWithAntraege> tops) {
    var isScreenWide = MediaQuery.sizeOf(context).width >= 600;
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
                          onPressed: () => showEditTop(
                              tops[index].id,
                              tops[index].name,
                              tops[index].kind,
                              tops[index].inhalt),
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
                  isScreenWide
                      ? SizedBox(
                          width: 150,
                          child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 8, bottom: 4),
                              child: Row(
                                children: tops[index]
                                    .antraege[index2]
                                    .creators
                                    .map((text) {
                                  return Text(text,
                                      style: TextStyle(
                                          color: Lib.darkTheme.textTheme
                                              .bodyMedium!.color));
                                }).toList(),
                              )),
                        )
                      : SizedBox(),
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

  Future<void> editTop(
      UuidValue topid, String dropdownValue, String name, String inhalt) async {
    final token = await OAuth.getToken(context);
    await http.patch(
        Uri.parse("https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/$topid/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8"
        },
        body: jsonEncode(
            {"kind": dropdownValue, "name": name, "inhalt": inhalt}));
    setState(() {
      futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
      futureTops.then((tops) => {_contents = fetchTops(tops)});
    });
  }

  Future<void> deleteTop(UuidValue topid) async {
    final token = await OAuth.getToken(context);
    await http.delete(
      Uri.parse("https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/$topid/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json; charset=UTF-8"
      },
    );
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

      SitzungsViewState.antragsListKey.currentState?.refreshAntraege();
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
      SitzungsViewState.antragsListKey.currentState?.refreshAntraege();
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

      SitzungsViewState.antragsListKey.currentState?.refreshAntraege();
    });
  }
}
