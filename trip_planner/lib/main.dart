import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:trip_planner/config/environment.dart';
import 'package:trip_planner/data_classes/trip.dart';
import 'package:trip_planner/trip_pages/trip_create.dart';
import 'package:trip_planner/trip_pages/trip_main.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  if (Env.mapsApi == null) {
    log("Unable to fallback to Google Maps");
  }
  // Open the database and store the reference.
  final database = openDatabase(
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    join(await getDatabasesPath(), 'tripdb.db'),

    onCreate: (db, version) {
      db.execute(
        'CREATE TABLE trips(id INTEGER PRIMARY KEY, name TEXT, start TEXT, end TEXT, location TEXT)',
      );
      db.execute(
        'CREATE TABLE activities(id INTEGER PRIMARY KEY, name TEXT, startDate TEXT, endDate TEXT, startTime TEXT, endTime TEXT, location TEXT, tripId INTEGER, travelType TEXT, travelTime INTEGER, coordinates TEXT, FOREIGN KEY (tripId) REFERENCES trips(id))',
      );
    },
    onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    // onUpgrade: (db, oldVersion, newVersion) => {
    //   if (oldVersion == 1)
    //     {
    //       db.execute(
    //         'CREATE TABLE activities(id INTEGER PRIMARY KEY, name TEXT, startDate TEXT, endDate TEXT, startTime TEXT, endTime TEXT, location TEXT, tripId INTEGER, FOREIGN KEY (tripId) REFERENCES trips(id))',
    //       ),
    //       oldVersion = 2,
    //     },
    //   if (oldVersion == 2)
    //     {
    //       db.execute("ALTER TABLE activities ADD COLUMN travelType TEXT"),
    //       db.execute("ALTER TABLE activities ADD COLUMN coordinates TEXT"),
    //       db.execute("ALTER TABLE activities ADD COLUMN travelTime INTEGER"),
    //       oldVersion = 3,
    //     },
    // },
    version: 1,
  );
  Intl.defaultLocale = "en_GB";
  initializeDateFormatting(Intl.defaultLocale, null);
  // await findSystemLocale();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Planner',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Trip Planner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Trip> _allTrips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final trips = await getTrips();
    setState(() {
      _allTrips = trips;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            ListView.builder(
              itemCount: _allTrips.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final trip = _allTrips[index];
                return ListTile(
                  title: Text(trip.name),
                  subtitle: Text(
                    'From ${DateFormat.yMd().format(trip.start)} to ${DateFormat.yMd().format(trip.end)}',
                  ),
                  onTap: () {
                    // Handle tap on the trip item.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripView(trip: trip),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (context) => const TripCreate()),
          ).then((_) => _loadTrips());
        },
        tooltip: 'Create Trip',
        child: const Icon(Icons.flight_takeoff),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
