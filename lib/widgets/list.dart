import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_verhuur_project/Model/Appliance_model.dart';
import 'package:flutter_verhuur_project/widgets/detailscreen.dart';

class ListViewScreen extends StatelessWidget {
  // De 'items' lijst is niet nodig als je data uit Firestore haalt.
  // final List<String> items = List.generate(20, (index) => 'Item ${index + 1}');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ListViewScreen({super.key});

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
        child: _buildItems(context), // Geef context door aan _buildItems
      ),
    );
  }

  Widget _buildItems(BuildContext context) {
    // Accepteer context hier
    // Stream om alle apparaten op te halen (geen filter op eigenaarId voor deze algemene lijst)
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection(
                'apparaten',
              ) // Zorg ervoor dat dit de juiste collectienaam is
              .snapshots(), // Haalt alle documenten op
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

        // Gebruik een ListView.builder om de items weer te geven
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildItemCard(
              context, // Geef context door aan _buildItemCard
              item,
            ); // Functie om een kaart voor elk item te bouwen
          },
        );
      },
    );
  }

  Widget _buildItemCard(BuildContext context, ApplianceModel item) {
    // Accepteer context hier
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: ListTile(
        // Afbeelding aan de linkerkant
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
                  : const Icon(
                    Icons.image_outlined,
                    size: 50,
                  ), // Placeholder als er geen afbeelding is
        ),
        // Titel van het item
        title: Text(
          item.naam,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Subtitel met extra details
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prijs: €${item.prijs}/${item.eenheid}'),
            Text('Locatie: ${item.locatie}'),
            if (item.genre.isNotEmpty) // Toon genres alleen als ze bestaan
              Text('Genre: ${item.genre.join(', ')}'),
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
        // Icoon aan de rechterkant
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        // Actie bij tikken op het item
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DetailScreen(
                    item: item,
                  ), // Geef het hele ApplianceModel door
            ),
          );
        },
      ),
    );
  }
}
