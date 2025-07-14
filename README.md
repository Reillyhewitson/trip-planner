# Trip Planner

A Flutter based application for planning trips. It allows you to edit times and dates directly from the itinerary and view your itinerary on a calendar view. The application also provides predictions for how long it will take to get between activities to help you plan when an activity should begin.

## Transit Predictions

The application has three ways to provide transit times.

1. [Transitous](https://transitous.org/)
2. [Google Maps](https://developers.google.com/maps/documentation/routes)
3. [Navitime](https://api-sdk.navitime.co.jp/api/specs/index.html) (For Japan only)

### Transitous

Transitous requires no API key and is a fully open source API. It is the only one that comes preconfigured with the application available here on GitHub.

### Google Maps

To configure Google Maps you will need to install [Dart](https://dart.dev/). Once installed create a .env file in the `trip_planner` directory.
Add the `MAPSAPI` key and set the value to your Google Maps API key.

Run `dart pub install`  
Run `dart run build_runner build`

Google maps is now configured as the fallback transit time provider.
Even if Google maps cannot find a transit time it will provide a walk time.

Then follow the instructions in [build](#build)

### Navitime

To configure Navitime you will need to install [Dart](https://dart.dev/). Once installed create a .env file in the `trip_planner` directory.
Add the `NAVITIME` key and set the value to your Navitime API key.

Run `dart pub install`  
Run `dart run build_runner build`

Navitime only provides transit routing within Japan, and outside Tokyo. You will need to sign up to [NAVITIME Route(totalnavi) API via rapidapi](https://rapidapi.com/navitimejapan-navitimejapan/api/navitime-route-totalnavi) if you want to use this. They have a free tier that allows up to 500 calls a month.

> If you do not have the Google Maps API you will **not** get walking times outside of Tokyo. The Navitime transit time getter uses Google Maps for walking routes as this is not provided by Navitime.
