import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/menu/appointment_history.dart';
import 'package:healthcare/views/screens/menu/faqs.dart';
import 'package:healthcare/views/screens/menu/payment_method.dart';
import 'package:healthcare/views/screens/menu/profile_update.dart';
import 'package:healthcare/views/screens/onboarding/onboarding_3.dart';
import 'package:healthcare/views/screens/onboarding/signupoptions.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page1.dart';
import 'package:healthcare/views/screens/patient/dashboard/patient_profile_details.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:healthcare/views/screens/dashboard/menu.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../services/cache_service.dart';

class PatientMenuScreen extends StatefulWidget {
  final String name;
  final String role;
  final double profileCompletionPercentage;
  final UserType userType;
  
  const PatientMenuScreen({
    super.key,
    this.name = "Amna",
    this.role = "Patient",
    this.profileCompletionPercentage = 0.0,
    this.userType = UserType.patient,
  });

  @override
  State<PatientMenuScreen> createState() => _PatientMenuScreenState();
}

class _PatientMenuScreenState extends State<PatientMenuScreen> {
  late List<MenuItem> menuItems;
  late double profileCompletionPercentage;
  bool isLoading = true;
  bool isRefreshing = false;
  String userName = "User";
  String? profileImageUrl;
  String userRole = "Patient";
  Map<String, dynamic>? _userData;
  static const String _userCacheKey = 'patient_profile_data';
  
  @override
  void initState() {
    super.initState();
    _initializeMenuItems();
    profileCompletionPercentage = widget.profileCompletionPercentage;
    // Clean up expired cache entries when app starts
    _cleanupCache();
    _loadData();
  }

  // Clean up expired cache
  Future<void> _cleanupCache() async {
    try {
      await CacheService.cleanupExpiredCache();
    } catch (e) {
      debugPrint('Error cleaning up cache: $e');
    }
  }

  Future<void> _loadData() async {
    try {
    setState(() {
      isLoading = true;
    });

      // First try to load data from cache
      await _loadCachedData();
    
      // Then fetch fresh data from Firestore in the background
      if (!mounted) return;
    _fetchUserData();
    } catch (e) {
      debugPrint('Error in _loadData: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadCachedData() async {
    try {
      Map<String, dynamic>? cachedData = await CacheService.getData(_userCacheKey);
      
      if (cachedData != null && mounted) {
        // Get completion percentage from cache or calculate it
        double cachedPercentage = 0.0;
        if (cachedData.containsKey('completionPercentage')) {
          cachedPercentage = (cachedData['completionPercentage'] as num).toDouble();
        } else {
          cachedPercentage = _calculateCompletionPercentage(cachedData);
        }
        
        setState(() {
          _userData = cachedData;
          userName = cachedData['fullName'] ?? cachedData['name'] ?? "User";
          profileImageUrl = cachedData['profileImageUrl'];
          userRole = cachedData['role'] ?? "Patient";
          profileCompletionPercentage = cachedPercentage;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cached data: $e');
    }
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return;
    
    setState(() => isRefreshing = true);
    
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      
      // Fetch user data from the users collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists || !mounted) {
        setState(() => isRefreshing = false);
        return;
      }
      
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      // Fetch patient data from the patients collection
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(userId)
          .get();
      
      // If patient document exists, merge with userData (patient data takes precedence)
      if (patientDoc.exists) {
        Map<String, dynamic> patientData = patientDoc.data() as Map<String, dynamic>;
        userData.addAll(patientData);
      }
      
      // Calculate completion percentage
      double storedPercentage = userData.containsKey('completionPercentage') 
          ? (userData['completionPercentage'] as num).toDouble()
          : _calculateCompletionPercentage(userData);
      
      // Update Firestore with calculated percentage if needed
      if (!userData.containsKey('completionPercentage')) {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(userId)
            .set({'completionPercentage': storedPercentage}, SetOptions(merge: true));
      }
      
      if (!mounted) return;
      
      // Check if data has changed before updating state
      bool hasDataChanged = _userData == null || 
          !_areMapContentsEqual(_userData!, userData) ||
          profileCompletionPercentage != storedPercentage;
      
      if (hasDataChanged) {
        setState(() {
          _userData = userData;
          userName = userData['fullName'] ?? userData['name'] ?? "User";
          profileImageUrl = userData['profileImageUrl'];
          userRole = userData['role'] ?? "Patient";
          profileCompletionPercentage = storedPercentage;
        });
        
        // Save updated data to cache with expiration
        await CacheService.saveData(_userCacheKey, userData);
      }
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isRefreshing = false;
          isLoading = false;
        });
      }
    }
  }

  // Calculate profile completion percentage based on filled fields
  double _calculateCompletionPercentage(Map<String, dynamic> userData) {
    int totalFields = 10; // Total number of important profile fields
    int filledFields = 0;
    
    // Check basic profile fields
    if ((userData['fullName']?.toString() ?? '').isNotEmpty) filledFields++;
    if ((userData['email']?.toString() ?? '').isNotEmpty) filledFields++;
    if ((userData['phoneNumber']?.toString() ?? '').isNotEmpty) filledFields++;
    
    // Check medical info
    if ((userData['age']?.toString() ?? '').isNotEmpty) filledFields++;
    if ((userData['bloodGroup']?.toString() ?? '').isNotEmpty) filledFields++;
    if ((userData['height']?.toString() ?? '').isNotEmpty) filledFields++;
    if ((userData['weight']?.toString() ?? '').isNotEmpty) filledFields++;
    
    // Check address info
    if ((userData['address']?.toString() ?? '').isNotEmpty) filledFields++;
    if ((userData['city']?.toString() ?? '').isNotEmpty) filledFields++;
    
    // Check profile image
    if ((userData['profileImageUrl']?.toString() ?? '').isNotEmpty) filledFields++;
    
    return (filledFields / totalFields) * 100;
  }

  // Helper method to compare maps (deep comparison)
  bool _areMapContentsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    
    for (String key in map1.keys) {
      if (!map2.containsKey(key)) return false;
      
      if (map1[key] is Map && map2[key] is Map) {
        if (!_areMapContentsEqual(
            Map<String, dynamic>.from(map1[key] as Map),
            Map<String, dynamic>.from(map2[key] as Map))) {
          return false;
        }
      } else if (map1[key] != map2[key]) {
        return false;
      }
    }
    
    return true;
  }

  Future<void> _refreshData() async {
    try {
      setState(() {
        isRefreshing = true;
      });
      await _fetchUserData();
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  void _initializeMenuItems() {
    menuItems = [
      MenuItem("Edit Profile", LucideIcons.user, const ProfileEditorScreen()),
      // MenuItem("Medical Records", LucideIcons.fileText, null),
      MenuItem("Payment Methods", LucideIcons.creditCard, PaymentMethodsScreen(userType: widget.userType)),
      MenuItem("FAQs", LucideIcons.info, const FAQScreen()),
      MenuItem("Help Center", LucideIcons.headphones, null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to the bottom navigation bar with PatientHomeScreen as initial tab
        Navigator.of(context).pushNamedAndRemoveUntil('/patient/bottom_navigation', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  // Use the same navigation approach for consistency
                  Navigator.of(context).pushNamedAndRemoveUntil('/patient/bottom_navigation', (route) => false);
                },
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Text(
                'Profile',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFF8FAFF),
        body: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                    Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3366CC),
            Color(0xFF5E8EF7),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3366CC).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 18),
      child: Column(
        children: [
          Row(
                                mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "My Profile",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Profile section
          Row(
            children: [
              // Profile image with border
              Hero(
                tag: 'profileImage',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : const AssetImage("assets/images/User.png") as ImageProvider,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      userRole,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // View detailed profile button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientDetailProfileScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.user,
                              color: Color(0xFF3366CC),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "View Medical Profile",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3366CC),
                              ),
                            ),
                          ],
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
                        
                        // Always show profile completion card
                        _buildProfileCompletionCard(),
                        
                        SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 25),
                                
                                Text(
                                  "Settings",
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Menu items
                                ...menuItems.map((item) => _buildMenuItem(item)).toList(),
                                
                                // Logout button
                                _buildLogoutButton(),
                                
                                const SizedBox(height: 25),
                                
                                // App version info
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        "HealthCare App",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF3366CC),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Version 1.0.0",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Loading indicator at bottom
              if (isLoading || isRefreshing)
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
                                const Color(0xFF3366CC),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            isLoading ? "Loading profile..." : "Refreshing...",
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
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (item.screen != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => item.screen!),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item.icon,
                    color: const Color(0xFF3366CC),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Icon(
                  LucideIcons.chevronRight,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.only(top: 5, bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFE5E5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showLogoutDialog(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.logOut,
                    color: Color(0xFFFF5252),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  "Logout",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFF5252),
                  ),
                ),
                const Spacer(),
                const Icon(
                  LucideIcons.chevronRight,
                  color: Color(0xFFFF9E9E),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
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
                    LucideIcons.logOut,
                    color: Color(0xFFFF5252),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Log Out",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Are you sure you want to log out of your account?",
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
                        onPressed: () => Navigator.pop(context),
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
                        onPressed: () async {
                          Navigator.pop(context);
                          
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return Dialog(
                                backgroundColor: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      CircularProgressIndicator(
                                        color: Color(0xFF3366CC),
                                      ),
                                      SizedBox(height: 16),
                                      Text('Logging out...'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                          
                          // Sign out from Firebase
                          try {
                            await FirebaseAuth.instance.signOut();
                            
                            // Close loading dialog
                            if (context.mounted) Navigator.pop(context);
                            
                            // Navigate to Onboarding3 screen and clear navigation stack
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const Onboarding3()),
                                (route) => false, // Remove all previous routes
                              );
                            }
                          } catch (e) {
                            // Close loading dialog
                            if (context.mounted) Navigator.pop(context);
                            
                            // Show error message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('An error occurred: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
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
                          "Log Out",
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
    );
  }

  // New widget for profile completion card
  Widget _buildProfileCompletionCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: profileCompletionPercentage < 100
              ? [Color(0xFFFFA726), Color(0xFFFF7043)]
              : [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (profileCompletionPercentage < 100
                    ? Color(0xFFFF7043)
                    : Color(0xFF4CAF50))
                .withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  profileCompletionPercentage < 100
                      ? LucideIcons.user
                      : LucideIcons.userCheck,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  profileCompletionPercentage < 100
                      ? "Complete Your Profile"
                      : "Profile Complete",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${profileCompletionPercentage.round()}%",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: profileCompletionPercentage < 100
                        ? Color(0xFFFF7043)
                        : Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: profileCompletionPercentage / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          if (profileCompletionPercentage < 100) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompleteProfilePatient1Screen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Complete Now",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFF7043),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          LucideIcons.arrowRight,
                          size: 14,
                          color: Color(0xFFFF7043),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class MenuItem {
  final String title;
  final IconData icon;
  final Widget? screen;

  MenuItem(this.title, this.icon, this.screen);
}
