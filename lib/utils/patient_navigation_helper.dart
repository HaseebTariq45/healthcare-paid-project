import 'package:flutter/material.dart';
import 'package:healthcare/views/screens/patient/bottom_navigation_patient.dart';

class PatientNavigationHelper {
  // Navigate to a screen within the app while preserving the bottom navigation bar
  static void navigateWithBottomBar(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
        // Setting this to true will make it replace the current route
        // but maintain the previous routes in the stack
        fullscreenDialog: false,
      ),
    );
  }
  
  // Navigate to a specific tab in the bottom navigation bar
  static void navigateToTab(BuildContext context, int tabIndex) {
    BottomNavigationBarPatientScreen.navigateTo(context, tabIndex);
  }
  
  // Navigate back to the home screen with bottom navigation
  static void navigateToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => BottomNavigationBarPatientScreen(
          key: BottomNavigationBarPatientScreen.navigatorKey,
          profileStatus: "complete",
        ),
      ),
      (route) => false,
    );
  }
}