import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import "package:trip_planner/data_classes/trip.dart";
import 'package:intl/intl.dart';

class TripCreateForm extends StatefulWidget {
  const TripCreateForm({super.key});

  @override
  TripCreateFormState createState() {
    return TripCreateFormState();
  }
}

class TripCreateFormState extends State<TripCreateForm> {
  final _formkey = GlobalKey<FormBuilderState>();
  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formkey,
      child: Column(
        children: <Widget>[
          FormBuilderTextField(
            name: "name",
            decoration: InputDecoration(labelText: 'Trip Name'),
            validator: FormBuilderValidators.required(),
          ),
          FormBuilderDateRangePicker(
            name: "date_range",
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ),
          FormBuilderTextField(
            name: "location",
            decoration: InputDecoration(labelText: 'Location'),
            validator: FormBuilderValidators.required(),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formkey.currentState!.saveAndValidate()) {
                final formData = _formkey.currentState!.value;
                // Process the data.
                final trip = Trip(
                  id: 0, // This will be set by the database
                  name: formData["name"],
                  start: formData["date_range"].start,
                  end: formData["date_range"].end,
                  location: formData['location'],
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Processing Data')),
                );
                insertTrip(trip)
                    .then((_) {
                      Navigator.pop(context);
                    })
                    .catchError((error) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $error')));
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

class TripCreate extends StatelessWidget {
  const TripCreate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: TripCreateForm()),
      ),
    );
  }
}
