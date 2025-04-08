import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/bottom_navigation_bar.dart';
import 'package:healthcare/views/screens/patient/bottom_navigation_patient.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page2.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage1 extends StatefulWidget {
  final UserRole userRole;
  
  const ProfilePage1({
    Key? key,
    required this.userRole,
  }) : super(key: key);

  @override
  State<ProfilePage1> createState() => _ProfilePage1State();
}

class _ProfilePage1State extends State<ProfilePage1> {
  late UserRole userRole;
  final AuthService _authService = AuthService();
  
  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  
  // Doctor specific controllers
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _clinicNameController = TextEditingController();
  
  // Patient specific controllers
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  String? _selectedGender = "Male";
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    userRole = widget.userRole;
    _loadUserInfo();
  }
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _specialtyController.dispose();
    _experienceController.dispose();
    _clinicNameController.dispose();
    _ageController.dispose();
    _bloodGroupController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserInfo() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Load existing user data from Firestore if available
        // This would be implemented to load any existing profile data
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }
  
  void _continueToNextPage() async {
    // Basic validation
    if (_fullNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your full name';
      });
      return;
    }
    
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
      });
      return;
    }
    
    // Different validation for doctors vs patients
    if (userRole == UserRole.doctor || userRole == UserRole.ladyHealthWorker) {
      if (_specialtyController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your specialty';
        });
        return;
      }
      
      if (_experienceController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your years of experience';
        });
        return;
      }
    } else {
      // Patient validation
      if (_ageController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your age';
        });
        return;
      }
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Save data to Firestore
      final user = _authService.currentUser;
      if (user != null) {
        // Create a data map based on user role
        Map<String, dynamic> userData = {
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'gender': _selectedGender,
        };
        
        // Add role-specific fields
        if (userRole == UserRole.doctor || userRole == UserRole.ladyHealthWorker) {
          userData.addAll({
            'specialty': _specialtyController.text.trim(),
            'experience': _experienceController.text.trim(),
            'clinicName': _clinicNameController.text.trim(),
          });
        } else {
          // Patient fields
          userData.addAll({
            'age': _ageController.text.trim(),
            'bloodGroup': _bloodGroupController.text.trim(),
            'height': _heightController.text.trim(),
            'weight': _weightController.text.trim(),
          });
        }
        
        // Update the user data in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(userData);
            
        // For patient continue to next page, for doctors complete profile
        if (userRole == UserRole.patient) {
          // Navigate to next profile page for patient
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage2(),
            ),
          );
        } else {
          // Complete profile for doctors and LHWs and navigate to dashboard
          await _authService.setProfileComplete(true);
          
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => BottomNavigationBarScreen(profileStatus: "complete"),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error saving profile: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDoctor = userRole == UserRole.doctor || userRole == UserRole.ladyHealthWorker;
    final String roleString = isDoctor ? 
      (userRole == UserRole.doctor ? "Doctor" : "Lady Health Worker") : 
      "Patient";
    
    return Scaffold(
      appBar: AppBarOnboarding(
        text: 'Complete Your Profile',
        isBackButtonVisible: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Personal Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3366CC),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  'Please complete your $roleString profile',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              SizedBox(height: 30),
              
              // Full Name
              _buildTextField(
                controller: _fullNameController,
                labelText: "Full Name",
                icon: Icons.person,
              ),
              SizedBox(height: 16),
              
              // Email
              _buildTextField(
                controller: _emailController,
                labelText: "Email Address",
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              
              // Gender selection
              _buildGenderSelection(),
              SizedBox(height: 16),
              
              // Doctor specific fields
              if (isDoctor) ...[
                _buildTextField(
                  controller: _specialtyController,
                  labelText: "Specialty",
                  icon: Icons.medical_services,
                ),
                SizedBox(height: 16),
                
                _buildTextField(
                  controller: _experienceController,
                  labelText: "Years of Experience",
                  icon: Icons.timelapse,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                
                _buildTextField(
                  controller: _clinicNameController,
                  labelText: "Clinic/Hospital Name",
                  icon: Icons.local_hospital,
                ),
                SizedBox(height: 16),
              ],
              
              // Patient specific fields
              if (!isDoctor) ...[
                _buildTextField(
                  controller: _ageController,
                  labelText: "Age",
                  icon: Icons.cake,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                
                _buildTextField(
                  controller: _bloodGroupController,
                  labelText: "Blood Group",
                  icon: Icons.bloodtype,
                ),
                SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _heightController,
                        labelText: "Height (cm)",
                        icon: Icons.height,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _weightController,
                        labelText: "Weight (kg)",
                        icon: Icons.monitor_weight,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
              
              // Common fields
              _buildTextField(
                controller: _addressController,
                labelText: "Address",
                icon: Icons.home,
              ),
              SizedBox(height: 16),
              
              _buildTextField(
                controller: _cityController,
                labelText: "City",
                icon: Icons.location_city,
              ),
              SizedBox(height: 16),
              
              // Error message display
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ),
              
              // Continue button
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _continueToNextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3366CC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isDoctor ? "Complete Profile" : "Continue",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
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
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade700,
        ),
        prefixIcon: Icon(icon, color: Color(0xFF3366CC)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF3366CC), width: 2),
        ),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.1),
      ),
    );
  }
  
  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            "Gender",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.person, color: Color(0xFF3366CC)),
              SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    _buildGenderOption("Male"),
                    SizedBox(width: 16),
                    _buildGenderOption("Female"),
                    SizedBox(width: 16),
                    _buildGenderOption("Other"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildGenderOption(String gender) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Row(
        children: [
          Radio<String>(
            value: gender,
            groupValue: _selectedGender,
            activeColor: Color(0xFF3366CC),
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
          Text(
            gender,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
