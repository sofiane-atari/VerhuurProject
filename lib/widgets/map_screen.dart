import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:js' as js;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key}) : super();

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  final GeoPoint _defaultLocation = GeoPoint(
    latitude: 51.2302,
    longitude: 4.4162,
  );

  @override
  void initState() {
    super.initState();
    _mapController = MapController.withPosition(initPosition: _defaultLocation);

    // Start live tracking zodra de map klaar is
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeLocationTracking();
    });
  }

  Future<void> _initializeLocationTracking() async {
    try {
      // Controleer locatiepermissies
      bool hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Locatiepermissie geweigerd')),
          );
        }
        return;
      }

      // Probeer tracking met flutter_osm_plugin
      await _mapController.enableTracking();
    } catch (e) {
      print('Fout bij inschakelen tracking: $e');
      // Fallback naar JavaScript voor web
      try {
        final location = await _getLocationWithJavaScript();
        if (location != null && mounted) {
          await _mapController.addMarker(
            location,
            markerIcon: const MarkerIcon(
              icon: Icon(
                Icons.location_history_rounded,
                color: Colors.green,
                size: 48,
              ),
            ),
          );
          await _mapController.moveTo(location);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kon locatie niet ophalen')),
          );
        }
      } catch (jsError) {
        print('JavaScript locatie fout: $jsError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Locatie niet beschikbaar')),
          );
        }
      }
    }
  }

  Future<bool> _requestLocationPermission() async {
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          OSMFlutter(
            controller: _mapController,
            onMapIsReady: (isReady) {
              if (isReady) {
                // Kaart is klaar
              }
            },
            osmOption: OSMOption(
              isPicker: false,
              zoomOption: ZoomOption(
                initZoom: 12,
                minZoomLevel: 3,
                maxZoomLevel: 19,
                stepZoom: 1.0,
              ),
              userLocationMarker: UserLocationMaker(
                personMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.location_history_rounded,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                directionArrowMarker: const MarkerIcon(
                  icon: Icon(Icons.double_arrow, size: 48),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
