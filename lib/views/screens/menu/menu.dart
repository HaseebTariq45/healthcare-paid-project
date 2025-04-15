import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_firestore/firebase_firestore.dart';
import 'package:json/json.dart';

class MenuScreen extends StatefulWidget {
  // ... (existing code)

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // ... (existing code)

  // Refresh data in background
  Future<void> _refreshDataInBackground() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Get current user ID
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get user data from Firestore
      final userData = await _authService.getUserData();
      if (userData != null) {
        // Convert any Timestamps to ISO strings before caching
        final Map<String, dynamic> processedUserData = _processDataForCache(userData);
        
        // Cache user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userDataCacheKey, json.encode(processedUserData));
        _updateUIWithUserData(userData);
      }

      // Get user role
      final UserRole userRole = await _authService.getUserRole();

      // Load doctor-specific data if user is a doctor
      if (userRole == UserRole.doctor) {
        final doctorProfile = await _doctorProfileService.getDoctorProfile();
        final doctorStats = await _doctorProfileService.getDoctorStats();

        // Combine profile and stats
        final Map<String, dynamic> fullDoctorProfile = {
          ...doctorProfile,
          ...doctorStats,
        };

        // Process data for caching (convert Timestamps)
        final processedDoctorProfile = _processDataForCache(fullDoctorProfile);

        // Cache doctor profile
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_doctorProfileCacheKey, json.encode(processedDoctorProfile));
        _updateUIWithDoctorProfile(fullDoctorProfile);
      }
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Helper method to process data for caching
  Map<String, dynamic> _processDataForCache(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      } else if (value is Map) {
        return MapEntry(key, _processDataForCache(Map<String, dynamic>.from(value)));
      } else if (value is List) {
        return MapEntry(key, value.map((item) {
          if (item is Map) {
            return _processDataForCache(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList());
      }
      return MapEntry(key, value);
    });
  }

  // Update UI with user data
  void _updateUIWithUserData(Map<String, dynamic> userData) {
    if (mounted) {
      setState(() {
        _userName = userData['fullName'] ?? userData['name'] ?? widget.name;
        _userRole = widget.userType == UserType.doctor ? _specialty : "Patient";
        _profileImageUrl = userData['profileImageUrl'];
      });
    }
  }

  // Update UI with doctor profile
  void _updateUIWithDoctorProfile(Map<String, dynamic> profile) {
    if (mounted) {
      setState(() {
        _specialty = profile['specialty'] ?? "";
        _userRole = _specialty.isNotEmpty ? _specialty : widget.role;
        _rating = (profile['rating'] ?? 0.0).toDouble();
        _experience = profile['experience'] != null ? "${profile['experience']} years" : "";
        _consultationFee = profile['fee'] != null ? "Rs. ${profile['fee']}" : "";
        _appointmentsCount = profile['totalAppointments'] ?? 0;
        _totalEarnings = (profile['totalEarnings'] ?? 0.0).toDouble();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshDataInBackground();
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing code)
  }
} 