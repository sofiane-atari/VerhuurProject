import 'package:flutter/material.dart';
import 'package:flutter_verhuur_project/widgets/detailscreen.dart';

class ListViewScreen extends StatelessWidget {
  final List<String> items = List.generate(20, (index) => 'Item ${index + 1}');

  ListViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ListView App'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                title: Text(
                  items[index],
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                leading: Icon(Icons.star, color: Colors.amber),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade700,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(item: items[index]),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
