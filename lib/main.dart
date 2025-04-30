import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_verhuur_project/widgets/homePage.dart';
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
  User? _user;
  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
        isLoggedIn = user != null;
      });
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> signInUser(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('Er is geen gebruiker gevonden voor dat e-mailadres.');
        // Toon een foutmelding aan de gebruiker
      } else if (e.code == 'wrong-password') {
        print('Het opgegeven wachtwoord is onjuist.');
        // Toon een foutmelding aan de gebruiker
      } else {
        print('Er is een fout opgetreden: ${e.message}');
        // Toon een algemene foutmelding aan de gebruiker
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<UserCredential?> registerUser(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('Het opgegeven wachtwoord is te zwak.');
        // Toon een foutmelding aan de gebruiker
      } else if (e.code == 'email-already-in-use') {
        print('Er bestaat al een account voor dat e-mailadres.');
        // Toon een foutmelding aan de gebruiker
      } else {
        print('Er is een fout opgetreden: ${e.message}');
        // Toon een algemene foutmelding aan de gebruiker
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> _handleSignIn(String email, String password) async {
    UserCredential? userCredential = await signInUser(email, password);
    if (userCredential?.user != null) {
      // Inloggen succesvol, de authStateChanges listener zal de state updaten
      print('Ingelogd als: ${userCredential!.user!.email}');
      // Hier kun je eventueel extra acties uitvoeren na het inloggen
    } else {
      // Inloggen mislukt, toon een foutmelding aan de gebruiker in de UI
      print('Inloggen mislukt');
      // TODO: Implementeer het tonen van een foutmelding in de LoginScreen
    }
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
      home:
          isLoggedIn
              ? HomePage(user: _user) // Geef de gebruiker mee
              : LoginScreen(
                onLogin: (email, password) => _handleSignIn(email, password),
              ),
    );
  }
}
