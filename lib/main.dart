import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:sitzungsverwaltung_gui/Sitzung.dart';
import 'package:sitzungsverwaltung_gui/custom_navigation_drawer.dart';

void main() {
  runApp(const Sitzungsverwaltung());
}

class Sitzungsverwaltung extends StatelessWidget {
  const Sitzungsverwaltung({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sitzungsverwaltung',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(title: 'Main'),
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
  late List<DragAndDropList> _contents;
  late Future<List<Sitzung>> futureSitzung;

  @override
  void initState() {
    super.initState();

    futureSitzung = Sitzung.fetchSitzungen();
    futureSitzung.then((sitzungen) => {
          _contents = List.generate(sitzungen.length, (index) {
            return DragAndDropList(
              header: Column(
                children: <Widget>[
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Text(
                          'Sitzung ${sitzungen[index].datetime}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              children: <DragAndDropItem>[
                DragAndDropItem(child: const Text(""))
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
          title: const Text('Drag Handle'),
        ),
        drawer: const CustomNavigationDrawer(),
        body: FutureBuilder<List<Sitzung>>(
            future: futureSitzung,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return DragAndDropLists(
                  children: _contents,
                  onItemReorder: _onItemReorder,
                  onListReorder: _onListReorder,
                  listPadding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                        offset:
                            const Offset(0, 0), // changes position of shadow
                      ),
                    ],
                  ),
                  listInnerDecoration: BoxDecoration(
                    color: Theme.of(context).canvasColor,
                    borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                  ),
                  lastItemTargetHeight: 8,
                  addLastItemTargetHeightToTop: true,
                  lastListTargetSize: 40,
                  listDragHandle: const DragHandle(
                    verticalAlignment: DragHandleVerticalAlignment.top,
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
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const CircularProgressIndicator();
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
