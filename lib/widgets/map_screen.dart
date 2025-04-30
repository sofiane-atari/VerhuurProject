import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_verhuur_project/widgets/list.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final double _initialZoom = 13.0;
  String _appBarTitle = 'Selecteer locatie';
  LatLng? _selectedLocation;
  List<Marker> _markers = [];
  final LatLng _defaultLocation = const LatLng(
    51.2302,
    4.4162,
  ); // Antwerpen coördinaten

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _centerToDefaultLocation,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _defaultLocation,
          initialZoom: _initialZoom,
          onTap: (tapPosition, point) => _handleMapTap(point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'list_button',
            backgroundColor: Colors.deepPurple,
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ListViewScreen()),
                ),
            child: const Icon(Icons.list),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'zoom_button',
            backgroundColor: Colors.deepPurple,
            onPressed: _zoomIn,
            child: const Icon(Icons.zoom_in),
          ),
        ],
      ),
    );
  }

  void _handleMapTap(LatLng point) {
    setState(() {
      _selectedLocation = point;
      _appBarTitle =
          'Geselecteerd: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      _markers = [
        Marker(
          point: point,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
        ),
      ];
    });
  }

  void _centerToDefaultLocation() {
    _mapController.move(_defaultLocation, _initialZoom);
    setState(() {
      _appBarTitle = 'Selecteer locatie';
      _markers = [];
      _selectedLocation = null;
    });
  }

  void _zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + 1,
    );
  }
}
