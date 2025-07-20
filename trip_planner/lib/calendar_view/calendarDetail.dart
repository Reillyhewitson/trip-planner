import 'dart:developer';

import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:trip_planner/apis/navigation/navigation.dart';
import 'package:trip_planner/data_classes/activity.dart';

class Calendardetail extends StatefulWidget {
  final CalendarEventData event;
  final DateTime date;
  const Calendardetail({super.key, required this.event, required this.date});

  @override
  State<StatefulWidget> createState() {
    return CalendardetailState();
  }
}

class CalendardetailState extends State<Calendardetail> {
  Activity? _activity;
  MapController _controller = MapController();
  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    Activity activity = await getActivity(
      int.tryParse(widget.event.event.toString()) ?? 0,
    );
    setState(() {
      _activity = activity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _activity != null
        ? Padding(
            padding: EdgeInsetsGeometry.all(8),
            child: Center(
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      widget.event.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Text("${DateFormat.yMd().format(widget.event.date)}  "),
                        Text(
                          TimeOfDay(
                            hour: widget.event.startTime?.hour ?? 0,
                            minute: widget.event.startTime?.minute ?? 0,
                          ).format(context),
                        ),
                        Text(" - "),
                        Text(
                          TimeOfDay(
                            hour: widget.event.endTime?.hour ?? 0,
                            minute: widget.event.endTime?.minute ?? 0,
                          ).format(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  Text(widget.event.description ?? ""),
                  Divider(),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: FlutterMap(
                      mapController: _controller,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _activity?.coordinates.latitude ?? 0,
                          _activity?.coordinates.longitude ?? 0,
                        ),
                        keepAlive: true,
                        initialZoom: 15.0,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'dev.trip_planner.reilly',
                        ),
                        SimpleAttributionWidget(
                          source: Text("OpenStreetMap contributors"),
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _activity?.coordinates.latitude ?? 0,
                                _activity?.coordinates.longitude ?? 0,
                              ),
                              child: Icon(Icons.location_on, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : Padding(
            padding: EdgeInsetsGeometry.all(8),
            child: CircularProgressIndicator.adaptive(),
          );
  }
}
