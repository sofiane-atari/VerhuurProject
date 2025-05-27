import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_verhuur_project/widgets/dashboard.dart';
import 'package:flutter_verhuur_project/widgets/map_screen.dart';
import 'package:flutter_verhuur_project/widgets/list.dart';

class HomePage extends StatefulWidget {
  final User? user;
  final VoidCallback onSignOut;

  const HomePage({super.key, this.user, required this.onSignOut});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  User? _user; // Declare _user as nullable
  VoidCallback? _onSignOut;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _user = widget.user; // Initialize _user here
    _onSignOut = widget.onSignOut;
    _pages = [
      Dashboard(user: _user, onSignOut: _onSignOut), // Pass the user here
      const MapScreen(),
      ListViewScreen(),
    ];
  }

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
