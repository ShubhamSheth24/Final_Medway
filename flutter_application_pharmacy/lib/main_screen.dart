import 'package:flutter/material.dart';
import 'package:flutter_application_pharmacy/home_page.dart';
import 'package:flutter_application_pharmacy/reports.dart';
import 'package:flutter_application_pharmacy/medicine_reminders.dart';
import 'package:flutter_application_pharmacy/profile_page.dart';
import 'package:flutter_application_pharmacy/widgets/custom_bottom_nav_bar.dart';
import 'package:flutter/services.dart'; // For SystemNavigator

class MainScreen extends StatefulWidget {
  final String userName;

  const MainScreen({super.key, required this.userName});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of screens to display in the IndexedStack
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize the screens with the userName passed from SignIn
    _screens = [
      HomePage(userName: widget.userName),
      ReportsPage(userName: widget.userName),
      MedicineReminder(userName: widget.userName),
      ProfilePage(userName: widget.userName),
    ];
  }

  // Callback to update the current index when a nav bar item is tapped
  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Handle system back button
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      // If not on Home, switch to Home
      setState(() {
        _currentIndex = 0;
      });
      return false; // Prevent app exit
    } else {
      // On Home, show exit confirmation dialog
      bool? shouldExit = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Do you want to exit the app?'),
              actions: [
                TextButton(
                  onPressed:
                      () => Navigator.of(context).pop(false), // Stay in app
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true), // Exit app
                  child: const Text('Yes'),
                ),
              ],
            ),
      );

      if (shouldExit == true) {
        SystemNavigator.pop(); // Exit the app
        return true;
      }
      return false; // Stay in app
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavBarTap,
        ),
      ),
    );
  }
}
