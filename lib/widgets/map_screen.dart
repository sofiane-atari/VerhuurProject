import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:js' as js;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter_verhuur_project/Model/Appliance_model.dart';
import 'package:flutter_verhuur_project/widgets/detailscreen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key}) : super();

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  final Set<GeoPoint> _currentMarkers = {};
  Map<String, ApplianceModel> _markerItems = {};
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

  void _showItemDetails(ApplianceModel item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (item.afbeelding.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.afbeelding,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 80),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.naam,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('€${item.prijs}/${item.eenheid}'),
                      Row(
                        children: [
                          Icon(
                            item.isBeschikbaar
                                ? Icons.check_circle
                                : Icons.remove_circle,
                            color: item.isBeschikbaar ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.isBeschikbaar
                                ? 'Beschikbaar'
                                : 'Niet beschikbaar',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Sluit bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(item: item),
                  ),
                );
              },
              child: const Text('Meer details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Map neemt alle beschikbare ruimte in behalve wanneer er een popup is
          Expanded(
            flex: _showPopup ? 3 : 1,
            child: OSMFlutter(
              controller: _mapController,
              onGeoPointClicked: (geoPoint) async {
                // Zoek alle items binnen 50 meter
                List<ApplianceModel> nearbyItems = [];
                
                for (var entry in _markerItems.entries) {
                  final coords = entry.key.split(',');
                  final markerLat = double.parse(coords[0]);
                  final markerLng = double.parse(coords[1]);
                  
                  final distance = Geolocator.distanceBetween(
                    geoPoint.latitude,
                    geoPoint.longitude,
                    markerLat,
                    markerLng,
                  );
                  
                  if (distance < 50) {
                    nearbyItems.add(entry.value);
                  }
                }
                
                if (nearbyItems.isNotEmpty && mounted) {
                  setState(() {
                    _nearbyItems = nearbyItems;
                    _selectedItemIndex = 0;
                    _showPopup = true;
                  });
                }
              },
              onMapIsReady: (isReady) async {
                if (isReady) {
                  await _loadMarkers();
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
          if (_showPopup && _nearbyItems.isNotEmpty)
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
                      if (_nearbyItems.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Item ${_selectedItemIndex + 1} van ${_nearbyItems.length}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_nearbyItems.length > 1)
                            IconButton(
                              onPressed: _selectedItemIndex > 0
                                  ? () {
                                      setState(() {
                                        _selectedItemIndex--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                              color: Colors.deepPurple,
                            ),
                          if (_nearbyItems[_selectedItemIndex].afbeelding.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _nearbyItems[_selectedItemIndex].afbeelding,
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
                                  _nearbyItems[_selectedItemIndex].naam,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '€${_nearbyItems[_selectedItemIndex].prijs.toStringAsFixed(2)}/${_nearbyItems[_selectedItemIndex].eenheid}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      _nearbyItems[_selectedItemIndex].isBeschikbaar
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: _nearbyItems[_selectedItemIndex].isBeschikbaar ? Colors.green : Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _nearbyItems[_selectedItemIndex].isBeschikbaar ? 'Beschikbaar' : 'Niet beschikbaar',
                                      style: TextStyle(
                                        color: _nearbyItems[_selectedItemIndex].isBeschikbaar ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (_nearbyItems.length > 1)
                            IconButton(
                              onPressed: _selectedItemIndex < _nearbyItems.length - 1
                                  ? () {
                                      setState(() {
                                        _selectedItemIndex++;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                              color: Colors.deepPurple,
                            ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showPopup = false;
                                _nearbyItems = [];
                                _selectedItemIndex = 0;
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
                              final item = _nearbyItems[_selectedItemIndex];
                              setState(() {
                                _showPopup = false;
                                _nearbyItems = [];
                                _selectedItemIndex = 0;
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailScreen(item: item),
                                ),
                              );
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

  // State variabelen
  List<ApplianceModel> _nearbyItems = [];
  int _selectedItemIndex = 0;
  bool _showPopup = false;

  Future<void> _loadMarkers() async {
    try {
      // Verwijder bestaande markers
      for (var marker in _currentMarkers) {
        await _mapController.removeMarker(marker);
      }
      _currentMarkers.clear();
      _markerItems.clear();

      // Haal items op uit Firestore
      final snapshot = await firestore.FirebaseFirestore.instance
          .collection('apparaten')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final locatie = data['locatie'] as firestore.GeoPoint?;
        
        if (locatie != null) {
          final markerPoint = GeoPoint(
            latitude: locatie.latitude,
            longitude: locatie.longitude,
          );

          final item = ApplianceModel(
            id: doc.id,
            naam: data['Naam'] ?? '',
            afbeelding: data['afbeelding'] ?? '',
            prijs: data['prijs']?.toDouble() ?? 0.0,
            eenheid: data['eenheid'] ?? '',
            isBeschikbaar: data['isBeschikbaar'] ?? false,
            locatie: locatie,
            genre: List<String>.from(data['genre'] ?? []),
            staat: data['staat'] ?? '',
            eigenaarId: data['eigenaarId'] ?? '',
          );
          
          await _mapController.addMarker(
            markerPoint,
            markerIcon: MarkerIcon(
              icon: Icon(
                Icons.location_on,
                color: item.isBeschikbaar ? Colors.red : Colors.grey,
                size: 48,
              ),
            ),
          );
          
          _currentMarkers.add(markerPoint);
          _markerItems['${markerPoint.latitude},${markerPoint.longitude}'] = item;
        }
      }
    } catch (e) {
      print('Fout bij laden markers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kon markers niet laden: $e')),
        );
      }
    }
  }
}