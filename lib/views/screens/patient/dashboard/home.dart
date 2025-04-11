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
        child: SingleChildScrollView(
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
                    "Amna!",
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
                        "Next Appointment",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Dr. Rizwan • 10 Jan • 12:00 PM",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 5),
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
                    "Upcoming",
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
                  "Find Your Specialist",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Book appointments with top doctors in Pakistan",
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
                      MaterialPageRoute(builder: (context) => AppointmentBookingFlow()),
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
                    "Book Now",
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
              LucideIcons.stethoscope,
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
          for (int i = 0; i < 2; i++) _buildAppointmentCard(),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard() {
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
                    backgroundImage: AssetImage("assets/images/User.png"),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dr. Rizwan Ahmed",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Cardiologist",
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
                    "Upcoming",
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
                      "Jan 10, 2025",
                    ),
                    SizedBox(width: 15),
                    _buildAppointmentDetail(
                      LucideIcons.clock,
                      "Time",
                      "12:00 pm - 1:00 pm",
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

