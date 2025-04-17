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
