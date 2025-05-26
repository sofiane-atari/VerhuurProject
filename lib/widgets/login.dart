import 'package:flutter/material.dart';
import 'package:flutter_verhuur_project/widgets/register.dart';

class LoginScreen extends StatefulWidget {
  final Function(String email, String password) onLogin;
  final void Function(BuildContext context)? onGoToRegister;

  const LoginScreen({super.key, required this.onLogin, this.onGoToRegister});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'email',
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
                  controller: _passwordController,
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
                        _emailController.text,
                        _passwordController.text,
                      );
                    }
                  },
                  child: const Text('Login'),
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    if (widget.onGoToRegister != null) {
                      widget.onGoToRegister!(
                        context,
                      ); // Correcte aanroep van de callback
                    }
                  },
                  child: const Text(
                    'Heeft u geen account? Registreer',
                  ), // Knop om naar Registratie te gaan
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
