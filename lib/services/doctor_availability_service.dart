import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthcare/utils/date_formatter.dart';

class DoctorAvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache data to avoid repeated queries
  static List<Map<String, dynamic>>? _cachedDoctorHospitals;
  static List<Map<String, dynamic>>? _cachedAllHospitals;
  static Map<String, Map<String, List<String>>>? _cachedAvailability = {};
  static DateTime? _lastFetchTime;
  static const Duration _cacheExpiration = Duration(minutes: 10);

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if cache is valid
  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheExpiration;
  }

  // Clear cache when needed (e.g., after updates)
  void clearCache() {
    _cachedDoctorHospitals = null;
    _cachedAllHospitals = null;
    _cachedAvailability = {};
    _lastFetchTime = null;
  }

  // Fetch all hospitals where the doctor works
  Future<List<Map<String, dynamic>>> getDoctorHospitals() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Return cached data if available and not expired
      if (_cachedDoctorHospitals != null && _isCacheValid()) {
        return _cachedDoctorHospitals!;
      }

      final snapshot = await _firestore
          .collection('doctor_hospitals')
          .where('doctorId', isEqualTo: currentUserId)
          .get();

      final hospitals = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
      
      // Update cache
      _cachedDoctorHospitals = hospitals;
      _lastFetchTime = DateTime.now();
      
      return hospitals;
    } catch (e) {
      debugPrint('Error fetching doctor hospitals: $e');
      return [];
    }
  }

  // Get doctor's availability for a specific hospital
  Future<Map<String, List<String>>> getDoctorAvailability({
    required String hospitalId,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Return cached data if available and not expired
      if (_cachedAvailability != null && 
          _cachedAvailability!.containsKey(hospitalId) && 
          _isCacheValid()) {
        return _cachedAvailability![hospitalId]!;
      }

      final snapshot = await _firestore
          .collection('doctor_availability')
          .where('doctorId', isEqualTo: currentUserId)
          .where('hospitalId', isEqualTo: hospitalId)
          .get();

      Map<String, List<String>> result = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dateStr = data['date'] as String;
        final timeSlots = List<String>.from(data['timeSlots'] ?? []);
        result[dateStr] = timeSlots;
      }

      // Update cache
      if (_cachedAvailability == null) {
        _cachedAvailability = {};
      }
      _cachedAvailability![hospitalId] = result;
      
      return result;
    } catch (e) {
      debugPrint('Error fetching doctor availability: $e');
      return {};
    }
  }

  // Save doctor availability
  Future<Map<String, dynamic>> saveDoctorAvailability({
    required String hospitalId,
    required String hospitalName,
    required DateTime date,
    required List<String> timeSlots,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Format date as YYYY-MM-DD
      final dateStr = DateFormatter.toYYYYMMDD(date);

      // Create a query to check if this date/hospital combination already exists
      final query = await _firestore
          .collection('doctor_availability')
          .where('doctorId', isEqualTo: currentUserId)
          .where('hospitalId', isEqualTo: hospitalId)
          .where('date', isEqualTo: dateStr)
          .limit(1)
          .get();

      // Document reference 
      DocumentReference docRef;
      
      // If entry exists, update it
      if (query.docs.isNotEmpty) {
        docRef = query.docs.first.reference;
        await docRef.update({
          'timeSlots': timeSlots,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Create a new entry
        docRef = await _firestore.collection('doctor_availability').add({
          'doctorId': currentUserId,
          'hospitalId': hospitalId,
          'hospitalName': hospitalName,
          'date': dateStr,
          'timeSlots': timeSlots,
          'created': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // Clear cache to ensure fresh data
      clearCache();

      return {
        'success': true,
        'message': 'Availability saved successfully',
        'id': docRef.id,
      };
    } catch (e) {
      debugPrint('Error saving doctor availability: $e');
      return {
        'success': false,
        'message': 'Failed to save availability: ${e.toString()}',
      };
    }
  }

  // Delete a specific availability entry
  Future<Map<String, dynamic>> deleteAvailability({
    required String availabilityId,
  }) async {
    try {
      await _firestore
          .collection('doctor_availability')
          .doc(availabilityId)
          .delete();

      // Clear cache to ensure fresh data
      clearCache();

      return {
        'success': true,
        'message': 'Availability deleted successfully',
      };
    } catch (e) {
      debugPrint('Error deleting availability: $e');
      return {
        'success': false,
        'message': 'Failed to delete availability: ${e.toString()}',
      };
    }
  }

  // Get all available hospitals (for admin to assign doctors)
  Future<List<Map<String, dynamic>>> getAllHospitals() async {
    try {
      // Return cached data if available and not expired
      if (_cachedAllHospitals != null && _isCacheValid()) {
        return _cachedAllHospitals!;
      }

      final snapshot = await _firestore.collection('hospitals').get();

      final hospitals = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
      
      // Update cache
      _cachedAllHospitals = hospitals;
      _lastFetchTime = DateTime.now();
      
      return hospitals;
    } catch (e) {
      debugPrint('Error fetching hospitals: $e');
      return [];
    }
  }

  // Add a hospital to doctor's list
  Future<Map<String, dynamic>> addHospitalToDoctor({
    required String hospitalId,
    required String hospitalName,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if relation already exists
      final query = await _firestore
          .collection('doctor_hospitals')
          .where('doctorId', isEqualTo: currentUserId)
          .where('hospitalId', isEqualTo: hospitalId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Hospital already assigned to doctor',
        };
      }

      // Create the relation
      final docRef = await _firestore.collection('doctor_hospitals').add({
        'doctorId': currentUserId,
        'hospitalId': hospitalId,
        'hospitalName': hospitalName,
        'created': FieldValue.serverTimestamp(),
      });

      // Clear cache to ensure fresh data
      clearCache();

      return {
        'success': true,
        'message': 'Hospital added to doctor successfully',
        'id': docRef.id,
      };
    } catch (e) {
      debugPrint('Error adding hospital to doctor: $e');
      return {
        'success': false,
        'message': 'Failed to add hospital: ${e.toString()}',
      };
    }
  }
  
  // Create a new hospital and add it to doctor's list
  Future<Map<String, dynamic>> createHospital({
    required String name,
    required String city,
    String? address,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      // Create hospital data
      final Map<String, dynamic> hospitalData = {
        'name': name,
        'city': city,
        'address': address ?? '$name, $city',
        'email': null,
        'active': true,
        'created': FieldValue.serverTimestamp(),
        'createdBy': currentUserId, // Track who created this hospital
      };
      
      // Add to hospitals collection
      final hospitalRef = await _firestore.collection('hospitals').add(hospitalData);
      
      // Format the hospital name for display
      final String hospitalName = '$name, $city';
      
      // Add to doctor's hospitals
      final result = await addHospitalToDoctor(
        hospitalId: hospitalRef.id,
        hospitalName: hospitalName,
      );
      
      // Clear cache to ensure fresh data
      clearCache();
      
      if (!result['success']) {
        // If adding to doctor failed, still return success for hospital creation
        return {
          'success': true,
          'message': 'Hospital created but could not be added to your profile: ${result['message']}',
          'id': hospitalRef.id,
        };
      }
      
      return {
        'success': true,
        'message': 'Hospital created and added to your profile',
        'id': hospitalRef.id,
      };
    } catch (e) {
      debugPrint('Error creating hospital: $e');
      return {
        'success': false,
        'message': 'Failed to create hospital: ${e.toString()}',
      };
    }
  }
} 