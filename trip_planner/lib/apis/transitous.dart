import 'dart:convert';

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
    return Route(
      duration: Duration(seconds: json['duration']),
      travelType: isTransit ? TravelType.TRANSIT : TravelType.WALK,
      effectiveDuration: isTransit
          ? Duration(seconds: json['duration'], minutes: 10)
          : Duration(seconds: json['duration']),
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

  Route bestRoute() {
    return routes.reduce(
      (current, evaluate) =>
          current.effectiveDuration < evaluate.effectiveDuration
          ? current
          : evaluate,
    );
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
    print("Getting transport: $from, $to, $time");
    final response = await http.get(
      Uri.parse(
        "https://api.transitous.org/api/v3/plan?fromPlace=${from.toString()}&toPlace=${to.toString()}&time=$time",
      ),
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> response_as_Json =
          jsonDecode(response.body) as Map<String, dynamic>;
      List<Route> routes_list = List<Route>.from(
        (response_as_Json['itineraries'] as List).map(
          (item) => Route.fromJson(item, true),
        ),
      );
      print(response_as_Json);
      if (!response_as_Json["direct"].isEmpty) {
        routes_list = routes_list
          ..add(Route.fromJson(response_as_Json["direct"][0], false));
      }
      return Routes(routes: routes_list);
    }
    print(response.statusCode);
    throw Exception("Couldn't get route");
  }
}
