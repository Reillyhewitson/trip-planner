import 'package:flutter/material.dart';
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
  final _formkey = GlobalKey<FormState>();

  final name = TextEditingController();
  final location = TextEditingController();
  DateTime start = DateTime.now();
  DateTime end = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Form( key: _formkey, child: Column(
      children: <Widget>[
        TextFormField(
          key: Key("name"),
          decoration: InputDecoration(labelText: 'Trip Name'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a trip name';
            }
            return null;
          },
          controller: name,
        ),
        ListTile(
          key: Key("start"),
          title: Text("Start Date: ${DateFormat.yMd().format(start)}"),
          trailing: Icon(Icons.calendar_today),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: start,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null && picked != start) {
              setState(() {
                start = picked;
              });
            }
          },
        ),
        ListTile(
          key: Key("end"),
          title: Text("End Date: ${DateFormat.yMd().format(end)}"),
          trailing: Icon(Icons.calendar_today),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: end,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null && picked != end) {
              setState(() {
                end = picked;
              });
            }
          },
        ),
        TextFormField(
          key: Key("location"),
          decoration: InputDecoration(labelText: 'Location'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a location';
            }
            return null;
          },
          controller: location,
        ),
        ElevatedButton(
          onPressed: () {
            if (_formkey.currentState!.validate()) {
              _formkey.currentState!.save();
              // Process the data.
              final trip = Trip(
                id: 0, // This will be set by the database
                name: name.text,
                start: start,
                end: end,
                location: location.text,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Processing Data')),
              );
              insertTrip(trip).then((_) {
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

class TripCreate extends StatelessWidget {
  const TripCreate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: TripCreateForm(),
        ),
      ),
    );
  }
}

