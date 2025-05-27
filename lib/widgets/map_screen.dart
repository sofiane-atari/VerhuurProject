import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_verhuur_project/Model/Appliance_model.dart';
import 'package:flutter_verhuur_project/services/location_service.dart';
import 'package:flutter_verhuur_project/services/marker_service.dart';
import 'package:flutter_verhuur_project/widgets/detailscreen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  Map<String, ApplianceModel> _markerItems = {};
  ApplianceModel? _selectedItem;
  bool _showPopup = false;

  final _locationService = LocationService();
  final _markerService = MarkerService();

  @override
  void initState() {
    super.initState();
    _mapController = MapController.withPosition(
      initPosition: LocationService.defaultLocation,
    );

    // Start live tracking zodra de map klaar is
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeLocationTracking();
    });
  }

  Future<void> _initializeLocationTracking() async {
    try {
      bool hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Locatiepermissie geweigerd')),
          );
        }
        return;
      }

      await _mapController.enableTracking();
    } catch (e) {
      print('Fout bij inschakelen tracking: $e');
      try {
        final location = await _locationService.getCurrentLocation();
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
      } catch (e) {
        print('Locatie fout: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Locatie niet beschikbaar')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Map
          Expanded(
            child: OSMFlutter(
              controller: _mapController,
              onGeoPointClicked: (geoPoint) async {
                final nearestItem = _markerService.findNearestItem(geoPoint, _markerItems);
                if (nearestItem != null && mounted) {
                  setState(() {
                    _selectedItem = nearestItem;
                    _showPopup = true;
                  });
                }
              },
              onMapIsReady: (isReady) async {
                if (isReady) {
                  _markerItems = await _markerService.loadMarkers(_mapController);
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
          ),
          // Popup onder de map
          if (_showPopup && _selectedItem != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedItem!.afbeelding.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _selectedItem!.afbeelding,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image, size: 80),
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedItem!.naam,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '€${_selectedItem!.prijs.toStringAsFixed(2)}/${_selectedItem!.eenheid}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      _selectedItem!.isBeschikbaar
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: _selectedItem!.isBeschikbaar ? Colors.green : Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedItem!.isBeschikbaar ? 'Beschikbaar' : 'Niet beschikbaar',
                                      style: TextStyle(
                                        color: _selectedItem!.isBeschikbaar ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showPopup = false;
                                _selectedItem = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              final item = _selectedItem;
                              setState(() {
                                _showPopup = false;
                                _selectedItem = null;
                              });
                              if (item != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailScreen(item: item),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Details'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}