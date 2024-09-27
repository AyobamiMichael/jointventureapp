import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert'; // For utf8.encode
import 'package:jointventureapp/dashboard.dart';
import 'package:jointventureapp/signuppage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true; // For password visibility toggle

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _login(BuildContext context) async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    try {
      // Fetch user document from Firestore
      final userSnapshot = await FirebaseFirestore.instance
          .collection('jointventureuserdata')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw Exception('User not found');
      }

      final userDoc = userSnapshot.docs.first;
      final storedPasswordHash = userDoc['password'];

      // Hash the input password and check it
      final hashedPassword = _hashPassword(password);

      if (hashedPassword != storedPasswordHash) {
        throw Exception('Invalid password');
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Dashboard(username: username),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _navigateToSignUp(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignUpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        'IGWE BU IKE',
        style: TextStyle(
          fontSize: 20,
          color: Colors.green,
        ),
      )),
      body: Container(
        color: Colors.black, // Background color
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: double
                      .infinity // Constrain the maximum width of the content
                  ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/igwebuike latest logo.png',
                    width: 200,
                    height: 200,
                  ),
                  /*const Text(
                    'M 2 1 W A L L E T',
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'Many To One Wallet For Community Projects',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    textAlign: TextAlign.center,
                  ),*/
                  const SizedBox(height: 30),
                  TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Username',
                      ),
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 20),
                  TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, // Full width button
                    child: ElevatedButton(
                      onPressed: () => _login(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                            255, 166, 186, 209), // Deeper blue color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // No rounded edges
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => _navigateToSignUp(context),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration:
                            TextDecoration.underline, // Underline the text
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
