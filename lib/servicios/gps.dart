import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
//import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mapToolKit;
import 'package:maps_toolkit/src/kalman_filter.dart' as kalmanFilter;
import 'package:maps_toolkit/src/location.dart' as mapToolKitLocation;
import 'package:maps_toolkit/src/latlng.dart' as mapToolKitLatLng;
import 'dart:math';
import 'package:geolocator/geolocator.dart';

class GpsProvider with ChangeNotifier {
  Geolocator location = new Geolocator();

  bool locationDataInitialized = false;
  late bool serviceEnabled;
  late LocationPermission permission;
  Position locationData = Position(
      altitudeAccuracy: 0,
      headingAccuracy: 0,
      latitude: 0,
      longitude: 0,
      accuracy: 0,
      altitude: 0,
      speed: 0,
      speedAccuracy: 0,
      heading: 0,
      timestamp: DateTime.now());
  Position locationDataLast = Position(
      altitudeAccuracy: 0,
      headingAccuracy: 0,
      latitude: 0,
      longitude: 0,
      accuracy: 0,
      altitude: 0,
      speed: 0,
      speedAccuracy: 0,
      heading: 0,
      timestamp: DateTime.now());
  Position currentLocation = Position(
      altitudeAccuracy: 0,
      headingAccuracy: 0,
      latitude: 0,
      longitude: 0,
      accuracy: 0,
      altitude: 0,
      speed: 0,
      speedAccuracy: 0,
      heading: 0,
      timestamp: DateTime.now());
  /*
  late PermissionStatus permissionGranted;
  late LocationData locationData;
  late LocationData locationDataLast;
  */

  double PI = 3.141592653589793238;

  Future<bool> iniGPS() async {
    if (locationDataInitialized) {
      return true;
    }

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When

    serviceEnabled = true;

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    if(locationData.altitude==0){
      locationData = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    }
    locationDataLast = locationData;
    locationDataInitialized = true;
    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      print(position == null
          ? 'Unknown'
          : '${position.latitude.toString()}, ${position.longitude.toString()}');

      currentLocation = position!;
      locationDataLast = locationData;
      locationData = currentLocation;
      notifyListeners();
    });

/*
    location.changeSettings(
        accuracy: LocationAccuracy.high, interval: 1000, distanceFilter: 0);
    locationData = await location.getLocation();
    locationDataLast = locationData;
    locationDataInitialized = true;
    location.onLocationChanged.listen((LocationData currentLocation) {
      locationDataLast = locationData;
      locationData = currentLocation;
      notifyListeners();
    });
    */
    return true;
  }

  num distancePointToLine(LatLng p, LatLng start, LatLng end) {
    final distance = mapToolKit.PolygonUtil.distanceToLine(
        mapToolKit.LatLng(p.latitude, p.longitude),
        mapToolKit.LatLng(start.latitude, start.longitude),
        mapToolKit.LatLng(end.latitude, end.longitude));
    return distance; //metros
  }

  num anglePointToPoint(LatLng start, LatLng end) {
    num heading = mapToolKit.SphericalUtil.computeHeading(
        mapToolKit.LatLng(start.latitude, start.longitude),
        mapToolKit.LatLng(end.latitude, end.longitude));
    heading = heading;
    return heading; //angle * earthRadius;
  }

  LatLng centerAhead(LatLng start, LatLng end) {
    mapToolKit.LatLng point = mapToolKit.SphericalUtil.interpolate(
        mapToolKit.LatLng(start.latitude, start.longitude),
        mapToolKit.LatLng(end.latitude, end.longitude),
        .5);
    return LatLng(point.latitude, point.longitude); //angle * earthRadius;
  }

  LatLng getKalmanLocation() {
    var locationCurrent = mapToolKitLocation.Location(
        latlng: mapToolKitLatLng.LatLng(
            locationData.latitude, locationData.longitude),
        accuracy: locationData.accuracy,
        time: locationData.timestamp);

    var locationBefore = mapToolKitLocation.Location(
        latlng: mapToolKitLatLng.LatLng(
            locationDataLast.latitude, locationDataLast.longitude),
        accuracy: locationDataLast.accuracy,
        time: locationDataLast.timestamp);

    var diffKalman =
        kalmanFilter.KalmanFilter.apply(locationCurrent, locationBefore, 1);

    var myLocation = LatLng(
        locationCurrent.latlng.latitude + diffKalman.latlng.latitude,
        locationCurrent.latlng.longitude + diffKalman.latlng.longitude);

    return myLocation;
  }

  double degreeToRadian(double degree) {
    return degree * PI / 180;
  }

  double radianToDegree(double radian) {
    return radian * 180 / PI;
  }
}
