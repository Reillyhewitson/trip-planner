import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Activity {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final int tripId;

  Activity({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.tripId,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'tripId': tripId,
    };
  }

  @override
  String toString() {
    return 'Activity{id: $id, name: $name, startDate: $startDate, endDate: $endDate, startTime: $startTime, endTime: $endTime, location: $location, tripId: $tripId}';
  }

}

Future<void> insertActivity(Activity activity) async {
  final db = await openDatabase(join(await getDatabasesPath(), 'tripdb.db'));

  await db.insert(
    'activities',
    activity.toMap()..remove("id"), // Remove id to let the database auto-generate it
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Activity>> getActivities(int tripId) async {
  final db = await openDatabase(join(await getDatabasesPath(), 'tripdb.db'));
  final List<Map<String, dynamic>> maps = await db.query(
    'activities',
    where: 'tripId = ?',
    whereArgs: [tripId],
  );

  return List.generate(maps.length, (i) {
    return Activity(
      id: maps[i]['id'],
      name: maps[i]['name'],
      startDate: DateTime.parse(maps[i]['startDate']),
      endDate: DateTime.parse(maps[i]['endDate']),
      startTime: DateTime.parse(maps[i]['startTime']),
      endTime: DateTime.parse(maps[i]['endTime']),
      location: maps[i]['location'],
      tripId: maps[i]['tripId'],
    );
  });
}

Future<void> updateActivity(Activity activity) async {
  final db = await openDatabase(join(await getDatabasesPath(), 'tripdb.db'));

  await db.update(
    'activities',
    activity.toMap(),
    where: 'id = ?',
    whereArgs: [activity.id],
  );
}

Future<void> deleteActivity(int id) async {
  final db = await openDatabase(join(await getDatabasesPath(), 'tripdb.db'));

  await db.delete(
    'activities',
    where: 'id = ?',
    whereArgs: [id],
  );
}