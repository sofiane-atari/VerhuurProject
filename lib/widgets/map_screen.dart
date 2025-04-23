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
  double _currentZoom = 13.0;
  String _appBarTitle = 'Klik op de map';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        backgroundColor: Colors.deepPurple,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(51.2302, 4.4162),
          initialZoom: _currentZoom,
          onTap: (tapPosition, point) => _updateLocation(point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'edu.ap.flutter_verhuur_project',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.list),
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ListViewScreen()),
          );
        },
      ),
    );
  }

  void _updateLocation(LatLng point) {
    setState(() {
      _appBarTitle = 'Lat: ${point.latitude}, Lon: ${point.longitude}';
    });
  }
}
