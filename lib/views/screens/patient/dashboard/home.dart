import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/appointment/available_doctors.dart';
import 'package:healthcare/views/screens/patient/appointment/appointment_booking_flow.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page1.dart';
import 'package:healthcare/views/screens/patient/appointment/payment_options.dart';
import 'package:healthcare/views/screens/appointment/all_appoinments.dart';
import 'package:healthcare/views/screens/menu/faqs.dart';
import 'package:healthcare/views/screens/patient/signup/patient_signup.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final int profileCompletionPercentage;
  
  const PatientHomeScreen({
    super.key, 
    this.profileStatus = "incomplete",
    this.suppressProfilePrompt = false,
    this.profileCompletionPercentage = 0,
  });

  @override
  _PatientHomeScreenState createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> with SingleTickerProviderStateMixin {
  late String profileStatus;
  late bool suppressProfilePrompt;
  late int profileCompletionPercentage;
  late TabController _tabController;
  final List<String> _categories = ["All", "Upcoming", "Completed", "Cancelled"];
  int _selectedCategoryIndex = 0;
  
  // User data
  String userName = "User";
  String? profileImageUrl;
  bool isLoading = true;
  List<Map<String, dynamic>> upcomingAppointments = [];
  Map<String, dynamic> userData = {};

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

  @override
  void initState() {
    super.initState();
    profileStatus = widget.profileStatus;
    suppressProfilePrompt = widget.suppressProfilePrompt;
    profileCompletionPercentage = widget.profileCompletionPercentage;
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // Initialize quick access doctors with a selection from different specialties
    _initializeQuickAccessDoctors();
    
    // Fetch user data from Firestore
    _fetchUserData();
    
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
  
  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      final userId = auth.currentUser?.uid;
      
      if (userId == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      print('Fetching data for user ID: $userId');
      
      // First try to get data from patients collection for medical details
      final patientDoc = await firestore.collection('patients').doc(userId).get();
      
      // Then get basic data from users collection (fallback)
      final userDoc = await firestore.collection('users').doc(userId).get();
      
      Map<String, dynamic> mergedData = {};
      
      // Check if either document exists
      if (!patientDoc.exists && !userDoc.exists) {
        print('No user data found in either collection');
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      // Merge data, prioritizing patients collection for medical info
      if (userDoc.exists) {
        mergedData.addAll(userDoc.data() ?? {});
        print('User data found: ${userDoc.data()?.keys.toList()}');
      }
      
      if (patientDoc.exists) {
        mergedData.addAll(patientDoc.data() ?? {});
        print('Patient data found: ${patientDoc.data()?.keys.toList()}');
      }
      
      // Get appointments based on selected category
      List<Map<String, dynamic>> appointments = [];
      try {
        // Define status filters based on category
        List<String> statusFilters;
        switch (_selectedCategoryIndex) {
          case 0: // All
            statusFilters = ['pending', 'confirmed', 'completed', 'cancelled', 'Pending', 'Confirmed', 'Completed', 'Cancelled'];
            break;
          case 1: // Upcoming
            statusFilters = ['pending', 'confirmed', 'Pending', 'Confirmed'];
            break;
          case 2: // Completed
            statusFilters = ['completed', 'Completed'];
            break;
          case 3: // Cancelled
            statusFilters = ['cancelled', 'Cancelled'];
            break;
          default:
            statusFilters = ['pending', 'confirmed', 'completed', 'cancelled', 'Pending', 'Confirmed', 'Completed', 'Cancelled'];
        }

        print('Fetching appointments with status filters: $statusFilters');
        
        // First try without the status filter to see if we have any appointments at all
        final allAppointmentsSnapshot = await firestore
            .collection('appointments')
            .where('patientId', isEqualTo: userId)
            .get();
            
        print('Total appointments found for patient: ${allAppointmentsSnapshot.docs.length}');
        
        if (allAppointmentsSnapshot.docs.isNotEmpty) {
          // Print all appointments and their status for debugging
          for (var doc in allAppointmentsSnapshot.docs) {
            print('Appointment ${doc.id} status: ${doc.data()['status']}');
          }
        }

        final appointmentsSnapshot = await firestore
            .collection('appointments')
            .where('patientId', isEqualTo: userId)
            .where('status', whereIn: statusFilters)
            .get();
        
        print('Found ${appointmentsSnapshot.docs.length} appointments matching status filter');
        
        for (var appointmentDoc in appointmentsSnapshot.docs) {
          try {
            final appointmentData = appointmentDoc.data();
            print('Processing appointment: ${appointmentDoc.id}');
            print('Appointment data: $appointmentData');
            
            // Fetch doctor details
            if (appointmentData['doctorId'] != null) {
              final doctorDoc = await firestore
                  .collection('doctors')
                  .doc(appointmentData['doctorId'])
                  .get();
              
              if (doctorDoc.exists) {
                final doctorData = doctorDoc.data() as Map<String, dynamic>;
                print('Found doctor data: ${doctorData['fullName'] ?? doctorData['name']}');
                
                // Format the appointment date
                DateTime appointmentDate;
                if (appointmentData['appointmentDate'] != null) {
                  appointmentDate = (appointmentData['appointmentDate'] as Timestamp).toDate();
                } else if (appointmentData['date'] != null && appointmentData['date'] is Timestamp) {
                  appointmentDate = (appointmentData['date'] as Timestamp).toDate();
                } else {
                  appointmentDate = DateTime.now();
                }
                
                String formattedDate = "${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}";
                String formattedTime = "${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')}";
                
                appointments.add({
                  'id': appointmentDoc.id,
                  'date': formattedDate,
                  'time': formattedTime,
                  'status': appointmentData['status'] ?? 'pending',
                  'doctorName': doctorData['fullName'] ?? doctorData['name'] ?? 'Unknown Doctor',
                  'specialty': doctorData['specialty'] ?? 'General',
                  'hospitalName': appointmentData['hospitalName'] ?? doctorData['hospitalName'] ?? 'Unknown Hospital',
                  'reason': appointmentData['reason'] ?? 'Consultation',
                  'doctorImage': doctorData['profileImageUrl'] ?? 'assets/images/User.png',
                  'fee': appointmentData['fee'] ?? '0',
                  'paymentStatus': appointmentData['paymentStatus'] ?? 'pending',
                  'paymentMethod': appointmentData['paymentMethod'] ?? 'Not specified',
                  'isPanelConsultation': appointmentData['isPanelConsultation'] ?? false,
                });
                print('Successfully added appointment to list');
              } else {
                print('Doctor document not found for ID: ${appointmentData['doctorId']}');
              }
            }
          } catch (e) {
            print('Error processing appointment: $e');
          }
        }
      } catch (e) {
        print('Error fetching appointments: $e');
      }
      
      // Calculate profile completion percentage if not available
      int completionPercentage = 0;
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
        
        completionPercentage = ((fieldsCompleted / totalFields) * 100).toInt();
      } else {
        completionPercentage = (mergedData['completionPercentage'] is int) 
            ? mergedData['completionPercentage'] 
            : (mergedData['completionPercentage'] is double)
                ? mergedData['completionPercentage'].toInt()
                : int.tryParse(mergedData['completionPercentage'].toString()) ?? 0;
      }
      
      setState(() {
        userData = mergedData;
        userName = mergedData['fullName'] ?? mergedData['name'] ?? "User";
        profileImageUrl = mergedData['profileImageUrl'];
        profileStatus = mergedData['profileComplete'] == true ? "complete" : "incomplete";
        profileCompletionPercentage = completionPercentage;
        upcomingAppointments = appointments;
        isLoading = false;
      });
      
      print('User data loaded: $userName, Profile Status: $profileStatus, Completion: $profileCompletionPercentage%');
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        isLoading = false;
      });
    }
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
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF3366CC),
                ),
              )
            : SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    
                    _buildBanner(),
                    _buildDiseaseCategories(),
                    _buildAppointmentsSection(),
                    _buildQuickAccessDoctors(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
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
              GestureDetector(
                onTap: () {
                  // Navigate to notifications
                },
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.bell,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                    LucideIcons.stethoscope,
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
                        "Profile Picture",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                              ? NetworkImage(profileImageUrl!) as ImageProvider
                              : AssetImage("assets/images/User.png"),
                            backgroundColor: Colors.grey.shade200,
                          ),
                          SizedBox(width: 10),
                          Text(
                            profileImageUrl != null && profileImageUrl!.isNotEmpty
                              ? "Profile picture set"
                              : "No profile picture",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: profileImageUrl != null && profileImageUrl!.isNotEmpty
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (upcomingAppointments.isNotEmpty)
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
                      "${upcomingAppointments.length} Upcoming",
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => profileStatus == "complete" ? 
                        AppointmentBookingFlow() : 
                        CompleteProfilePatient1Screen()),
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
                    profileStatus == "complete" ? "Book Now" : "Complete Profile",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
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
      onTap: () {
        // Navigate to doctors screen with the selected specialty
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorsScreen(
              specialty: category.name,
              doctors: _doctorsBySpecialty[category.name] ?? [],
            ),
          ),
        );
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

  Widget _buildAppointmentsSection() {
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
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                      _tabController.animateTo(index);
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 10),
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: _selectedCategoryIndex == index
                          ? Color(0xFF3366CC)
                          : Color(0xFFF5F7FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _categories[index],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _selectedCategoryIndex == index
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 15),
          if (upcomingAppointments.isEmpty)
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
                      "No appointments found",
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
            for (var appointment in upcomingAppointments)
              _buildAppointmentCard(appointment),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Container(
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
                    appointment['status'],
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildAppointmentDetail(
                      LucideIcons.calendar,
                      "Date",
                      appointment['date'],
                    ),
                    SizedBox(width: 15),
                    _buildAppointmentDetail(
                      LucideIcons.clock,
                      "Time",
                      appointment['time'],
                    ),
                  ],
                ),
                SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Join session
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
                        icon: Icon(LucideIcons.video, size: 18),
                        label: Text(
                          "Join Session",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF3366CC).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF3366CC).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // Show details
                        },
                        icon: Icon(
                          LucideIcons.info,
                          color: Color(0xFF3366CC),
                          size: 20,
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

  Widget _buildQuickAccessDoctors() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Top Doctors",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DoctorsScreen(
                      doctors: _getAllDoctors(),
                    )),
                  );
                },
                child: Text(
                  "See all",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color.fromRGBO(64, 124, 226, 1),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Container(
            height: 180,
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: _quickAccessDoctors.length,
              itemBuilder: (context, index) {
                final doctor = _quickAccessDoctors[index];
                return Container(
                  width: 150,
                  margin: EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(64, 124, 226, 0.05),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                        child: Center(
                          child: CircleAvatar(
                            radius: 35,
                            backgroundImage: AssetImage(doctor["image"]),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Text(
                              doctor["name"],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              doctor["specialty"],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  doctor["rating"].toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get all doctors from all specialties
  List<Map<String, dynamic>> _getAllDoctors() {
    List<Map<String, dynamic>> allDoctors = [];
    _doctorsBySpecialty.forEach((specialty, doctors) {
      allDoctors.addAll(doctors);
    });
    return allDoctors;
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

