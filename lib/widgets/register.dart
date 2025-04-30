import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  final Function(String email, String password) onRegister;

  const RegisterScreen({super.key, required this.onRegister});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  String _errorMessage = ''; // Toegevoegd voor foutmeldingen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registreer')), // Titel van de pagina
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  // E-mail invoerveld
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail', // Label voor het veld
                    border: OutlineInputBorder(), // Randstijl
                  ),
                  validator: (value) {
                    // Validator voor het e-mailveld
                    if (value == null || value.isEmpty) {
                      return 'Vul je e-mailadres in'; // Foutmelding als het leeg is
                    }
                    if (!value.contains('@')) {
                      return 'Ongeldig e-mailadres'; // Foutmelding als het geen geldig e-mail is
                    }
                    return null; // Retourneer null als de invoer geldig is
                  },
                ),
                const SizedBox(height: 16.0), // Verticale ruimte tussen velden
                TextFormField(
                  // Wachtwoord invoerveld
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Wachtwoord', // Label voor het veld
                    border: const OutlineInputBorder(), // Randstijl
                    suffixIcon: IconButton(
                      // Icoon om wachtwoord zichtbaarheid te schakelen
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText =
                              !_obscureText; // Schakel de zichtbaarheid
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    // Validator voor het wachtwoordveld
                    if (value == null || value.isEmpty) {
                      return 'Vul je wachtwoord in'; // Foutmelding als het leeg is
                    }
                    if (value.length < 6) {
                      return 'Wachtwoord moet minstens 6 tekens lang zijn'; // Foutmelding als het te kort is
                    }
                    return null; // Retourneer null als de invoer geldig is
                  },
                ),
                const SizedBox(height: 24.0), // Verticale ruimte voor de knop
                ElevatedButton(
                  // Registreer knop
                  onPressed: () async {
                    // Asynchrone functie voor het registreren
                    if (_formKey.currentState!.validate()) {
                      // Valideer het formulier
                      setState(() {
                        _errorMessage =
                            ''; // Reset de foutmelding bij elke poging
                      });
                      widget.onRegister(
                        _emailController.text,
                        _passwordController.text,
                      );
                    }
                  },
                  child: const Text('Registreer'), // Tekst op de knop
                ),
                if (_errorMessage
                    .isNotEmpty) // Toon foutmelding indien aanwezig
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose de controllers om geheugenlekken te voorkomen
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
