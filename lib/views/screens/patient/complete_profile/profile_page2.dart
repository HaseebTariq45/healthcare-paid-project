import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/bottom_navigation_patient.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage2 extends StatefulWidget {
  const ProfilePage2({Key? key}) : super(key: key);

  @override
  State<ProfilePage2> createState() => _ProfilePage2State();
}

class _ProfilePage2State extends State<ProfilePage2> {
  final AuthService _authService = AuthService();
  
  // Form controllers for medical history
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _chronicConditionsController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _surgicalHistoryController = TextEditingController();
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactNumberController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Medical conditions checkboxes
  Map<String, bool> _medicalConditions = {
    'Diabetes': false,
    'Hypertension': false,
    'Asthma': false,
    'Heart Disease': false,
    'Arthritis': false,
    'Cancer': false,
    'Other': false,
  };
  
  @override
  void dispose() {
    _allergiesController.dispose();
    _chronicConditionsController.dispose();
    _medicationsController.dispose();
    _surgicalHistoryController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    super.dispose();
  }
  
  void _completeProfile() async {
    // Validate emergency contact fields
    if (_emergencyContactNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter emergency contact name';
      });
      return;
    }
    
    if (_emergencyContactNumberController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter emergency contact number';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Save medical history to Firestore
      final user = _authService.currentUser;
      if (user != null) {
        // Get selected medical conditions
        List<String> selectedConditions = [];
        _medicalConditions.forEach((condition, isSelected) {
          if (isSelected) {
            selectedConditions.add(condition);
          }
        });
        
        // Create medical history data
        Map<String, dynamic> medicalHistory = {
          'allergies': _allergiesController.text.trim(),
          'chronicConditions': _chronicConditionsController.text.trim(),
          'medications': _medicationsController.text.trim(),
          'surgicalHistory': _surgicalHistoryController.text.trim(),
          'medicalConditions': selectedConditions,
          'emergencyContact': {
            'name': _emergencyContactNameController.text.trim(),
            'phone': _emergencyContactNumberController.text.trim(),
          },
        };
        
        // Update user document with medical history
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'medicalHistory': medicalHistory,
          'profileComplete': true, // Mark profile as complete
        });
        
        // Update the profile status in the auth service
        await _authService.setProfileComplete(true);
        
        // Navigate to patient dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavigationBarPatientScreen(profileStatus: "complete"),
          ),
          (route) => false,
        );
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
    return Scaffold(
      appBar: AppBarOnboarding(
        text: 'Medical History', 
        isBackButtonVisible: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide your medical history',
                style: GoogleFonts.poppins(
                  fontSize: 16, 
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 24),
              
              // Medical conditions section
              Text(
                'Medical Conditions',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3366CC),
                ),
              ),
              SizedBox(height: 12),
              
              // Checkboxes for medical conditions
              ..._medicalConditions.entries.map((entry) => _buildCheckboxTile(
                entry.key, 
                entry.value,
                (value) {
                  setState(() {
                    _medicalConditions[entry.key] = value ?? false;
                  });
                },
              )).toList(),
              
              SizedBox(height: 24),
              
              // Allergies
              _buildTextField(
                controller: _allergiesController,
                labelText: 'Allergies',
                maxLines: 2,
              ),
              SizedBox(height: 16),
              
              // Chronic Conditions
              _buildTextField(
                controller: _chronicConditionsController,
                labelText: 'Chronic Conditions',
                maxLines: 2,
              ),
              SizedBox(height: 16),
              
              // Current Medications
              _buildTextField(
                controller: _medicationsController,
                labelText: 'Current Medications',
                maxLines: 2,
              ),
              SizedBox(height: 16),
              
              // Surgical History
              _buildTextField(
                controller: _surgicalHistoryController,
                labelText: 'Surgical History',
                maxLines: 2,
              ),
              SizedBox(height: 24),
              
              // Emergency Contact
              Text(
                'Emergency Contact',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3366CC),
                ),
              ),
              SizedBox(height: 12),
              
              // Emergency Contact Name
              _buildTextField(
                controller: _emergencyContactNameController,
                labelText: 'Name',
              ),
              SizedBox(height: 16),
              
              // Emergency Contact Number
              _buildTextField(
                controller: _emergencyContactNumberController,
                labelText: 'Phone Number',
                keyboardType: TextInputType.phone,
              ),
              
              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ),
              
              // Complete Profile Button
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3366CC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Complete Profile',
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
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade700,
        ),
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
  
  Widget _buildCheckboxTile(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Color(0xFF3366CC),
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
