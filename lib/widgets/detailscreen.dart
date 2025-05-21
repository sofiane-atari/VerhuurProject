import 'package:flutter/material.dart';
import 'package:flutter_verhuur_project/Model/Appliance_model.dart'; // Importeer je ApplianceModel

class DetailScreen extends StatelessWidget {
  final ApplianceModel item; // Aangepast naar ApplianceModel

  const DetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.naam), // Toon de naam van het item in de AppBar
        backgroundColor: Colors.deepPurple, // Consistent met je appbar thema
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: SingleChildScrollView(
        // Gebruik SingleChildScrollView voor scrollen bij veel content
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Afbeelding van het item
            if (item.afbeelding.isNotEmpty)
              Center(
                child: Image.network(
                  item.afbeelding,
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
              item.naam,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),

            // Prijs en eenheid
            Text(
              'Prijs: €${item.prijs}/${item.eenheid}',
              style: const TextStyle(fontSize: 20, color: Colors.black87),
            ),
            const SizedBox(height: 8),

            // Locatie
            Text(
              'Locatie: ${item.locatie}',
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 8),

            // Staat
            Text(
              'Staat: ${item.staat}',
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 8),

            // Beschikbaarheid
            Row(
              children: [
                Icon(
                  item.isBeschikbaar ? Icons.check_circle : Icons.remove_circle,
                  color: item.isBeschikbaar ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  item.isBeschikbaar ? 'Beschikbaar' : 'Niet beschikbaar',
                  style: TextStyle(
                    fontSize: 18,
                    color: item.isBeschikbaar ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Genres
            if (item.genre.isNotEmpty)
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
                    spacing: 8.0, // Horizontale ruimte tussen chips
                    runSpacing: 4.0, // Verticale ruimte tussen rijen chips
                    children:
                        item.genre
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
          ],
        ),
      ),
    );
  }
}
