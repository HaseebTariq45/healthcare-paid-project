import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Dashboard stats cache
  Map<String, dynamic>? _dashboardStatsCache;
  DateTime? _lastStatsFetchTime;
  
  // Users/Doctors/Patients cache
  List<Map<String, dynamic>>? _doctorsCache;
  List<Map<String, dynamic>>? _patientsCache;
  DateTime? _lastUsersFetchTime;
  
  // Appointments cache
  List<Map<String, dynamic>>? _appointmentsCache;
  DateTime? _lastAppointmentsFetchTime;
  
  // Recent activities cache
  List<Map<String, dynamic>>? _recentActivitiesCache;
  DateTime? _lastActivitiesFetchTime;
  
  // Cache validity duration - 5 minutes
  final Duration _cacheDuration = const Duration(minutes: 5);
  
  // Check if cache is still valid
  bool _isCacheValid(DateTime? lastFetchTime) {
    if (lastFetchTime == null) return false;
    return DateTime.now().difference(lastFetchTime) < _cacheDuration;
  }
  
  // Clear all caches
  void clearAllCaches() {
    _dashboardStatsCache = null;
    _doctorsCache = null;
    _patientsCache = null;
    _appointmentsCache = null;
    _recentActivitiesCache = null;
    _lastStatsFetchTime = null;
    _lastUsersFetchTime = null;
    _lastAppointmentsFetchTime = null;
    _lastActivitiesFetchTime = null;
  }
  
  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Return cached data if available and not expired
      if (_dashboardStatsCache != null && _isCacheValid(_lastStatsFetchTime)) {
        return _dashboardStatsCache!;
      }
      
      // Get counts from Firestore collections
      final doctorsQuery = await _firestore.collection('users')
          .where('role', isEqualTo: 'doctor')
          .count()
          .get();
      
      final patientsQuery = await _firestore.collection('users')
          .where('role', isEqualTo: 'patient')
          .count()
          .get();
      
      final appointmentsQuery = await _firestore.collection('appointments')
          .count()
          .get();
      
      // Get total revenue (sum of all appointment fees)
      final appointmentsSnapshot = await _firestore.collection('appointments')
          .where('status', isNotEqualTo: 'cancelled')
          .get();
      
      double totalRevenue = 0;
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('fee') && data['fee'] != null) {
          try {
            totalRevenue += (data['fee'] is int) 
                ? (data['fee'] as int).toDouble() 
                : (data['fee'] is String) 
                    ? double.tryParse(data['fee'] as String) ?? 0 
                    : (data['fee'] as num?)?.toDouble() ?? 0;
          } catch (e) {
            debugPrint('Error calculating revenue: $e');
          }
        }
      }
      
      // Get counts of appointments by status
      final confirmedAppointmentsQuery = await _firestore.collection('appointments')
          .where('status', whereIn: ['confirmed', 'Confirmed'])
          .count()
          .get();
      
      final completedAppointmentsQuery = await _firestore.collection('appointments')
          .where('status', whereIn: ['completed', 'Completed'])
          .count()
          .get();
      
      final cancelledAppointmentsQuery = await _firestore.collection('appointments')
          .where('status', whereIn: ['cancelled', 'Cancelled'])
          .count()
          .get();
      
      // Create stats object
      final stats = {
        'doctorCount': doctorsQuery.count,
        'patientCount': patientsQuery.count,
        'appointmentCount': appointmentsQuery.count,
        'totalRevenue': totalRevenue,
        'revenueFormatted': 'Rs ${totalRevenue.toStringAsFixed(2)}',
        'confirmedAppointments': confirmedAppointmentsQuery.count,
        'completedAppointments': completedAppointmentsQuery.count,
        'cancelledAppointments': cancelledAppointmentsQuery.count,
        'lastUpdated': DateTime.now(),
      };
      
      // Update cache
      _dashboardStatsCache = stats;
      _lastStatsFetchTime = DateTime.now();
      
      return stats;
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      return {
        'doctorCount': '0',
        'patientCount': '0',
        'appointmentCount': '0',
        'totalRevenue': 0.0,
        'revenueFormatted': 'Rs 0.00',
        'confirmedAppointments': 0,
        'completedAppointments': 0,
        'cancelledAppointments': 0,
        'error': e.toString(),
        'lastUpdated': DateTime.now(),
      };
    }
  }
  
  // Get list of all doctors
  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    try {
      // Return cached data if available and not expired
      if (_doctorsCache != null && _isCacheValid(_lastUsersFetchTime)) {
        return _doctorsCache!;
      }
      
      debugPrint('🩺 Fetching doctors from Firestore...');
      
      // Query the doctors collection directly
      final snapshot = await _firestore.collection('doctors').get();
      debugPrint('📊 Found ${snapshot.docs.length} doctors in Firestore');
      
      if (snapshot.docs.isNotEmpty) {
        final sampleData = snapshot.docs.first.data();
        debugPrint('📝 Sample doctor data structure:');
        sampleData.forEach((key, value) {
          debugPrint('   $key: $value (${value?.runtimeType})');
        });
      }
      
      final doctors = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final doctorId = data['id'] ?? doc.id;
        
        // Get doctor's appointment count
        final appointmentsQuery = await _firestore.collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .count()
            .get();
        
        // Get doctor's reviews information if not already in data
        double rating = 0.0;
        int reviewCount = 0;
        
        if (data.containsKey('reviewCount')) {
          reviewCount = data['reviewCount'] is int 
              ? data['reviewCount'] 
              : (data['reviewCount'] is String ? int.tryParse(data['reviewCount']) ?? 0 : 0);
        }
        
        // If not provided in document, calculate average rating from reviews
        if (!data.containsKey('rating')) {
          try {
            final reviewsSnapshot = await _firestore
                .collection('doctor_reviews')
                .where('doctorId', isEqualTo: doctorId)
                .get();
                
            if (reviewsSnapshot.docs.isNotEmpty) {
              double totalRating = 0.0;
              for (var reviewDoc in reviewsSnapshot.docs) {
                final reviewData = reviewDoc.data();
                if (reviewData.containsKey('rating')) {
                  totalRating += (reviewData['rating'] is num) 
                      ? (reviewData['rating'] as num).toDouble() 
                      : 0.0;
                }
              }
              rating = totalRating / reviewsSnapshot.docs.length;
              reviewCount = reviewsSnapshot.docs.length;
            }
          } catch (e) {
            debugPrint('⚠️ Error calculating rating from reviews: $e');
          }
        } else {
          rating = data['rating'] is num 
              ? (data['rating'] as num).toDouble() 
              : (data['rating'] is String ? double.tryParse(data['rating']) ?? 0.0 : 0.0);
        }
        
        // Process education data
        List<Map<String, dynamic>> education = [];
        if (data.containsKey('education') && data['education'] is List) {
          education = (data['education'] as List).map((item) {
            if (item is Map) {
              final map = item as Map;
              return {
                'degree': map['degree']?.toString() ?? 'Unknown',
                'institution': map['institution']?.toString() ?? 'Unknown',
                'completionDate': map['completionDate']?.toString() ?? 'Unknown',
              };
            }
            return {'degree': 'Unknown', 'institution': 'Unknown', 'completionDate': 'Unknown'};
          }).toList().cast<Map<String, dynamic>>();
        }
        
        // Process languages
        List<String> languages = [];
        if (data.containsKey('languages') && data['languages'] is List) {
          languages = (data['languages'] as List)
              .map((item) => item?.toString() ?? '')
              .where((item) => item.isNotEmpty)
              .toList()
              .cast<String>();
        }
        
        // Process qualifications
        List<String> qualifications = [];
        if (data.containsKey('qualifications') && data['qualifications'] is List) {
          qualifications = (data['qualifications'] as List)
              .map((item) => item?.toString() ?? '')
              .where((item) => item.isNotEmpty)
              .toList()
              .cast<String>();
        }
        
        // Process available days
        List<String> availableDays = [];
        if (data.containsKey('availableDays') && data['availableDays'] is List) {
          availableDays = (data['availableDays'] as List)
              .map((item) => item?.toString() ?? '')
              .where((item) => item.isNotEmpty)
              .toList()
              .cast<String>();
        }
        
        return {
          'id': doctorId,
          'name': data['fullName'] ?? 'Unknown',
          'specialty': data['specialty'] ?? 'General',
          'phoneNumber': data['phoneNumber'] ?? 'N/A',
          'email': data['email'] ?? 'N/A',
          'profileImageUrl': data['profileImageUrl'],
          'experience': data['experience'] ?? 'N/A',
          'fee': data['fee'] ?? 0,
          'rating': rating.toStringAsFixed(1),
          'reviewCount': reviewCount,
          'city': data['city'] ?? 'N/A',
          'address': data['address'] ?? 'N/A',
          'bio': data['bio'] ?? 'No bio available',
          'languages': languages,
          'qualifications': qualifications,
          'education': education,
          'availableDays': availableDays,
          'appointmentCount': appointmentsQuery.count,
          'verified': data['isVerified'] ?? false,
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
          'status': data['isActive'] == false ? 'Inactive' : 'Active',
          'profileComplete': data['profileComplete'] ?? false,
        };
      }));
      
      // Update cache
      _doctorsCache = doctors;
      _lastUsersFetchTime = DateTime.now();
      
      return doctors;
    } catch (e) {
      debugPrint('❌ Error fetching doctors: $e');
      return [];
    }
  }
  
  // Get list of all patients
  Future<List<Map<String, dynamic>>> getAllPatients() async {
    try {
      // Return cached data if available and not expired
      if (_patientsCache != null && _isCacheValid(_lastUsersFetchTime)) {
        return _patientsCache!;
      }
      
      final snapshot = await _firestore.collection('users')
          .where('role', isEqualTo: 'patient')
          .get();
      
      final patients = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        
        // Get patient's appointment count
        final appointmentsQuery = await _firestore.collection('appointments')
            .where('patientId', isEqualTo: doc.id)
            .count()
            .get();
        
        return {
          'id': doc.id,
          'name': data['fullName'] ?? 'Unknown',
          'gender': data['gender'] ?? 'Not specified',
          'age': data['dateOfBirth'] != null 
              ? _calculateAge(data['dateOfBirth']) 
              : 'N/A',
          'phoneNumber': data['phoneNumber'] ?? 'N/A',
          'email': data['email'] ?? 'N/A',
          'profileImageUrl': data['profileImageUrl'],
          'appointmentCount': appointmentsQuery.count,
          'createdAt': data['createdAt'],
          'lastLogin': data['lastLogin'],
          'status': data['active'] == false ? 'Inactive' : 'Active',
        };
      }));
      
      // Update cache
      _patientsCache = patients;
      if (_lastUsersFetchTime == null) {
        _lastUsersFetchTime = DateTime.now();
      }
      
      return patients;
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      return [];
    }
  }
  
  // Get all appointments
  Future<List<Map<String, dynamic>>> getAllAppointments() async {
    try {
      debugPrint('🔍 Starting getAllAppointments...');
      
      // Return cached data if available and not expired
      if (_appointmentsCache != null && _isCacheValid(_lastAppointmentsFetchTime)) {
        debugPrint('📦 Returning cached appointments: ${_appointmentsCache!.length} items');
        return _appointmentsCache!;
      }
      
      debugPrint('🔄 Cache invalid or empty, fetching from Firestore...');
      
      // Query appointments with fallback date fields
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _firestore.collection('appointments')
            .orderBy('appointmentDate', descending: true)
            .limit(100)
            .get();
            
        if (snapshot.docs.isEmpty) {
          debugPrint('⚠️ No appointments found with appointmentDate, trying date field...');
          snapshot = await _firestore.collection('appointments')
              .orderBy('date', descending: true)
              .limit(100)
              .get();
        }
      } catch (e) {
        debugPrint('⚠️ Error with ordered query: $e');
        debugPrint('🔄 Falling back to unordered query...');
        snapshot = await _firestore.collection('appointments').limit(100).get();
      }
      
      debugPrint('📊 Found ${snapshot.docs.length} appointments in Firestore');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('❌ No appointments found in database');
        return [];
      }
      
      // Sample the first document to debug data structure
      if (snapshot.docs.isNotEmpty) {
        final sampleData = snapshot.docs.first.data();
        debugPrint('📝 Sample appointment data structure:');
        sampleData.forEach((key, value) {
          debugPrint('   $key: $value (${value?.runtimeType})');
        });
      }
      
      final appointments = await Future.wait(snapshot.docs.map((doc) async {
        try {
          final data = doc.data();
          debugPrint('Processing appointment ${doc.id}...');
          
          // Get doctor details
          String doctorName = "Unknown Doctor";
          String specialty = "Unknown";
          if (data['doctorId'] != null) {
            final doctorDoc = await _firestore.collection('users')
                .doc(data['doctorId'])
                .get();
            
            if (doctorDoc.exists) {
              final doctorData = doctorDoc.data();
              doctorName = doctorData?['fullName'] ?? doctorData?['name'] ?? "Unknown Doctor";
              specialty = doctorData?['specialty'] ?? "Unknown";
            }
          }
          
          // Get patient details
          String patientName = "Unknown Patient";
          if (data['patientId'] != null) {
            final patientDoc = await _firestore.collection('users')
                .doc(data['patientId'])
                .get();
            
            if (patientDoc.exists) {
              final patientData = patientDoc.data();
              patientName = patientData?['fullName'] ?? patientData?['name'] ?? "Unknown Patient";
            }
          }
          
          // Format date with fallbacks
          DateTime appointmentDate;
          try {
            if (data['appointmentDate'] != null) {
              appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
            } else if (data['date'] != null) {
              if (data['date'] is Timestamp) {
                appointmentDate = (data['date'] as Timestamp).toDate();
              } else if (data['date'] is String) {
                appointmentDate = DateTime.parse(data['date'] as String);
              } else {
                appointmentDate = DateTime.now();
              }
            } else {
              appointmentDate = DateTime.now();
            }
          } catch (e) {
            debugPrint('⚠️ Error parsing date for appointment ${doc.id}: $e');
            appointmentDate = DateTime.now();
          }
          
          String formattedDate = "${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}";
          String formattedTime = data['time'] ?? 
                             "${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')}";
          
          // Determine status
          String status = data['status']?.toString().toLowerCase() ?? 'pending';
          if (status == 'pending' || status == 'confirmed') {
            if (_isAppointmentPast(appointmentDate, formattedTime)) {
              status = 'completed';
            }
          }
          
          String displayStatus = status.substring(0, 1).toUpperCase() + status.substring(1);
          
          return {
            'id': doc.id,
            'patientId': data['patientId'],
            'doctorId': data['doctorId'],
            'patientName': patientName,
            'doctorName': doctorName,
            'specialty': specialty,
            'date': formattedDate,
            'time': formattedTime,
            'hospital': data['hospitalName'] ?? data['hospital'] ?? "Unknown Hospital",
            'reason': data['reason'] ?? data['notes'] ?? 'Consultation',
            'status': displayStatus,
            'statusRaw': status,
            'amount': data['fee'] ?? 0,
            'type': 'In-Person Visit',
            'displayAmount': data['fee'] != null ? "Rs ${data['fee']}" : "Free",
            'actualDate': appointmentDate,
            'paymentStatus': data['paymentStatus'] ?? 'pending',
            'created': data['created'],
          };
        } catch (e) {
          debugPrint('❌ Error processing appointment ${doc.id}: $e');
          return null;
        }
      }));
      
      // Filter out any null appointments from errors
      final validAppointments = appointments.where((a) => a != null).cast<Map<String, dynamic>>().toList();
      
      debugPrint('✅ Successfully processed ${validAppointments.length} appointments');
      
      // Update cache
      _appointmentsCache = validAppointments;
      _lastAppointmentsFetchTime = DateTime.now();
      
      return validAppointments;
    } catch (e) {
      debugPrint('❌ Error in getAllAppointments: $e');
      return [];
    }
  }
  
  // Get recent activities for dashboard
  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      // Return cached data if available and not expired
      if (_recentActivitiesCache != null && _isCacheValid(_lastActivitiesFetchTime)) {
        return _recentActivitiesCache!;
      }
      
      List<Map<String, dynamic>> activities = [];
      
      // Get recent appointments
      final appointmentsSnapshot = await _firestore.collection('appointments')
          .orderBy('created', descending: true)
          .limit(5)
          .get();
      
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        
        // Get patient name
        String patientName = "Unknown Patient";
        if (data['patientId'] != null) {
          final patientDoc = await _firestore.collection('users')
              .doc(data['patientId'])
              .get();
          
          if (patientDoc.exists) {
            final patientData = patientDoc.data();
            patientName = patientData?['fullName'] ?? "Unknown Patient";
          }
        }
        
        // Get doctor name
        String doctorName = "Unknown Doctor";
        if (data['doctorId'] != null) {
          final doctorDoc = await _firestore.collection('users')
              .doc(data['doctorId'])
              .get();
          
          if (doctorDoc.exists) {
            final doctorData = doctorDoc.data();
            doctorName = doctorData?['fullName'] ?? "Unknown Doctor";
          }
        }
        
        String status = data['status'] ?? 'Pending';
        IconData icon;
        Color color;
        
        // Set icon and color based on status
        switch (status.toLowerCase()) {
          case 'confirmed':
            icon = Icons.check_circle;
            color = Colors.green;
            break;
          case 'cancelled':
            icon = Icons.cancel;
            color = Colors.red;
            break;
          case 'completed':
            icon = Icons.done_all;
            color = Colors.blue;
            break;
          default:
            icon = Icons.schedule;
            color = Colors.orange;
        }
        
        DateTime createdAt = data['created'] != null 
            ? (data['created'] as Timestamp).toDate() 
            : DateTime.now();
        
        activities.add({
          'title': 'New Appointment',
          'description': '$patientName booked an appointment with $doctorName',
          'time': _getTimeAgo(createdAt),
          'timestamp': createdAt,
          'icon': icon,
          'color': color,
          'type': 'appointment',
        });
      }
      
      // Get recent user registrations
      final usersSnapshot = await _firestore.collection('users')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        String role = data['role'] ?? 'user';
        String name = data['fullName'] ?? 'Unknown User';
        
        IconData icon;
        Color color;
        String title;
        
        // Set icon, color, and title based on role
        switch (role.toLowerCase()) {
          case 'doctor':
            icon = Icons.medical_services;
            color = Colors.blue;
            title = 'New Doctor Registration';
            break;
          case 'patient':
            icon = Icons.person;
            color = Colors.green;
            title = 'New Patient Registration';
            break;
          default:
            icon = Icons.person_add;
            color = Colors.purple;
            title = 'New User Registration';
        }
        
        DateTime createdAt = data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate() 
            : DateTime.now();
        
        activities.add({
          'title': title,
          'description': '$name has registered as a ${role.substring(0, 1).toUpperCase() + role.substring(1)}',
          'time': _getTimeAgo(createdAt),
          'timestamp': createdAt,
          'icon': icon,
          'color': color,
          'type': 'registration',
        });
      }
      
      // Sort activities by timestamp
      activities.sort((a, b) => 
        (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
      
      // Limit to 10 most recent activities
      if (activities.length > 10) {
        activities = activities.sublist(0, 10);
      }
      
      // Update cache
      _recentActivitiesCache = activities;
      _lastActivitiesFetchTime = DateTime.now();
      
      return activities;
    } catch (e) {
      debugPrint('Error fetching recent activities: $e');
      return [];
    }
  }
  
  // Update doctor verification status
  Future<Map<String, dynamic>> updateDoctorVerification(String doctorId, bool isVerified) async {
    try {
      await _firestore.collection('users').doc(doctorId).update({
        'verified': isVerified,
        'verifiedAt': isVerified ? FieldValue.serverTimestamp() : null,
        'verifiedBy': isVerified ? _auth.currentUser?.uid : null,
      });
      
      // Clear cache to ensure fresh data
      _doctorsCache = null;
      _lastUsersFetchTime = null;
      
      return {
        'success': true,
        'message': 'Doctor verification status updated successfully',
      };
    } catch (e) {
      debugPrint('Error updating doctor verification: $e');
      return {
        'success': false,
        'message': 'Failed to update doctor verification status: ${e.toString()}',
      };
    }
  }
  
  // Update doctor active status (block/unblock)
  Future<Map<String, dynamic>> updateDoctorActiveStatus(String doctorId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(doctorId).update({
        'active': isActive,
        'blockedAt': isActive ? null : FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
      
      // Clear cache to ensure fresh data
      _doctorsCache = null;
      _lastUsersFetchTime = null;
      
      return {
        'success': true,
        'message': isActive ? 'Doctor unblocked successfully' : 'Doctor blocked successfully',
      };
    } catch (e) {
      debugPrint('Error updating doctor active status: $e');
      return {
        'success': false,
        'message': 'Failed to update doctor active status: ${e.toString()}',
      };
    }
  }
  
  // Update doctor status (wrapper method)
  Future<Map<String, dynamic>> updateDoctorStatus(String doctorId, String status) async {
    try {
      bool isActive = status.toLowerCase() == 'active';
      
      // Update in users collection
      await _firestore.collection('users').doc(doctorId).update({
        'status': status,
        'active': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
      
      // Also try to update in doctors collection if it exists
      try {
        await _firestore.collection('doctors').doc(doctorId).update({
          'status': status,
          'isActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Doctor not found in doctors collection: $e');
      }
      
      // Clear cache to ensure fresh data
      _doctorsCache = null;
      _lastUsersFetchTime = null;
      
      return {
        'success': true,
        'message': isActive 
            ? 'Doctor activated successfully' 
            : 'Doctor deactivated successfully',
      };
    } catch (e) {
      debugPrint('Error updating doctor status: $e');
      return {
        'success': false,
        'message': 'Failed to update doctor status: ${e.toString()}',
      };
    }
  }
  
  // Delete doctor and associated data
  Future<Map<String, dynamic>> deleteDoctor(String doctorId) async {
    try {
      // Delete doctor from users collection
      await _firestore.collection('users').doc(doctorId).delete();
      
      // Get and delete hospital associations
      final hospitalDocs = await _firestore
          .collection('doctor_hospitals')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      
      // Create a batch to delete all hospital associations
      final batch = _firestore.batch();
      for (var doc in hospitalDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // Clear cache to ensure fresh data
      _doctorsCache = null;
      _lastUsersFetchTime = null;
      
      return {
        'success': true,
        'message': 'Doctor deleted successfully',
      };
    } catch (e) {
      debugPrint('Error deleting doctor: $e');
      return {
        'success': false,
        'message': 'Failed to delete doctor: ${e.toString()}',
      };
    }
  }
  
  // Update doctor details
  Future<Map<String, dynamic>> updateDoctorDetails(String doctorId, Map<String, dynamic> data) async {
    try {
      // Add updated timestamp
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['updatedBy'] = _auth.currentUser?.uid;
      
      // Update doctor document
      await _firestore.collection('users').doc(doctorId).update(data);
      
      // Clear cache to ensure fresh data
      _doctorsCache = null;
      _lastUsersFetchTime = null;
      
      return {
        'success': true,
        'message': 'Doctor details updated successfully',
      };
    } catch (e) {
      debugPrint('Error updating doctor details: $e');
      return {
        'success': false,
        'message': 'Failed to update doctor details: ${e.toString()}',
      };
    }
  }
  
  // Update appointment status
  Future<Map<String, dynamic>> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
      
      // Clear cache to ensure fresh data
      _appointmentsCache = null;
      _lastAppointmentsFetchTime = null;
      
      return {
        'success': true,
        'message': 'Appointment status updated successfully',
      };
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      return {
        'success': false,
        'message': 'Failed to update appointment status: ${e.toString()}',
      };
    }
  }
  
  // Calculate age from date of birth
  int _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return 0;
    
    DateTime birthDate;
    if (dateOfBirth is Timestamp) {
      birthDate = dateOfBirth.toDate();
    } else if (dateOfBirth is DateTime) {
      birthDate = dateOfBirth;
    } else {
      return 0;
    }
    
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    // Check if birthday hasn't occurred this year yet
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }
  
  // Get time ago string (e.g. "2 hours ago")
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
  
  // Check if an appointment has already passed
  bool _isAppointmentPast(DateTime appointmentDate, String timeStr) {
    final now = DateTime.now();
    
    // First check if the date is in the past
    if (appointmentDate.year < now.year ||
        (appointmentDate.year == now.year && appointmentDate.month < now.month) ||
        (appointmentDate.year == now.year && appointmentDate.month == now.month && appointmentDate.day < now.day)) {
      return true;
    }
    
    // If it's today, check if the time has passed
    if (appointmentDate.year == now.year && 
        appointmentDate.month == now.month && 
        appointmentDate.day == now.day) {
      
      // Parse the time string (HH:MM AM/PM format)
      final parsedTime = _parseTimeString(timeStr);
      
      // Check if the appointment time has passed
      final appointmentDateTime = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        parsedTime.hour,
        parsedTime.minute,
      );
      
      return now.isAfter(appointmentDateTime);
    }
    
    return false;
  }
  
  // Helper method to parse time strings like "10:30 AM" or "02:15 PM"
  TimeOfDay _parseTimeString(String timeStr) {
    // Default to noon if parsing fails
    TimeOfDay result = TimeOfDay(hour: 12, minute: 0);
    
    try {
      timeStr = timeStr.trim().toUpperCase();
      
      bool isPM = timeStr.contains('PM');
      
      // Remove AM/PM indicator
      timeStr = timeStr.replaceAll(' AM', '').replaceAll(' PM', '');
      
      // Split hours and minutes
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        
        // Convert to 24-hour format if PM
        if (isPM && hour < 12) {
          hour += 12;
        } else if (!isPM && hour == 12) {
          hour = 0;
        }
        
        result = TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      debugPrint('Error parsing time string: $e');
    }
    
    return result;
  }
  
  // Get appointments by date range for analytics
  Future<Map<String, dynamic>> getAppointmentsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      debugPrint('Fetching appointments from ${startDate.toString()} to ${endDate.toString()}');
      
      // Query appointments by date range
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _firestore.collection('appointments')
            .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .orderBy('appointmentDate')
            .get();
        
        debugPrint('Found ${snapshot.docs.length} appointments in date range');
      } catch (e) {
        debugPrint('Error in date range query: $e');
        // Fallback to get all appointments if specific query fails
        debugPrint('Falling back to fetch all appointments');
        snapshot = await _firestore.collection('appointments').get();
      }
      
      // Prepare data for charts
      Map<String, int> appointmentsByDay = {};
      Map<String, double> revenueByDay = {};
      int totalAppointments = 0;
      double totalRevenue = 0;
      
      // Count appointments by status
      int confirmedCount = 0;
      int completedCount = 0;
      int cancelledCount = 0;
      
      // Specialty distribution
      Map<String, int> specialtyDistribution = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Get appointment date - handle missing or invalid appointmentDate
        DateTime appointmentDate;
        try {
          if (data['appointmentDate'] is Timestamp) {
            appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
          } else if (data['date'] is Timestamp) {
            appointmentDate = (data['date'] as Timestamp).toDate();
          } else {
            appointmentDate = DateTime.now();
          }
          
          // Skip if outside our date range (for the fallback query)
          if (appointmentDate.isBefore(startDate) || appointmentDate.isAfter(endDate)) {
            continue;
          }
          
          totalAppointments++;
          
          // Format date as key (YYYY-MM-DD)
          final dateKey = "${appointmentDate.year}-${appointmentDate.month.toString().padLeft(2, '0')}-${appointmentDate.day.toString().padLeft(2, '0')}";
          
          // Increment appointment count for this day
          appointmentsByDay[dateKey] = (appointmentsByDay[dateKey] ?? 0) + 1;
          
          // Add fee to revenue for this day
          double fee = 0.0;
          try {
            if (data['fee'] != null) {
              if (data['fee'] is int) {
                fee = (data['fee'] as int).toDouble();
              } else if (data['fee'] is double) {
                fee = data['fee'] as double;
              } else if (data['fee'] is String) {
                fee = double.tryParse(data['fee'] as String) ?? 0.0;
              }
            }
          } catch (e) {
            debugPrint('Error parsing fee: $e');
          }
          
          revenueByDay[dateKey] = (revenueByDay[dateKey] ?? 0) + fee;
          totalRevenue += fee;
          
          // Count by status
          final status = (data['status'] ?? '').toString().toLowerCase();
          if (status == 'confirmed') {
            confirmedCount++;
          } else if (status == 'completed') {
            completedCount++;
          } else if (status == 'cancelled') {
            cancelledCount++;
          }
          
          // Get specialty data
          if (data['doctorId'] != null) {
            try {
              final doctorDoc = await _firestore.collection('users')
                  .doc(data['doctorId'])
                  .get();
                  
              if (doctorDoc.exists) {
                final doctorData = doctorDoc.data();
                final specialty = doctorData?['specialty'] ?? 'Unknown';
                specialtyDistribution[specialty] = (specialtyDistribution[specialty] ?? 0) + 1;
              }
            } catch (e) {
              // Ignore errors fetching individual doctor data
              debugPrint('Error fetching doctor data: $e');
            }
          }
        } catch (e) {
          debugPrint('Error processing appointment document: $e');
          // Continue to next appointment
          continue;
        }
      }
      
      debugPrint('Processed data: $totalAppointments appointments, Rs $totalRevenue revenue');
      
      return {
        'totalAppointments': totalAppointments,
        'totalRevenue': totalRevenue,
        'appointmentsByDay': appointmentsByDay,
        'revenueByDay': revenueByDay,
        'confirmedCount': confirmedCount,
        'completedCount': completedCount,
        'cancelledCount': cancelledCount,
        'specialtyDistribution': specialtyDistribution,
      };
    } catch (e) {
      debugPrint('Error fetching appointments by date range: $e');
      return {
        'totalAppointments': 0,
        'totalRevenue': 0.0,
        'appointmentsByDay': {},
        'revenueByDay': {},
        'confirmedCount': 0,
        'completedCount': 0,
        'cancelledCount': 0,
        'specialtyDistribution': {},
      };
    }
  }
  
  // Get growth metrics comparing current period with previous period
  Future<Map<String, dynamic>> getGrowthMetrics(String period) async {
    try {
      debugPrint('Starting getGrowthMetrics for period: $period');
      
      DateTime now = DateTime.now();
      DateTime currentPeriodStart;
      DateTime currentPeriodEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      DateTime previousPeriodStart;
      DateTime previousPeriodEnd;
      
      // Define date ranges based on selected period
      switch (period) {
        case 'Last 7 days':
          currentPeriodStart = DateTime(now.year, now.month, now.day - 6);
          previousPeriodStart = DateTime(now.year, now.month, now.day - 13);
          previousPeriodEnd = DateTime(now.year, now.month, now.day - 7, 23, 59, 59);
          break;
        case 'Last 30 days':
          currentPeriodStart = DateTime(now.year, now.month, now.day - 29);
          previousPeriodStart = DateTime(now.year, now.month, now.day - 59);
          previousPeriodEnd = DateTime(now.year, now.month, now.day - 30, 23, 59, 59);
          break;
        case 'Last 3 months':
          currentPeriodStart = DateTime(now.year, now.month - 2, now.day);
          previousPeriodStart = DateTime(now.year, now.month - 5, now.day);
          previousPeriodEnd = DateTime(now.year, now.month - 3, now.day, 23, 59, 59);
          break;
        case 'Last year':
          currentPeriodStart = DateTime(now.year - 1, now.month, now.day);
          previousPeriodStart = DateTime(now.year - 2, now.month, now.day);
          previousPeriodEnd = DateTime(now.year - 1, now.month, now.day, 23, 59, 59);
          break;
        default:
          currentPeriodStart = DateTime(now.year, now.month, now.day - 29);
          previousPeriodStart = DateTime(now.year, now.month, now.day - 59);
          previousPeriodEnd = DateTime(now.year, now.month, now.day - 30, 23, 59, 59);
      }
      
      debugPrint('Date ranges calculated: Current period: ${currentPeriodStart.toString()} to ${currentPeriodEnd.toString()}');
      
      // Get current period data
      debugPrint('Getting current period appointment data...');
      final currentPeriodData = await getAppointmentsByDateRange(
        currentPeriodStart, 
        currentPeriodEnd
      );
      
      // Get previous period data
      debugPrint('Getting previous period appointment data...');
      final previousPeriodData = await getAppointmentsByDateRange(
        previousPeriodStart,
        previousPeriodEnd
      );
      
      // Calculate growth percentages
      double appointmentGrowth = 0;
      double revenueGrowth = 0;
      
      if (previousPeriodData['totalAppointments'] > 0) {
        appointmentGrowth = ((currentPeriodData['totalAppointments'] - 
                              previousPeriodData['totalAppointments']) / 
                              previousPeriodData['totalAppointments']) * 100;
      } else if (currentPeriodData['totalAppointments'] > 0) {
        appointmentGrowth = 100; // If previous was 0 and current is positive, 100% growth
      }
      
      if (previousPeriodData['totalRevenue'] > 0) {
        revenueGrowth = ((currentPeriodData['totalRevenue'] - 
                          previousPeriodData['totalRevenue']) / 
                          previousPeriodData['totalRevenue']) * 100;
      } else if (currentPeriodData['totalRevenue'] > 0) {
        revenueGrowth = 100; // If previous was 0 and current is positive, 100% growth
      }
      
      debugPrint('Calculated growth rates: Appointments: $appointmentGrowth%, Revenue: $revenueGrowth%');
      
      // Calculate new user growth (patiens and doctors)
      try {
        debugPrint('Querying for patient and doctor counts...');
        
        // Safe Firestore queries with error handling
        int currentPatientCount = 0;
        int previousPatientCount = 0;
        int currentDoctorCount = 0; 
        int previousDoctorCount = 0;
        
        try {
          currentPatientCount = await _getUserCountWithDateFilter('patient', currentPeriodStart, currentPeriodEnd);
          debugPrint('Current period patients count: $currentPatientCount');
        } catch (e) {
          debugPrint('Error getting current period patients: $e');
        }
        
        try {
          previousPatientCount = await _getUserCountWithDateFilter('patient', previousPeriodStart, previousPeriodEnd);
          debugPrint('Previous period patients count: $previousPatientCount');
        } catch (e) {
          debugPrint('Error getting previous period patients: $e');
        }
        
        try {
          currentDoctorCount = await _getUserCountWithDateFilter('doctor', currentPeriodStart, currentPeriodEnd);
          debugPrint('Current period doctors count: $currentDoctorCount');
        } catch (e) {
          debugPrint('Error getting current period doctors: $e');
        }
        
        try {
          previousDoctorCount = await _getUserCountWithDateFilter('doctor', previousPeriodStart, previousPeriodEnd);
          debugPrint('Previous period doctors count: $previousDoctorCount');
        } catch (e) {
          debugPrint('Error getting previous period doctors: $e');
        }
        
        double patientGrowth = 0;
        double doctorGrowth = 0;
        
        if (previousPatientCount > 0) {
          patientGrowth = ((currentPatientCount - previousPatientCount) / 
                            previousPatientCount) * 100;
        } else if (currentPatientCount > 0) {
          patientGrowth = 100;
        }
        
        if (previousDoctorCount > 0) {
          doctorGrowth = ((currentDoctorCount - previousDoctorCount) / 
                          previousDoctorCount) * 100;
        } else if (currentDoctorCount > 0) {
          doctorGrowth = 100;
        }
        
        debugPrint('Calculated user growth: Patients: $patientGrowth%, Doctors: $doctorGrowth%');
        
        final result = {
          'appointmentGrowth': appointmentGrowth,
          'revenueGrowth': revenueGrowth,
          'patientGrowth': patientGrowth,
          'doctorGrowth': doctorGrowth,
          'currentPeriodAppointments': currentPeriodData['totalAppointments'],
          'currentPeriodRevenue': currentPeriodData['totalRevenue'],
          'currentPeriodPatients': currentPatientCount,
          'currentPeriodDoctors': currentDoctorCount,
          'appointmentsByDay': currentPeriodData['appointmentsByDay'],
          'revenueByDay': currentPeriodData['revenueByDay'],
          'specialtyDistribution': currentPeriodData['specialtyDistribution'],
        };
        
        debugPrint('Successfully built analytics data');
        return result;
      } catch (e) {
        debugPrint('Error in user growth calculation: $e');
        // Continue with partial data
        return {
          'appointmentGrowth': appointmentGrowth,
          'revenueGrowth': revenueGrowth,
          'patientGrowth': 0,
          'doctorGrowth': 0,
          'currentPeriodAppointments': currentPeriodData['totalAppointments'],
          'currentPeriodRevenue': currentPeriodData['totalRevenue'],
          'currentPeriodPatients': 0,
          'currentPeriodDoctors': 0,
          'appointmentsByDay': currentPeriodData['appointmentsByDay'],
          'revenueByDay': currentPeriodData['revenueByDay'],
          'specialtyDistribution': currentPeriodData['specialtyDistribution'],
        };
      }
    } catch (e, stackTrace) {
      debugPrint('Error in getGrowthMetrics: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Return empty data with error flag
      return {
        'error': true,
        'errorMessage': e.toString(),
        'appointmentGrowth': 0,
        'revenueGrowth': 0,
        'patientGrowth': 0,
        'doctorGrowth': 0,
        'currentPeriodAppointments': 0,
        'currentPeriodRevenue': 0,
        'currentPeriodPatients': 0,
        'currentPeriodDoctors': 0,
        'appointmentsByDay': {},
        'revenueByDay': {},
        'specialtyDistribution': {},
      };
    }
  }
  
  // Separate method to safely get user count with createdAt filter
  Future<int> _getUserCountWithDateFilter(String role, DateTime startDate, DateTime endDate) async {
    try {
      // First try with createdAt filter
      try {
        final querySnapshot = await _firestore.collection('users')
            .where('role', isEqualTo: role)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .count()
            .get();
        return querySnapshot.count ?? 0;
      } catch (e) {
        debugPrint('Error getting $role count with createdAt filter: $e');
        
        // If that fails, try a manual approach by fetching all users with role and checking dates manually
        final querySnapshot = await _firestore.collection('users')
            .where('role', isEqualTo: role)
            .get();
        
        // Count users with createdAt in the date range
        int count = 0;
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
            final createdAt = (data['createdAt'] as Timestamp).toDate();
            if (createdAt.isAfter(startDate) && createdAt.isBefore(endDate)) {
              count++;
            }
          }
        }
        
        return count;
      }
    } catch (e) {
      debugPrint('Error in _getUserCountWithDateFilter: $e');
      return 0;
    }
  }
} 