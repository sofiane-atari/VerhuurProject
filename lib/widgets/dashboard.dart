import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_verhuur_project/Model/Appliance_model.dart';

class Dashboard extends StatefulWidget {
  final User? user;

  const Dashboard({super.key, this.user});

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
                prijs:
                    data['prijs']?.toDouble() ??
                    0.0, // Zorg voor het juiste type
                eenheid: data['eenheid'] ?? '',
                isBeschikbaar: data['isBeschikbaar'] ?? false,
                locatie: data['locatie'] ?? '',
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
            return _buildItemCard(
              item,
            ); // Functie om een kaart voor elk item te bouwen
          },
        );
      },
    );
  }

  Widget _buildItemCard(ApplianceModel item) {
    return Card(
      // ... (kaart styling en weergave van item details)
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(item.naam),
      ),
    );
  }

  void _showAddItemDialog() {
    // ... (dialoogvenster om een nieuw item toe te voegen)
  }

  Widget _buildReservations() {
    return const Center(child: Text('Reserveringen komen hier'));
  }

  Widget _buildSettings() {
    return const Center(child: Text('Instellingen komen hier'));
  }
}
