import 'dart:convert';
import 'dart:html' as html;

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

  @override
  void initState() {
    super.initState();

    futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
    futureTops.then((tops) => {
          _contents = List.generate(tops.length, (index) {
            return DragAndDropList(
              header: Column(
                children: <Widget>[
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Text(
                          'Top ${index + 2}: ${tops[index].name}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              children: <DragAndDropItem>[
                for (var antrag in tops[index].antraege)
                  DragAndDropItem(
                    child: Container(
                      height: 50,
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 8, bottom: 4),
                              child: Text(
                                antrag.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
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

    futureAntraege = Antrag.fetchAntraege();
    futureAntraege.then((antraege) => {
          _contentsAntraege = ListView.builder(
              itemCount: antraege.length,
              itemBuilder: (context, index) {
                return Container(
                  height: 50,
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: Draggable<DragAndDropItem>(
                          data: DragAndDropItem(
                              child: Container(
                            height: 50,
                            color: Colors.white,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8, bottom: 4),
                                    child: Text(
                                      antraege[index].title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          feedback: Text(antraege[index].title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Text(
                              antraege[index].title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })
        });
  }

  @override
  Widget build(BuildContext context) {
    var backgroundColor = const Color.fromARGB(255, 243, 242, 248);

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(title: const Text('Sitzung View'), actions: [
          ElevatedButton(
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
                          const Text("Name"),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 300,
                            child: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Location',
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
            ),
            child: const Text('Create Top'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Create Antrag'),
          ),
        ]),
        body: StreamBuilder<List<TopWithAntraege>>(
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
                        return const Center(child: CircularProgressIndicator());
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
                                itemDivider: Divider(
                                  thickness: 2,
                                  height: 2,
                                  color: backgroundColor,
                                ),
                                itemDecorationWhileDragging: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 3,
                                      offset: const Offset(
                                          0, 0), // changes position of shadow
                                    ),
                                  ],
                                ),
                                listInnerDecoration: BoxDecoration(
                                  color: Theme.of(context).canvasColor,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(8.0)),
                                ),
                                lastItemTargetHeight: 8,
                                addLastItemTargetHeightToTop: true,
                                lastListTargetSize: 40,
                                listDragHandle: const DragHandle(
                                  verticalAlignment:
                                      DragHandleVerticalAlignment.top,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Icon(
                                      Icons.menu,
                                      color: Colors.black26,
                                    ),
                                  ),
                                ),
                                itemDragHandle: const DragHandle(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Icon(
                                      Icons.menu,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ),
                              )),
                              Expanded(child: _contentsAntraege)
                            ]);
                      }
                    });
              }
            }));
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

    final requestDelete = html.HttpRequest();
    requestDelete.open('DELETE',
        "https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/$topOld/assoc/");
    requestDelete.withCredentials = true;
    requestDelete.setRequestHeader("Authorization", "Bearer $token");
    requestDelete.send(jsonEncode({"antrag_id": "$antrag"}));

    final requestAdd = html.HttpRequest();
    requestAdd.open('PATCH',
        "https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/$topNew/assoc/");
    requestAdd.withCredentials = true;
    requestAdd.setRequestHeader("Authorization", "Bearer $token");
    requestAdd.send(jsonEncode({"antrag_id": "$antrag"}));
  }

  Future<void> updateTopApi(int oldListIndex, int newListIndex) async {
    var tops = await Sitzung.fetchTopWithAntraege(sitzungsid);

    tops[oldListIndex].weight = newListIndex + 1;
    tops[newListIndex].weight = oldListIndex + 1;

    for (var top in tops) {
      final token = await OAuth.getToken(context);

      final request = html.HttpRequest();
      request.open('PATCH',
          "https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/${top.id}/");
      request.withCredentials = true;
      request.setRequestHeader("Authorization", "Bearer $token");
      request.send(jsonEncode({"weight": top.weight}));
    }
  }

  Future<void> addTop(String dropdownValue, String text) async {
    final token = await OAuth.getToken(context);
    final request = html.HttpRequest();
    request.open('POST', "https://fscs.hhu.de/api/sitzungen/$sitzungsid/tops/");
    request.withCredentials = true;
    request.setRequestHeader("Authorization", "Bearer $token");
    request.setRequestHeader("Content-Type", "application/json");
    request.send(jsonEncode({
      "kind": "$dropdownValue",
      "name": "$text",
    }));
    await request.onLoadEnd.first;
    setState(() {
      futureTops = Sitzung.fetchTopWithAntraege(sitzungsid);
      futureTops.then((tops) => {
            _contents = List.generate(tops.length, (index) {
              return DragAndDropList(
                header: Column(
                  children: <Widget>[
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 4),
                          child: Text(
                            'Top ${index + 2}: ${tops[index].name}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                children: <DragAndDropItem>[
                  for (var antrag in tops[index].antraege)
                    DragAndDropItem(
                      child: Container(
                        height: 50,
                        color: Colors.white,
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, bottom: 4),
                                child: Text(
                                  antrag.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
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
