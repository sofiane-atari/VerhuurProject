import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  final Function(String voornaam, String achternaam) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _voornaamController = TextEditingController();
  final TextEditingController _achternaamController = TextEditingController();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  style: TextStyle(color: Colors.deepPurple),
                  controller: _voornaamController,
                  decoration: const InputDecoration(
                    labelText: 'Gebruikersnaam',
                    fillColor: Colors.black,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vul je gebruikersnaam in';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  style: TextStyle(color: Colors.deepPurple),
                  controller: _achternaamController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Wachtwoord',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vul je Wachtwoord in';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onLogin(
                        _voornaamController.text,
                        _achternaamController.text,
                      );
                    }
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
