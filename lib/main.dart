import 'package:flutter/material.dart';
import 'package:healthcare/views/screens/onboarding/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:healthcare/firebase_options.dart';
import 'package:healthcare/views/screens/bottom_navigation_bar.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthcare/views/screens/patient/bottom_navigation_patient.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page1.dart';
import 'package:healthcare/views/screens/doctor/complete_profile/doctor_profile_page1.dart';
import 'package:healthcare/views/screens/menu/appointment_history.dart';
import 'package:healthcare/views/screens/menu/faqs.dart';
import 'package:healthcare/views/screens/menu/payment_method.dart';
import 'package:healthcare/views/screens/menu/profile_update.dart';
import 'package:healthcare/views/screens/dashboard/menu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare/views/screens/patient/dashboard/home.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/profile/edit': (context) => const ProfileEditorScreen(),
        '/appointments/history': (context) => const AppointmentHistoryScreen(),
        '/payment/methods': (context) => PaymentMethodsScreen(userType: UserType.doctor),
        '/faqs': (context) => const FAQScreen(),
        '/bottom_navigation': (context) => const BottomNavigationBarScreen(profileStatus: "complete"),
        '/patient/home': (context) => const PatientHomeScreen(profileStatus: "complete"),
        '/patient/bottom_navigation': (context) => const BottomNavigationBarPatientScreen(
          profileStatus: "complete",
          profileCompletionPercentage: 100.0,
        ),
        '/help': (context) => Scaffold(
          appBar: AppBar(title: const Text("Help Center")),
          body: const Center(child: Text("Help Center Coming Soon")),
        ),
        '/medical/records': (context) => Scaffold(
          appBar: AppBar(title: const Text("Medical Records")),
          body: const Center(child: Text("Medical Records Coming Soon")),
        ),
      },
    );
  }
}

// Authentication Wrapper Component
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _initialized = false;
  bool _error = false;
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  // Check if user is already authenticated
  Future<void> _checkAuthState() async {
    try {
      // Check for existing authentication
      if (_authService.isLoggedIn) {
        // Update last login timestamp
        await _authService.updateLastLogin(_authService.currentUser!.uid);
        
        // Check profile completion status
        final isProfileComplete = await _authService.isProfileComplete();
        
        setState(() {
          _checkingAuth = false;
          _initialized = true;
        });
        
        // Use the simplified navigation helper
        final navigationScreen = await _authService.getNavigationScreenForUser(
          isProfileComplete: isProfileComplete
        );
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => navigationScreen),
          );
        });
      } else {
        // No existing user - need to go through onboarding flow
        setState(() {
          _checkingAuth = false;
          _initialized = true;
        });
      }
    } catch (e) {
      print('Error checking authentication state: $e');
      setState(() {
        _error = true;
        _checkingAuth = false;
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking authentication
    if (_checkingAuth) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // If there was an error or user is not logged in, go to splash screen
    if (_error || !_authService.isLoggedIn) {
      return Scaffold(
        body: SplashScreen(),
      );
    }
    
    // This is a placeholder - navigation happens in checkAuthState
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}