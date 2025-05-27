import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter_verhuur_project/Model/Appliance_model.dart';
import 'package:geolocator/geolocator.dart';

class MarkerService {
  static final MarkerService _instance = MarkerService._internal();
  
  factory MarkerService() {
    return _instance;
  }
  
  MarkerService._internal();

  Future<Map<String, ApplianceModel>> loadMarkers(MapController mapController) async {
    final Set<GeoPoint> currentMarkers = {};
    final Map<String, ApplianceModel> markerItems = {};

    try {
      // Verwijder bestaande markers
      for (var marker in currentMarkers) {
        await mapController.removeMarker(marker);
      }
      currentMarkers.clear();
      markerItems.clear();

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
          
          await mapController.addMarker(
            markerPoint,
            markerIcon: MarkerIcon(
              icon: Icon(
                Icons.location_on,
                color: item.isBeschikbaar ? Colors.red : Colors.grey,
                size: 48,
              ),
            ),
          );
          
          currentMarkers.add(markerPoint);
          markerItems['${markerPoint.latitude},${markerPoint.longitude}'] = item;
        }
      }

      return markerItems;
    } catch (e) {
      print('Fout bij laden markers: $e');
      return {};
    }
  }

  ApplianceModel? findNearestItem(
    GeoPoint clickedPoint,
    Map<String, ApplianceModel> markerItems,
  ) {
    ApplianceModel? nearestItem;
    double smallestDistance = double.infinity;

    for (var entry in markerItems.entries) {
      final coords = entry.key.split(',');
      final markerLat = double.parse(coords[0]);
      final markerLng = double.parse(coords[1]);
      
      final distance = Geolocator.distanceBetween(
        clickedPoint.latitude,
        clickedPoint.longitude,
        markerLat,
        markerLng,
      );
      
      if (distance < smallestDistance) {
        smallestDistance = distance;
        nearestItem = entry.value;
      }
    }

    return nearestItem;
  }
} 