import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:trip_planner/data_classes/activity.dart';
import 'package:trip_planner/data_classes/trip.dart';
import 'package:trip_planner/activity_pages/activity_create.dart';
import 'package:sticky_headers/sticky_headers.dart';

class TripView extends StatefulWidget{
  const TripView({super.key, required this.trip});

  final Trip trip;

  @override
  TripViewState createState() {
    return TripViewState();
  }
}

class TripViewState extends State<TripView> {
  final List<Activity> _activities = [];
  @override
  void initState() {
    super.initState();
    _loadActivities();
    // Initialize any data or state here if needed
  }

  Future<void> _loadActivities() async {
    // Load activities for the trip
    final activities = await getActivities(widget.trip.id);
    print(activities.toString());
    setState(() {
      _activities.addAll(activities);
    });
  }

  Widget _buildActivityList(int index) {
    final dayActivities = _activities.where((activity) => activity.startDate == widget.trip.start.add(Duration(days: index))).toList();

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
      itemBuilder: (context, index) {
        final activity = dayActivities[index];
        return ListTile(
          title: Text(activity.name),
          subtitle: Text('From ${DateFormat.yMd().format(activity.startDate)} ${activity.startTime.format(context)} to ${activity.endTime.format(context)}'),
          onTap: () {
                  // Handle tap on the trip item.
                  print('Tapped on trip ${widget.trip.id}');
                },
              );
            },
          );
        }

  Widget _buildListHeader(int index) {
    final date = widget.trip.start.add(Duration(days: index));
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Text(DateFormat.yMd().format(date)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return 
      Scaffold(
        appBar: AppBar(
          title: Text(widget.trip.name),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.trip.end.difference(widget.trip.start).inDays + 1,
          itemBuilder: (context, index) {
            return StickyHeader(
              header: _buildListHeader(index),
              content: _buildActivityList(index),
            );
          },
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