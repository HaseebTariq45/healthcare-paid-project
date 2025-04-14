import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/appointment/available_doctors.dart';
import 'package:healthcare/views/screens/patient/appointment/appointment_booking_flow.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page1.dart';
import 'package:healthcare/views/screens/patient/appointment/payment_options.dart';
import 'package:healthcare/views/screens/appointment/all_appoinments.dart';
import 'package:healthcare/views/screens/appointment/appointment_detail.dart';
import 'package:healthcare/views/screens/menu/faqs.dart';
import 'package:healthcare/views/screens/patient/signup/patient_signup.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Disease category model
class DiseaseCategory {
  final String name;
  final String nameUrdu;
  final IconData icon;
  final Color color;
  final String description;

  DiseaseCategory({
    required this.name,
    required this.nameUrdu,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class PatientHomeScreen extends StatefulWidget {
  final String profileStatus;
  final bool suppressProfilePrompt;
  final double profileCompletionPercentage;
  
  const PatientHomeScreen({
    super.key, 
    this.profileStatus = "incomplete",
    this.suppressProfilePrompt = false,
    this.profileCompletionPercentage = 0.0,
  });

  @override
  _PatientHomeScreenState createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> with SingleTickerProviderStateMixin {
  late String profileStatus;
  late bool suppressProfilePrompt;
  late double profileCompletionPercentage;
  late TabController _tabController;
  final List<String> _categories = ["All", "Upcoming", "Completed", "Cancelled"];
  int _selectedCategoryIndex = 0;
  
  // User data
  String userName = "User";
  String? profileImageUrl;
  bool isLoading = true;
  bool isRefreshing = false; // Flag for background refresh
  List<Map<String, dynamic>> upcomingAppointments = [];
  Map<String, dynamic> userData = {};
  static const String _userCacheKey = 'patient_home_data';

  // Updated disease categories data with 12 specialties
  final List<DiseaseCategory> _diseaseCategories = [
    DiseaseCategory(
      name: "Cardiology",
      nameUrdu: "امراض قلب",
      icon: LucideIcons.heartPulse,
      color: Color(0xFFF44336),
      description: "Heart and cardiovascular system specialists",
    ),
    DiseaseCategory(
      name: "Neurology",
      nameUrdu: "امراض اعصاب",
      icon: LucideIcons.brain,
      color: Color(0xFF2196F3),
      description: "Brain and nervous system specialists",
    ),
    DiseaseCategory(
      name: "Dermatology",
      nameUrdu: "جلدی امراض",
      icon: Icons.face_retouching_natural,
      color: Color(0xFFFF9800),
      description: "Skin and hair specialists",
    ),
    DiseaseCategory(
      name: "Pediatrics",
      nameUrdu: "اطفال",
      icon: Icons.child_care,
      color: Color(0xFF4CAF50),
      description: "Child health specialists",
    ),
    DiseaseCategory(
      name: "Orthopedics",
      nameUrdu: "ہڈیوں کے امراض",
      icon: LucideIcons.bone,
      color: Color(0xFF9C27B0),
      description: "Bone and joint specialists",
    ),
    DiseaseCategory(
      name: "ENT",
      nameUrdu: "کان ناک گلے کے امراض",
      icon: LucideIcons.ear,
      color: Color(0xFF00BCD4),
      description: "Ear, nose and throat specialists",
    ),
    DiseaseCategory(
      name: "Gynecology",
      nameUrdu: "نسائی امراض",
      icon: Icons.pregnant_woman,
      color: Color(0xFFE91E63),
      description: "Women's health specialists",
    ),
    DiseaseCategory(
      name: "Ophthalmology",
      nameUrdu: "آنکھوں کے امراض",
      icon: LucideIcons.eye,
      color: Color(0xFF3F51B5),
      description: "Eye care specialists",
    ),
    DiseaseCategory(
      name: "Dentistry",
      nameUrdu: "دانتوں کے امراض",
      icon: Icons.healing,
      color: Color(0xFF607D8B),
      description: "Dental care specialists",
    ),
    DiseaseCategory(
      name: "Psychiatry",
      nameUrdu: "نفسیاتی امراض",
      icon: LucideIcons.brain,
      color: Color(0xFF795548),
      description: "Mental health specialists",
    ),
    DiseaseCategory(
      name: "Pulmonology",
      nameUrdu: "پھیپھڑوں کے امراض",
      icon: Icons.air,
      color: Color(0xFF009688),
      description: "Lung and respiratory specialists",
    ),
    DiseaseCategory(
      name: "Gastrology",
      nameUrdu: "معدے کے امراض",
      icon: Icons.local_dining,
      color: Color(0xFFFF5722),
      description: "Digestive system specialists",
    ),
  ];

  // Sample doctors by specialty for quick access
  final Map<String, List<Map<String, dynamic>>> _doctorsBySpecialty = {
    "Cardiology": [
      {
        "name": "Dr. Arshad Khan",
        "specialty": "Cardiology",
        "rating": "4.9",
        "experience": "15 years",
        "fee": "Rs 2500",
        "location": "Shifa International Hospital",
        "image": "assets/images/User.png",
        "available": true
      },
      {
        "name": "Dr. Saima Malik",
        "specialty": "Cardiology",
        "rating": "4.7",
        "experience": "12 years",
        "fee": "Rs 2200",
        "location": "Pakistan Institute of Medical Sciences",
        "image": "assets/images/User.png",
        "available": true
      },
    ],
    "Neurology": [
      {
        "name": "Dr. Imran Rashid",
        "specialty": "Neurology",
        "rating": "4.8",
        "experience": "10 years",
        "fee": "Rs 2000",
        "location": "Agha Khan Hospital",
        "image": "assets/images/User.png",
        "available": true
      },
      {
        "name": "Dr. Nadia Ahmed",
        "specialty": "Neurology",
        "rating": "4.6",
        "experience": "8 years",
        "fee": "Rs 1800",
        "location": "CMH Rawalpindi",
        "image": "assets/images/User.png",
        "available": false
      },
    ],
    "Dermatology": [
      {
        "name": "Dr. Amina Khan",
        "specialty": "Dermatology",
        "rating": "4.7",
        "experience": "9 years",
        "fee": "Rs 1900",
        "location": "Quaid-e-Azam International Hospital",
        "image": "assets/images/User.png",
        "available": true
      },
      {
        "name": "Dr. Hassan Ali",
        "specialty": "Dermatology",
        "rating": "4.5",
        "experience": "7 years",
        "fee": "Rs 1700",
        "location": "Maroof International Hospital",
        "image": "assets/images/User.png",
        "available": true
      },
    ],
    "Pediatrics": [
      {
        "name": "Dr. Fatima Zaidi",
        "specialty": "Pediatrics",
        "rating": "4.9",
        "experience": "14 years",
        "fee": "Rs 2300",
        "location": "Children's Hospital",
        "image": "assets/images/User.png",
        "available": true
      },
      {
        "name": "Dr. Adeel Raza",
        "specialty": "Pediatrics",
        "rating": "4.8",
        "experience": "11 years",
        "fee": "Rs 2100",
        "location": "Shifa International Hospital",
        "image": "assets/images/User.png",
        "available": true
      },
    ],
    "Orthopedics": [
      {
        "name": "Dr. Farhan Khan",
        "specialty": "Orthopedics",
        "rating": "4.8",
        "experience": "13 years",
        "fee": "Rs 2200",
        "location": "Shaukat Khanum Memorial Hospital",
        "image": "assets/images/User.png",
        "available": true
      },
      {
        "name": "Dr. Sana Siddiqui",
        "specialty": "Orthopedics",
        "rating": "4.7",
        "experience": "10 years",
        "fee": "Rs 1900",
        "location": "PIMS Islamabad",
        "image": "assets/images/User.png",
        "available": false
      },
    ],
    "ENT": [
      {
        "name": "Dr. Ahmad Raza",
        "specialty": "ENT",
        "rating": "4.6",
        "experience": "9 years",
        "fee": "Rs 1800",
        "location": "KRL Hospital",
        "image": "assets/images/User.png",
        "available": true
      },
      {
        "name": "Dr. Zainab Tariq",
        "specialty": "ENT",
        "rating": "4.5",
        "experience": "8 years",
        "fee": "Rs 1700",
        "location": "Holy Family Hospital",
        "image": "assets/images/User.png",
        "available": true
      },
    ],
    "Gynecology": [
      {
        "name": "Dr. Samina Khan",
        "specialty": "Gynecology",
        "rating": "4.9",
        "experience": "15 years",
        "fee": "Rs 2400",
        "location": "Lady Reading Hospital",
        "image": "assets/images/User.png",
        "available": true
      },
      {
        "name": "Dr. Ayesha Malik",
        "specialty": "Gynecology",
        "rating": "4.8",
        "experience": "12 years",
        "fee": "Rs 2200",
        "location": "Shifa International Hospital",
        "image": "assets/images/User.png",
        "available": true
      },
    ],
    "Ophthalmology": [
      {
        "name": "Dr. Zulfiqar Ali",
        "specialty": "Ophthalmology",
        "rating": "4.7",
        "experience": "11 years",
        "fee": "Rs 1900",
        "location": "Al-Shifa Eye Trust Hospital",
        "image": "assets/images/User.png",
        "available": true
      },
      {
        "name": "Dr. Maryam Aziz",
        "specialty": "Ophthalmology",
        "rating": "4.6",
        "experience": "9 years",
        "fee": "Rs 1700",
        "location": "LRBT Eye Hospital",
        "image": "assets/images/User.png",
        "available": false
      },
    ],
    "Dentistry": [
      {
        "name": "Dr. Faisal Khan",
        "specialty": "Dentistry",
        "rating": "4.8",
        "experience": "10 years",
        "fee": "Rs 1800",
        "location": "Islamabad Dental Hospital",
        "image": "assets/images/User.png",
        "available": true
      },
      {
        "name": "Dr. Hina Nasir",
        "specialty": "Dentistry",
        "rating": "4.7",
        "experience": "8 years",
        "fee": "Rs 1600",
        "location": "Pearl Dental Clinic",
        "image": "assets/images/User.png",
        "available": true
      },
    ],
    "Psychiatry": [
      {
        "name": "Dr. Sohail Ahmed",
        "specialty": "Psychiatry",
        "rating": "4.8",
        "experience": "12 years",
        "fee": "Rs 2100",
        "location": "Institute of Psychiatry",
        "image": "assets/images/User.png",
        "available": true
      },
      {
        "name": "Dr. Nazia Hameed",
        "specialty": "Psychiatry",
        "rating": "4.7",
        "experience": "9 years",
        "fee": "Rs 1900",
        "location": "Fountain House",
        "image": "assets/images/User.png",
        "available": false
      },
    ],
    "Pulmonology": [
      {
        "name": "Dr. Tariq Mehmood",
        "specialty": "Pulmonology",
        "rating": "4.8",
        "experience": "13 years",
        "fee": "Rs 2200",
        "location": "National Institute of Chest Diseases",
        "image": "assets/images/User.png",
        "available": true
      },
      {
        "name": "Dr. Sadia Khan",
        "specialty": "Pulmonology",
        "rating": "4.6",
        "experience": "10 years",
        "fee": "Rs 2000",
        "location": "Gulab Devi Chest Hospital",
        "image": "assets/images/User.png",
        "available": true
      },
    ],
    "Gastrology": [
      {
        "name": "Dr. Adnan Qureshi",
        "specialty": "Gastrology",
        "rating": "4.7",
        "experience": "11 years",
        "fee": "Rs 2100",
        "location": "Pakistan Kidney and Liver Institute",
        "image": "assets/images/User.png",
        "available": true
      },
      {
        "name": "Dr. Rabia Saleem",
        "specialty": "Gastrology",
        "rating": "4.6",
        "experience": "9 years",
        "fee": "Rs 1900",
        "location": "Shifa International Hospital",
        "image": "assets/images/User.png",
        "available": false
      },
    ],
  };

  // Quick access doctors list
  List<Map<String, dynamic>> _quickAccessDoctors = [];

  // Add this at the top with other class variables
  Map<String, List<Map<String, dynamic>>> _cachedDoctors = {};

  // Add this method to format rating
  String _formatRating(double rating) {
    return rating.toStringAsFixed(1); // This will show only one decimal place
  }

  @override
  void initState() {
    super.initState();
    profileStatus = widget.profileStatus;
    suppressProfilePrompt = widget.suppressProfilePrompt;
    profileCompletionPercentage = widget.profileCompletionPercentage;
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // Initialize quick access doctors with a selection from different specialties
    _initializeQuickAccessDoctors();
    
    // Load data with caching
    _loadData();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (profileStatus.toLowerCase() != "complete" && !suppressProfilePrompt) {
        // Directly navigate to profile completion screen instead of showing popup
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CompleteProfilePatient1Screen(),
          ),
        );
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    // Try to load data from cache first
    await _loadCachedData();
    
    // Then fetch fresh data from Firestore
    await _fetchUserData();
  }

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString(_userCacheKey);
      
      if (cachedData != null) {
        Map<String, dynamic> data = json.decode(cachedData);
        
        setState(() {
          userData = data;
          userName = data['fullName'] ?? data['name'] ?? "User";
          profileImageUrl = data['profileImageUrl'];
          profileStatus = data['profileComplete'] == true ? "complete" : "incomplete";
          profileCompletionPercentage = (data['completionPercentage'] as num?)?.toDouble() ?? 0.0;
          upcomingAppointments = List<Map<String, dynamic>>.from(data['appointments'] ?? []);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cached data: $e');
    }
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        isRefreshing = true;
      });

      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      final userId = auth.currentUser?.uid;
      
      if (userId == null) {
        setState(() {
          isRefreshing = false;
          isLoading = false;
        });
        return;
      }

      // First try to get data from patients collection for medical details
      final patientDoc = await firestore.collection('patients').doc(userId).get();
      
      // Then get basic data from users collection (fallback)
      final userDoc = await firestore.collection('users').doc(userId).get();
      
      Map<String, dynamic> mergedData = {};
      
      // Check if either document exists
      if (!patientDoc.exists && !userDoc.exists) {
        debugPrint('No user data found in either collection');
        setState(() => isLoading = false);
        return;
      }
      
      // Merge data, prioritizing patients collection for medical info
      if (userDoc.exists) {
        mergedData.addAll(userDoc.data() ?? {});
      }
      
      if (patientDoc.exists) {
        mergedData.addAll(patientDoc.data() ?? {});
      }

      // Get appointments
      List<Map<String, dynamic>> appointments = [];
      try {
        final appointmentsSnapshot = await firestore
            .collection('appointments')
            .where('patientId', isEqualTo: userId)
            .get();

        final DateTime now = DateTime.now();

        for (var appointmentDoc in appointmentsSnapshot.docs) {
          final appointmentData = appointmentDoc.data();
          
          // Fetch doctor details
          if (appointmentData['doctorId'] != null) {
            final doctorDoc = await firestore
                .collection('doctors')
                .doc(appointmentData['doctorId'].toString())
                .get();
            
            if (doctorDoc.exists) {
              final doctorData = doctorDoc.data() as Map<String, dynamic>;
              
              // Get appointment date and time
              final String dateStr = appointmentData['date']?.toString() ?? '';
              final String timeStr = appointmentData['time']?.toString() ?? '';
              
              DateTime? appointmentDateTime;
              
              // Try to parse date and time
              try {
                if (dateStr.contains('/')) {
                  // Parse dd/MM/yyyy format
                  final parts = dateStr.split('/');
                  if (parts.length == 3) {
                    appointmentDateTime = DateTime(
                      int.parse(parts[2]),  // year
                      int.parse(parts[1]),  // month
                      int.parse(parts[0]),  // day
                    );
                  }
                } else {
                  // Try parsing ISO format
                  appointmentDateTime = DateTime.parse(dateStr);
                }

                // Add time if available
                if (appointmentDateTime != null && timeStr.isNotEmpty) {
                  // Clean up time string and handle AM/PM
                  String cleanTime = timeStr.toUpperCase().trim();
                  bool isPM = cleanTime.contains('PM');
                  cleanTime = cleanTime.replaceAll('AM', '').replaceAll('PM', '').trim();
                  
                  final timeParts = cleanTime.split(':');
                  if (timeParts.length >= 2) {
                    int hour = int.parse(timeParts[0]);
                    int minute = int.parse(timeParts[1]);
                    
                    // Convert to 24-hour format if PM
                    if (isPM && hour < 12) {
                      hour += 12;
                    }
                    // Handle 12 AM case
                    if (!isPM && hour == 12) {
                      hour = 0;
                    }
                    
                    appointmentDateTime = DateTime(
                      appointmentDateTime.year,
                      appointmentDateTime.month,
                      appointmentDateTime.day,
                      hour,
                      minute,
                    );
                  }
                }
              } catch (e) {
                print('Error parsing date/time for appointment: $e');
                print('Date string: $dateStr');
                print('Time string: $timeStr');
              }

              // Determine appointment status based on date/time
              String status;
              if (appointmentDateTime != null) {
                status = appointmentDateTime.isAfter(now) ? 'upcoming' : 'completed';
                print('Appointment DateTime: $appointmentDateTime');
                print('Current DateTime: $now');
                print('Status determined: $status');
              } else {
                status = appointmentData['status']?.toString().toLowerCase() ?? 'upcoming';
                print('Using fallback status: $status');
              }
              
              appointments.add({
                'id': appointmentDoc.id,
                'date': dateStr,
                'time': timeStr,
                'status': status,
                'doctorName': doctorData['fullName'] ?? doctorData['name'] ?? 'Unknown Doctor',
                'specialty': doctorData['specialty'] ?? 'General',
                'hospitalName': appointmentData['hospitalName'] ?? 'Unknown Hospital',
                'reason': appointmentData['reason'] ?? 'Consultation',
                'doctorImage': doctorData['profileImageUrl'] ?? 'assets/images/User.png',
                'fee': appointmentData['fee']?.toString() ?? '0',
                'paymentStatus': appointmentData['paymentStatus'] ?? 'pending',
                'paymentMethod': appointmentData['paymentMethod'] ?? 'Not specified',
                'isPanelConsultation': appointmentData['isPanelConsultation'] ?? false,
                'type': appointmentData['isPanelConsultation'] ? 'In-Person Visit' : 'Regular Consultation',
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching appointments: $e');
      }

      // Calculate profile completion percentage if not available
      double completionPercentage = 0.0;
      if (mergedData['completionPercentage'] == null) {
        int fieldsCompleted = 0;
        int totalFields = 10; // Adjust based on your required fields
        
        // Check basic fields
        if (mergedData['fullName'] != null && mergedData['fullName'].toString().isNotEmpty) fieldsCompleted++;
        if (mergedData['email'] != null && mergedData['email'].toString().isNotEmpty) fieldsCompleted++;
        if (mergedData['phoneNumber'] != null && mergedData['phoneNumber'].toString().isNotEmpty) fieldsCompleted++;
        if (mergedData['address'] != null && mergedData['address'].toString().isNotEmpty) fieldsCompleted++;
        if (mergedData['city'] != null && mergedData['city'].toString().isNotEmpty) fieldsCompleted++;
        
        // Check medical fields
        if (mergedData['age'] != null && mergedData['age'].toString().isNotEmpty) fieldsCompleted++;
        if (mergedData['bloodGroup'] != null && mergedData['bloodGroup'].toString().isNotEmpty) fieldsCompleted++;
        if (mergedData['height'] != null && mergedData['height'].toString().isNotEmpty) fieldsCompleted++;
        if (mergedData['weight'] != null && mergedData['weight'].toString().isNotEmpty) fieldsCompleted++;
        if (mergedData['profileImageUrl'] != null && mergedData['profileImageUrl'].toString().isNotEmpty) fieldsCompleted++;
        
        completionPercentage = ((fieldsCompleted / totalFields) * 100).toDouble();
      } else {
        completionPercentage = (mergedData['completionPercentage'] is double)
            ? mergedData['completionPercentage']
            : (mergedData['completionPercentage'] is int)
                ? mergedData['completionPercentage'].toDouble()
                : double.tryParse(mergedData['completionPercentage'].toString()) ?? 0.0;
      }

      // Convert Timestamps to strings in mergedData to make it cacheable
      Map<String, dynamic> cacheableData = Map<String, dynamic>.from(mergedData);
      _convertTimestampsToStrings(cacheableData);

      // Save to cache
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userCacheKey, json.encode({
          ...cacheableData,
          'appointments': appointments,
        }));
      } catch (e) {
        debugPrint('Error saving to cache: $e');
      }
      
      setState(() {
        userData = mergedData;
        userName = mergedData['fullName'] ?? mergedData['name'] ?? "User";
        profileImageUrl = mergedData['profileImageUrl'];
        profileStatus = mergedData['profileComplete'] == true ? "complete" : "incomplete";
        profileCompletionPercentage = completionPercentage;
        upcomingAppointments = appointments;
        isLoading = false;
        isRefreshing = false;
      });
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  // Helper method to convert Timestamps to strings in a map
  void _convertTimestampsToStrings(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is Timestamp) {
        data[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        _convertTimestampsToStrings(value);
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          if (value[i] is Map<String, dynamic>) {
            _convertTimestampsToStrings(value[i]);
          }
        }
      }
    });
  }

  Future<void> _refreshData() async {
    await _fetchUserData();
  }

  void _initializeQuickAccessDoctors() {
    // Get one doctor from each of the top 3 specialties
    _quickAccessDoctors = [
      _doctorsBySpecialty["Cardiology"]![0],
      _doctorsBySpecialty["Gynecology"]![0],
      _doctorsBySpecialty["Pediatrics"]![0],
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: isLoading && userData.isEmpty
              ? Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF3366CC),
                  ),
                )
              : Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _refreshData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            _buildBanner(),
                            _buildDiseaseCategories(),
                            _buildAppointmentsSection(),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    
                    // Refresh indicator at bottom
                    if (isRefreshing)
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
      ),
    );
  }

  Widget _buildHeader() {
    // Find the earliest upcoming appointment if available
    Map<String, dynamic>? earliestAppointment;
    if (upcomingAppointments.isNotEmpty) {
      // Filter only upcoming appointments (pending/confirmed)
      List<Map<String, dynamic>> upcoming = upcomingAppointments.where(
        (appointment) => appointment['status'].toString().toLowerCase() == 'pending' || 
                        appointment['status'].toString().toLowerCase() == 'confirmed'
      ).toList();
      
      if (upcoming.isNotEmpty) {
        // Sort by date and time to find the earliest
        upcoming.sort((a, b) {
          // Simple string comparison for date format "dd/mm/yyyy"
          int dateCompare = a['date'].toString().compareTo(b['date'].toString());
          if (dateCompare != 0) return dateCompare;
          // If same date, compare time
          return a['time'].toString().compareTo(b['time'].toString());
        });
        
        earliestAppointment = upcoming.first;
      }
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 15, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3366CC),
            Color(0xFF5E8EF7),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3366CC).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello,",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Profile Completion Tab - Only show when not 100% complete
          if (profileCompletionPercentage < 100)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFA726),
                    Color(0xFFFF7043),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF7043).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.userCheck,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Profile Completion",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$profileCompletionPercentage%",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF7043),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: profileCompletionPercentage / 100,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
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
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.arrowRight,
                        color: Color(0xFFFF7043),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFF3366CC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    earliestAppointment != null ? LucideIcons.calendar : LucideIcons.user,
                    color: Color(0xFF3366CC),
                    size: 24,
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        earliestAppointment != null ? "Upcoming Appointment" : "Profile Status",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      earliestAppointment != null 
                      ? Text(
                          "With ${earliestAppointment['doctorName']} on ${earliestAppointment['date']}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                LucideIcons.user,
                                color: Colors.grey.shade400,
                                size: 22,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "No profile picture added",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (earliestAppointment != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF3366CC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(0xFF3366CC).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      earliestAppointment['time'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3366CC),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3366CC),
            Color(0xFF5E8EF7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3366CC).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData.containsKey('bloodGroup') ? 
                    "Your Blood Group: ${userData['bloodGroup']}" :
                    "Complete Your Profile",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  profileStatus == "complete" ?
                    "Your profile is complete. Book appointments with top doctors." :
                    "Complete your profile to get personalized recommendations",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppointmentBookingFlow(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF3366CC),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Book Appointment",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    if (profileStatus != "complete")
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CompleteProfilePatient1Screen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3366CC).withOpacity(0.1),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Complete Profile",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              profileStatus == "complete" ? LucideIcons.stethoscope : LucideIcons.userPlus,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCategories() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Specialties",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _diseaseCategories.length,
            itemBuilder: (context, index) {
              final category = _diseaseCategories[index];
              return _buildDiseaseCategoryCard(category);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCategoryCard(DiseaseCategory category) {
    return InkWell(
      onTap: () async {
        try {
          // Check if we have cached data
          if (_cachedDoctors.containsKey(category.name)) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorsScreen(
                  specialty: category.name,
                  doctors: _cachedDoctors[category.name]!,
                ),
              ),
            );
            // Fetch fresh data in background
            _fetchDoctorsData(category.name, showLoading: false);
            return;
          }

          // Show loading dialog only for first load
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3366CC)),
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Loading doctors...",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

          await _fetchDoctorsData(category.name, showLoading: true);

        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context); // Pop loading dialog if showing
            
            // Show error dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(
                    "Error",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  content: Text(
                    "Failed to load doctors. Please try again later.",
                    style: GoogleFonts.poppins(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "OK",
                        style: GoogleFonts.poppins(
                          color: Color(0xFF3366CC),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 24,
              ),
            ),
            SizedBox(height: 8),
            Text(
              category.name,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              category.nameUrdu,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Add this new method for fetching doctors data
  Future<void> _fetchDoctorsData(String specialty, {required bool showLoading}) async {
    try {
      // Fetch doctors from Firestore based on specialty
      final QuerySnapshot doctorsSnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .where('specialty', isEqualTo: specialty)
          .where('isApproved', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> doctors = [];
      
      for (var doc in doctorsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get doctor's rating from reviews
        final QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
            .collection('doctor_reviews')
            .where('doctorId', isEqualTo: doc.id)
            .get();
        
        double averageRating = 0.0;
        if (reviewsSnapshot.docs.isNotEmpty) {
          double totalRating = 0;
          for (var review in reviewsSnapshot.docs) {
            totalRating += (review.data() as Map<String, dynamic>)['rating'] ?? 0;
          }
          averageRating = (totalRating / reviewsSnapshot.docs.length);
        }

        // Get doctor's hospital affiliations
        List<String> hospitals = [];
        if (data['hospitalIds'] != null) {
          for (String hospitalId in List<String>.from(data['hospitalIds'])) {
            final hospitalDoc = await FirebaseFirestore.instance
                .collection('hospitals')
                .doc(hospitalId)
                .get();
            if (hospitalDoc.exists) {
              hospitals.add(hospitalDoc.get('name'));
            }
          }
        }

        doctors.add({
          'id': doc.id,
          'name': data['fullName'] ?? 'Dr. Unknown',
          'specialty': data['specialty'] ?? specialty,
          'rating': averageRating.toStringAsFixed(1),
          'experience': data['experience'] ?? '0 years',
          'fee': data['consultationFee']?.toString() ?? 'Not specified',
          'location': hospitals.isNotEmpty ? hospitals.first : 'Location not specified',
          'image': data['profileImageUrl'] ?? 'assets/images/User.png',
          'available': data['isAvailable'] ?? true,
          'hospitals': hospitals,
          'education': data['education'] ?? [],
          'about': data['about'] ?? 'No information available',
          'languages': data['languages'] ?? ['English'],
          'services': data['services'] ?? [],
        });
      }

      // Update cache
      _cachedDoctors[specialty] = doctors;

      if (showLoading) {
        // Pop loading dialog if it was shown
        if (context.mounted) {
          Navigator.pop(context);
        }

        // Navigate to doctors screen with fetched data
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorsScreen(
                specialty: specialty,
                doctors: doctors,
              ),
            ),
          );
        }
      }
    } catch (e) {
      rethrow; // Let the calling method handle the error
    }
  }

  Widget _buildAppointmentsSection() {
    // Filter appointments based on status
    final List<Map<String, dynamic>> upcoming = upcomingAppointments.where((a) => 
      a['status']?.toString().toLowerCase() == 'upcoming').toList();
    final List<Map<String, dynamic>> completed = upcomingAppointments.where((a) => 
      a['status']?.toString().toLowerCase() == 'completed').toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My Appointments",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AppointmentsScreen()),
                  );
                },
                child: Text(
                  "See all",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3366CC),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Container(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = 0;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: _selectedCategoryIndex == 0
                            ? Color(0xFF3366CC)
                            : Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Upcoming",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _selectedCategoryIndex == 0
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = 1;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedCategoryIndex == 1
                            ? Color(0xFF3366CC)
                            : Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Completed",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _selectedCategoryIndex == 1
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          if ((_selectedCategoryIndex == 0 ? upcoming : completed).isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "No ${_selectedCategoryIndex == 0 ? 'upcoming' : 'completed'} appointments",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (var appointment in (_selectedCategoryIndex == 0 ? upcoming : completed).take(2))
              _buildAppointmentCard(appointment),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final String statusText = appointment['status']?.toString().toLowerCase() ?? 'upcoming';
    final bool isUpcoming = statusText == 'upcoming' || statusText == 'pending' || statusText == 'confirmed';
    
    final Color statusColor = isUpcoming
        ? Color.fromRGBO(64, 124, 226, 1)
        : Color(0xFF4CAF50);
            
    final String displayStatus = isUpcoming ? "Upcoming" : "Completed";
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(
              appointmentDetails: appointment,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF3366CC).withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
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
                      radius: 25,
                      backgroundImage: appointment['doctorImage'].startsWith('assets/')
                          ? AssetImage(appointment['doctorImage'])
                          : NetworkImage(appointment['doctorImage']) as ImageProvider,
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment['doctorName'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          appointment['specialty'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF3366CC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(0xFF3366CC).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      displayStatus,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildAppointmentDetail(
                        LucideIcons.calendar,
                        "Appointment Date",
                        appointment['date'],
                      ),
                      SizedBox(width: 15),
                      _buildAppointmentDetail(
                        LucideIcons.clock,
                        "Appointment Time",
                        appointment['time'],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildAppointmentDetail(
                        LucideIcons.building2,
                        "Hospital",
                        appointment['hospitalName'] ?? "Unknown Hospital",
                      ),
                      SizedBox(width: 15),
                      _buildAppointmentDetail(
                        LucideIcons.tag,
                        "Type",
                        appointment['type'],
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
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
                                  appointmentDetails: appointment,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3366CC),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            shadowColor: Color(0xFF3366CC).withOpacity(0.3),
                          ),
                          icon: Icon(LucideIcons.building2, size: 18),
                          label: Text(
                            "View Details",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildAppointmentDetail(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color.fromRGBO(64, 124, 226, 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Color.fromRGBO(64, 124, 226, 1),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add exit confirmation dialog
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
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
}

void showPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5,
              sigmaY: 5,
            ),
            child: Container(
              color: const Color.fromARGB(30, 0, 0, 0),
            ),
          ),
          AlertDialog(
            backgroundColor: const Color.fromRGBO(64, 124, 226, 1),
            title: Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 20),
              child: Center(
                child: Text(
                  "Please Complete Your Profile first",
                  style: GoogleFonts.poppins(fontSize: 20, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            actions: [
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CompleteProfilePatient1Screen(),
                    ),
                  );
                },
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      color: const Color.fromRGBO(217, 217, 217, 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        "Proceed",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

