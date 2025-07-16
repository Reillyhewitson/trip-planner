import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trip_planner/calendar_view/calendarDetail.dart';
import 'package:trip_planner/data_classes/activity.dart';
import 'package:trip_planner/data_classes/trip.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key, required this.trip, required this.activities});
  final Trip trip;
  final List<Activity> activities;

  @override
  CalendarViewState createState() {
    return CalendarViewState();
  }
}

class CalendarViewState extends State<CalendarView> {
  bool weekView = true;

  @override
  Widget build(BuildContext context) {
    EventController events = EventController();

    for (Activity activity in widget.activities) {
      final event = CalendarEventData(
        title: activity.name,
        date: activity.startDate,
        startTime: DateTime(
          activity.startDate.year,
          activity.startDate.month,
          activity.startDate.day,
          activity.startTime.hour,
          activity.startTime.minute,
        ),
        endTime: DateTime(
          activity.endDate.year,
          activity.endDate.month,
          activity.endDate.day,
          activity.endTime.hour,
          activity.endTime.minute,
        ),
        endDate: activity.endDate,
        description: activity.location,
        event: activity.id,
      );
      events.add(event);
    }

    return CalendarControllerProvider(
      controller: events,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.trip.name),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  weekView = !weekView;
                });
              },
              icon: weekView
                  ? Icon(Icons.calendar_view_day)
                  : Icon(Icons.calendar_view_week),
            ),
          ],
        ),
        body: weekView
            ? WeekView(
                initialDay: DateTime.now().isAfter(widget.trip.start)
                    ? DateTime.now()
                    : widget.trip.start,
                minDay: widget.trip.start,
                maxDay: widget.trip.end,
                startDay: WeekDays.monday,
                onEventTap: (events, date) => showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    CalendarEventData event = events
                        .where((event) => event.date == date)
                        .toList()[0];
                    return Calendardetail(event: event, date: date);
                  },
                ),
                heightPerMinute: 2,
                eventTileBuilder:
                    (date, events, boundary, startDuration, endDuration) =>
                        _buildEventTile(
                          date,
                          events,
                          boundary,
                          startDuration,
                          endDuration,
                        ),
              )
            : DayView(
                initialDay: DateTime.now().isAfter(widget.trip.start)
                    ? DateTime.now()
                    : widget.trip.start,
                minDay: widget.trip.start,
                maxDay: widget.trip.end,
                heightPerMinute: 1,
                eventTileBuilder:
                    (date, events, boundary, startDuration, endDuration) =>
                        _buildEventTile(
                          date,
                          events,
                          boundary,
                          startDuration,
                          endDuration,
                        ),
                onEventTap: (events, date) => showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    CalendarEventData event = events
                        .where((event) => event.date == date)
                        .toList()[0];

                    return Calendardetail(event: event, date: date);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildEventTile(
    DateTime date,
    List<CalendarEventData> events,
    Rect boundary,
    DateTime startDuration,
    DateTime endDuration,
  ) {
    return RoundedEventTile(
      title: events
          .where(
            (event) => event.startTime == startDuration && event.date == date,
          )
          .toList()[0]
          .title,
      titleStyle: TextStyle(height: 1, color: Colors.white),
      borderRadius: BorderRadius.all(Radius.circular(5)),
      padding: EdgeInsets.all(2),
    );
  }
}
