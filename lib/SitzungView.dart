import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:sitzungsverwaltung_gui/Antrag.dart';
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
  final UuidValue id;
  _SitzungsViewState(this.id);
  late List<DragAndDropList> _contents;
  late List<DragAndDropList> _contentsAntraege;
  late Future<List<TopWithAntraege>> futureTops;
  late Future<List<Antrag>> futureAntraege;

  @override
  void initState() {
    super.initState();

    futureTops = Sitzung.fetchTopWithAntraege(id);
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
          _contentsAntraege = List.generate(1, (index) {
            return DragAndDropList(
              header: const Column(
                children: <Widget>[
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 4),
                        child: Text(
                          'Alle Anträge',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              children: <DragAndDropItem>[
                for (var antrag in antraege)
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
  }

  @override
  Widget build(BuildContext context) {
    var backgroundColor = const Color.fromARGB(255, 243, 242, 248);

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Sitzung View'),
        ),
        body: FutureBuilder<List<TopWithAntraege>>(
            future: futureTops,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                return FutureBuilder<List<Antrag>>(
                    future: futureAntraege,
                    builder: (context, secondSnapshot) {
                      if (secondSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
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
                              Expanded(
                                  child: DragAndDropLists(
                                children: _contentsAntraege,
                                onItemReorder: _onItemReorder,
                                onListReorder: _onListReorder,
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
                              ))
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
    });
  }

  _onListReorder(int oldListIndex, int newListIndex) {
    setState(() {
      var movedList = _contents.removeAt(oldListIndex);
      _contents.insert(newListIndex, movedList);
    });
  }
}