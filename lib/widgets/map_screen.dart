import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  final GeoPoint _defaultLocation = GeoPoint(
    latitude: 51.2302,
    longitude: 4.4162,
  ); // Antwerpen

  @override
  void initState() {
    super.initState();
    _mapController = MapController.withPosition(initPosition: _defaultLocation);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OSMFlutter(
        controller: _mapController,
        onMapIsReady: (isReady) {
          if (isReady) {
            // Map is ready
          }
        },
        osmOption: OSMOption(
          // Use OSMOption to configure the map
          zoomOption: ZoomOption(
            initZoom: 10, // You can adjust the initial zoom level
            minZoomLevel: 3,
            maxZoomLevel: 19,
            stepZoom: 1.0,
          ),
          userLocationMarker: UserLocationMaker(
            personMarker: const MarkerIcon(
              icon: Icon(
                Icons.location_history_rounded,
                color: Colors.red,
                size: 48,
              ),
            ),
            directionArrowMarker: const MarkerIcon(
              icon: Icon(Icons.double_arrow, size: 48),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in_button',
            backgroundColor: Colors.deepPurple,
            onPressed: () {
              _mapController.zoomIn();
            },
            child: const Icon(Icons.zoom_in),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'zoom_out_button',
            backgroundColor: Colors.deepPurple,
            onPressed: () {
              _mapController.zoomOut();
            },
            child: const Icon(Icons.zoom_out),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
