import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:flutter_application_pharmacy/medicine_reminders.dart';
import 'package:flutter_application_pharmacy/models/user_model';
import 'package:flutter_application_pharmacy/profile_page.dart';
import 'package:flutter_application_pharmacy/reports.dart';
import 'package:flutter_application_pharmacy/signin.dart';
import 'package:flutter_application_pharmacy/signup.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyC3ZTxN5FbvDigGHIsu6mxmnUCpO6Fv1Wo",
          authDomain: "final-fdbdf.firebaseapp.com",
          projectId: "final-fdbdf",
          storageBucket: "final-fdbdf.firebasestorage.app",
          messagingSenderId: "303329458389",
          appId: "1:303329458389:web:ddca75e80fa3b42d904a5c",
          measurementId: "G-CFWM391TRV",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => UserModel())],
      child: MaterialApp(
        title: 'Pharmacy App',
        home: const AuthWrapper(), // Start with auth check
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          // User is signed in, go to MainScreen
          return MainScreen(
            userName: "User",
          ); // Replace with actual userName if fetched
        } else {
          // User not signed in, go to SignIn
          return const SignIn();
        }
      },
    );
  }
}

class MainScreen extends StatelessWidget {
  final String userName;

  const MainScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    // Directly return HomePage as the starting point with its own nav bar
    return HomePage(userName: userName);
  }
}
