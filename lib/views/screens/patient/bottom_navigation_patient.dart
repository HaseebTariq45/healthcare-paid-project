import 'package:flutter/material.dart';
import 'package:healthcare/views/screens/analytics/reports.dart';
import 'package:healthcare/views/screens/patient/dashboard/finance.dart';
import 'package:healthcare/views/screens/patient/dashboard/home.dart';
import 'package:healthcare/views/screens/patient/dashboard/profile.dart';

class BottomNavigationBarPatientScreen extends StatefulWidget {
  final String profileStatus;
  const BottomNavigationBarPatientScreen({super.key, required this.profileStatus});

  @override
  State<BottomNavigationBarPatientScreen> createState() =>
      _BottomNavigationBarPatientScreenState();
}

class _BottomNavigationBarPatientScreenState extends State<BottomNavigationBarPatientScreen> {
  late String profileStatus;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    profileStatus = widget.profileStatus;
  }

  List<Widget> _widgetOptions() => <Widget>[
    PatientHomeScreen(profileStatus: profileStatus),
    ReportsScreen(),
    PatientFinancesScreen(),
    PatientMenuScreen(),
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
