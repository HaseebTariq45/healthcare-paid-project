import 'package:flutter/material.dart';
import 'package:healthcare/views/screens/appointment/all_appoinments.dart';
import 'package:healthcare/views/screens/patient/dashboard/finance.dart';
import 'package:healthcare/views/screens/patient/dashboard/home.dart';
import 'package:healthcare/views/screens/patient/dashboard/profile.dart';

class BottomNavigationBarPatientScreen extends StatefulWidget {
  final String profileStatus;
  final bool suppressProfilePrompt;
  final double profileCompletionPercentage;
  final int initialIndex;

  // Singleton pattern for the key to prevent duplicates
  static final GlobalKey<_BottomNavigationBarPatientScreenState> _navigatorKey = 
      GlobalKey<_BottomNavigationBarPatientScreenState>();
  
  // Getter for the key that ensures we only use one instance
  static GlobalKey<_BottomNavigationBarPatientScreenState> get navigatorKey => _navigatorKey;

  const BottomNavigationBarPatientScreen({
    Key? key, 
    required this.profileStatus,
    this.suppressProfilePrompt = false,
    this.profileCompletionPercentage = 0.0,
    this.initialIndex = 0,
  }) : super(key: key);  // Use the passed key, not the static navigatorKey

  @override
  State<BottomNavigationBarPatientScreen> createState() => _BottomNavigationBarPatientScreenState();

  // Static method that can be called from anywhere to change the active tab
  static void navigateTo(BuildContext context, int index) {
    if (_navigatorKey.currentState != null) {
      _navigatorKey.currentState!._onItemTapped(index);
    } else {
      // Fallback if navigatorKey isn't available
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BottomNavigationBarPatientScreen(
            profileStatus: "complete",
            profileCompletionPercentage: 100.0,
            initialIndex: index,
          ),
        ),
      );
    }
  }
}

class _BottomNavigationBarPatientScreenState extends State<BottomNavigationBarPatientScreen> {
  late String profileStatus;
  late bool suppressProfilePrompt;
  late double profileCompletionPercentage;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    profileStatus = widget.profileStatus;
    suppressProfilePrompt = widget.suppressProfilePrompt;
    profileCompletionPercentage = widget.profileCompletionPercentage;
    _selectedIndex = widget.initialIndex;
  }

  List<Widget> _widgetOptions() => <Widget>[
    PatientHomeScreen(
      profileStatus: profileStatus,
      suppressProfilePrompt: suppressProfilePrompt,
      profileCompletionPercentage: profileCompletionPercentage,
    ),
    AppointmentsScreen(),
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
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
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
