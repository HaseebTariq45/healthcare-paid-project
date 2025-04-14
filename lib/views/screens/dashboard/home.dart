import 'dart:ui';
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
  
  // Financial data
  double _totalEarnings = 0.0;
  
  // Rating data
  double _overallRating = 0.0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    profileStatus = widget.profileStatus;
    userType = widget.userType;
    
    print('***** HOME SCREEN INITIALIZED WITH USER TYPE: $userType *****');
    _loadUserData();
    
    // Auto-redirect to profile completion screens if profile is incomplete
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

  // Load all user data
  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      // We'll use the userType from widget instead of querying again
      if (userType == "Doctor") {
        // Load doctor profile and data
        await _loadDoctorProfileData();
      } else {
        // For other user types, load basic profile data
        await _loadProfileData();
      }
      
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Load doctor profile data using the new service
  Future<void> _loadDoctorProfileData() async {
    try {
      // Get doctor profile
      final doctorProfile = await _doctorProfileService.getDoctorProfile();
      
      // Get doctor stats - this now uses consistent earnings calculation
      final doctorStats = await _doctorProfileService.getDoctorStats();
      
      // Fetch doctor ratings from doctor_reviews collection
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final String doctorId = currentUser.uid;
        
        // Query doctor_reviews collection for this doctor
        final QuerySnapshot reviewsSnapshot = await _firestore
            .collection('doctor_reviews')
            .where('doctorId', isEqualTo: doctorId)
            .get();
        
        // Calculate average rating
        double totalRating = 0;
        int reviewCount = reviewsSnapshot.docs.length;
        
        for (var doc in reviewsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('rating')) {
            totalRating += (data['rating'] as num).toDouble();
          }
        }
        
        // Calculate average rating if there are reviews
        double averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;
      
      if (mounted) {
        setState(() {
          // Set doctor profile info
          _userName = doctorProfile['fullName'] ?? "Doctor";
          _specialty = doctorProfile['specialty'] ?? "";
          _profileImageUrl = doctorProfile['profileImageUrl'];
            
            // Use the calculated rating from reviews instead of profile rating
            _overallRating = averageRating;
          
          // Set statistics
          if (doctorStats['success'] == true) {
            _totalEarnings = doctorStats['totalEarnings'] ?? 0.0;
              _reviewCount = reviewCount; // Use actual count from reviews query
          }
        });
        }
      }
    } catch (e) {
      print('Error loading doctor profile data: $e');
    }
  }
  
  // Load profile data from Firestore (legacy method for non-doctor users)
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
    }
  }

  void _onItemTapped(int index) {
    NavigationHelper.navigateToTab(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(64, 124, 226, 1),
              ),
            )
          : SingleChildScrollView(
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
