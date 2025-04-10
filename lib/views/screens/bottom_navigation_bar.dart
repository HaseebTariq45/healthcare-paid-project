import 'package:flutter/material.dart';
import 'package:healthcare/views/screens/dashboard/analytics.dart';
import 'package:healthcare/views/screens/dashboard/finances.dart';
import 'package:healthcare/views/screens/dashboard/home.dart';
import 'package:healthcare/views/screens/dashboard/menu.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  final String profileStatus;
  
  // Add static key to access navigator state
  static final GlobalKey<_BottomNavigationBarScreenState> navigatorKey = GlobalKey<_BottomNavigationBarScreenState>();
  
  const BottomNavigationBarScreen({super.key, required this.profileStatus});

  @override
  State<BottomNavigationBarScreen> createState() => _BottomNavigationBarScreenState();
  
  // Static method that can be called from anywhere to change the active tab
  static void navigateTo(BuildContext context, int index) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!._onItemTapped(index);
    } else {
      // Fallback if navigatorKey isn't available
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BottomNavigationBarScreen(
            profileStatus: "complete",
          ),
        ),
      );
    }
  }
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  late String profileStatus;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    profileStatus = widget.profileStatus;
  }

  List<Widget> _widgetOptions() => <Widget>[
    HomeScreen(profileStatus: profileStatus),
    AnalyticsScreen(),
    FinancesScreen(),
    MenuScreen(),
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
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Finances',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
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
