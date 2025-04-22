import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final String item;

  const DetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item), backgroundColor: Colors.blueAccent),
      body: Center(
        child: Text(
          item,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
