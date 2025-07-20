import 'dart:developer';

import 'package:flutter/material.dart' hide Route;
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/standalone.dart';
import 'package:trip_planner/apis/navigation/navigation.dart';
import 'package:trip_planner/config/environment.dart';
import 'package:trip_planner/data_classes/trip.dart';
// import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum TravelType { WALK, TRANSIT }

class Activity {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final TZDateTime startTime;
  final TZDateTime endTime;
  final String location;
  final int tripId;
  Duration? travelTime;
  TravelType? travelType;
  final Coordinates coordinates;

  Activity({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.tripId,
    this.travelTime,
    this.travelType,
    required this.coordinates,
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
      'travelTime': travelTime?.inMinutes,
      'travelType': travelType?.toString(),
      'coordinates': coordinates.toString(),
    };
  }

  @override
  String toString() {
    return 'Activity{id: $id, name: $name, startDate: $startDate, endDate: $endDate, startTime: $startTime, endTime: $endTime, location: $location, tripId: $tripId, travelTime: $travelTime, travelType: $travelType, coordinates: ${coordinates.toString()}}';
  }
}

Future<int?> insertActivity(Activity activity) async {
  final db = await openDatabase(join(await getDatabasesPath(), 'tripdb.db'));
  print(activity.toString());
  int id = await db.insert(
    'activities',
    activity.toMap()
      ..remove("id"), // Remove id to let the database auto-generate it
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  return id;
}

Future<List<Activity>> getActivities(int tripId) async {
  final db = await openDatabase(join(await getDatabasesPath(), 'tripdb.db'));
  final List<Map<String, dynamic>> maps = await db.query(
    'activities',
    where: 'tripId = ?',
    whereArgs: [tripId],
    orderBy: "startDate ASC, startTime ASC",
  );
  return List.generate(maps.length, (i) {
    return Activity(
      id: maps[i]['id'],
      name: maps[i]['name'],
      startDate: DateTime.parse(maps[i]['startDate']),
      endDate: DateTime.parse(maps[i]['endDate']),
      startTime: TZDateTime.parse(
        tz.getLocation(
          latLngToTimezoneString(
            Coordinates.fromString(maps[i]['coordinates']).latitude,
            Coordinates.fromString(maps[i]['coordinates']).longitude,
          ),
        ),
        maps[i]['startTime'],
      ),
      endTime: TZDateTime.parse(
        tz.getLocation(
          latLngToTimezoneString(
            Coordinates.fromString(maps[i]['coordinates']).latitude,
            Coordinates.fromString(maps[i]['coordinates']).longitude,
          ),
        ),
        maps[i]['endTime'],
      ),
      location: maps[i]['location'],
      tripId: maps[i]['tripId'],
      travelTime: maps[i]['travelTime'] != null
          ? Duration(minutes: maps[i]['travelTime'])
          : null,
      travelType: maps[i]['travelType'] != null
          ? TravelType.values.firstWhere(
              (e) => e.toString() == maps[i]['travelType'],
            )
          : null,
      coordinates: Coordinates.fromString(maps[i]['coordinates']),
    );
  });
}

Future<Activity> getActivity(int id) async {
  final db = await openDatabase(join(await getDatabasesPath(), 'tripdb.db'));
  final List<Map<String, dynamic>> maps = await db.query(
    'activities',
    where: 'id = ?',
    whereArgs: [id],
    orderBy: "startDate ASC, startTime ASC",
  );

  return Activity(
    id: maps[0]['id'],
    name: maps[0]['name'],
    startDate: DateTime.parse(maps[0]['startDate']),
    endDate: DateTime.parse(maps[0]['endDate']),
    startTime: TZDateTime.parse(
      tz.getLocation(
        latLngToTimezoneString(
          Coordinates.fromString(maps[0]['coordinates']).latitude,
          Coordinates.fromString(maps[0]['coordinates']).longitude,
        ),
      ),
      maps[0]['startTime'],
    ),
    endTime: TZDateTime.parse(
      tz.getLocation(
        latLngToTimezoneString(
          Coordinates.fromString(maps[0]['coordinates']).latitude,
          Coordinates.fromString(maps[0]['coordinates']).longitude,
        ),
      ),
      maps[0]['endTime'],
    ),
    location: maps[0]['location'],
    tripId: maps[0]['tripId'],
    travelTime: maps[0]['travelTime'] != null
        ? Duration(minutes: maps[0]['travelTime'])
        : null,
    travelType: maps[0]['travelType'] != null
        ? TravelType.values.firstWhere(
            (e) => e.toString() == maps[0]['travelType'],
          )
        : null,
    coordinates: Coordinates.fromString(maps[0]['coordinates']),
  );
}

Future<int?> updateActivity(Activity activity) async {
  final db = await openDatabase(join(await getDatabasesPath(), 'tripdb.db'));

  int id = await db.update(
    'activities',
    activity.toMap(),
    where: 'id = ?',
    whereArgs: [activity.id],
  );

  return id;
}

Future<void> deleteActivity(int id) async {
  final db = await openDatabase(join(await getDatabasesPath(), 'tripdb.db'));

  await db.delete('activities', where: 'id = ?', whereArgs: [id]);
}

Future<void> createActivity(
  Map<String, dynamic>? formData,
  Trip trip,
  bool update,
  BuildContext context,
) async {
  final List<Activity> activities = await getActivities(
    trip.id,
  ); //  gets activities
  log("Formdata is ${formData.toString()}");
  final tzCurrentLocation = tz.getLocation(
    latLngToTimezoneString(
      formData!["location"].coordinates.latitude,
      formData["location"].coordinates.longitude,
    ),
  );
  final DateTime startDate = formData!['startDate']; // gets startdate
  final TZDateTime startTime = TZDateTime(
    tzCurrentLocation,
    formData['startDate'].year,
    formData['startDate'].month,
    formData['startDate'].hour,
    formData['startTime'].hour,
    formData['startTime'].minute,
  );
  final TZDateTime endTime = TZDateTime(
    tzCurrentLocation,
    formData['startDate'].year,
    formData['startDate'].month,
    formData['startDate'].hour,
    formData['endTime'].hour,
    formData['endTime'].minute,
  );
  // Find the activity with the latest endTime before the new activity's startDate
  final Activity? previousActivity = activities
      .where((activity) => activity.endDate == startDate)
      .where((activity) => activity.endTime.isBefore(startTime))
      .fold<Activity?>(null, (prev, curr) {
        if (prev == null) return curr;
        return curr.endTime.isAfter(prev.endTime) ? curr : prev;
      });
  // Finds the activity immediately after this one
  Activity? nextActivity = activities
      .where((activity) => activity.startDate == startDate)
      .where((activity) => activity.endTime.isAfter(endTime))
      .fold<Activity?>(null, (prev, curr) {
        if (prev == null) return curr;
        return curr.endTime.isBefore(prev.endTime) ? curr : prev;
      });
  log("Previous activity is ${previousActivity.toString()}");
  log("Next activity is ${nextActivity.toString()}");
  Route? bestRoute;
  if (previousActivity != null) {
    final tzLocation = tz.getLocation(
      latLngToTimezoneString(
        previousActivity.coordinates.latitude,
        previousActivity.coordinates.longitude,
      ),
    );
    tz.TZDateTime actualDate = tz.TZDateTime(
      tzLocation,
      previousActivity.endDate.year,
      previousActivity.endDate.month,
      previousActivity.endDate.day,
      previousActivity.endTime.hour,
      previousActivity.endTime.minute,
    );
    log(actualDate.toIso8601String());
    Navigation? getTripInfo = Navigation(
      from: previousActivity.coordinates,
      to: formData["location"].coordinates,
      time: actualDate,
      country: formData["location"].country,
    );
    log("Calling best route on new activtiy");
    bestRoute = await getTripInfo.getBestRoute();
    log(
      "Duration: ${bestRoute?.duration.inMinutes}, travelType: ${bestRoute?.travelType}",
    );
  }

  final activity = Activity(
    id: 0,
    name: formData['name'],
    startDate: formData['startDate'],
    endDate: formData['startDate'],
    startTime: startTime,
    endTime: endTime,
    location: formData['location'].toString(),
    tripId: trip.id,
    coordinates: formData['location'].coordinates,
    travelTime: bestRoute?.duration,
    travelType: bestRoute?.travelType,
  );

  int? insert = update
      ? await updateActivity(activity)
      : await insertActivity(activity);

  if (insert != null && nextActivity != null) {
    final tzLocationCurrent = previousActivity != null
        ? tz.getLocation(
            latLngToTimezoneString(
              activity.coordinates.latitude,
              activity.coordinates.longitude,
            ),
          )
        : tz.UTC;
    tz.TZDateTime actualDateCurrent = tz.TZDateTime(
      tzLocationCurrent,
      activity.endDate.year,
      activity.endDate.month,
      activity.endDate.day,
      activity.endTime.hour,
      activity.endTime.minute,
    ).toUtc();
    log("Time is $actualDateCurrent");
    Navigation getNextRoutes = Navigation(
      from: activity.coordinates,
      to: nextActivity.coordinates,
      time: actualDateCurrent,
      country: activity.location.split(", ").last,
    );
    log("Calling next best");
    Route? nextBest = await getNextRoutes.getBestRoute();
    nextActivity.travelTime = nextBest?.duration;
    nextActivity.travelType = nextBest?.travelType;
    updateActivity(nextActivity);
  }
}

Future<void> activityDeleteProcess(Activity activityDelete) async {
  List<Activity> activities = await getActivities(activityDelete.tripId);
  TZDateTime? actualDateCurrent = null;
  final Activity? previousActivity = activities
      .where((activity) => activity.startDate == activityDelete.startDate)
      .where((activity) => activity.endTime.isBefore(activityDelete.startTime))
      .fold<Activity?>(null, (prev, curr) {
        if (prev == null) return curr;
        return curr.endTime.isAfter(prev.endTime) ? curr : prev;
      });

  Activity? nextActivity = activities
      .where((activity) => activity.endDate == activityDelete.endDate)
      .where((activity) => activity.startTime.isAfter(activityDelete.endTime))
      .fold<Activity?>(null, (prev, curr) {
        if (prev == null) return curr;
        return curr.endTime.isBefore(prev.endTime) ? curr : prev;
      });
  if (previousActivity != null) {
    final tzLocationCurrent = tz.getLocation(
      latLngToTimezoneString(
        previousActivity.coordinates.latitude,
        previousActivity.coordinates.longitude,
      ),
    );

    tz.TZDateTime actualDateCurrent = tz.TZDateTime(
      tzLocationCurrent,
      previousActivity.endDate.year,
      previousActivity.endDate.month,
      previousActivity.endDate.day,
      previousActivity.endTime.hour,
      previousActivity.endTime.minute,
    ).toUtc();
    log("Time is $actualDateCurrent");
  }
  Navigation? getNextRoutes = previousActivity != null
      ? nextActivity != null
            ? actualDateCurrent != null
                  ? Navigation(
                      from: previousActivity.coordinates,
                      to: nextActivity.coordinates,
                      time: actualDateCurrent,
                      country: previousActivity.location.split(", ").last,
                    )
                  : null
            : null
      : null;
  Route? nextBest = await getNextRoutes?.getBestRoute();
  nextActivity?.travelTime = nextBest?.duration;
  nextActivity?.travelType = nextBest?.travelType;
  nextActivity != null ? updateActivity(nextActivity) : null;
  deleteActivity(activityDelete.id);
}
