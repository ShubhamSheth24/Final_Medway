import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_pharmacy/models/user_model.dart';
import 'package:flutter_application_pharmacy/pharmacy_registration.dart';
import 'package:flutter_application_pharmacy/screens/welcome_screen.dart';
import 'home_page.dart';
import 'package:flutter_application_pharmacy/medicine_reminders.dart';
import 'package:flutter_application_pharmacy/profile_page.dart';
import 'package:flutter_application_pharmacy/reports.dart';
import 'package:flutter_application_pharmacy/signin.dart';
import 'package:flutter_application_pharmacy/signup.dart';
import 'package:provider/provider.dart';
// Removed import for custom_bottom_nav_bar.dart as it's not needed in MainScreen

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
      child: MaterialApp(title: 'Pharmacy App', home: const WelcomeScreen()),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String userName;

  const MainScreen({super.key, required this.userName});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(userName: widget.userName),
      ReportsPage(userName: widget.userName),
      MedicineReminder(userName: widget.userName),
      ProfilePage(userName: widget.userName),
    ];
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0; // Navigate to HomePage (index 0)
      });
      return false; // Prevent app exit
    }
    // Delegate to the current page's _onWillPop (e.g., HomePage's exit dialog)
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: IndexedStack(index: _currentIndex, children: _pages),
    );
  }
}
