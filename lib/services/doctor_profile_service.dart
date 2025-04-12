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

  // Get doctor statistics
  Future<Map<String, dynamic>> getDoctorStats() async {
    try {
      final String uid = _auth.currentUser?.uid ?? '';
      
      if (uid.isEmpty) {
        return {
          'success': false,
          'message': 'User not authenticated'
        };
      }
      
      // Get initial stats from the stats document if it exists
      final doctorStatsDoc = await _firestore
          .collection('doctorStats')
          .doc(uid)
          .get();
      
      Map<String, dynamic> stats = {};
      
      if (doctorStatsDoc.exists && doctorStatsDoc.data() != null) {
        stats = doctorStatsDoc.data()!;
      }
      
      // Calculate earnings directly to ensure consistency
      final totalEarnings = await calculateDoctorEarnings(uid);
      
      // Count total appointments
      final appointmentsQuery = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: uid)
          .get();
          
      final int totalAppointments = appointmentsQuery.docs.length;
      
      // Count number of reviews
      int reviewCount = 0;
      try {
        final reviewsQuery = await _firestore
            .collection('reviews')
            .where('doctorId', isEqualTo: uid)
            .get();
            
        reviewCount = reviewsQuery.docs.length;
      } catch (e) {
        debugPrint('Error counting reviews: $e');
      }
      
      return {
        'success': true,
        'totalEarnings': totalEarnings,
        'totalAppointments': totalAppointments,
        'totalReviews': reviewCount,
        'completedAppointments': stats['completedAppointments'] ?? 0,
        'cancelledAppointments': stats['cancelledAppointments'] ?? 0,
        'upcomingAppointments': stats['upcomingAppointments'] ?? 0,
      };
    } catch (e) {
      debugPrint('Error getting doctor stats: $e');
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }

  // Calculate doctor earnings consistently across the app
  Future<double> calculateDoctorEarnings(String doctorId) async {
    double totalEarnings = 0.0;
    
    try {
      // Calculate earnings from appointments
      final completedAppointments = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'completed')
          .where('paymentStatus', isEqualTo: 'completed')
          .get();
          
      for (var doc in completedAppointments.docs) {
        final data = doc.data();
        if (data.containsKey('fee') && data['fee'] is num) {
          totalEarnings += (data['fee'] as num).toDouble();
        }
      }
      
      // Also check transactions collection if it exists
      final transactions = await _firestore
          .collection('transactions')
          .where('doctorId', isEqualTo: doctorId)
          .where('type', isEqualTo: 'payment')
          .where('status', isEqualTo: 'completed')
          .get();
          
      for (var doc in transactions.docs) {
        final data = doc.data();
        if (data.containsKey('amount') && data['amount'] is num) {
          totalEarnings += (data['amount'] as num).toDouble();
        }
      }
      
      return totalEarnings;
    } catch (e) {
      debugPrint('Error calculating earnings: $e');
      return 0.0;
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

  // Get selected hospitals for a doctor
  Future<List<String>> getDoctorSelectedHospitals() async {
    try {
      final String uid = _auth.currentUser?.uid ?? '';
      
      if (uid.isEmpty) {
        return [];
      }
      
      // First try to get from doctor profile
      final doctorDoc = await _firestore.collection('doctors').doc(uid).get();
      
      if (doctorDoc.exists && doctorDoc.data() != null) {
        final data = doctorDoc.data()!;
        
        // Check if there's a 'hospitals' field containing selected hospitals
        if (data.containsKey('hospitals') && data['hospitals'] is List) {
          return List<String>.from(data['hospitals']);
        }
        
        // Alternative: if there's a 'selectedHospitals' field
        if (data.containsKey('selectedHospitals') && data['selectedHospitals'] is List) {
          return List<String>.from(data['selectedHospitals']);
        }
      }
      
      // If not found in doctor profile, try the dedicated collection
      final hospitalsDoc = await _firestore
          .collection('doctorHospitals')
          .doc(uid)
          .get();
          
      if (hospitalsDoc.exists && hospitalsDoc.data() != null) {
        final data = hospitalsDoc.data()!;
        
        if (data.containsKey('selectedHospitals') && data['selectedHospitals'] is List) {
          return List<String>.from(data['selectedHospitals']);
        }
      }
      
      // Return empty list if no data found
      return [];
    } catch (e) {
      debugPrint('Error getting doctor selected hospitals: $e');
      return [];
    }
  }
} 