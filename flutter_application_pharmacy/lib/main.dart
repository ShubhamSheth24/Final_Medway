import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_pharmacy/home_page.dart';
import 'package:flutter_application_pharmacy/models/user_model';
import 'package:flutter_application_pharmacy/profile_page.dart';
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
      providers: [
        ChangeNotifierProvider(create: (context) => UserModel()),
      ],
      child: MaterialApp(
        title: 'Pharmacy App',
        initialRoute: '/login', // Start with LoginPage
        routes: {
          '/login': (context) => const SignIn(), // Add your LoginPage here
          '/signup': (context) => const SignUp(),
          '/home': (context) => HomePage(userName: ModalRoute.of(context)?.settings.arguments as String? ?? 'User'),
          '/profile': (context) => ProfilePage(userName: ModalRoute.of(context)?.settings.arguments as String? ?? 'User'),
        },
      ),
    );
  }
}