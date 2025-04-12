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
        body: Stack(
          children: [
            SplashScreen(),
            Positioned(
              bottom: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () async {
                  // Show dialog to change a user's role for debugging
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Debug: Change Role'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Enter phone number to change role:'),
                          SizedBox(height: 10),
                          TextField(
                            decoration: InputDecoration(
                              hintText: '+92...',
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(
                              text: '+923128344065'
                            ),
                            onChanged: (value) {
                              // placeholder
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              // Get the user document by phone number
                              final querySnapshot = await FirebaseFirestore.instance
                                  .collection('users')
                                  .where('phoneNumber', isEqualTo: '+923128344065')
                                  .limit(1)
                                  .get();
                              
                              if (querySnapshot.docs.isNotEmpty) {
                                final userId = querySnapshot.docs.first.id;
                                
                                // Update the role to doctor
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .update({
                                  'role': 'doctor',
                                });
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Role changed to doctor!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('User not found!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            
                            Navigator.of(context).pop();
                          },
                          child: Text('Change to Doctor'),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(Icons.build),
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(16),
                  backgroundColor: Colors.blue.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
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