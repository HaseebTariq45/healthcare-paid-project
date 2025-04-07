import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Current user state
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  
  // Verification ID for phone auth
  String? _verificationId;
  
  // Get verification ID
  String? get verificationId => _verificationId;
  
  // Send OTP
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
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        codeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }
  
  // Verify OTP
  Future<UserCredential?> verifyOTP(String smsCode) async {
    try {
      if (_verificationId == null) return null;
      
      // Create credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode
      );
      
      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } catch (e) {
      print('Error verifying OTP: $e');
      return null;
    }
  }
  
  // Register new user
  Future<UserModel?> registerUser({
    required String phoneNumber,
    required String name,
    required String type,
  }) async {
    try {
      if (currentUser == null) return null;
      
      // Extract first and last name
      List<String> nameParts = name.trim().split(' ');
      String firstName = nameParts.first;
      String lastName = nameParts.length > 1 
          ? nameParts.sublist(1).join(' ') 
          : '';
      
      // Create user model
      final userModel = UserModel(
        id: currentUser!.uid,
        firstName: firstName,
        lastName: lastName,
        email: '',
        contactNumber: phoneNumber,
        specialty: type == 'Doctor' ? 'General Practitioner' : '',
      );
      
      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .set(userModel.toMap());
      
      return userModel;
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Check if user exists
  Future<bool> checkUserExists(String phoneNumber) async {
    try {
      // Query Firestore to check if user with phone number exists
      final querySnapshot = await _firestore
          .collection('users')
          .where('contactNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
          
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }
} 