import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';

import 'package:http/http.dart' as http;
import 'package:trip_planner/data_classes/activity.dart';

class Route {
  final Duration duration;
  final TravelType travelType;
  final Duration effectiveDuration;

  Route({
    required this.duration,
    required this.travelType,
    required this.effectiveDuration,
  });

  factory Route.fromJson(Map<String, dynamic> json, bool isTransit) {
    final int getDuration = json['duration'] is String
        ? double.parse(
            json["duration"].toString().substring(
              0,
              json["duration"].length - 1,
            ),
          ).toInt()
        : double.parse(json["duration"].toString()).toInt();
    return Route(
      duration: Duration(seconds: getDuration),
      travelType: isTransit ? TravelType.TRANSIT : TravelType.WALK,
      effectiveDuration: isTransit
          ? Duration(seconds: getDuration, minutes: 10)
          : Duration(seconds: getDuration),
    );
  }
} // Fill with results from Transitous API#

class Routes {
  final List<Route> routes;

  Routes({required this.routes});

  factory Routes.fromJson(List<dynamic> json, bool isTransit) {
    return Routes(
      routes: json.map((route) => Route.fromJson(route, isTransit)).toList(),
    );
  }

  Route? bestRoute() {
    try {
      return routes.reduce(
        (current, evaluate) =>
            current.effectiveDuration < evaluate.effectiveDuration
            ? current
            : evaluate,
      );
    } on StateError {
      log("No routes available");
      return null;
    }
  }
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates(this.latitude, this.longitude);

  static Coordinates fromString(String str) {
    final parts = str.split(',');
    return Coordinates(double.parse(parts[0]), double.parse(parts[1]));
  }

  @override
  String toString() {
    return '$latitude,$longitude';
  }
}

class Transitous {
  static Future<Routes> search(
    Coordinates from,
    Coordinates to,
    String time,
  ) async {
    final response = await http.get(
      Uri.parse(
        "https://api.transitous.org/api/v3/plan?fromPlace=${from.toString()}&toPlace=${to.toString()}&time=$time",
      ),
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> responseAsJson =
          jsonDecode(response.body) as Map<String, dynamic>;
      List<Route> routesList = List<Route>.from(
        (responseAsJson['itineraries'] as List).map(
          (item) => Route.fromJson(item, true),
        ),
      );
      print(responseAsJson);
      if (!responseAsJson["direct"].isEmpty) {
        routesList = routesList
          ..add(Route.fromJson(responseAsJson["direct"][0], false));
      }
      return Routes(routes: routesList);
    }
    print(response.statusCode);
    throw Exception("Couldn't get route");
  }
}
