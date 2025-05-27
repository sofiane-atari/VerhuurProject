import 'dart:typed_data';

import 'package:flutter/src/material/icons.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_verhuur_project/Model/Appliance_model.dart';
import 'package:geolocator/geolocator.dart';

class Dashboard extends StatefulWidget {
  final User? user;
  final VoidCallback? onSignOut;
  const Dashboard({super.key, this.user, this.onSignOut});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Gebruik de user parameter van de widget
    _currentUserId = widget.user?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Mijn Items'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Reserveringen'),
            Tab(icon: Icon(Icons.settings), text: 'Instellingen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyItems(), // Deze functie haalt nu de items van de gebruiker op
          _buildReservations(),
          _buildSettings(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMyItems() {
    // Controleer of de gebruiker is ingelogd
    if (_currentUserId == null) {
      return const Center(
        child: Text('Je moet ingelogd zijn om je items te zien.'),
      );
    }

    // Stream om de apparaten van de huidige gebruiker op te halen
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection(
                'apparaten',
              ) // Zorg ervoor dat dit de juiste collectienaam is
              .where(
                'eigenaarId',
                isEqualTo: _currentUserId,
              ) // Filter op eigenaarId
              .snapshots(),
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
            child: Text('Je hebt nog geen items toegevoegd.'),
          );
        }

        // Map de documenten naar ApplianceModel objecten
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
                locatie:
                    data['locatie'] is GeoPoint
                        ? data['locatie'] as GeoPoint
                        : const GeoPoint(0, 0), // Fallback voor locatie
                genre: List<String>.from(data['genre'] ?? []),
                staat: data['staat'] ?? '',
                eigenaarId: data['eigenaarId'] ?? '',
              );
            }).toList();

        // Gebruik een ListView.builder of GridView.builder om de items weer te geven
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildItemCard(item);
          },
        );
      },
    );
  }

  Future<void> _deleteItem(String itemId, String imageUrl) async {
    try {
      // Toon bevestigingsdialoog
      bool confirmDelete = await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Item verwijderen'),
              content: const Text(
                'Weet je zeker dat je dit item wilt verwijderen?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuleren'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Verwijderen',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
      );

      if (confirmDelete == true) {
        // Verwijder eerst de afbeelding uit Storage als het een Firebase URL is
        if (imageUrl.startsWith('https://firebasestorage.googleapis.com')) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            print('Fout bij verwijderen afbeelding: $e');
          }
        }

        // Verwijder het document uit Firestore
        await _firestore.collection('apparaten').doc(itemId).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item succesvol verwijderd')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fout bij verwijderen: $e')));
    }
  }

  Widget _buildItemCard(ApplianceModel item) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading:
            item.afbeelding.isNotEmpty
                ? Image.network(
                  item.afbeelding,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
                : const Icon(Icons.image),
        title: Text(item.naam),
        subtitle: Text('${item.prijs} ${item.eenheid}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.staat),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteItem(item.id, item.afbeelding),
            ),
          ],
        ),
      ),
    );
  }

  Future<GeoPoint?> _getUserLocation() async {
    try {
      // Controleer eerst of de plugin beschikbaar is
      try {
        await Geolocator.getCurrentPosition();
      } on MissingPluginException {
        print('Geolocator plugin niet beschikbaar');
        return null;
      }

      // Controleer locatiediensten
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Locatiediensten uitgeschakeld');
        return null;
      }

      // Controleer permissies
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Locatietoestemming geweigerd');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Locatietoestemming permanent geweigerd');
        return null;
      }

      // Haal locatie op
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return GeoPoint(position.latitude, position.longitude);
    } catch (e) {
      print('Fout bij ophalen locatie: $e');
      return null;
    }
  }

  void _showAddItemDialog() {
    final _formKey = GlobalKey<FormState>();
    String naam = '';
    double prijs = 0.0;
    String eenheid = 'per dag';
    bool isBeschikbaar = true;
    String staat = 'Nieuw';
    List<String> genre = [];
    String afbeeldingUrl = '';
    GeoPoint? selectedLocation;
    bool isLoadingLocation = true;

    _getUserLocation().then((location) {
      if (mounted) {
        setState(() {
          selectedLocation =
              location ??
              const GeoPoint(52.1326, 5.2913); // Fallback: Nederland
          isLoadingLocation = false;
        });
      }
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nieuw Item Toevoegen'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Naam'),
                    style: const TextStyle(color: Colors.black),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vul een naam in';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      naam = value!;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Prijs'),
                    style: const TextStyle(color: Colors.black),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null ||
                          double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Vul een geldige prijs in';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      prijs = double.parse(value!);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Eenheid'),
                    value: eenheid,
                    items:
                        ['per dag', 'per uur', 'per week'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (value) {
                      eenheid = value!;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Genre (komma gescheiden)',
                    ),
                    style: const TextStyle(color: Colors.black),
                    onSaved: (value) {
                      genre =
                          value?.split(',').map((e) => e.trim()).toList() ?? [];
                    },
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Staat'),
                    value: staat,
                    items:
                        ['Nieuw', 'Zo goed als nieuw', 'Gebruikt'].map((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (value) {
                      staat = value!;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Afbeelding URL',
                      hintText:
                          'Rechtermuisklik op een afbeelding en kies "Afbeeldingsadres kopiëren"',
                    ),
                    style: const TextStyle(color: Colors.black),
                    validator: (value) {
                      if (value == null && value!.isEmpty) {
                        return 'Vul een geldige afbeelding-URL in (jpg, jpeg, png, gif)';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      afbeeldingUrl = value ?? '';
                    },
                    onChanged: (value) {
                      setState(() {
                        afbeeldingUrl = value;
                      });
                    },
                  ),
                  if (afbeeldingUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Image.network(
                        afbeeldingUrl,
                        height: 100,
                        errorBuilder:
                            (context, error, stackTrace) => const Text(
                              'Ongeldige afbeelding-URL',
                              style: TextStyle(color: Colors.red),
                            ),
                      ),
                    ),
                  if (isLoadingLocation)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (!isLoadingLocation && selectedLocation != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Locatie: (${selectedLocation!.latitude.toStringAsFixed(4)}, ${selectedLocation!.longitude.toStringAsFixed(4)})',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  if (!isLoadingLocation && selectedLocation == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Kon locatie niet ophalen',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annuleren',
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (selectedLocation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kon locatie niet automatisch ophalen'),
                      ),
                    );
                    return;
                  }
                  _formKey.currentState!.save();

                  try {
                    final newAppliance = ApplianceModel(
                      id: '',
                      naam: naam,
                      afbeelding: afbeeldingUrl,
                      prijs: prijs,
                      eenheid: eenheid,
                      isBeschikbaar: isBeschikbaar,
                      locatie: selectedLocation!,
                      genre: genre,
                      staat: staat,
                      eigenaarId: _currentUserId!,
                    );

                    // Sla op in Firestore
                    await _firestore
                        .collection('apparaten')
                        .add(newAppliance.toJson());

                    Navigator.of(context).pop();
                  } catch (e) {
                    print('Fout in hele proces: $e'); // Debug
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Fout: $e')));
                  }
                }
              },
              child: const Text('Toevoegen'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReservations() {
    return const Center(child: Text('Reserveringen komen hier'));
  }

  Widget _buildSettings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Instellingen',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.onSignOut != null) {
                widget.onSignOut!(); // Roep de doorgegeven uitlog-callback aan
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Uitloggen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, // Rode kleur voor uitlogknop
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
