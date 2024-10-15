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

class SitzungView extends StatefulWidget {
  final UuidValue id;
  const SitzungView(this.id, {super.key});

  @override
  State<SitzungView> createState() => _SitzungsViewState(id);
}

class _SitzungsViewState extends State<SitzungView> {
  final UuidValue sitzungsid;
  _SitzungsViewState(this.sitzungsid);
  late List<DragAndDropList> _contents;
  late Widget _contentsAntraege;
  late Future<List<TopWithAntraege>> futureTops;
  late Future<List<Antrag>> futureAntraege;

  final nameController = TextEditingController();
  String dropdownValue = "normal";

  final titleController = TextEditingController();
  final begruendungController = TextEditingController();
  final antragstextController = TextEditingController();
  var dragedIndex = -1;

  final ThemeData darkTheme = ThemeData(
      colorScheme: const ColorScheme.dark(
          primary: Color.fromRGBO(119, 119, 119, 1),
          secondary: Color.fromRGBO(85, 85, 85, 1),
          surface: Color.fromRGBO(50, 50, 50, 1),
          surfaceDim: Color.fromRGBO(40, 40, 40, 1)),
      textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      buttonTheme:
          const ButtonThemeData(buttonColor: Color.fromRGBO(11, 80, 181, 1)));

  @override
  void initState() {
    super.initState();

    futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
    futureTops.then((tops) => {_contents = fetchTops(tops)});

    futureAntraege = Antrag.fetchAntraege();
    futureAntraege
        .then((antraege) => {_contentsAntraege = fetchAntraege(antraege)});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: darkTheme.colorScheme.surfaceDim,
            foregroundColor: darkTheme.textTheme.bodyMedium!.color,
            title: const Text('Sitzung View'),
            actions: [
              ElevatedButton(
                onPressed: () => showCreateTop(),
                child: const Text('Create Top'),
              ),
              ElevatedButton(
                onPressed: () => showCreateAntrag(),
                child: const Text('Create Antrag'),
              ),
            ]),
        body: Container(
            color: darkTheme.colorScheme.surface,
            child: StreamBuilder<List<TopWithAntraege>>(
                stream: futureTops.asStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    return FutureBuilder<List<Antrag>>(
                        future: futureAntraege,
                        builder: (context, secondSnapshot) {
                          if (secondSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (secondSnapshot.hasError) {
                            return Center(
                                child: Text('Error: ${secondSnapshot.error}'));
                          } else {
                            return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                      child: DragAndDropLists(
                                    children: _contents,
                                    onItemReorder: _onItemReorder,
                                    onListReorder: _onListReorder,
                                    onItemAdd: _onItemAdd,
                                    onListAdd: _onListAdd,
                                    listPadding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 10),
                                    itemDecorationWhileDragging: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 2,
                                          blurRadius: 3,
                                          offset: const Offset(0,
                                              0), // changes position of shadow
                                        ),
                                      ],
                                    ),
                                    listInnerDecoration: const BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(8.0)),
                                    ),
                                    lastItemTargetHeight: 8,
                                    addLastItemTargetHeightToTop: true,
                                    lastListTargetSize: 40,
                                    listDragHandle: const DragHandle(
                                      verticalAlignment:
                                          DragHandleVerticalAlignment.top,
                                      child: Padding(
                                        padding:
                                            EdgeInsets.only(top: 11, right: 10),
                                        child: Icon(
                                          Icons.menu,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    itemDragHandle: const DragHandle(
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 10),
                                        child: Icon(Icons.menu,
                                            color: Colors.white70),
                                      ),
                                    ),
                                  )),
                                  Expanded(child: _contentsAntraege)
                                ]);
                          }
                        });
                  }
                })));
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
                  const Text("Name"),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Name',
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Kind'),
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
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        addTop(dropdownValue, nameController.text);
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
    );
  }

  showEditTop(UuidValue uuid, String name, TopKind kind) {
    nameController.text = name;
    dropdownValue = kind.name;
    print("name: $name, kind: $kind");
    showDialog<String>(
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
                  const Text("Name"),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Name',
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Kind'),
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
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        editTop(dropdownValue, nameController.text);
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
    );
  }

  showCreateAntrag() {
    showDialog<String>(
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
                  const Text("Titel"),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Titel',
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text("Begründung"),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: begruendungController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Begeündung',
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text("Antragstext"),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: antragstextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Antragstext',
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
                        addAntrag(titleController, begruendungController,
                            antragstextController);
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
    );
  }

  Future<void> addAntrag(
      TextEditingController titleController,
      TextEditingController begruendungController,
      TextEditingController antragstextController) async {
    final token = await OAuth.getToken(context);
    await http.post(Uri.parse("https://fscs.hhu.de/api/anträge/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8"
        },
        body: jsonEncode({
          "titel": titleController.text,
          "begründung": begruendungController.text,
          "antragstext": antragstextController.text,
          "antragssteller": ["72c4eed3-4142-4aa7-8eaa-9af01486a559"]
        }));
    setState(() {
      futureAntraege = Antrag.fetchAntraege();
      futureAntraege
          .then((antraege) => {_contentsAntraege = fetchAntraege(antraege)});
    });
  }

  Future<void> addAntragToTop(int listIndex) async {
    var tops = await Sitzung.fetchTopWithAntraege(sitzungsid);
    var antrag = await Antrag.fetchAntraege();
    var antragId = antrag[dragedIndex].id;
    var top = tops[listIndex].id;
    final token = await OAuth.getToken(context);
    await http.patch(
        Uri.parse(
            "https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/$top/assoc/"),
        headers: {"Authorization": "Bearer $token"},
        body: jsonEncode({"antrag_id": "$antragId"}));
  }

  List<DragAndDropList> fetchTops(List<TopWithAntraege> tops) {
    return List.generate(tops.length, (index) {
      return DragAndDropList(
          decoration: BoxDecoration(
            color: darkTheme.colorScheme.surfaceDim,
          ),
          header: Column(
            children: <Widget>[
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 8, bottom: 2),
                    child: Text(
                      'Top ${index + 2}: ${tops[index].name}',
                      style: darkTheme.textTheme.bodyMedium!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8, right: 4),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: darkTheme.colorScheme.secondary
                                  .withOpacity(0.5),
                              foregroundColor:
                                  darkTheme.textTheme.bodyMedium!.color),
                          onPressed: () => showEditTop(tops[index].id,
                              tops[index].name, tops[index].kind),
                          child: const Text("EDIT"))),
                ],
              ),
            ],
          ),
          children: List.generate(tops[index].antraege.length, (index2) {
            Color itemColor = index2 % 2 == 0
                ? darkTheme.colorScheme.primary.withOpacity(0.5)
                : darkTheme.colorScheme.secondary.withOpacity(0.5);
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
                              backgroundColor: darkTheme.colorScheme.surfaceDim,
                              foregroundColor:
                                  darkTheme.textTheme.bodyMedium!.color),
                          onPressed: () {},
                          child: const Text("EDIT"))),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        tops[index].antraege[index2].title,
                        style: darkTheme.textTheme.bodyMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ));
          }));
    });
  }

  fetchAntraege(List<Antrag> antraege) {
    return ListView.builder(
        itemCount: antraege.length,
        itemBuilder: (context, index) {
          Color itemColor = index % 2 == 0
              ? darkTheme.colorScheme.primary.withOpacity(0.5)
              : darkTheme.colorScheme.secondary.withOpacity(0.5);
          return Container(
            color: itemColor,
            height: 50,
            child: Row(
              children: [
                Expanded(
                  child: Draggable<DragAndDropItem>(
                    onDragStarted: () {
                      //get index of dragged
                      dragedIndex = index;
                    },
                    data: DragAndDropItem(
                        child: Container(
                      height: 50,
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 8, bottom: 4),
                              child: Text(
                                antraege[index].title,
                                style: darkTheme.textTheme.bodyMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    feedback: Text(antraege[index].title,
                        style: darkTheme.textTheme.bodyMedium!
                            .copyWith(fontWeight: FontWeight.bold)),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        antraege[index].title,
                        style: darkTheme.textTheme.bodyMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Future<void> editTop(String dropdownValue, String text) async {
    final token = await OAuth.getToken(context);
    await http.patch(
        Uri.parse("https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8"
        },
        body: jsonEncode({
          "kind": dropdownValue,
          "name": text,
        }));
  }
}
