import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole {
  patient,
  doctor,
  ladyHealthWorker,
  unknown,
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Get user role from shared preferences (for quicker access)
  Future<UserRole> getUserRole() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? roleStr = prefs.getString('user_role');
    
    if (roleStr == null) {
      return await _fetchUserRoleFromFirestore();
    }
    
    switch (roleStr) {
      case 'patient': return UserRole.patient;
      case 'doctor': return UserRole.doctor;
      case 'ladyHealthWorker': return UserRole.ladyHealthWorker;
      default: return UserRole.unknown;
    }
  }

  // Save user role to shared preferences
  Future<void> _saveUserRole(UserRole role) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String roleStr;
    
    switch (role) {
      case UserRole.patient: roleStr = 'patient'; break;
      case UserRole.doctor: roleStr = 'doctor'; break;
      case UserRole.ladyHealthWorker: roleStr = 'ladyHealthWorker'; break;
      default: roleStr = 'unknown'; break;
    }
    
    await prefs.setString('user_role', roleStr);
  }

  // Fetch user role from Firestore
  Future<UserRole> _fetchUserRoleFromFirestore() async {
    if (currentUser == null) return UserRole.unknown;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (!doc.exists) return UserRole.unknown;
      
      final data = doc.data();
      if (data == null || !data.containsKey('role')) return UserRole.unknown;
      
      final String role = data['role'];
      
      UserRole userRole;
      switch (role) {
        case 'patient': userRole = UserRole.patient; break;
        case 'doctor': userRole = UserRole.doctor; break;
        case 'ladyHealthWorker': userRole = UserRole.ladyHealthWorker; break;
        default: userRole = UserRole.unknown; break;
      }
      
      // Cache the result
      await _saveUserRole(userRole);
      return userRole;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return UserRole.unknown;
    }
  }

  // Send OTP to phone number
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  // Verify OTP and sign in
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final AuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    
    return await _auth.signInWithCredential(credential);
  }

  // Register a new user
  Future<void> registerUser({
    required String uid,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
  }) async {
    // Prepare role string for Firestore
    String roleStr;
    switch (role) {
      case UserRole.patient: roleStr = 'patient'; break;
      case UserRole.doctor: roleStr = 'doctor'; break;
      case UserRole.ladyHealthWorker: roleStr = 'ladyHealthWorker'; break;
      default: roleStr = 'unknown'; break;
    }
    
    // Prepare user data
    final Map<String, dynamic> userData = {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': roleStr,
      'createdAt': FieldValue.serverTimestamp(),
      'profileComplete': false,
    };
    
    // Save user data to Firestore
    await _firestore.collection('users').doc(uid).set(userData);
    
    // Cache user role
    await _saveUserRole(role);
  }

  // Check if a user profile exists
  Future<bool> userExists(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
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
    
    await _firestore.collection('users').doc(currentUser!.uid).update({
      'profileComplete': isComplete,
    });
  }

  // Sign out
  Future<void> signOut() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await _auth.signOut();
  }
} 