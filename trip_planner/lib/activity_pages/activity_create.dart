import 'package:flutter/material.dart';
import 'package:trip_planner/apis/navigation/navigation.dart';
import 'package:trip_planner/data_classes/activity.dart';
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import 'package:trip_planner/data_classes/trip.dart';
import 'package:trip_planner/apis/photon.dart';
import 'package:trip_planner/debounce/debounce.dart';

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
  DateTime date = DateTime.now();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      date = widget.trip.start;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          FormBuilderTextField(
            name: "name",
            decoration: InputDecoration(labelText: "Activity Name"),
            validator: FormBuilderValidators.required(),
          ),
          FormBuilderDateTimePicker(
            name: "startDate",
            decoration: InputDecoration(labelText: "Start Date"),
            initialValue: widget.trip.start,
            firstDate: widget.trip.start,
            lastDate: widget.trip.end,
            validator: FormBuilderValidators.required(),
            inputType: InputType.date,
            onChanged: (value) => setState(() {
              date = value ?? date;
            }),
          ),
          FormBuilderDateTimePicker(
            name: "startTime",
            decoration: InputDecoration(labelText: "Start Time"),
            initialValue: date,
            validator: FormBuilderValidators.required(),
            inputType: InputType.time,
          ),
          FormBuilderDateTimePicker(
            name: "endTime",
            decoration: InputDecoration(labelText: "End Time"),
            initialValue: date,
            validator: FormBuilderValidators.required(),
            inputType: InputType.time,
          ),
          // FormBuilderTextField(name: "location", decoration: InputDecoration(labelText: "Location"), validator: FormBuilderValidators.required()),
          // _AsyncAutocomplete(key: Key("location"), formKey: _formKey),
          _AsyncAutocomplete(),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.saveAndValidate() ?? false) {
                // _formKey.currentState?.fields["location"]?.didChange(
                //   _autocomplete.selected,
                // );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Text('Finding transit data '),
                        CircularProgressIndicator.adaptive(),
                      ],
                    ),
                  ),
                );
                final formData = _formKey.currentState?.value;
                createActivity(
                  formData,
                  widget.trip,
                  false,
                  context,
                ).then((_) => Navigator.pop(context));
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
  final Activity? previousActivity;

  const ActivityCreate({super.key, required this.trip, this.previousActivity});

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

class _AsyncAutocomplete extends StatefulWidget {
  const _AsyncAutocomplete();
  @override
  State<_AsyncAutocomplete> createState() => _AsyncAutocompleteState();
}

class _AsyncAutocompleteState extends State<_AsyncAutocomplete> {
  String? _currentQuery;
  late Iterable<Feature> _lastOptions = <Feature>[];

  late final Debounceable<List<Feature>?, String> _debouncedSearch;
  static String _displayStringForOption(Feature option) {
    return option.toString();
  }

  bool _networkError = false;
  bool _noFeatures = false;

  List<Feature>? options;

  Future<List<Feature>?> _search(String query) async {
    _currentQuery = query;
    print("searching...");
    late final List<Feature> options;

    try {
      options = await FetchOptions.search(_currentQuery!);
    } on NetworkException {
      if (mounted) {
        setState(() {
          _networkError = true;
        });
      }
      return <Feature>[];
    } on NoFeatures {
      if (mounted) {
        setState(() {
          _noFeatures = true;
        });
      }
      return <Feature>[];
    }

    // If another search happened after this one, throw away these options.
    // if (_currentQuery != query) {
    //   return null;
    // }
    // _currentQuery = null;

    return options;
  }

  @override
  void initState() {
    super.initState();
    _debouncedSearch = debounce<List<Feature>?, String>(_search);
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<Feature>(
      name: "location",
      validator: FormBuilderValidators.required(),
      builder: (FormFieldState field) {
        return Autocomplete<Feature>(
          fieldViewBuilder:
              (
                BuildContext context,
                TextEditingController controller,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted,
              ) {
                return TextFormField(
                  decoration: InputDecoration(
                    errorText: _networkError
                        ? "Network error, please try again"
                        : _noFeatures
                        ? "No Addresses found"
                        : null,
                  ),
                  focusNode: focusNode,
                  controller: controller,
                );
              },

          displayStringForOption: _displayStringForOption,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            setState(() {
              _networkError = false;
              _noFeatures = false;
            });
            final List<Feature>? options = await _debouncedSearch(
              textEditingValue.text,
            );

            if (options == null) {
              return _lastOptions;
            }

            _lastOptions = options.map((Feature feature) => feature);
            return _lastOptions;
          },
          onSelected: (Feature selection) {
            field.didChange(selection);
          },
        );
      },
    );
  }
}
