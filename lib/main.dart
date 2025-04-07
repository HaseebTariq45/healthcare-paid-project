import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthcare/views/screens/onboarding/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:healthcare/firebase_options.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/services/user_service.dart';
import 'package:healthcare/views/screens/bottom_navigation_bar.dart';
import 'package:healthcare/views/screens/dashboard/home.dart';
import 'package:healthcare/views/screens/patient/dashboard/home.dart' as PatientHome;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // If Firebase is initializing, show loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        // If user is authenticated
        if (snapshot.hasData) {
          return FutureBuilder(
            future: _userService.getCurrentUser(),
            builder: (context, userSnapshot) {
              // While loading user data, show loading
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // If user data is available
              if (userSnapshot.hasData && userSnapshot.data != null) {
                final user = userSnapshot.data!;
                
                // Route based on user type (specialty)
                if (user.specialty.isNotEmpty) {
                  // Doctor
                  return HomeScreen(profileStatus: "complete");
                } else {
                  // Patient
                  return PatientHome.PatientHomeScreen();
                }
              }
              
              // Fall back to splash if no user data
              return const SplashScreen();
            },
          );
        }
        
        // If not authenticated, show splash screen
        return const SplashScreen();
      },
    );
  }
}