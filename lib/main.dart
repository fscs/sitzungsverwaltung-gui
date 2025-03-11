import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sitzungsverwaltung_gui/Admin/SitzungView.dart';
import 'package:sitzungsverwaltung_gui/Admin/main.dart';
import 'package:sitzungsverwaltung_gui/OAuth.dart';
import 'package:sitzungsverwaltung_gui/Sitzung.dart';
import 'package:sitzungsverwaltung_gui/lib.dart';
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
                child: const Text('Admin', style: TextStyle(fontSize: 20)),
                onPressed: () async {
                  var token = await OAuth.getToken(context);
                  Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

                  if (decodedToken["groups"].contains("FS_Rat_Informatik")) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminMainPage(
                                  title: 'Admin',
                                )));
                  } else {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => const AlertDialog(
                            title: Text("fehler"), content: Text("blub")));
                  }
                },
              ))
        ]),
      ),
      body: Container(
        color: Lib.darkTheme.colorScheme.surface,
        child: Center(
          child: ElevatedButton(
              onPressed: () {
                Lib.showCreateAntrag(context);
              },
              child: Text("Antrag Einreichen")),
        ),
      ),
    );
  }
}
