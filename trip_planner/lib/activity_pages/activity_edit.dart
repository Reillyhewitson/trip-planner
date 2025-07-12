import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import "package:trip_planner/data_classes/trip.dart";
import 'package:intl/intl.dart';
import "package:form_builder_validators/form_builder_validators.dart";
import 'package:trip_planner/data_classes/activity.dart';

class TripEditForm extends StatefulWidget {
  const TripEditForm({super.key, required this.trip, required this.activity});

  final Trip trip;
  final Activity activity;

  @override
  TripEditFormState createState() {
    return TripEditFormState();
  }
}

class TripEditFormState extends State<TripEditForm> {
  final _formkey = GlobalKey<FormBuilderState>();

  DateTime start = DateTime.now();
  DateTime end = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formkey,
      child: Column(
        children: <Widget>[
          FormBuilderTextField(
            name: "name",
            decoration: InputDecoration(labelText: "Activity Name"),
            initialValue: widget.activity?.name,
            validator: FormBuilderValidators.required(),
          ),
          FormBuilderDateTimePicker(
            name: "startDate",
            decoration: InputDecoration(labelText: "Start Date"),
            initialValue: widget.activity?.startDate,
            firstDate: widget.trip?.start,
            lastDate: widget.trip?.end,
            validator: FormBuilderValidators.required(),
            inputType: InputType.date,
          ),
          FormBuilderDateTimePicker(
            name: "startTime",
            decoration: InputDecoration(labelText: "Start Time"),
            initialValue: widget.activity?.startTime,
            validator: FormBuilderValidators.required(),
            inputType: InputType.time,
          ),
          FormBuilderDateTimePicker(
            name: "endTime",
            decoration: InputDecoration(labelText: "End Time"),
            initialValue: widget.activity?.endTime,
            validator: FormBuilderValidators.required(),
            inputType: InputType.time,
          ),
          FormBuilderTextField(
            name: "location",
            decoration: InputDecoration(labelText: "Location"),
            initialValue: widget.activity?.location,
            validator: FormBuilderValidators.required(),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formkey.currentState?.saveAndValidate() ?? false) {
                final formData = _formkey.currentState?.value;
                if (formData!["location"] != widget.activity.location) {
                  createActivity(
                    formData,
                    widget.trip,
                    true,
                  ).then((_) => Navigator.pop(context));
                }
                final activity = Activity(
                  id: widget.activity.id,
                  name: formData['name'],
                  startDate: formData['startDate'],
                  endDate: formData['startDate'],
                  startTime: formData['startTime'],
                  endTime: formData['endTime'],
                  location: widget.activity.location,
                  tripId: widget.trip.id,
                  coordinates: widget.activity.coordinates,
                  travelTime: widget.activity.travelTime,
                  travelType: widget.activity.travelType,
                );
                updateActivity(activity).then((_) => Navigator.pop(context));
                // Save the activity to the database
              }
            },
            child: Text('Create Activity'),
          ),
        ],
      ),
    );
  }
}

class TripEdit extends StatelessWidget {
  const TripEdit({super.key, required this.trip, required this.activity});

  final Trip trip;
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: TripEditForm(trip: trip, activity: activity),
        ),
      ),
    );
  }
}
