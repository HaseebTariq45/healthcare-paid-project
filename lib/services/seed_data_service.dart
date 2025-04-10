import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthcare/utils/date_formatter.dart';

/// This class is used to seed data for testing purposes only
/// It should not be included in production code
class SeedDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add sample hospitals to Firestore
  Future<Map<String, dynamic>> seedHospitals() async {
    try {
      final List<Map<String, dynamic>> hospitals = [
        {
          'name': 'Aga Khan Hospital',
          'city': 'Karachi',
          'address': 'Stadium Road, Karachi',
          'phoneNumber': '+92213486123',
          'email': 'info@aku.edu',
          'active': true,
          'created': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Shaukat Khanum Hospital',
          'city': 'Lahore',
          'address': '7A Block R3, Johar Town, Lahore',
          'phoneNumber': '+924235945100',
          'email': 'info@shaukatkhanum.org.pk',
          'active': true,
          'created': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Jinnah Hospital',
          'city': 'Karachi',
          'address': 'Rafiqui Shaheed Road, Karachi',
          'phoneNumber': '+922199201300',
          'email': 'info@jpmc.edu.pk',
          'active': true,
          'created': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Liaquat National Hospital',
          'city': 'Karachi',
          'address': 'Stadium Road, Karachi',
          'phoneNumber': '+922134412271',
          'email': 'info@lnh.edu.pk',
          'active': true,
          'created': FieldValue.serverTimestamp(),
        },
      ];

      // Add hospitals to Firestore
      final batch = _firestore.batch();
      final hospitalRefs = <DocumentReference>[];
      
      for (final hospital in hospitals) {
        final docRef = _firestore.collection('hospitals').doc();
        hospitalRefs.add(docRef);
        batch.set(docRef, hospital);
      }
      
      // Execute batch
      await batch.commit();
      
      // If user is a doctor, assign these hospitals to them
      if (currentUserId != null) {
        final userDoc = await _firestore.collection('users').doc(currentUserId).get();
        if (userDoc.exists && userDoc.data()?['role'] == 'doctor') {
          final doctorBatch = _firestore.batch();
          
          for (var i = 0; i < hospitalRefs.length; i++) {
            final docRef = _firestore.collection('doctor_hospitals').doc();
            doctorBatch.set(docRef, {
              'doctorId': currentUserId,
              'hospitalId': hospitalRefs[i].id,
              'hospitalName': '${hospitals[i]['name']}, ${hospitals[i]['city']}',
              'created': FieldValue.serverTimestamp(),
            });
          }
          
          await doctorBatch.commit();
        }
      }
      
      return {
        'success': true,
        'message': 'Successfully added ${hospitals.length} hospitals',
        'count': hospitals.length,
      };
    } catch (e) {
      debugPrint('Error seeding hospitals: $e');
      return {
        'success': false,
        'message': 'Failed to seed hospitals: ${e.toString()}',
      };
    }
  }

  // Delete all hospitals and doctor_hospitals data
  Future<Map<String, dynamic>> cleanupHospitals() async {
    try {
      // Delete all hospitals
      final hospitalsSnapshot = await _firestore.collection('hospitals').get();
      final batch = _firestore.batch();
      
      for (final doc in hospitalsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Delete all doctor_hospitals connections
      final doctorHospitalsSnapshot = await _firestore.collection('doctor_hospitals').get();
      final doctorHospitalsBatch = _firestore.batch();
      
      for (final doc in doctorHospitalsSnapshot.docs) {
        doctorHospitalsBatch.delete(doc.reference);
      }
      
      await doctorHospitalsBatch.commit();
      
      return {
        'success': true,
        'message': 'Successfully cleaned up hospital data',
        'hospitalsDeleted': hospitalsSnapshot.docs.length,
        'doctorHospitalsDeleted': doctorHospitalsSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('Error cleaning up hospitals: $e');
      return {
        'success': false,
        'message': 'Failed to clean up hospitals: ${e.toString()}',
      };
    }
  }
  
  // Add a quick availability for a doctor (today and tomorrow)
  Future<Map<String, dynamic>> addQuickAvailability() async {
    try {
      if (currentUserId == null) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }
      
      // Get first hospital for the doctor
      final hospitalDoc = await _firestore
          .collection('doctor_hospitals')
          .where('doctorId', isEqualTo: currentUserId)
          .limit(1)
          .get();
      
      if (hospitalDoc.docs.isEmpty) {
        return {
          'success': false,
          'message': 'No hospitals found for this doctor',
        };
      }
      
      final hospitalData = hospitalDoc.docs[0].data();
      final String hospitalId = hospitalData['hospitalId'];
      final String hospitalName = hospitalData['hospitalName'];
      
      // Create availability for today and tomorrow
      final today = DateTime.now();
      final tomorrow = today.add(Duration(days: 1));
      
      final List<Map<String, dynamic>> availabilityEntries = [
        {
          'doctorId': currentUserId,
          'hospitalId': hospitalId,
          'hospitalName': hospitalName,
          'date': DateFormatter.toYYYYMMDD(today),
          'timeSlots': ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM', '03:00 PM'],
          'created': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        {
          'doctorId': currentUserId,
          'hospitalId': hospitalId,
          'hospitalName': hospitalName,
          'date': DateFormatter.toYYYYMMDD(tomorrow),
          'timeSlots': ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM', '03:00 PM', '04:00 PM', '07:00 PM'],
          'created': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      ];
      
      // Add availability to Firestore
      final batch = _firestore.batch();
      
      for (final entry in availabilityEntries) {
        final docRef = _firestore.collection('doctor_availability').doc();
        batch.set(docRef, entry);
      }
      
      await batch.commit();
      
      return {
        'success': true,
        'message': 'Successfully added availability for today and tomorrow',
      };
    } catch (e) {
      debugPrint('Error adding quick availability: $e');
      return {
        'success': false,
        'message': 'Failed to add quick availability: ${e.toString()}',
      };
    }
  }
} 