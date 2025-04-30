import 'package:flutter/material.dart';
import 'package:flutter_verhuur_project/widgets/dashboard.dart';
import 'package:flutter_verhuur_project/widgets/map_screen.dart';
import 'package:flutter_verhuur_project/widgets/list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const Dashboard(),
    MapScreen(),
    ListViewScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Kaart'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Apparaten'),
        ],
      ),
    );
  }
}
