import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trip_planner/apis/transitous.dart';
import 'package:trip_planner/data_classes/trip.dart';
import 'package:trip_planner/debounce/debounce.dart';

enum TravelType { WALK, TRANSIT }

class Activity {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime startTime;
  final DateTime endTime;
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
      startTime: DateTime.parse(maps[i]['startTime']),
      endTime: DateTime.parse(maps[i]['endTime']),
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
) async {
  final List<Activity> activities = await getActivities(trip.id);
  final DateTime startDate = formData!['startDate'];
  // Find the activity with the latest endTime before the new activity's startDate
  final Activity? previousActivity = activities
      .where((activity) => activity.startDate == startDate)
      .where((activity) => activity.endTime.isBefore(formData["startTime"]))
      .fold<Activity?>(null, (prev, curr) {
        if (prev == null) return curr;
        return curr.endTime.isAfter(prev.endTime) ? curr : prev;
      });
  print("previous activity: ");
  print(previousActivity);
  Activity? nextActivity = activities
      .where((activity) => activity.startDate == startDate)
      .where((activity) => activity.endTime.isAfter(formData["endTime"]))
      .fold<Activity?>(null, (prev, curr) {
        if (prev == null) return curr;
        return curr.endTime.isBefore(prev.endTime) ? curr : prev;
      });
  final Routes? getTripInfo = previousActivity != null
      ? await Transitous.search(
          previousActivity.coordinates,
          formData["location"].coordinates,
          DateTime(
            previousActivity.endDate.year,
            previousActivity.endDate.month,
            previousActivity.endDate.day,
            previousActivity.endTime.hour,
            previousActivity.endTime.minute,
          ).toUtc().toIso8601String(),
        )
      : null;
  Route? bestRoute = getTripInfo?.bestRoute();
  print(
    "Duration: ${bestRoute?.duration.inMinutes}, travelType: ${bestRoute?.travelType}",
  );
  final activity = Activity(
    id: 0,
    name: formData['name'],
    startDate: formData['startDate'],
    endDate: formData['startDate'],
    startTime: formData['startTime'],
    endTime: formData['endTime'],
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
    final Routes? updateNext = nextActivity.endDate == activity.endDate
        ? await Transitous.search(
            activity.coordinates,
            nextActivity.coordinates,
            DateTime(
              activity.endDate.year,
              activity.endDate.month,
              activity.endDate.day,
              activity.endTime.hour,
              activity.endTime.minute,
            ).toUtc().toIso8601String(),
          )
        : null;
    nextActivity.travelTime = updateNext?.bestRoute().duration;
    nextActivity.travelType = updateNext?.bestRoute().travelType;
    updateActivity(nextActivity);
  }
}
