import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_verhuur_project/widgets/homePage.dart';
import 'package:flutter_verhuur_project/widgets/register.dart';
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
      String errorMessage = 'Er is een fout opgetreden bij het inloggen.';
      if (e.code == 'user-not-found') {
        errorMessage = 'Er is geen gebruiker gevonden voor dat e-mailadres.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Het opgegeven wachtwoord is onjuist.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return null;
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Er is een onverwachte fout opgetreden.')),
      );
      return null;
    }
  }

  Future<void> _handleRegister(String email, String password) async {
    UserCredential? userCredential = await registerUser(email, password);
    if (userCredential?.user != null) {
      print('Registratie succesvol: ${userCredential!.user!.email}');
      // Na registratie wordt de gebruiker automatisch ingelogd,
      // dus authStateChanges zal de UI updaten.
      // Optioneel: toon een succesmelding en navigeer terug naar login of direct naar home
      Navigator.pop(context); // Sluit het registratiescherm
    } else {
      print('Registratie mislukt');
      // Foutmelding wordt al getoond via SnackBar in registerUser
    }
  }

  Future<UserCredential?> registerUser(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return credential;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Er is een fout opgetreden bij de registratie.';
      if (e.code == 'weak-password') {
        errorMessage = 'Het opgegeven wachtwoord is te zwak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Er bestaat al een account voor dat e-mailadres.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return null;
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Er is een onverwachte fout opgetreden.')),
      );
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
      print('Inloggen mislukt');
      // Foutmelding wordt al getoond via SnackBar in signInUser
    }
  }

  void _goToRegisterScreen(BuildContext loginContext) {
    Navigator.of(loginContext).push(
      MaterialPageRoute(
        builder:
            (context) => RegisterScreen(
              onRegister: _handleRegister,
              onGoToLogin: () {
                Navigator.pop(
                  context,
                ); // Sluit het registratiescherm om terug te gaan naar login
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        textTheme: const TextTheme(
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
                // Correcte manier om de functie door te geven
                onGoToRegister:
                    (loginContext) => _goToRegisterScreen(loginContext),
              ),
    );
  }
}
