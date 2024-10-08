import 'package:crypto/crypto.dart';
import 'dart:convert'; // For utf8.encode
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jointventureapp/loginpage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _login(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _signUp(BuildContext context) async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Basic validation
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage(context, 'Please fill all fields');
      return;
    }

    if (!_validatePassword(password)) {
      _showMessage(context,
          'Password must be at least 6 characters long and contain both letters and digits.');
      return;
    }

    try {
      // Check if the username already exists
      final querySnapshot = await FirebaseFirestore.instance
          .collection('jointventureuserdata')
          .where('username', isEqualTo: username)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _showMessage(context, 'Username is already taken');
        return;
      }

      // Encrypt the password
      final encryptedPassword = _encryptPassword(password);

      // Insert user data into Firestore with a unique ID
      await FirebaseFirestore.instance.collection('jointventureuserdata').add({
        'username': username,
        'email': email,
        'password': encryptedPassword,
        'option': '',
        'comment': '',
        'wightedvotingoption': '',
        'weightedvotingcomment': '',
        'VotingPower': ''
      });

      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
      // Show success message
      _showMessage(context, 'Signup successful!');
    } catch (e) {
      _showMessage(context, 'Signup failed: $e');
      print(e);
    }
  }

  String _encryptPassword(String password) {
    // Convert password to bytes
    final bytes = utf8.encode(password);

    // Encrypt password using SHA256
    final digest = sha256.convert(bytes);

    // Convert digest to string
    return digest.toString();
  }

  bool _validatePassword(String password) {
    // Ensure password is at least 6 characters and contains both letters and digits
    if (password.length < 6) return false;
    bool hasLetter = password.contains(RegExp(r'[A-Za-z]'));
    bool hasDigit = password.contains(RegExp(r'\d'));
    return hasLetter && hasDigit;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Igwe Bu Ike')),
      body: Container(
        color: Colors.black,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400, // Constrain the maximum width of the content
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
                  TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Username',
                      ),
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 20),
                  TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
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
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _signUp(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 97, 132, 185),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _login(context),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
