import 'dart:convert';
import 'dart:developer';

import 'package:trip_planner/apis/navigation/transitous.dart';

import 'package:http/http.dart' as http;
import 'package:trip_planner/config/environment.dart';
import 'package:trip_planner/data_classes/activity.dart';

class Maps {
  static Future<Routes> search(
    Coordinates from,
    Coordinates to,
    String time,
  ) async {
    List<Route> routeList = [];
    final transitResponse = await http.post(
      Uri.parse("https://routes.googleapis.com/directions/v2:computeRoutes"),
      body: jsonEncode(_bodyBuilder(from, to, time, TravelType.TRANSIT)),
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": Env.mapsApi ?? "",
        "X-Goog-FieldMask": "routes.duration,routes.legs.steps.transitDetails",
      },
    );

    if (transitResponse.statusCode == 200) {
      Map<String, dynamic> responseAsJson = jsonDecode(transitResponse.body);
      log(responseAsJson.toString());
      try {
        routeList.addAll(
          List<Route>.from(
            (responseAsJson['routes'] as List).map(
              (item) => Route.fromJson(item, true),
            ),
          ),
        );
      } on TypeError {
        log(transitResponse.body);
        log("Response may have been empty");
      }
    }
    if (transitResponse.statusCode != 200) {
      log("Status: ${transitResponse.body}, response: ${transitResponse.body}");
    }

    final walkResponse = await http.post(
      Uri.parse("https://routes.googleapis.com/directions/v2:computeRoutes"),
      body: jsonEncode(_bodyBuilder(from, to, time, TravelType.WALK)),
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": Env.mapsApi ?? "",
        "X-Goog-FieldMask": "routes.duration",
      },
    );
    if (walkResponse.statusCode == 200) {
      Map<String, dynamic> responseAsJson = jsonDecode(walkResponse.body);
      try {
        routeList.addAll(
          List<Route>.from(
            (responseAsJson['routes'] as List).map(
              (item) => Route.fromJson(item, false),
            ),
          ),
        );
      } on TypeError {
        log(walkResponse.body);
        log("Response may have been empty");
      }
    }
    if (walkResponse.statusCode != 200) {
      log(
        "Status: ${walkResponse.statusCode}, response: ${transitResponse.body}",
      );
    }

    return Routes(routes: routeList);
  }

  static Map<String, dynamic> _bodyBuilder(
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
