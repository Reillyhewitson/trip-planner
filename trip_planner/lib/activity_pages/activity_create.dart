import 'package:flutter/material.dart';
import 'package:trip_planner/data_classes/activity.dart';
import 'package:intl/intl.dart';
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import 'package:trip_planner/data_classes/trip.dart';

class ActivityCreateForm extends StatefulWidget {
  final Trip trip;

  const ActivityCreateForm({super.key, required this.trip});

  @override
  ActivityCreateFormState createState() {
    return ActivityCreateFormState();
  }
}

class ActivityCreateFormState extends State<ActivityCreateForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          FormBuilderTextField(name: "name", decoration: InputDecoration(labelText: "Activity Name"), validator: FormBuilderValidators.required()),
          FormBuilderDateTimePicker(name: "startDate", decoration: InputDecoration(labelText: "Start Date"), initialValue: widget.trip.start, firstDate: widget.trip.start, lastDate: widget.trip.end, validator: FormBuilderValidators.required(), inputType: InputType.date),
          FormBuilderDateTimePicker(name: "startTime", decoration: InputDecoration(labelText: "Start Time"), initialValue: DateTime.now(), validator: FormBuilderValidators.required(), inputType: InputType.time),
          FormBuilderDateTimePicker(name: "endTime", decoration: InputDecoration(labelText: "End Time"), initialValue: DateTime.now(), validator: FormBuilderValidators.required(), inputType: InputType.time),
          FormBuilderTextField(name: "location", decoration: InputDecoration(labelText: "Location"), validator: FormBuilderValidators.required()),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.saveAndValidate() ?? false) {
                final formData = _formKey.currentState?.value;
                print(formData!['startTime']);
                final activity = Activity(
                  id: 0,
                  name: formData!['name'],
                  startDate: formData!['startDate'],
                  endDate: formData!['startDate'],
                  startTime: formData!['startTime'],
                  endTime: formData!['endTime'],
                  location: formData!['location'],
                  tripId: widget.trip.id,
                );
                insertActivity(activity).then((_) => Navigator.pop(context));
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

class ActivityCreate extends StatelessWidget {
  final Trip trip;

  const ActivityCreate({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Activity"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ActivityCreateForm(trip: trip),
      ),
    );
  }
}