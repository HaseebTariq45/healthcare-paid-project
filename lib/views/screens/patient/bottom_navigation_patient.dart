import 'package:flutter/material.dart';
import 'package:healthcare/views/screens/analytics/reports.dart';
import 'package:healthcare/views/screens/patient/dashboard/finance.dart';
import 'package:healthcare/views/screens/patient/dashboard/home.dart';
import 'package:healthcare/views/screens/patient/dashboard/profile.dart';

class BottomNavigationBarPatientScreen extends StatefulWidget {
  final String profileStatus;
  final bool suppressProfilePrompt;
  final int profileCompletionPercentage;

  // Add static key to access navigator state
  static final GlobalKey<_BottomNavigationBarPatientScreenState> navigatorKey = GlobalKey<_BottomNavigationBarPatientScreenState>();

  const BottomNavigationBarPatientScreen({
    super.key, 
    required this.profileStatus,
    this.suppressProfilePrompt = false,
    this.profileCompletionPercentage = 0,
  });

  @override
  State<BottomNavigationBarPatientScreen> createState() => _BottomNavigationBarPatientScreenState();

  // Static method that can be called from anywhere to change the active tab
  static void navigateTo(BuildContext context, int index) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!._onItemTapped(index);
    } else {
      // Fallback if navigatorKey isn't available
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BottomNavigationBarPatientScreen(
            profileStatus: "complete",
            profileCompletionPercentage: 100,
          ),
        ),
      );
    }
  }
}

class _BottomNavigationBarPatientScreenState extends State<BottomNavigationBarPatientScreen> {
  late String profileStatus;
  late bool suppressProfilePrompt;
  late int profileCompletionPercentage;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    profileStatus = widget.profileStatus;
    suppressProfilePrompt = widget.suppressProfilePrompt;
    profileCompletionPercentage = widget.profileCompletionPercentage;
  }

  List<Widget> _widgetOptions() => <Widget>[
    PatientHomeScreen(
      profileStatus: profileStatus,
      suppressProfilePrompt: suppressProfilePrompt,
      profileCompletionPercentage: profileCompletionPercentage,
    ),
    ReportsScreen(),
    PatientFinancesScreen(),
    PatientMenuScreen(
      profileCompletionPercentage: profileCompletionPercentage,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions().elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Finances',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu), 
            label: 'Menu'
          ),
        ],
        currentIndex: _selectedIndex,
        unselectedItemColor: const Color.fromARGB(255, 94, 93, 93),
        unselectedLabelStyle: TextStyle(color: Colors.grey),
        selectedItemColor: Color.fromRGBO(64, 124, 226, 1),
        onTap: _onItemTapped,
      ),
    );
  }
}
