import 'package:flutter/material.dart';
import 'package:flutter_verhuur_project/Model/Appliance_model.dart'; // Importeer je ApplianceModel
import 'package:cloud_firestore/cloud_firestore.dart'; // Importeer Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Importeer FirebaseAuth
import 'package:geolocator/geolocator.dart';

class DetailScreen extends StatefulWidget {
  final ApplianceModel item;

  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instantie
  String?
  _currentUserId; // Toegevoegd: Om de ID van de huidige huurder op te slaan
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    // Haal de ID van de momenteel ingelogde gebruiker op
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _determinePosition();
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
        _locationError = 'Locatietoestemmingen zijn permanent geweigerd.';
        _isLoadingLocation = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
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

  String _getDistanceText() {
    if (_isLoadingLocation) {
      return 'Locatie wordt opgehaald...';
    }
    if (_locationError != null) {
      return 'Kon afstand niet berekenen';
    }
    if (_currentPosition != null && widget.item.locatie != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        (widget.item.locatie as GeoPoint).latitude,
        (widget.item.locatie as GeoPoint).longitude,
      );
      // Convert to kilometers and round to 1 decimal place
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km van jou';
    }
    return 'Locatie onbekend';
  }

  // Functie om een item te huren
  Future<void> _rentItem() async {
    // Controleer of het item-ID beschikbaar is
    if (widget.item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kan item niet huren: ID ontbreekt.')),
      );
      return;
    }

    // Controleer of er een gebruiker is ingelogd
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('U moet ingelogd zijn om een item te huren.'),
        ),
      );
      return;
    }

    // Bereken de nieuwe reservedUntil datum (1 week vanaf nu)
    DateTime newReservedUntil = DateTime.now().add(const Duration(days: 7));

    try {
      // Update het Firestore-document van het item
      await _firestore.collection('apparaten').doc(widget.item.id).update({
        'isBeschikbaar': false, // Markeer als niet beschikbaar
        'reservedUntil': Timestamp.fromDate(
          newReservedUntil,
        ), // Stel de reserveringsdatum in
        'huurderId': _currentUserId, // Voeg de ID van de huurder toe
      });

      // Optioneel: update de lokale state van het item direct na de update
      // Dit zorgt voor een snellere UI-update zonder opnieuw te hoeven laden
      setState(() {
        widget.item.isBeschikbaar = false;
        widget.item.reservedUntil = newReservedUntil;
        widget.item.huurderId =
            _currentUserId; // Update ook lokaal de huurderId
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.item.naam} is succesvol gehuurd voor 1 week!',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fout bij huren van ${widget.item.naam}: ${e.toString()}',
          ),
        ),
      );
      print('Error renting item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bepaal of het item momenteel beschikbaar is
    bool isCurrentlyAvailable =
        widget.item.isBeschikbaar &&
        (widget.item.reservedUntil == null ||
            widget.item.reservedUntil!.isBefore(DateTime.now()));

    // De huurknop is alleen zichtbaar als het item beschikbaar is EN de huidige gebruiker is ingelogd
    bool showRentButton = isCurrentlyAvailable && _currentUserId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.naam), // Toon de naam van het item in de AppBar
        backgroundColor: Colors.deepPurple, // Consistent met je appbar thema
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Afbeelding van het item
            if (widget.item.afbeelding.isNotEmpty)
              Center(
                child: Image.network(
                  widget.item.afbeelding,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 100,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.photo, size: 100, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),

            // Naam van het item
            Text(
              widget.item.naam,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),

            // Prijs en eenheid
            Text(
              'Prijs: €${widget.item.prijs}/${widget.item.eenheid}',
              style: const TextStyle(fontSize: 20, color: Colors.black87),
            ),
            const SizedBox(height: 8),

            // Locatie met afstand
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Locatie:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDistanceText(),
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Staat
            Text(
              'Staat: ${widget.item.staat}',
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 8),

            // Beschikbaarheid
            Row(
              children: [
                Icon(
                  isCurrentlyAvailable
                      ? Icons.check_circle
                      : Icons.remove_circle,
                  color: isCurrentlyAvailable ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isCurrentlyAvailable ? 'Beschikbaar' : 'Niet beschikbaar',
                  style: TextStyle(
                    fontSize: 18,
                    color: isCurrentlyAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (!isCurrentlyAvailable && widget.item.reservedUntil != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Gereserveerd tot: ${widget.item.reservedUntil!.day}-${widget.item.reservedUntil!.month}-${widget.item.reservedUntil!.year}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            if (!isCurrentlyAvailable && widget.item.huurderId != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Huurder ID: ${widget.item.huurderId}',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
                ),
              ),
            const SizedBox(height: 16),

            // Genres
            if (widget.item.genre.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Genres:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children:
                        widget.item.genre
                            .map(
                              (category) => Chip(
                                label: Text(category),
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                                backgroundColor: Colors.deepPurple[300],
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Huur knop
            ElevatedButton(
              onPressed:
                  showRentButton
                      ? _rentItem
                      : null, // Schakel knop uit indien niet beschikbaar of geen gebruiker ingelogd
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    showRentButton
                        ? Colors.deepPurple
                        : Colors.grey, // Kleur op basis van beschikbaarheid
                foregroundColor: Colors.white,
                minimumSize: const Size(
                  double.infinity,
                  50,
                ), // Volle breedte knop
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
              child: Text(
                showRentButton ? 'Huur dit item' : 'Niet beschikbaar',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
