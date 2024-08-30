import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jointventureapp/loginpage.dart';
import 'package:jointventureapp/poll_cubit.dart';
import 'package:jointventureapp/votingpage.dart';
import 'package:jointventureapp/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PollCubit(), // Provide PollCubit
      child: MaterialApp(
        title: 'Joint Venture App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const LoginPage(), // Initial page is LoginPage
      ),
    );
  }
}
