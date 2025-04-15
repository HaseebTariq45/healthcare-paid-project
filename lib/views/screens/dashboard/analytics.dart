import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/analytics/financial_analysis.dart';
import 'package:healthcare/views/screens/analytics/patients.dart';
import 'package:healthcare/views/screens/analytics/performance_analysis.dart';
import 'package:healthcare/views/screens/analytics/reports.dart';
import 'package:healthcare/views/screens/doctor/availability/doctor_availability_screen.dart';
import 'package:healthcare/views/screens/doctor/availability/hospital_selection_screen.dart';
import 'package:healthcare/views/screens/menu/appointment_history.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:healthcare/utils/navigation_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:healthcare/services/doctor_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/views/screens/bottom_navigation_bar.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Dashboard data
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _totalPatients = 0;
  int _totalAppointments = 0;
  double _totalEarnings = 0.0;

  // Cache key
  static const String _analyticsCacheKey = 'doctor_analytics_data';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // First try to load data from cache
    await _loadCachedData();
    
    // Then fetch fresh data from Firebase
    await _loadDashboardData();
  }

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_analyticsCacheKey);
      
      if (cachedData != null) {
        final Map<String, dynamic> data = json.decode(cachedData);
        
        setState(() {
          _totalPatients = data['totalPatients'] ?? 0;
          _totalAppointments = data['totalAppointments'] ?? 0;
          _totalEarnings = (data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cached analytics data: $e');
    }
  }
  
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final String? doctorId = _auth.currentUser?.uid;
      
      if (doctorId == null) {
        throw Exception('User not authenticated');
      }
      
      // Load data in parallel for efficiency
      await Future.wait([
        _loadTotalPatients(doctorId),
        _loadTotalAppointments(doctorId),
        _loadTotalEarnings(doctorId),
      ]);

      // Save to cache
      final Map<String, dynamic> cacheData = {
        'totalPatients': _totalPatients,
        'totalAppointments': _totalAppointments,
        'totalEarnings': _totalEarnings,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_analyticsCacheKey, json.encode(cacheData));
      
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isLoading = false;
        });
      }
    }
  }
  
  // Load total unique patients seen by this doctor
  Future<void> _loadTotalPatients(String doctorId) async {
    try {
      // Get all appointments for this doctor
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      
      // Extract unique patient IDs
      final Set<String> uniquePatientIds = {};
      
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('patientId') && data['patientId'] != null) {
          uniquePatientIds.add(data['patientId'] as String);
        }
      }
      
      if (mounted) {
        setState(() {
          _totalPatients = uniquePatientIds.length;
        });
      }
    } catch (e) {
      print('Error loading total patients: $e');
    }
  }
  
  // Load total appointments for this doctor
  Future<void> _loadTotalAppointments(String doctorId) async {
    try {
      // Get count of all appointments
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .count()
          .get();
      
      if (mounted) {
        setState(() {
          _totalAppointments = appointmentsSnapshot.count ?? 0;
        });
      }
    } catch (e) {
      print('Error loading total appointments: $e');
      
      // Fallback method if count() is not available
      try {
        final appointmentsSnapshot = await _firestore
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .get();
        
        if (mounted) {
          setState(() {
            _totalAppointments = appointmentsSnapshot.docs.length;
          });
        }
      } catch (fallbackError) {
        print('Error in fallback appointments count: $fallbackError');
      }
    }
  }
  
  // Load total earnings for this doctor
  Future<void> _loadTotalEarnings(String doctorId) async {
    try {
      // First try transactions collection
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: doctorId)
          .where('type', isEqualTo: 'income')
          .get();
      
      double total = 0.0;
      
      // If transactions exist, calculate from there
      if (transactionsSnapshot.docs.isNotEmpty) {
        for (var doc in transactionsSnapshot.docs) {
          final data = doc.data();
          if (data.containsKey('amount') && data['amount'] != null) {
            total += (data['amount'] as num).toDouble();
          }
        }
      } else {
        // Otherwise, calculate from completed appointments
        final appointmentsSnapshot = await _firestore
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .where('status', isEqualTo: 'completed')
            .get();
        
        for (var doc in appointmentsSnapshot.docs) {
          final data = doc.data();
          if (data.containsKey('fee') && data['fee'] != null) {
            total += (data['fee'] as num).toDouble();
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _totalEarnings = total;
        });
      }
    } catch (e) {
      print('Error loading total earnings: $e');
    }
  }
  
  // Format currency for display
  String _formatCurrency(double amount) {
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to the bottom navigation bar with home tab selected
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavigationBarScreen(
              profileStatus: "complete",
              initialIndex: 0, // Home tab index
            ),
          ),
        );
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom app bar with gradient
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade100,
                          spreadRadius: 1,
                          blurRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Analytics Dashboard",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(64, 124, 226, 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            LucideIcons.activity,
                            color: Color.fromRGBO(64, 124, 226, 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Summary stats row with loading state
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromRGBO(64, 124, 226, 1),
                            Color.fromRGBO(84, 144, 246, 1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(64, 124, 226, 0.3),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20.0),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem("${_totalPatients}", "Patients"),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                _buildSummaryItem("${_totalAppointments}", "Appointments"),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                _buildSummaryItem(_formatCurrency(_totalEarnings), "Earnings"),
                              ],
                            ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Analytics Categories",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  // Analytics cards
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1.05,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        children: [
                          _buildAnalyticsCard(
                            icon: LucideIcons.activity,
                            title: "Financial Analytics",
                            description: "Revenue & expense reports",
                            bgColor: Color(0xFFE1F5FE),
                            iconColor: Color(0xFF03A9F4),
                            onPressed: () {
                              NavigationHelper.navigateWithBottomBar(context, FinancialAnalyticsScreen());
                            },
                          ),
                          _buildAnalyticsCard(
                            icon: LucideIcons.clipboardCheck,
                            title: "Appointments",
                            description: "View appointment history",
                            bgColor: Color(0xFFF0F4FF),
                            iconColor: Color(0xFF3366CC),
                            onPressed: () {
                              NavigationHelper.navigateWithBottomBar(context, AppointmentHistoryScreen());
                            },
                          ),
                          _buildAnalyticsCard(
                            icon: LucideIcons.calendar,
                            title: "Manage Availability",
                            description: "Set your schedule & locations",
                            bgColor: Color(0xFFE8EAF6),
                            iconColor: Color(0xFF3F51B5),
                            onPressed: () {
                              NavigationHelper.navigateToCachedScreen(
                                context, 
                                "DoctorAvailabilityScreen", 
                                () => DoctorAvailabilityScreen()
                              );
                            },
                          ),
                          _buildAnalyticsCard(
                            icon: LucideIcons.users,
                            title: "Patients",
                            description: "Manage patient data",
                            bgColor: Color(0xFFE8F5E9),
                            iconColor: Color(0xFF4CAF50),
                            onPressed: () {
                              NavigationHelper.navigateWithBottomBar(context, PatientsScreen());
                            },
                          ),
                          _buildAnalyticsCard(
                            icon: LucideIcons.building2,
                            title: "Hospital Selection",
                            description: "Manage your practice locations",
                            bgColor: Color(0xFFE0F2F1),
                            iconColor: Color(0xFF009688),
                            onPressed: () async {
                              try {
                                // Get current selected hospitals
                                final doctorService = DoctorProfileService();
                                final currentHospitals = await doctorService.getDoctorSelectedHospitals();
                                
                                // Navigate to hospital selection screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HospitalSelectionScreen(
                                      selectedHospitals: currentHospitals,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not load hospital selection'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
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
                          "Refreshing analytics...",
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

  Widget _buildSummaryItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard({
    required IconData icon,
    required String title,
    required String description,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                size: 22,
                color: iconColor,
              ),
            ),
            Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 3),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black54,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
