import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trip_planner/apis/navigation/transitous.dart';
import 'package:trip_planner/debounce/debounce.dart';

class Feature {
  final String type;
  final String? label;
  final String? name;
  final String? housenumber;
  final String? street;
  final String? locality;
  final String? postcode;
  final String? city;
  final String? district;
  final String? county;
  final String? state;
  final String? country;
  final Coordinates coordinates;

  Feature({
    required this.type,
    this.name,
    this.label,
    this.housenumber,
    this.street,
    this.locality,
    this.postcode,
    this.city,
    this.district,
    this.county,
    this.state,
    this.country,
    required this.coordinates,
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      type: json['properties']['type'],
      name: json['properties']['name'],
      label: json['properties']['label'],
      housenumber: json['properties']['housenumber'],
      street: json['properties']['street'],
      locality: json['properties']['locality'],
      postcode: json['properties']['postcode'],
      city: json['properties']['city'],
      district: json['properties']['district'],
      county: json['properties']['county'],
      state: json['properties']['state'],
      country: json['properties']['country'],
      coordinates: Coordinates(
        json["geometry"]["coordinates"][1],
        json["geometry"]["coordinates"][0],
      ),
    );
  }

  @override
  String toString() {
    String result = '';
    if (name != null) {
      result += "$name, ";
    }
    if (label != null) {
      result += "$label, ";
    }
    if (housenumber != null) {
      result += "$housenumber, ";
    }
    if (street != null) {
      result += "$street, ";
    }
    if (locality != null) {
      result += "$locality, ";
    }
    if (city != null) {
      result += "$city, ";
    }
    if (state != null) {
      result += "$state, ";
    }
    if (country != null) {
      result += "$country";
    }
    return result;
  }
}

class FetchOptions {
  static Future<List<Feature>> search(String query) async {
    final response = await http.get(
      Uri.parse('https://photon.komoot.io/api/?q=$query&lang=en'),
    );
    if (response.statusCode == 200) {
      // Assuming the response is a JSON array of strings
      final List<Feature> locations = List<Feature>.from(
        (jsonDecode(response.body) as Map)['features'].map(
          (item) => Feature.fromJson(item),
        ),
      );
      if (locations.isEmpty) {
        throw const NoFeatures();
      }
      // Generate useful list from this
      return locations;
    } else {
      print(response.statusCode);
      throw const NetworkException();
    }
  }
}
