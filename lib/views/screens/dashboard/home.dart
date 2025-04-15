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
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:healthcare/utils/navigation_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/services/doctor_profile_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Cache keys
  static const String _doctorCacheKey = 'doctor_home_data';

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

      // First try to load data from cache
      await _loadCachedData();
      
      // Then fetch fresh data from Firebase
      await _loadUserData();
    } catch (e) {
      print('Error in _loadData: $e');
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

  void _onItemTapped(int index) {
    NavigationHelper.navigateToTab(context, index);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show exit confirmation dialog
        return await showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Color.fromRGBO(64, 124, 226, 1),
                ),
              )
            else
              SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with gradient
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromRGBO(64, 124, 226, 1),
                            Color.fromRGBO(84, 144, 246, 1),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(64, 124, 226, 0.3),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(25, 70, 25, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Welcome",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  Text(
                                    _userName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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
                                            radius: 28,
                                            backgroundImage: NetworkImage(_profileImageUrl!),
                                          )
                                        : CircleAvatar(
                                            radius: 28,
                                            backgroundImage: AssetImage("assets/images/User.png"),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 25),
                          // Earnings info in header
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.paid_outlined,
                                    color: Color.fromRGBO(64, 124, 226, 1),
                                    size: 30,
                                  ),
                                ),
                                SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total Earning",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "Rs ${_totalEarnings.toStringAsFixed(2)}",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Spacer(),
                                IconButton(
                                  onPressed: () {
                                    NavigationHelper.navigateToTab(context, 2); // Navigate to Finances tab
                                  },
                                  icon: Icon(
                                    LucideIcons.arrowRight,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 25),
                          
                          // Quick action buttons
                          Row(
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
                              ),
                              _buildQuickActionButton(
                                icon: Icons.bar_chart,
                                label: "Reports",
                                color: Color(0xFFF44336),
                                onTap: () {
                                  _onItemTapped(1); // Navigate to Analytics
                                },
                              ),
                              _buildQuickActionButton(
                                icon: LucideIcons.messageCircle,
                                label: "Menu",
                                color: Color(0xFFFF9800),
                                onTap: () {
                                  _onItemTapped(3); // Navigate to Menu
                                },
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 25),
                          
                          // Ratings Card with improved design
                          Container(
                            padding: EdgeInsets.all(20),
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
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Color.fromRGBO(64, 124, 226, 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        LucideIcons.thumbsUp,
                                        color: Color.fromRGBO(64, 124, 226, 1),
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Overall Ratings",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15),
                                Row(
                                  children: [
                                    Text(
                                      _overallRating.toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromRGBO(64, 124, 226, 1),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Column(
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
                                                size: 18,
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          "Based on $_reviewCount reviews",
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 25),

                          // Add extra space at the bottom
                          SizedBox(height: 25),
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
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromRGBO(64, 124, 226, 1),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Refreshing...",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showExitDialog(BuildContext context) async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.exit_to_app,
                  color: Color(0xFFFF5252),
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Exit App",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to exit the app?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 25),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        "Exit",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
