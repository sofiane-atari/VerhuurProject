import 'dart:async';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'dart:js' as js;

class LocationService {
  static final LocationService _instance = LocationService._internal();
  
  factory LocationService() {
    return _instance;
  }
  
  LocationService._internal();

  static GeoPoint get defaultLocation => GeoPoint(
    latitude: 51.2302,
    longitude: 4.4162,
  );

  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
      return true;
    } catch (e) {
      print('Fout bij permissiecontrole: $e');
      return false;
    }
  }

  Future<GeoPoint?> getCurrentLocation() async {
    try {
      // Controleer eerst of de plugin beschikbaar is
      try {
        await Geolocator.getCurrentPosition();
      } on MissingPluginException {
        print('Geolocator plugin niet beschikbaar');
        return await _getLocationWithJavaScript();
      }

      // Controleer locatiediensten
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Locatiediensten uitgeschakeld');
        return null;
      }

      // Controleer permissies
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      // Haal locatie op
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      print('Fout bij ophalen locatie: $e');
      return null;
    }
  }

  Future<GeoPoint?> _getLocationWithJavaScript() async {
    try {
      final completer = Completer<GeoPoint?>();
      js.context.callMethod('navigator.geolocation.getCurrentPosition', [
        (position) {
          final latitude = position['coords']['latitude'] as double;
          final longitude = position['coords']['longitude'] as double;
          completer.complete(
            GeoPoint(latitude: latitude, longitude: longitude),
          );
        },
        (error) {
          completer.complete(null);
        },
      ]);
      return await completer.future;
    } catch (e) {
      print('JavaScript geolocation fout: $e');
      return null;
    }
  }

  double calculateDistance(GeoPoint point1, GeoPoint point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }
} 