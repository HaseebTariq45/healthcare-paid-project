import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/appointment/all_appoinments.dart';
import 'package:healthcare/views/screens/appointment/appointment_detail.dart';
import 'package:healthcare/views/screens/complete_profile/profile1.dart';
import 'package:healthcare/views/screens/dashboard/analytics.dart';
import 'package:healthcare/views/screens/dashboard/finances.dart';
import 'package:healthcare/views/screens/dashboard/menu.dart';
import 'package:healthcare/views/screens/doctor/complete_profile/doctor_profile_page1.dart';
import 'package:healthcare/views/screens/doctor/availability/hospital_selection_screen.dart';
import 'package:healthcare/views/screens/doctor/availability/doctor_availability_screen.dart';
import 'package:healthcare/views/screens/menu/appointment_history.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:healthcare/utils/navigation_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/services/doctor_profile_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notifications/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  final String profileStatus;
  final String userType;
  const HomeScreen({
    super.key, 
    this.profileStatus = "incomplete", 
    this.userType = "Doctor"
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String profileStatus;
  late String userType;
  int _selectedIndex = 0;
  int _selectedAppointmentCategoryIndex = 0; // For appointment tabs
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final DoctorProfileService _doctorProfileService = DoctorProfileService();
  
  // User data
  String _userName = "Dr. Asmara";
  String _specialty = "";
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isRefreshing = false;
  
  // Financial data
  double _totalEarnings = 0.0;
  
  // Rating data
  double _overallRating = 0.0;
  int _reviewCount = 0;

  // Appointment data
  List<Map<String, dynamic>> _appointments = [];
  List<String> _appointmentCategories = ["Upcoming", "Completed"];
  bool _isLoadingAppointments = false;
  bool _isSyncingAppointments = false;
  DateTime? _lastAppointmentSync;

  // Cache keys
  static const String _doctorCacheKey = 'doctor_home_data';
  static const String _doctorAppointmentsCacheKey = 'doctor_appointments_cache';
  static const String _appointmentLastSyncKey = 'appointment_last_sync';

  @override
  void initState() {
    super.initState();
    profileStatus = widget.profileStatus;
    userType = widget.userType;
    
    _initializeData();
  }

  Future<void> _initializeData() async {
    print('***** HOME SCREEN INITIALIZED WITH USER TYPE: $userType *****');
    
    // Load data (first from cache, then from Firebase)
    await _loadData();
    
    // Check profile completion status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (profileStatus != "complete") {
        if (userType == "Doctor") {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const DoctorProfilePage1Screen(),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CompleteProfileScreen(),
            ),
          );
        }
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // First immediately load data from cache before anything else
      await _loadCachedData();
      await _loadAppointmentsFromCache();
      
      // Now we can set isLoading to false since we have cache data
      setState(() {
        _isLoading = false;
      });
      
      // Then fetch fresh data from Firebase in background
      _loadUserData();
      _syncAppointmentsInBackground();
    } catch (e) {
      print('Error in _loadData: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_doctorCacheKey);
      
      if (cachedData != null) {
        final Map<String, dynamic> data = json.decode(cachedData);
        
        setState(() {
          _userName = data['userName'] ?? "Doctor";
          _specialty = data['specialty'] ?? "";
          _profileImageUrl = data['profileImageUrl'];
          _totalEarnings = (data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
          _overallRating = (data['overallRating'] as num?)?.toDouble() ?? 0.0;
          _reviewCount = data['reviewCount'] as int? ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
          setState(() {
          _isRefreshing = false;
            _isLoading = false;
          });
        return;
      }
      
      if (userType == "Doctor") {
        await _loadDoctorProfileData();
      } else {
        await _loadProfileData();
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadDoctorProfileData() async {
    try {
      final doctorProfile = await _doctorProfileService.getDoctorProfile();
      final doctorStats = await _doctorProfileService.getDoctorStats();
      
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final String doctorId = currentUser.uid;
        
        final QuerySnapshot reviewsSnapshot = await _firestore
            .collection('doctor_reviews')
            .where('doctorId', isEqualTo: doctorId)
            .get();
        
        double totalRating = 0;
        int reviewCount = reviewsSnapshot.docs.length;
        
        for (var doc in reviewsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('rating')) {
            totalRating += (data['rating'] as num).toDouble();
          }
        }
        
        double averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;
      
        // Prepare data for caching
        final Map<String, dynamic> cacheData = {
          'userName': doctorProfile['fullName'] ?? "Doctor",
          'specialty': doctorProfile['specialty'] ?? "",
          'profileImageUrl': doctorProfile['profileImageUrl'],
          'totalEarnings': doctorStats['totalEarnings'] ?? 0.0,
          'overallRating': averageRating,
          'reviewCount': reviewCount,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
        
        // Save to cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_doctorCacheKey, json.encode(cacheData));
        
      if (mounted) {
        setState(() {
            _userName = cacheData['userName'];
            _specialty = cacheData['specialty'];
            _profileImageUrl = cacheData['profileImageUrl'];
            _totalEarnings = cacheData['totalEarnings'];
            _overallRating = cacheData['overallRating'];
            _reviewCount = cacheData['reviewCount'];
        });
        }
      }
    } catch (e) {
      print('Error loading doctor profile data: $e');
      rethrow;
    }
  }
  
  Future<void> _loadProfileData() async {
    try {
      final userData = await _authService.getUserData();
      
      if (userData != null && mounted) {
        setState(() {
          _userName = userData['fullName'] ?? "User";
          _profileImageUrl = userData['profileImageUrl'];
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
      rethrow;
    }
  }

  Future<void> _loadAppointmentsData() async {
    if (!mounted) return;

    try {
      // First try to load from cache
      await _loadAppointmentsFromCache();
      
      // Then fetch fresh data from Firestore
      await _fetchAppointments();
    } catch (e) {
      print('Error loading appointments data: $e');
    }
  }

  Future<void> _loadAppointmentsFromCache() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get last sync time
      final String? lastSyncStr = prefs.getString(_appointmentLastSyncKey);
      if (lastSyncStr != null) {
        _lastAppointmentSync = DateTime.parse(lastSyncStr);
      }
      
      // Load appointments from cache
      final String? cachedData = prefs.getString(_doctorAppointmentsCacheKey);
      
      if (cachedData != null) {
        final List<dynamic> decodedData = json.decode(cachedData);
        final List<Map<String, dynamic>> appointments = 
            decodedData.map((item) => Map<String, dynamic>.from(item)).toList();
        
        if (mounted) {
          setState(() {
            _appointments = appointments;
            _isLoadingAppointments = false;
          });
          print('Loaded ${appointments.length} appointments from cache');
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingAppointments = false;
          });
        }
      }
    } catch (e) {
      print('Error loading cached appointments: $e');
      if (mounted) {
        setState(() {
          _isLoadingAppointments = false;
        });
      }
    }
  }

  void _syncAppointmentsInBackground() async {
    // Don't sync if already syncing
    if (_isSyncingAppointments) return;
    
    // Don't sync too frequently (at most once every 1 minute)
    if (_lastAppointmentSync != null) {
      final Duration sinceLastSync = DateTime.now().difference(_lastAppointmentSync!);
      if (sinceLastSync.inMinutes < 1) {
        print('Skipping appointment sync, last synced ${sinceLastSync.inSeconds} seconds ago');
        return;
      }
    }
    
    setState(() {
      _isSyncingAppointments = true;
    });
    
    try {
      await _fetchAppointments();
      
      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      final String now = DateTime.now().toIso8601String();
      await prefs.setString(_appointmentLastSyncKey, now);
      
      setState(() {
        _lastAppointmentSync = DateTime.now();
      });
    } catch (e) {
      print('Error syncing appointments in background: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingAppointments = false;
        });
      }
    }
  }

  Future<void> _fetchAppointments() async {
    if (!mounted) return;
    
    try {
      final String? doctorId = _auth.currentUser?.uid;
      if (doctorId == null) {
        return;
      }
      
      // Query appointments where this doctor is assigned
      final QuerySnapshot appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('date', descending: false)  // Sort by date (ascending)
          .limit(50)  // Limit to 50 appointments for performance
          .get();
      
      if (appointmentsSnapshot.docs.isEmpty) {
        print('No appointments found for doctor ID: $doctorId');
      } else {
        print('Found ${appointmentsSnapshot.docs.length} appointments for doctor ID: $doctorId');
      }
      
      final List<Map<String, dynamic>> appointments = [];
      
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('Processing appointment: ${doc.id}');
        print('Appointment data: ${data.toString()}');
        
        // Get patient details
        String patientName = "Patient";
        String patientImage = "assets/images/User.png";
        
        if (data['patientId'] != null) {
          try {
            final patientDoc = await _firestore
                .collection('users')
                .doc(data['patientId'])
                .get();
            
            if (patientDoc.exists) {
              final patientData = patientDoc.data();
              patientName = patientData?['fullName'] ?? "Patient";
              patientImage = patientData?['profileImageUrl'] ?? "assets/images/User.png";
            }
          } catch (e) {
            print('Error fetching patient data: $e');
          }
        }
        
        // Get hospital details - check multiple possible field names
        String hospitalName = "Not specified";
        
        // Debug hospital information in appointment
        if (data.containsKey('hospital')) {
          print('Hospital field found: ${data['hospital']}');
        }
        if (data.containsKey('hospitalId')) {
          print('HospitalId field found: ${data['hospitalId']}');
        }
        if (data.containsKey('hospitalName')) {
          print('HospitalName field found: ${data['hospitalName']}');
        }
        
        // Try different field names for hospital
        if (data['hospital'] != null && data['hospital'].toString().isNotEmpty) {
          hospitalName = data['hospital'].toString();
        } else if (data['hospitalName'] != null && data['hospitalName'].toString().isNotEmpty) {
          hospitalName = data['hospitalName'].toString();
        } else if (data['hospitalId'] != null) {
          // If we have hospitalId but no name, try to fetch from hospitals collection
          try {
            final hospitalDoc = await _firestore
                .collection('hospitals')
                .doc(data['hospitalId'].toString())
                .get();
            
            if (hospitalDoc.exists) {
              final hospitalData = hospitalDoc.data();
              hospitalName = hospitalData?['name'] ?? hospitalData?['hospitalName'] ?? "Not specified";
              print('Retrieved hospital name from Firestore: $hospitalName');
            }
          } catch (e) {
            print('Error fetching hospital data: $e');
          }
        }
        
        // If we still don't have a hospital name and there's a doctorHospitalId field, try that
        if (hospitalName == "Not specified" && data['doctorHospitalId'] != null) {
          try {
            final hospitalDoc = await _firestore
                .collection('doctor_hospitals')
                .doc(data['doctorHospitalId'].toString())
                .get();
            
            if (hospitalDoc.exists) {
              final hospitalData = hospitalDoc.data();
              if (hospitalData != null && hospitalData.containsKey('hospitalName')) {
                hospitalName = hospitalData['hospitalName'];
                print('Retrieved hospital name from doctor_hospitals: $hospitalName');
              }
            }
          } catch (e) {
            print('Error fetching doctor hospital data: $e');
          }
        }
        
        print('Final hospital name: $hospitalName');
        
        // Format appointment data
        appointments.add({
          'id': doc.id,
          'patientName': patientName,
          'patientImage': patientImage,
          'date': data['date'] ?? "No date",
          'time': data['time'] ?? "No time",
          'type': data['type'] ?? "In-person",
          'status': data['status'] ?? "Pending",
          'reason': data['reason'] ?? "General checkup",
          'hospitalName': hospitalName,
          'fee': data['fee'] ?? "0",
          'syncedAt': DateTime.now().toIso8601String(),
        });
      }
      
      if (appointments.isNotEmpty) {
        // Cache the appointments data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_doctorAppointmentsCacheKey, json.encode(appointments));
        
        if (mounted) {
          setState(() {
            _appointments = appointments;
          });
          print('Updated appointments with ${appointments.length} records from server');
        }
      }
    } catch (e) {
      print('Error fetching appointments: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadUserData();
    await _fetchAppointments();
  }

  void _onItemTapped(int index) {
    NavigationHelper.navigateToTab(context, index);
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    
    // Calculate responsive values
    final double headerHeight = screenHeight * 0.28;
    final double horizontalPadding = screenWidth * 0.06;
    final double verticalSpacing = screenHeight * 0.025;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                return Stack(
                  children: [
                      // Main scrollable content
              SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                            // Header with gradient background
            Container(
                              height: headerHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(64, 124, 226, 1),
                                    Color.fromRGBO(46, 106, 208, 1),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                                    color: Colors.blue.shade200.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                  ),
                ],
              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: verticalSpacing,
                              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                                  // Top row with user name and profile image
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              "Hi, $_userName",
                      style: GoogleFonts.poppins(
                                                fontSize: screenWidth * 0.065,
                        fontWeight: FontWeight.w600,
                              color: Colors.white,
                                              ),
                      ),
                    ),
                  ],
                ),
                                  GestureDetector(
                        onTap: () {
                          NavigationHelper.navigateToTab(context, 3); // Navigate to Menu tab
                        },
                        child: Container(
              decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                  ),
                ],
              ),
                          child: Hero(
                            tag: 'profileImage',
                            child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                ? CircleAvatar(
                                                    radius: screenWidth * 0.07,
                                    backgroundImage: NetworkImage(_profileImageUrl!),
                                  )
                                : CircleAvatar(
                                                    radius: screenWidth * 0.07,
                                    backgroundImage: AssetImage("assets/images/User.png"),
                                  ),
                          ),
                        ),
                                  ),
                                ],
                      ),
                                  SizedBox(height: verticalSpacing),
                  // Earnings info in header
                                  Flexible(
                                    child: Container(
                                      padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                        Container(
                                            padding: EdgeInsets.all(screenWidth * 0.025),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.paid_outlined,
                            color: Color.fromRGBO(64, 124, 226, 1),
                                              size: screenWidth * 0.075,
                          ),
                        ),
                                          SizedBox(width: screenWidth * 0.04),
                                          Expanded(
                                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                    children: [
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                        "Total Earning",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                                                      fontSize: screenWidth * 0.035,
                                                    ),
                        ),
                      ),
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                              "Rs ${_totalEarnings.toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                                                      fontSize: screenWidth * 0.055,
                          fontWeight: FontWeight.bold,
                                                    ),
                        ),
                      ),
                    ],
                        ),
                                          ),
                        IconButton(
                          onPressed: () {
                            NavigationHelper.navigateToTab(context, 2); // Navigate to Finances tab
                          },
                          icon: Icon(
                            LucideIcons.arrowRight,
                            color: Colors.white,
                                              size: screenWidth * 0.05,
                          ),
                        ),
                      ],
                                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                  SizedBox(height: verticalSpacing),
                  
                  // Quick action buttons
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final double buttonWidth = (constraints.maxWidth - 24) / 4;
                                      return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickActionButton(
                        icon: LucideIcons.building2,
                        label: "Add Hospital",
                        color: Color.fromRGBO(64, 124, 226, 1),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HospitalSelectionScreen(
                                selectedHospitals: [],
                              ),
                            ),
                          );
                        },
                                            width: buttonWidth,
                      ),
                      _buildQuickActionButton(
                        icon: LucideIcons.calendar,
                        label: "Availability",
                        color: Color(0xFF4CAF50),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorAvailabilityScreen(),
                            ),
                          );
                        },
                                            width: buttonWidth,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.bar_chart,
                        label: "Reports",
                        color: Color(0xFFF44336),
                        onTap: () {
                          _onItemTapped(1); // Navigate to Analytics
                        },
                                            width: buttonWidth,
                      ),
                      _buildQuickActionButton(
                        icon: LucideIcons.messageCircle,
                        label: "Menu",
                        color: Color(0xFFFF9800),
                        onTap: () {
                          _onItemTapped(3); // Navigate to Menu
                        },
                                            width: buttonWidth,
                      ),
                    ],
                                      );
                                    }
                  ),
                  
                                  SizedBox(height: verticalSpacing),
                  
                  // Ratings Card with improved design
            Container(
                                    padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                          color: Color.fromRGBO(158, 158, 158, 0.2),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.shade100,
                        width: 1,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                            Container(
                                              padding: EdgeInsets.all(screenWidth * 0.02),
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(64, 124, 226, 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                LucideIcons.thumbsUp,
                                color: Color.fromRGBO(64, 124, 226, 1),
                                                size: screenWidth * 0.05,
                              ),
                            ),
                                            SizedBox(width: screenWidth * 0.03),
                      Text(
                        "Overall Ratings",
                        style: GoogleFonts.poppins(
                                                fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                                        SizedBox(height: verticalSpacing * 0.6),
                  Row(
                    children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                              _overallRating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                                                  fontSize: screenWidth * 0.075,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(64, 124, 226, 1),
                        ),
                      ),
                                            ),
                                            SizedBox(width: screenWidth * 0.03),
                                            Expanded(
                                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    for (int i = 1; i <= 5; i++)
                                      Icon(
                                        i <= _overallRating
                                            ? Icons.star
                                            : i <= _overallRating + 0.5
                                                ? Icons.star_half
                                                : Icons.star_border,
                                        color: Colors.amber,
                                                          size: screenWidth * 0.045,
                                      ),
                                  ],
                                ),
                                                  SizedBox(height: screenHeight * 0.005),
                                                  FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                    "Based on $_reviewCount reviews",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                                        fontSize: screenWidth * 0.03,
                                                      ),
                                  ),
                                ),
                              ],
                                              ),
                            ),
                          ],
                  ),
                ],
              ),
            ),
                  
                                  SizedBox(height: verticalSpacing),
                                  
                  // My Appointments Section
                  _buildAppointmentsSection(screenWidth, screenHeight, horizontalPadding, verticalSpacing),

                  // Add extra space at the bottom
                                  SizedBox(height: verticalSpacing),
                ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Bottom refresh indicator
            if (_isRefreshing)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04, 
                                vertical: screenHeight * 0.01
                              ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                                    width: screenWidth * 0.04,
                                    height: screenWidth * 0.04,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromRGBO(64, 124, 226, 1),
                            ),
                          ),
                        ),
                                  SizedBox(width: screenWidth * 0.02),
                        Text(
                          "Refreshing...",
                          style: GoogleFonts.poppins(
                                      fontSize: screenWidth * 0.03,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
            ),
          ],
                  );
                }
        ),
      ),
    );
  }
  
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
      child: Column(
        children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
                child: Icon(icon, color: color, size: width * 0.5),
              ),
          ),
          SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
            label,
                textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                  fontSize: width * 0.24,
              fontWeight: FontWeight.w500,
                ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  // Build the appointments section widget
  Widget _buildAppointmentsSection(
    double screenWidth, 
    double screenHeight, 
    double horizontalPadding, 
    double verticalSpacing
  ) {
    // Filter appointments based on the selected category
    List<Map<String, dynamic>> filteredAppointments = [];
    
    if (_appointments.isNotEmpty) {
      if (_selectedAppointmentCategoryIndex == 0) {
        // Upcoming appointments
        filteredAppointments = _appointments.where((appointment) => 
          appointment['status']?.toString().toLowerCase() == 'upcoming' || 
          appointment['status']?.toString().toLowerCase() == 'confirmed' ||
          appointment['status']?.toString().toLowerCase() == 'pending'
        ).toList();
      } else if (_selectedAppointmentCategoryIndex == 1) {
        // Completed appointments
        filteredAppointments = _appointments.where((appointment) => 
          appointment['status']?.toString().toLowerCase() == 'completed'
        ).toList();
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "My Appointments",
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Row(
              children: [
                if (_isSyncingAppointments)
                  Container(
                    width: screenWidth * 0.04,
                    height: screenWidth * 0.04,
                    margin: EdgeInsets.only(right: screenWidth * 0.02),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3366CC).withOpacity(0.7),
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    // Navigate to AppointmentHistoryScreen instead of AppointmentsScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AppointmentHistoryScreen()),
                    );
                  },
                  child: Text(
                    "See all",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3366CC),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_lastAppointmentSync != null)
          Padding(
            padding: EdgeInsets.only(top: verticalSpacing * 0.2),
            child: Text(
              "Last updated: ${_formatLastUpdateTime(_lastAppointmentSync!)}",
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.025,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        SizedBox(height: verticalSpacing * 0.5),
        
        // Category tabs
        SizedBox(
          height: screenHeight * 0.05,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _appointmentCategories.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAppointmentCategoryIndex = index;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: horizontalPadding * 0.5),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.7),
                  decoration: BoxDecoration(
                    color: _selectedAppointmentCategoryIndex == index
                        ? Color(0xFF3366CC)
                        : Color(0xFFF5F7FF),
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _appointmentCategories[index],
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w500,
                      color: _selectedAppointmentCategoryIndex == index
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: verticalSpacing),
        
        // Appointments list - only show loading if no cache data and this is first load
        filteredAppointments.isEmpty && _isLoadingAppointments
        ? Center(
            child: SizedBox(
              height: screenHeight * 0.15,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: screenWidth * 0.06,
                    height: screenWidth * 0.06,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3366CC),
                      ),
                    ),
                  ),
                  SizedBox(height: verticalSpacing * 0.5),
                  Text(
                    "Loading appointments...",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        : filteredAppointments.isEmpty
          ? Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.03,
              horizontal: screenWidth * 0.05
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: screenWidth * 0.15,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: verticalSpacing * 0.5),
                Text(
                  "No ${_appointmentCategories[_selectedAppointmentCategoryIndex].toLowerCase()} appointments",
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
          : LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: filteredAppointments.take(3).map((appointment) => 
                  _buildAppointmentCard(
                    appointment, 
                    screenWidth, 
                    screenHeight, 
                    horizontalPadding, 
                    verticalSpacing,
                    constraints.maxWidth
                  )
                ).toList(),
              );
            },
          ),
          
        // Only show refresh button if we have appointments to show
        if (filteredAppointments.isNotEmpty) 
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: verticalSpacing),
              child: InkWell(
                onTap: _syncAppointmentsInBackground,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.01, 
                    horizontal: screenWidth * 0.04
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.refreshCw,
                        size: screenWidth * 0.04,
                        color: Color(0xFF3366CC),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        "Refresh",
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3366CC),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Helper function to format the last update time
  String _formatLastUpdateTime(DateTime time) {
    final Duration difference = DateTime.now().difference(time);
    
    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago";
    } else {
      return DateFormat('MMM d, h:mm a').format(time);
    }
  }

  // Build a single appointment card
  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment, 
    double screenWidth, 
    double screenHeight, 
    double horizontalPadding, 
    double verticalSpacing,
    [double cardWidth = 0]
  ) {
    // Determine status color
    Color statusColor;
    String displayStatus = appointment['status'];
    
    switch (displayStatus.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'upcoming':
      case 'confirmed':
        statusColor = Color(0xFF3366CC);
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    // Calculate responsive values based on container width
    final double imageSizeMultiplier = 0.06;
    final double textSizeMultiplier = 0.035;
    final double detailIconSize = screenWidth * 0.04;
    final double detailSpacing = screenWidth * 0.02;
    final bool isSmallScreen = screenWidth < 360;
    
    return GestureDetector(
      onTap: () {
        // Navigate to appointment details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(
              appointmentId: appointment['id'],
            ),
          ),
        );
      },
      child: Container(
        width: cardWidth > 0 ? cardWidth : double.infinity,
        margin: EdgeInsets.only(bottom: verticalSpacing),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(horizontalPadding * 0.6),
              decoration: BoxDecoration(
                color: Color(0xFF3366CC).withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenWidth * 0.04),
                  topRight: Radius.circular(screenWidth * 0.04),
                ),
              ),
              child: Row(
                children: [
                  // Patient image
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: screenWidth * imageSizeMultiplier,
                      backgroundImage: appointment['patientImage'].startsWith('assets/')
                          ? AssetImage(appointment['patientImage'])
                          : NetworkImage(appointment['patientImage']) as ImageProvider,
                    ),
                  ),
                  SizedBox(width: horizontalPadding * 0.6),
                  // Patient name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment['patientName'],
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * textSizeMultiplier,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: verticalSpacing * 0.1),
                        Text(
                          appointment['reason'],
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen 
                                ? screenWidth * (textSizeMultiplier - 0.01)
                                : screenWidth * (textSizeMultiplier - 0.005),
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding * 0.5,
                      vertical: verticalSpacing * 0.3
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      border: Border.all(
                        color: statusColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      displayStatus,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen 
                            ? screenWidth * 0.025
                            : screenWidth * 0.03,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Appointment details
            Padding(
              padding: EdgeInsets.all(horizontalPadding * 0.6),
              child: Column(
                children: [
                  // Use Wrap instead of Row for better responsiveness on smaller screens
                  Wrap(
                    spacing: horizontalPadding * 0.6,
                    runSpacing: verticalSpacing * 0.6,
                    children: [
                      _buildAppointmentDetail(
                        LucideIcons.calendar,
                        "Date",
                        appointment['date'],
                        screenWidth,
                        detailIconSize,
                        detailSpacing,
                        isSmallScreen
                      ),
                      _buildAppointmentDetail(
                        LucideIcons.clock,
                        "Time",
                        appointment['time'],
                        screenWidth,
                        detailIconSize,
                        detailSpacing,
                        isSmallScreen
                      ),
                    ],
                  ),
                  SizedBox(height: verticalSpacing * 0.6),
                  Wrap(
                    spacing: horizontalPadding * 0.6,
                    runSpacing: verticalSpacing * 0.6,
                    children: [
                      _buildAppointmentDetail(
                        LucideIcons.building2,
                        "Hospital",
                        appointment['hospitalName'],
                        screenWidth,
                        detailIconSize,
                        detailSpacing,
                        isSmallScreen
                      ),
                      _buildAppointmentDetail(
                        LucideIcons.tag,
                        "Type",
                        appointment['type'],
                        screenWidth,
                        detailIconSize,
                        detailSpacing,
                        isSmallScreen
                      ),
                    ],
                  ),
                  SizedBox(height: verticalSpacing * 0.9),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to appointment details
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AppointmentDetailsScreen(
                                  appointmentId: appointment['id'],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3366CC),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: verticalSpacing * 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            ),
                            elevation: 2,
                            shadowColor: Color(0xFF3366CC).withOpacity(0.3),
                          ),
                          icon: Icon(LucideIcons.fileText, size: screenWidth * 0.045),
                          label: Text(
                            "View Details",
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build appointment detail items
  Widget _buildAppointmentDetail(
    IconData icon, 
    String label, 
    String value, 
    double screenWidth,
    double iconSize,
    double spacing,
    bool isSmallScreen
  ) {
    return Container(
      width: isSmallScreen ? double.infinity : screenWidth * 0.38,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(
              color: Color.fromRGBO(64, 124, 226, 0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: Color.fromRGBO(64, 124, 226, 1),
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? screenWidth * 0.025 : screenWidth * 0.03,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? screenWidth * 0.03 : screenWidth * 0.035,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showExitDialog(BuildContext context) async {
  final Size screenSize = MediaQuery.of(context).size;
  final double screenWidth = screenSize.width;
  
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.exit_to_app,
                  color: Color(0xFFFF5252),
                  size: screenWidth * 0.075,
                ),
              ),
              SizedBox(height: screenWidth * 0.05),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                "Exit App",
                style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.025),
              Text(
                "Are you sure you want to exit the app?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: screenWidth * 0.06),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        SystemNavigator.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5252),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                        elevation: 0,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                      child: Text(
                        "Exit",
                        style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ) ?? false;
}
