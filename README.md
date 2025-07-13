# Trip Planner

A flutter based application for planning trips. It allows you to edit times and dates directly from the itinerary and view your itinerary on a calendar view. The application also provides predictions for how long it will take to get between activities to help you plan when an activity should begin.

## Transit Predictions

The application has three ways to provide transit times.

1. (Transitous)[https://transitous.org/]
2. (Google Maps)[https://developers.google.com/maps/documentation/routes]
3. Manual entry

### Transitous

Transitous requires no API key and is a fully open source API. It is the only one that comes preconfigured with the application available here on GitHub.

### Google Maps

To configure Google Maps you will need to install (Dart)[https://dart.dev/]. Once installed create a .env file in the `trip_planner` directory.
Add the `MAPSAPI` key and set the value to your Google Maps API key.

Google maps is now configured as the fallback transit time provider.
Even if Google maps cannot find a transit time it will provide a walk time.

<!-- ## Manual

This is the last resort. If the Google Maps API cannot access a transit route then the Google Maps app may be able to. It provides a way for a user to manually input a transit time to use for predictions.

To enable this create a .env file in the `trip_planner` directory and add the `MANUAL` key and set the value to true. -->
