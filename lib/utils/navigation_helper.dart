import 'package:flutter/material.dart';
import 'package:healthcare/views/screens/bottom_navigation_bar.dart';

class NavigationHelper {
  // Cached screen instances for faster navigation
  static final Map<String, Widget> _cachedScreens = {};
  
  // Cache a screen instance for future navigation
  static void cacheScreen(String key, Widget screen) {
    _cachedScreens[key] = screen;
  }
  
  // Get a cached screen if available, or create a new one
  static Widget getScreen(String key, Widget Function() builder) {
    if (_cachedScreens.containsKey(key)) {
      return _cachedScreens[key]!;
    }
    
    final screen = builder();
    _cachedScreens[key] = screen;
    return screen;
  }
  
  // Clear all cached screens
  static void clearCache() {
    _cachedScreens.clear();
  }
  
  // Clear a specific cached screen
  static void removeCachedScreen(String key) {
    _cachedScreens.remove(key);
  }
  
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
  
  // Navigate to a cached screen with the bottom navigation bar
  static void navigateToCachedScreen(BuildContext context, String key, Widget Function() builder) {
    final screen = getScreen(key, builder);
    navigateWithBottomBar(context, screen);
  }
  
  // Navigate to a specific tab in the bottom navigation bar
  static void navigateToTab(BuildContext context, int tabIndex) {
    BottomNavigationBarScreen.navigateTo(context, tabIndex);
  }
  
  // Navigate back to the home screen with bottom navigation
  static void navigateToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => BottomNavigationBarScreen(
          key: BottomNavigationBarScreen.navigatorKey,
          profileStatus: "complete",
        ),
      ),
      (route) => false,
    );
  }
} 