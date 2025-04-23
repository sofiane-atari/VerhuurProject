import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_verhuur_project/widgets/homePage.dart';
import 'package:flutter_verhuur_project/widgets/list.dart';
import 'firebase_options.dart';
import 'package:flutter_verhuur_project/widgets/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedIn = false;
  String? loggedInVoornaam;
  String? loggedInAchternaam;

  void login(String voornaam, String achternaam) {
    setState(() {
      isLoggedIn = true;
      loggedInVoornaam = voornaam;
      loggedInAchternaam = achternaam;
    });
    print('ingelogd als: $voornaam $achternaam');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: isLoggedIn ? const HomePage() : LoginScreen(onLogin: login),
    );
  }
}
