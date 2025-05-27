import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_verhuur_project/Model/Appliance_model.dart';
import 'package:flutter_verhuur_project/widgets/detailscreen.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator

class ListViewScreen extends StatefulWidget {
  ListViewScreen({super.key});

  @override
  State<ListViewScreen> createState() => _ListViewScreenState();
}

class _ListViewScreenState extends State<ListViewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Position? _currentPosition; // To store the user's current location
  bool _isLoadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _determinePosition(); // Start fetching the user's location
  }

  // Function to determine the user's position
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationError = 'Locatieservices zijn uitgeschakeld.';
        _isLoadingLocation = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Locatietoestemmingen zijn geweigerd.';
          _isLoadingLocation = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationError =
            'Locatietoestemmingen zijn permanent geweigerd, we kunnen geen locatie ophalen.';
        _isLoadingLocation = false;
      });
      return;
    }

    // When permissions are granted, fetch the position.
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Add a timeout
      );
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Fout bij het ophalen van de locatie: ${e.toString()}';
        _isLoadingLocation = false;
      });
      print('Location error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apparaten'),
        backgroundColor: Colors.deepPurple,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurpleAccent, Colors.blue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildItems(context),
      ),
    );
  }

  Widget _buildItems(BuildContext context) {
    if (_isLoadingLocation) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_locationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _locationError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _determinePosition,
                child: const Text('Locatie opnieuw proberen'),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('apparaten').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Er is een fout opgetreden: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Er zijn nog geen apparaten beschikbaar.'),
          );
        }

        List<ApplianceModel> items =
            snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return ApplianceModel(
                id: doc.id,
                naam: data['Naam'] ?? '',
                afbeelding: data['afbeelding'] ?? '',
                prijs: data['prijs']?.toDouble() ?? 0.0,
                eenheid: data['eenheid'] ?? '',
                isBeschikbaar: data['isBeschikbaar'] ?? false,
                // Locatie kan een GeoPoint zijn, dus direct casten
                locatie: data['locatie'] is GeoPoint ? data['locatie'] : null,
                genre: List<String>.from(data['genre'] ?? []),
                staat: data['staat'] ?? '',
                eigenaarId: data['eigenaarId'] ?? '',
                huurderId: data['huurderId'] as String?,
              );
            }).toList();

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildItemCard(context, item);
          },
        );
      },
    );
  }

  Widget _buildItemCard(BuildContext context, ApplianceModel item) {
    String distanceText = 'Locatie onbekend';
    if (_currentPosition != null && item.locatie != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        (item.locatie as GeoPoint).latitude,
        (item.locatie as GeoPoint).longitude,
      );
      // Convert to kilometers and round to 1 decimal place
      double distanceInKm = distanceInMeters / 1000;
      distanceText = '${distanceInKm.toStringAsFixed(1)} km van jou';
    } else if (item.locatie != null) {
      // If the user has no location, but the item has a GeoPoint
      distanceText = 'Locatie beschikbaar';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: ListTile(
        leading: SizedBox(
          width: 80,
          height: 80,
          child:
              item.afbeelding.isNotEmpty
                  ? Image.network(
                    item.afbeelding,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image_not_supported_outlined,
                        size: 50,
                      );
                    },
                  )
                  : const Icon(Icons.image_outlined, size: 50),
        ),
        title: Text(
          item.naam,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prijs: €${item.prijs}/${item.eenheid}'),
            Text('Afstand: $distanceText'), // Display the calculated distance
            if (item.genre.isNotEmpty) Text('Genre: ${item.genre.join(', ')}'),
            Text('Staat: ${item.staat}'),
            Row(
              children: [
                Icon(
                  item.isBeschikbaar ? Icons.check_circle : Icons.remove_circle,
                  color: item.isBeschikbaar ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(item.isBeschikbaar ? 'Beschikbaar' : 'Niet beschikbaar'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DetailScreen(item: item)),
          );
        },
      ),
    );
  }
}
