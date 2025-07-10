import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Trip {
  final int id;
  final String name;
  final DateTime start;
  final DateTime end;
  final String location;

  const Trip({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.location,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'location': location,
    };
  }

  @override
  String toString() {
    return 'Trip{id: $id, name: $name, start: $start, end: $end, location: $location}';
  }
}


Future<void> insertTrip(Trip trip) async {
  final db = await openDatabase(join(await getDatabasesPath(), 'tripdb.db'));
  
  await db.insert(
    'trips',
    trip.toMap()..remove("id"), // Remove id to let the database auto-generate it
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Trip>> getTrips() async {
  final db = await openDatabase(join(await getDatabasesPath(), 'tripdb.db'));
  final List<Map<String, dynamic>> maps = await db.query('trips');

  return List.generate(maps.length, (i) {
    return Trip(
      id: maps[i]['id'],
      name: maps[i]['name'],
      start: DateTime.parse(maps[i]['start']),
      end: DateTime.parse(maps[i]['end']),
      location: maps[i]['location'],
    );
  });
}

Future<void> updateTrip(Trip trip) async {
  final db = await openDatabase(join(await getDatabasesPath(), 'tripdb.db'));
  await db.update(
    'trips',
    trip.toMap(),
    where: 'id = ?',
    whereArgs: [trip.id],
  );
}

Future<void> deleteTrip(int id) async {
  final db = await openDatabase(join(await getDatabasesPath(), 'tripdb.db'));
  await db.delete(
    'trips',
    where: 'id = ?',
    whereArgs: [id],
  );
}