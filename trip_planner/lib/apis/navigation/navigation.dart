import 'dart:convert';
import 'dart:developer';

import 'package:calendar_view/calendar_view.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart';
import 'package:trip_planner/apis/photon.dart';
import 'package:trip_planner/config/environment.dart';
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

class Navigation {
  final Coordinates from;
  final Coordinates to;
  final TZDateTime time;
  final String country;

  Navigation({
    required this.from,
    required this.to,
    required this.time,
    required this.country,
  });

  Routes routes = Routes(routes: []);

  Future<Route?> getBestRoute() async {
    await transitousSearch();
    log("Country is $country");
    log("Time is ${time.toIso8601String()}");
    if ((Env.navitime != null) & (country.toLowerCase() == "japan")) {
      log("Using Navitime in Japan");
      await navitimeSearch();
      if (Env.mapsApi != null) {
        await mapsWalkSearch();
      }
    }
    if ((routes.routes.isEmpty) & (Env.mapsApi != null)) {
      log("Falling back to Google Maps");
      await mapsTransitSearch();
      await mapsWalkSearch();
    }

    return routes.bestRoute();
  }

  Future<void> transitousSearch() async {
    final response = await http.get(
      Uri.parse(
        "https://api.transitous.org/api/v3/plan?fromPlace=${from.toString()}&toPlace=${to.toString()}&time=${time.toUtc().toIso8601String()}",
      ),
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> responseAsJson =
          jsonDecode(response.body) as Map<String, dynamic>;
      routes.routes.addAll(
        List<Route>.from(
          (responseAsJson['itineraries'] as List).map(
            (item) => Route.fromJson(item, true),
          ),
        ),
      );
      if (!responseAsJson["direct"].isEmpty) {
        routes.routes.add(Route.fromJson(responseAsJson["direct"][0], false));
      }
    }
    if (response.statusCode != 200) {
      log("TRANSITOUS - Status: ${response.body}, response: ${response.body}");
    }
  }

  Future<void> mapsTransitSearch() async {
    final transitResponse = await http.post(
      Uri.parse("https://routes.googleapis.com/directions/v2:computeRoutes"),
      body: jsonEncode(
        _bodyBuilder(
          from,
          to,
          time.toUtc().toIso8601String(),
          TravelType.TRANSIT,
        ),
      ),
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": Env.mapsApi ?? "",
        "X-Goog-FieldMask": "routes.duration,routes.legs.steps.transitDetails",
      },
    );

    if (transitResponse.statusCode == 200) {
      Map<String, dynamic> responseAsJson = jsonDecode(transitResponse.body);

      try {
        routes.routes.addAll(
          List<Route>.from(
            (responseAsJson['routes'] as List).map(
              (item) => Route.fromJson(item, true),
            ),
          ),
        );
      } on TypeError {
        log(transitResponse.body);
        log("MAPS - Response may have been empty");
      }
    }
    if (transitResponse.statusCode != 200) {
      log(
        "MAPS - Status: ${transitResponse.body}, response: ${transitResponse.body}",
      );
    }
  }

  Future<void> mapsWalkSearch() async {
    final walkResponse = await http.post(
      Uri.parse("https://routes.googleapis.com/directions/v2:computeRoutes"),
      body: jsonEncode(
        _bodyBuilder(from, to, time.toUtc().toIso8601String(), TravelType.WALK),
      ),
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": Env.mapsApi ?? "",
        "X-Goog-FieldMask": "routes.duration",
      },
    );
    if (walkResponse.statusCode == 200) {
      Map<String, dynamic> responseAsJson = jsonDecode(walkResponse.body);
      try {
        routes.routes.addAll(
          List<Route>.from(
            (responseAsJson['routes'] as List).map(
              (item) => Route.fromJson(item, false),
            ),
          ),
        );
      } on TypeError {
        log(walkResponse.body);
        log("MAPS - Response may have been empty");
      }
    }
    if (walkResponse.statusCode != 200) {
      log(
        "MAPS - Status: ${walkResponse.statusCode}, response: ${walkResponse.body}",
      );
    }
  }

  Future<void> navitimeSearch() async {
    String customTime = time
        .toIso8601String()
        .replaceAll(".000+0900", "")
        .replaceAll(".000Z", "");
    log(customTime);
    final response = await http.get(
      Uri.parse(
        "https://navitime-route-totalnavi.p.rapidapi.com/route_transit?start=${from.toString()}&goal=${to.toString()}&datum=wgs84&term=1440&limit=5&start_time=$customTime&coord_unit=degree",
      ),
      headers: {
        "x-rapidapi-key": Env.navitime ?? "",
        "x-rapidapi-host": 'navitime-route-totalnavi.p.rapidapi.com',
      },
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> responseAsJson = jsonDecode(response.body);
      try {
        routes.routes.addAll(
          List<Route>.from(
            (responseAsJson["items"] as List).map(
              (item) => Route(
                duration: Duration(minutes: item["summary"]["move"]["time"]),
                effectiveDuration: Duration(
                  minutes: (item["summary"]["move"]["time"]) + 10,
                ),
                travelType: TravelType.TRANSIT,
              ),
            ),
          ),
        );
      } on TypeError {
        log(response.body);
        log("NAVITIME - Response may have been empty");
      }
    }
    if (response.statusCode != 200) {
      log(
        "NAVITIME - Status: ${response.statusCode}, response: ${response.body}",
      );
    }
  }

  Map<String, dynamic> _bodyBuilder(
    Coordinates from,
    Coordinates to,
    String time,
    TravelType travelMode,
  ) {
    return {
      "origin": {
        "location": {
          "latLng": {"latitude": from.latitude, "longitude": from.longitude},
        },
      },
      "destination": {
        "location": {
          "latLng": {"latitude": to.latitude, "longitude": to.longitude},
        },
      },
      "travelMode": travelMode == TravelType.TRANSIT ? "TRANSIT" : "WALK",
      "computeAlternativeRoutes": true,
      "departureTime": time,
    };
  }
}
