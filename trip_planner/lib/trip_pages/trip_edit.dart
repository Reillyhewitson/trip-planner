import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import "package:trip_planner/data_classes/trip.dart";
import 'package:intl/intl.dart';
import "package:form_builder_validators/form_builder_validators.dart";

class TripEditForm extends StatefulWidget {
  const TripEditForm({super.key, required this.trip});

  final Trip? trip;

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
    return FormBuilder( key: _formkey, child: Column(
      children: <Widget>[
        FormBuilderTextField(
          name: "name",
          decoration: InputDecoration(labelText: 'Trip Name'),
          initialValue: widget.trip?.name,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a trip name';
            }
            return null;
          },
        ),
        FormBuilderDateRangePicker(
          name: "date_range",
          decoration: InputDecoration(labelText: 'Date Range'),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          initialValue: DateTimeRange(start: widget.trip?.start ?? DateTime.now(), end: widget.trip?.end ?? DateTime.now()),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                start = value.start;
                end = value.end;
              });
            }
          },
        ),
        FormBuilderTextField(
          name: "location",
          decoration: InputDecoration(labelText: 'Location'),
          initialValue: widget.trip?.location,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a location';
            }
            return null;
          },
        ),
        ElevatedButton(
          onPressed: () {
            if (_formkey.currentState!.saveAndValidate() ?? false) {
              final formData = _formkey.currentState!.value;
              // Process the data.
              final trip = Trip(
                id: widget.trip?.id ?? 0, // This will be set by the database
                name: formData['name'] ?? '',
                start: formData['date_range'].start,
                end: formData['date_range'].end,
                location: formData['location'] ?? '',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Processing Data')),
              );
              updateTrip(trip).then((_) {
                Navigator.pop(context);
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $error')),
                );
              });
            }
          },
          child: const Text('Submit'),
        ),
      ],
    ),
    );
  }
}

class TripEdit extends StatelessWidget {
  const TripEdit({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: TripEditForm(trip: trip),
        ),
      ),
    );
  }
}

