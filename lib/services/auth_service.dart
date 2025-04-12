import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/views/screens/patient/bottom_navigation_patient.dart';
import 'package:healthcare/views/screens/bottom_navigation_bar.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page1.dart';
import 'package:healthcare/views/screens/doctor/complete_profile/doctor_profile_page1.dart';
import 'package:healthcare/views/screens/onboarding/splash.dart';

enum UserRole {
  patient,
  doctor,
  ladyHealthWorker,
  admin,
  unknown,
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Admin credentials - keep only this for admin access
  static const String adminPhoneNumber = "+923031234567";
  static const String adminOTP = "123456";

  // Check if credentials match admin
  bool isAdminCredentials(String phoneNumber, String otp) {
    return phoneNumber == adminPhoneNumber && otp == adminOTP;
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Get user role from shared preferences (for quicker access)
  Future<UserRole> getUserRole() async {  
    // If not logged in, return unknown
    if (currentUser == null) {
      print('***** NO CURRENT USER, RETURNING UNKNOWN ROLE *****');
      return UserRole.unknown;
    }
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? roleStr = prefs.getString('user_role_${currentUser!.uid}');
    print('***** ROLE FROM PREFS: $roleStr for user ${currentUser!.uid} *****');
    
    if (roleStr == null) {
      print('***** NO CACHED ROLE, FETCHING FROM FIRESTORE *****');
      return await _fetchUserRoleFromFirestore();
    }
    
    UserRole role;
    switch (roleStr) {
      case 'patient': role = UserRole.patient; break;
      case 'doctor': role = UserRole.doctor; break;
      case 'ladyHealthWorker': role = UserRole.ladyHealthWorker; break;
      case 'admin': role = UserRole.admin; break;
      default: role = UserRole.unknown; break;
    }
    
    print('***** RETURNING ROLE FROM PREFS: $role *****');
    return role;
  }

  // Save user role to shared preferences
  Future<void> _saveUserRole(UserRole role) async {
    if (currentUser == null) return;
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String roleStr;
    
    switch (role) {
      case UserRole.patient: roleStr = 'patient'; break;
      case UserRole.doctor: roleStr = 'doctor'; break;
      case UserRole.ladyHealthWorker: roleStr = 'ladyHealthWorker'; break;
      case UserRole.admin: roleStr = 'admin'; break;
      default: roleStr = 'unknown'; break;
    }
    
    print('***** SAVING USER ROLE TO PREFS: $roleStr for user ${currentUser!.uid} *****');
    await prefs.setString('user_role_${currentUser!.uid}', roleStr);
    print('***** ROLE SAVED TO PREFS *****');
  }

  // Fetch user role from Firestore
  Future<UserRole> _fetchUserRoleFromFirestore() async {
    if (currentUser == null) return UserRole.unknown;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      print('***** FETCHING USER ROLE - DOC EXISTS: ${doc.exists} *****');
      print('***** USER ID: ${currentUser!.uid} *****');
      
      if (!doc.exists) return UserRole.unknown;
      
      final data = doc.data();
      print('***** FIRESTORE USER DATA: $data *****');
      
      if (data == null || !data.containsKey('role')) {
        print('***** NO ROLE FIELD FOUND IN USER DATA *****');
        // Check if there might be a casing issue with the role field
        if (data != null) {
          final keys = data.keys.toList();
          print('***** AVAILABLE FIELDS: $keys *****');
          // Check for alternative casing of 'role'
          for (final key in keys) {
            if (key.toLowerCase() == 'role') {
              print('***** FOUND ROLE WITH DIFFERENT CASING: $key *****');
              final String role = data[key].toString().toLowerCase();
              print('***** ROLE VALUE WITH DIFFERENT CASING: $role *****');
              
              UserRole userRole;
              switch (role) {
                case 'patient': userRole = UserRole.patient; break;
                case 'doctor': userRole = UserRole.doctor; break;
                case 'ladyhealthworker': userRole = UserRole.ladyHealthWorker; break;
                case 'admin': userRole = UserRole.admin; break;
                default: userRole = UserRole.unknown; break;
              }
              
              print('***** DETERMINED USER ROLE FROM ALTERNATIVE CASING: $userRole *****');
              await _saveUserRole(userRole);
              return userRole;
            }
          }
        }
        return UserRole.unknown;
      }
      
      final String role = data['role'].toString().toLowerCase();  // Convert to lowercase for case-insensitive comparison
      print('***** ROLE STRING FROM FIRESTORE (normalized): $role *****');
      
      UserRole userRole;
      switch (role) {
        case 'patient': userRole = UserRole.patient; break;
        case 'doctor': userRole = UserRole.doctor; break;
        case 'ladyhealthworker': userRole = UserRole.ladyHealthWorker; break;
        case 'admin': userRole = UserRole.admin; break;
        default: 
          print('***** UNKNOWN ROLE STRING: $role *****');
          userRole = UserRole.unknown; 
          break;
      }
      
      print('***** DETERMINED USER ROLE: $userRole *****');
      // Cache the result
      await _saveUserRole(userRole);
      return userRole;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return UserRole.unknown;
    }
  }

  // Send OTP for signin or signup
  Future<Map<String, dynamic>> sendOTP({
    required String phoneNumber,
  }) async {
    try {
      // Special handling for admin only
      if (phoneNumber == adminPhoneNumber) {
        return {
          'success': true,
          'verificationId': 'admin-verification-id-${DateTime.now().millisecondsSinceEpoch}',
          'message': 'Admin verification code sent',
          'isAdmin': true
        };
      }

      final completer = Completer<Map<String, dynamic>>();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android
          try {
            await _auth.signInWithCredential(credential);
            completer.complete({
              'success': true,
              'message': 'Auto-verification successful',
              'autoVerified': true
            });
          } catch (e) {
            completer.complete({
              'success': false,
              'message': 'Auto-verification failed: ${e.toString()}',
              'autoVerified': false
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          // Handle specific errors
          if (e.code == 'too-many-requests') {
            completer.complete({
              'success': false,
              'message': 'Too many requests. Please try again later.',
              'error': e
            });
          } else if (e.message != null && e.message!.contains('BILLING_NOT_ENABLED')) {
            // Provide helpful message for billing issues
            debugPrint('Firebase Phone Auth billing error: ${e.message}');
            completer.complete({
              'success': false,
              'message': 'Firebase Phone Authentication requires billing to be enabled in the Firebase console.',
              'error': e,
              'billingIssue': true
            });
          } else {
            completer.complete({
              'success': false,
              'message': _getReadableAuthError(e),
              'error': e
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          completer.complete({
            'success': true,
            'verificationId': verificationId,
            'resendToken': resendToken,
            'message': 'OTP sent successfully'
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Only complete if not already completed
          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'verificationId': verificationId,
              'message': 'Auto-retrieval timeout'
            });
          }
        },
        timeout: const Duration(seconds: 60),
      );

      return completer.future;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send OTP: ${e.toString()}'
      };
    }
  }

  // Verify OTP and sign in
  Future<Map<String, dynamic>> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      // Handle admin verification
      if (verificationId.startsWith('admin-verification-id-')) {
        if (smsCode == adminOTP) {
          // Create a temporary auth instance for admin user
          try {
            final userCredential = await _auth.signInAnonymously();
            final User? adminUser = userCredential.user;
            
            if (adminUser != null) {
              // Create or update admin user in Firestore
              await _firestore.collection('users').doc(adminUser.uid).set({
                'phoneNumber': adminPhoneNumber,
                'role': 'admin',
                'fullName': 'Admin User',
                'profileComplete': true,
                'lastLogin': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              
              // Cache admin role
              await _saveUserRole(UserRole.admin);
            }
            
            return {
              'success': true,
              'user': adminUser,
              'isNewUser': false,
              'message': 'Admin verification successful',
              'isAdmin': true
            };
          } catch (e) {
            debugPrint('Error creating admin user: $e');
            return {
              'success': false,
              'message': 'Failed to create admin session: ${e.toString()}'
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Invalid admin verification code',
            'isAdmin': true
          };
        }
      }
      
      // Normal verification flow
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Check if user exists in Firestore
      final bool userExists = await this.userExists(userCredential.user!.uid);
      
      return {
        'success': true,
        'user': userCredential.user,
        'isNewUser': !userExists,
        'message': 'OTP verified successfully'
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getReadableAuthError(e),
        'error': e
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to verify OTP: ${e.toString()}'
      };
    }
  }

  // Register a new user
  Future<Map<String, dynamic>> registerUser({
    required String uid,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
  }) async {
    try {
      print('***** REGISTERING USER: $fullName with role: $role *****');
      
      // Prepare role string for Firestore - use lowercase for consistency
      String roleStr;
      switch (role) {
        case UserRole.patient: roleStr = 'patient'; break;
        case UserRole.doctor: roleStr = 'doctor'; break;
        case UserRole.ladyHealthWorker: roleStr = 'ladyhealthworker'; break;
        case UserRole.admin: roleStr = 'admin'; break;
        default: roleStr = 'unknown'; break;
      }
      
      print('***** ROLE STR FOR FIRESTORE: $roleStr *****');
      
      // Prepare user data
      final Map<String, dynamic> userData = {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'role': roleStr,  // Always use lowercase for consistency
        'createdAt': FieldValue.serverTimestamp(),
        'profileComplete': false,
        'lastLogin': FieldValue.serverTimestamp(),
      };
      
      print('***** WRITING USER DATA TO FIRESTORE: $userData *****');
      
      // Save user data to Firestore
      await _firestore.collection('users').doc(uid).set(userData);
      
      print('***** USER DATA WRITTEN SUCCESSFULLY *****');
      
      // Cache user role
      await _saveUserRole(role);
      
      return {
        'success': true,
        'message': 'User registered successfully'
      };
    } catch (e) {
      print('***** ERROR REGISTERING USER: $e *****');
      return {
        'success': false,
        'message': 'Failed to register user: ${e.toString()}'
      };
    }
  }
  
  // Update user's last login timestamp
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating last login: $e');
    }
  }

  // Check if a user profile exists
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      return false;
    }
  }

  // Check if profile is complete
  Future<bool> isProfileComplete() async {
    if (currentUser == null) return false;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (!doc.exists) return false;
      
      final data = doc.data();
      return data != null && data['profileComplete'] == true;
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
      return false;
    }
  }

  // Set profile complete status
  Future<void> setProfileComplete(bool isComplete) async {
    if (currentUser == null) return;
    
    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'profileComplete': isComplete,
      });
    } catch (e) {
      debugPrint('Error setting profile completion: $e');
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (!doc.exists) return null;
      
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (currentUser != null) {
        await prefs.remove('user_role_${currentUser!.uid}');
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
  
  // Clear role cache for current user
  Future<void> clearRoleCache() async {
    try {
      if (currentUser != null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_role_${currentUser!.uid}');
        print('***** CLEARED ROLE CACHE FOR ${currentUser!.uid} *****');
      }
    } catch (e) {
      debugPrint('Error clearing role cache: $e');
    }
  }
  
  // Helper method to get readable auth error messages
  String _getReadableAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The provided phone number is invalid.';
      case 'invalid-verification-code':
        return 'The verification code is invalid. Please check and try again.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'quota-exceeded':
        return 'Service temporarily unavailable. Please try again later.';
      case 'session-expired':
        return 'The verification session has expired. Please request a new code.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }

  // Check if a phone number exists in Firestore and get user data
  Future<Map<String, dynamic>> getUserByPhoneNumber(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final userId = querySnapshot.docs.first.id;
        
        // Parse the role
        UserRole userRole = UserRole.unknown;
        if (userData.containsKey('role')) {
          final String roleStr = userData['role'];
          switch (roleStr) {
            case 'patient': userRole = UserRole.patient; break;
            case 'doctor': userRole = UserRole.doctor; break;
            case 'ladyHealthWorker': userRole = UserRole.ladyHealthWorker; break;
            case 'admin': userRole = UserRole.admin; break;
            default: userRole = UserRole.unknown; break;
          }
        }
        
        return {
          'exists': true,
          'userId': userId,
          'userData': userData,
          'userRole': userRole,
          'isProfileComplete': userData['profileComplete'] ?? false,
        };
      }
      
      // Return not exists if phone number not found in Firestore
      return {'exists': false};
    } catch (e) {
      debugPrint('Error checking user by phone number: $e');
      return {'error': e.toString()};
    }
  }

  // Navigate user to correct screen based on role - simple and direct approach
  Future<Widget> getNavigationScreenForUser({required bool isProfileComplete}) async {
    final userRole = await getUserRole();
    print('***** SIMPLE NAVIGATION: Got user role: $userRole *****');
    
    // Simple direct routing based on role
    if (userRole == UserRole.doctor) {
      print('***** SIMPLE NAVIGATION: Routing to DOCTOR home screen *****');
      if (!isProfileComplete) {
        return DoctorProfilePage1Screen();
      } else {
        return BottomNavigationBarScreen(
          key: BottomNavigationBarScreen.navigatorKey,
          profileStatus: "complete",
          userType: "Doctor"
        );
      }
    } 
    else if (userRole == UserRole.patient) {
      print('***** SIMPLE NAVIGATION: Routing to PATIENT home screen *****');
      if (!isProfileComplete) {
        return CompleteProfilePatient1Screen();
      } else {
        return BottomNavigationBarPatientScreen(
          key: BottomNavigationBarPatientScreen.navigatorKey,
          profileStatus: "complete"
        );
      }
    }
    else if (userRole == UserRole.ladyHealthWorker) {
      print('***** SIMPLE NAVIGATION: Routing to LHW home screen *****');
      if (!isProfileComplete) {
        return CompleteProfilePatient1Screen();
      } else {
        return BottomNavigationBarScreen(
          key: BottomNavigationBarScreen.navigatorKey,
          profileStatus: "complete",
          userType: "LadyHealthWorker"
        );
      }
    }
    else {
      // Default/fallback
      print('***** SIMPLE NAVIGATION: Unknown role, routing to onboarding *****');
      return SplashScreen();
    }
  }
} 