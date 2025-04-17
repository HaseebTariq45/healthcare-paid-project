import 'package:flutter/material.dart';
import 'package:healthcare/views/screens/dashboard/analytics.dart';
import 'package:healthcare/views/screens/dashboard/finances.dart';
import 'package:healthcare/views/screens/dashboard/home.dart';
import 'package:healthcare/views/screens/dashboard/menu.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  final String profileStatus;
  final String userType;
  final int initialIndex;
  
  // Add static key to access navigator state
  static final GlobalKey<_BottomNavigationBarScreenState> navigatorKey = GlobalKey<_BottomNavigationBarScreenState>();
  
  const BottomNavigationBarScreen({
    super.key, 
    required this.profileStatus,
    this.userType = "Doctor", // Default to Doctor for backward compatibility
    this.initialIndex = 0,
  });

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
            userType: "Doctor",
            initialIndex: index,
          ),
        ),
      );
    }
  }
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  late String profileStatus;
  late String userType;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    profileStatus = widget.profileStatus;
    userType = widget.userType;
    _selectedIndex = widget.initialIndex;
    print('***** BOTTOM NAV BAR INITIALIZED WITH USER TYPE: $userType *****');
  }

  List<Widget> _widgetOptions() => <Widget>[
    HomeScreen(
      profileStatus: profileStatus,
      userType: userType,
    ),
    AnalyticsScreen(),
    FinancesScreen(),
    MenuScreen(
      role: userType,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final bottomPadding = mediaQuery.padding.bottom;
    
    // Calculate icon size based on screen width
    final double iconSize = screenWidth * 0.06;
    // Calculate label font size based on screen width
    final double fontSize = screenWidth * 0.03;
    // Calculate bottom navigation bar height based on screen height
    final double navBarHeight = 56.0 + (bottomPadding > 0 ? bottomPadding : 0);
    
    return Scaffold(
      body: SafeArea(
        bottom: false, // Handle bottom padding in the NavBar itself
        child: Center(
          child: _widgetOptions().elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            elevation: 0,
        backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: fontSize,
            unselectedFontSize: fontSize,
            iconSize: iconSize,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled), 
                label: 'Home',
              ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Finances',
          ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu), 
                label: 'Menu',
              ),
        ],
        currentIndex: _selectedIndex,
        unselectedItemColor: const Color.fromARGB(255, 94, 93, 93),
        unselectedLabelStyle: TextStyle(color: Colors.grey),
        selectedItemColor: Color.fromRGBO(64, 124, 226, 1),
        onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
