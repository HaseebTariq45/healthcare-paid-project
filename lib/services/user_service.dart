import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Get user from Firestore
  Future<UserModel?> getCurrentUser() async {
    try {
      if (currentUserId == null) return null;
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
          
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }
  
  // Update user in Firestore
  Future<bool> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toMap());
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }
  
  // Upload profile image and update user
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      if (currentUserId == null) return null;
      
      final storageRef = _storage.ref().child('profile_images/$currentUserId.jpg');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Update user profile with new image URL
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update({'profileImageUrl': downloadUrl});
          
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }
  
  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }
  
  // Delete user account
  Future<bool> deleteUserAccount() async {
    try {
      if (currentUserId == null) return false;
      
      // Delete user data from Firestore
      await _firestore.collection('users').doc(currentUserId).delete();
      
      // Delete profile image if exists
      try {
        await _storage.ref().child('profile_images/$currentUserId.jpg').delete();
      } catch (e) {
        // Ignore if image doesn't exist
      }
      
      // Delete Authentication account
      await _auth.currentUser?.delete();
      
      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }
} 