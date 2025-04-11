import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache data
  static Map<String, dynamic>? _cachedDoctorProfile;
  static DateTime? _lastFetchTime;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if cache is valid
  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheExpiration;
  }

  // Clear cache
  void clearCache() {
    _cachedDoctorProfile = null;
    _lastFetchTime = null;
  }

  // Fetch doctor profile data from Firestore
  Future<Map<String, dynamic>> getDoctorProfile({bool forceRefresh = false}) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Return cached data if available and not expired
      if (_cachedDoctorProfile != null && _isCacheValid() && !forceRefresh) {
        return _cachedDoctorProfile!;
      }

      // Fetch the doctor data from Firestore
      final doctorDoc = await _firestore.collection('doctors').doc(currentUserId).get();
      
      if (!doctorDoc.exists) {
        throw Exception('Doctor profile not found');
      }

      // Get the data and add the ID
      final doctorData = {
        'id': doctorDoc.id,
        ...doctorDoc.data() ?? {},
      };
      
      // Update cache
      _cachedDoctorProfile = doctorData;
      _lastFetchTime = DateTime.now();
      
      return doctorData;
    } catch (e) {
      debugPrint('Error fetching doctor profile: $e');
      return {
        'error': e.toString(),
        'success': false,
      };
    }
  }

  // Get doctor statistics (appointments, ratings, earnings)
  Future<Map<String, dynamic>> getDoctorStats() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get total appointments
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: currentUserId)
          .get();
      
      int totalAppointments = appointmentsSnapshot.docs.length;
      int upcomingAppointments = 0;
      int completedAppointments = 0;
      double totalEarnings = 0.0;
      
      // Process each appointment
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        
        if (status == 'upcoming') {
          upcomingAppointments++;
        } else if (status == 'completed') {
          completedAppointments++;
          
          // Add to earnings if fee is available
          if (data.containsKey('fee')) {
            totalEarnings += (data['fee'] as num).toDouble();
          }
        }
      }
      
      // Get reviews data (if stored separately)
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('doctorId', isEqualTo: currentUserId)
          .get();
      
      int totalReviews = reviewsSnapshot.docs.length;
      double totalRating = 0;
      
      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('rating')) {
          totalRating += (data['rating'] as num).toDouble();
        }
      }
      
      double averageRating = totalReviews > 0 ? totalRating / totalReviews : 0;
      
      return {
        'success': true,
        'totalAppointments': totalAppointments,
        'upcomingAppointments': upcomingAppointments,
        'completedAppointments': completedAppointments,
        'totalEarnings': totalEarnings,
        'totalReviews': totalReviews,
        'averageRating': averageRating,
      };
    } catch (e) {
      debugPrint('Error fetching doctor stats: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get upcoming appointments for the doctor
  Future<List<Map<String, dynamic>>> getUpcomingAppointments({int limit = 5}) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'upcoming')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayDate))
          .orderBy('date', descending: false)
          .limit(limit)
          .get();
      
      return appointmentsSnapshot.docs.map((doc) {
        final data = doc.data();
        
        // Convert Timestamp to DateTime if needed
        DateTime? appointmentDate;
        if (data.containsKey('date') && data['date'] is Timestamp) {
          appointmentDate = (data['date'] as Timestamp).toDate();
        }
        
        return {
          'id': doc.id,
          'date': appointmentDate,
          'patientId': data['patientId'],
          'patientName': data['patientName'] ?? 'Unknown Patient',
          'timeSlot': data['timeSlot'] ?? '',
          'status': data['status'] ?? 'upcoming',
          'isOnline': data['isOnline'] ?? false,
          'fee': data['fee'] ?? 0,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching upcoming appointments: $e');
      return [];
    }
  }
} 