import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_verhuur_project/Model/Appliance_model.dart';
import 'package:flutter_verhuur_project/widgets/map_screen.dart';
import 'package:flutter_verhuur_project/widgets/list.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId; // Moet ingevuld worden via je auth systeem

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Haal huidige gebruiker ID op (moet je invullen via je auth)
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
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
        children: [_buildMyItems(), _buildReservations(), _buildSettings()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMyItems() {
    if (_currentUserId == null)
      return const Center(child: CircularProgressIndicator());

    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('appliances')
              .where('eigenaarId', isEqualTo: _currentUserId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items =
            snapshot.data!.docs.map((doc) {
              return ApplianceModel(
                id: doc.id,
                naam: doc['Naam'],
                afbeelding: doc['afbeelding'],
                prijs: doc['prijs'],
                eenheid: doc['eenheid'],
                isBeschikbaar: doc['isBeschikbaar'],
                locatie: doc['locatie'],
                genre: List<String>.from(doc['genre']),
                staat: doc['staat'],
              );
            }).toList();

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Nog geen items toegevoegd'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showAddItemDialog,
                  child: const Text('Voeg je eerste item toe'),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildItemCard(ApplianceModel item) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child:
                item.afbeelding.isNotEmpty
                    ? Image.network(
                      item.afbeelding,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                    : Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.photo, size: 50)),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.naam,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '€${item.prijs}/${item.eenheid}',
                  style: const TextStyle(color: Colors.deepPurple),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children:
                      item.genre
                          .map(
                            (category) => Chip(
                              label: Text(category),
                              labelStyle: const TextStyle(fontSize: 10),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 4),
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
                      item.isBeschikbaar ? 'Beschikbaar' : 'Niet beschikbaar',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservations() {
    // TODO
    return const Center(child: Text('Reserveringen komen hier'));
  }

  Widget _buildSettings() {
    // TODO
    return const Center(child: Text('Instellingen komen hier'));
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nieuw item toevoegen'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TextField(
                    decoration: InputDecoration(labelText: 'Naam'),
                  ),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Prijs'),
                    keyboardType: TextInputType.number,
                  ),
                  // Voeg meer velden toe volgens je Firestore structuur
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuleren'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Implementeer opslaan naar Firestore
                  Navigator.pop(context);
                },
                child: const Text('Opslaan'),
              ),
            ],
          ),
    );
  }
}
