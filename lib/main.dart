import 'package:flutter/material.dart';
import 'package:sitzungsverwaltung_gui/Sitzung.dart';
import 'package:sitzungsverwaltung_gui/SitzungView.dart';

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
  late List<Widget> _contents;
  late Future<List<Sitzung>> futureSitzung;

  @override
  void initState() {
    super.initState();

    futureSitzung = Sitzung.fetchSitzungen();
    futureSitzung.then((sitzungen) => {
          _contents = List.generate(sitzungen.length, (index) {
            Color color;
            if (index % 2 == 0) {
              color = Colors.green;
            } else {
              color = Colors.greenAccent;
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
                              'Sitzung ${sitzungen[index].datetime}',
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
  Widget build(BuildContext context) {
    var backgroundColor = const Color.fromARGB(255, 243, 242, 248);

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Drag Handle'),
        ),
        body: FutureBuilder<List<Sitzung>>(
            future: futureSitzung,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView(
                    padding: const EdgeInsets.all(8), children: _contents);
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const CircularProgressIndicator();
            }));
  }
}
