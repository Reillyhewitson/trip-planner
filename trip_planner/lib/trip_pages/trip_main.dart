import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:trip_planner/calendar_view/calendar.dart';
import 'package:trip_planner/data_classes/activity.dart';
import 'package:trip_planner/data_classes/trip.dart';
import 'package:trip_planner/activity_pages/activity_create.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:trip_planner/trip_pages/trip_edit.dart';

class TripView extends StatefulWidget {
  const TripView({super.key, required this.trip});

  final Trip trip;

  @override
  TripViewState createState() {
    return TripViewState();
  }
}

class TripViewState extends State<TripView> {
  List<Activity> _activities = [];
  int _trip_length = 0;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    // Load activities for the trip
    final activities = await getActivities(widget.trip.id);
    // Calculate the trip length
    final start = widget.trip.start;
    final end = widget.trip.end;
    setState(() {
      _activities = activities;
      _trip_length =
          end.difference(start).inDays + 1; // +1 to include the start day
      print("Trip length: $_trip_length days");
    });
  }

  Future<void> _setTripLength() async {
    final start = widget.trip.start;
    final end = widget.trip.end;
    setState(() {
      _trip_length =
          end.difference(start).inDays + 1; // +1 to include the start day
    });
  }

  Widget _buildActivityList(int index) {
    final dayActivities = _activities
        .where(
          (activity) =>
              activity.startDate ==
              widget.trip.start.add(Duration(days: index)),
        )
        .toList();

    if (dayActivities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'No activities planned for this day.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.builder(
      itemCount: dayActivities.length,
      shrinkWrap: true,
      primary: false,
      itemBuilder: (context, index) {
        Activity activity = dayActivities[index];
        bool isEnoughTime = activity.travelTime != null
            ? DateTime(
                    dayActivities[index - 1].endDate.year,
                    dayActivities[index - 1].endDate.month,
                    dayActivities[index - 1].endDate.day,
                    dayActivities[index - 1].endTime.hour,
                    dayActivities[index - 1].endTime.minute,
                  )
                  .add(activity.travelTime ?? Duration(days: 0))
                  .isBefore(
                    DateTime(
                      activity.startDate.year,
                      activity.startDate.month,
                      activity.startDate.day,
                      activity.startTime.hour,
                      activity.startTime.minute,
                    ),
                  )
            : true;
        return Container(
          padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Card(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: activity.travelTime != null
                      ? Column(
                          children: [
                            Icon(
                              activity.travelType == TravelType.TRANSIT
                                  ? Icons.train
                                  : Icons.directions_walk,
                              color: !isEnoughTime ? Colors.redAccent : null,
                              size: 20,
                            ),
                            Text(
                              "${activity.travelTime?.inMinutes}m",
                              selectionColor: !isEnoughTime
                                  ? Colors.redAccent
                                  : null,
                            ),
                            !isEnoughTime
                                ? Icon(
                                    Icons.warning,
                                    color: Colors.redAccent,
                                    size: 20,
                                  )
                                : Icon(Icons.check_circle, size: 20),
                          ],
                        )
                      : Column(children: [Icon(Icons.apartment)]),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(activity.name),
                      Text(activity.location.split(", ")[0]),
                    ],
                  ),
                ),
                SizedBox(
                  // width: MediaQuery.sizeOf(context).width * 0.45,
                  child: Column(
                    children: [
                      Container(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                          ),
                          child: Text(
                            DateFormat.yMd().format(activity.startDate),
                            textAlign: TextAlign.left,
                            style: TextStyle(height: 0.5),
                          ),
                          onPressed: () {
                            showDatePicker(
                              context: context,
                              firstDate: widget.trip.start,
                              lastDate: widget.trip.end,
                              initialDate: activity.startDate,
                            ).then((value) {
                              if (value != null) {
                                setState(() {
                                  DateTime newDate = DateTime(
                                    activity.startTime.year,
                                    activity.startTime.month,
                                    activity.startTime.day,
                                    value.hour,
                                    value.minute,
                                  );
                                  Activity updatedActivity = Activity(
                                    id: activity.id,
                                    name: activity.name,
                                    startDate: newDate,
                                    endDate: newDate,
                                    startTime: activity.startTime,
                                    endTime: activity.endTime,
                                    location: activity.location,
                                    tripId: activity.tripId,
                                    travelTime: activity.travelTime,
                                    travelType: activity.travelType,
                                    coordinates: activity.coordinates,
                                  );
                                  updateActivity(updatedActivity)
                                      .then((_) {
                                        _loadActivities();
                                      })
                                      .catchError((error) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error updating activity: $error',
                                            ),
                                          ),
                                        );
                                      });
                                });
                              }
                            });
                          },
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                            ),
                            child: Text(
                              TimeOfDay.fromDateTime(
                                activity.startTime,
                              ).format(context),
                            ),
                            onPressed: () {
                              showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  activity.startTime,
                                ),
                              ).then((value) {
                                if (value != null) {
                                  setState(() {
                                    DateTime newTime = DateTime(
                                      activity.startTime.year,
                                      activity.startTime.month,
                                      activity.startTime.day,
                                      value.hour,
                                      value.minute,
                                    );
                                    Activity updatedActivity = Activity(
                                      id: activity.id,
                                      name: activity.name,
                                      startDate: activity.startDate,
                                      endDate: activity.endDate,
                                      startTime: newTime,
                                      endTime: activity.endTime,
                                      location: activity.location,
                                      tripId: activity.tripId,
                                      travelTime: activity.travelTime,
                                      travelType: activity.travelType,
                                      coordinates: activity.coordinates,
                                    );
                                    updateActivity(updatedActivity)
                                        .then((_) {
                                          _loadActivities();
                                        })
                                        .catchError((error) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error updating activity: $error',
                                              ),
                                            ),
                                          );
                                        });
                                  });
                                }
                              });
                            },
                          ),
                          Text(' - '),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                            ),
                            child: Text(
                              TimeOfDay.fromDateTime(
                                activity.endTime,
                              ).format(context),
                            ),
                            onPressed: () {
                              showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  activity.endTime,
                                ),
                              ).then((value) {
                                if (value != null) {
                                  setState(() {
                                    DateTime newTime = DateTime(
                                      activity.endTime.year,
                                      activity.endTime.month,
                                      activity.endTime.day,
                                      value.hour,
                                      value.minute,
                                    );
                                    Activity updatedActivity = Activity(
                                      id: activity.id,
                                      name: activity.name,
                                      startDate: activity.startDate,
                                      endDate: activity.endDate,
                                      startTime: activity.startTime,
                                      endTime: newTime,
                                      location: activity.location,
                                      tripId: activity.tripId,
                                      travelTime: activity.travelTime,
                                      travelType: activity.travelType,
                                      coordinates: activity.coordinates,
                                    );
                                    updateActivity(updatedActivity)
                                        .then((_) {
                                          _loadActivities();
                                        })
                                        .catchError((error) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error updating activity: $error',
                                              ),
                                            ),
                                          );
                                        });
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListHeader(int index) {
    // final date = widget.trip.start.add(Duration(days: index));
    return ColoredBox(
      color: const Color.fromARGB(255, 221, 221, 221),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        width: MediaQuery.sizeOf(context).width,
        child: Text('Day ${index + 1}', textAlign: TextAlign.center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // if (_trip_length == 0) {
    //   return Scaffold(
    //     appBar: AppBar(
    //       title: Text(widget.trip.name),
    //       backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    //     ),
    //     body: Center(child: CircularProgressIndicator()),
    //   );
    // }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CalendarView(trip: widget.trip, activities: _activities),
                ),
              );
            },
            icon: Icon(Icons.calendar_view_week),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripEdit(trip: widget.trip),
                ),
              ).then((_) {
                // Reload activities after editing the trip
                _loadActivities();
              });
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverList.builder(
            itemCount: _trip_length,
            itemBuilder: (context, index) {
              return StickyHeader(
                header: _buildListHeader(index),
                content: _buildActivityList(index),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityCreate(trip: widget.trip),
            ),
          ).then((_) {
            // Reload activities after creating a new one
            _loadActivities();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
