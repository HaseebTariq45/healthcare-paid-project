import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/components/signup.dart';
import 'package:healthcare/views/screens/bottom_navigation_bar.dart';
import 'package:healthcare/views/screens/common/OTPVerification.dart';
import 'package:healthcare/views/screens/common/signup.dart';
import 'package:healthcare/views/screens/patient/bottom_navigation_patient.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page1.dart';
import 'package:healthcare/views/screens/doctor/complete_profile/doctor_profile_page1.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignIN extends StatefulWidget {
  const SignIN({super.key});

  @override
  State<SignIN> createState() => _SignINState();
}

class _SignINState extends State<SignIN> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
  
  // Send OTP for sign in
  Future<void> _sendOTP() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid phone number';
      });
      return;
    }
    
    // Format phone number if needed
    final formattedPhoneNumber = phoneNumber.startsWith('+') 
        ? phoneNumber 
        : '+92${phoneNumber.replaceAll(RegExp(r'^0+'), '')}';
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First check if this phone number exists in our database
      final userCheck = await _authService.getUserByPhoneNumber(formattedPhoneNumber);
      
      if (userCheck.containsKey('error')) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error checking user account: ${userCheck['error']}';
        });
        return;
      }
      
      if (userCheck['exists'] == true) {
        final userRole = userCheck['userRole'] as UserRole;
        final isProfileComplete = userCheck['isProfileComplete'] as bool;
        
        // Show a success message about the found account
        String userRoleDisplay = 'User';
        switch (userRole) {
          case UserRole.doctor: userRoleDisplay = 'Doctor'; break;
          case UserRole.patient: userRoleDisplay = 'Patient'; break;
          case UserRole.ladyHealthWorker: userRoleDisplay = 'Lady Health Worker'; break;
          case UserRole.admin: userRoleDisplay = 'Admin'; break;
          default: userRoleDisplay = 'User'; break;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account found for $userRoleDisplay'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Always proceed with OTP for real security - don't skip verification
      _proceedWithOTP(formattedPhoneNumber);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to sign in. Please try again.';
      });
    }
  }
  
  // Continue with OTP verification
  Future<void> _proceedWithOTP(String formattedPhoneNumber) async {
    try {
      // Send real OTP using Firebase
      final result = await _authService.sendOTP(
        phoneNumber: formattedPhoneNumber,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success']) {
        // If admin verification
        bool isAdmin = result['isAdmin'] == true;
        
        // If auto-verified (rare, but happens on some Android devices)
        if (result['autoVerified'] == true) {
          // Auto verification succeeded, navigate to home
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign in successful!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to appropriate screen based on user role
          _navigateAfterLogin();
        } else {
          // Navigate to OTP verification screen with verification ID
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                text: isAdmin ? "Admin Verification" : "Welcome Back",
                phoneNumber: formattedPhoneNumber,
                verificationId: result['verificationId'],
              ),
            ),
          );
        }
      } else {
        // Check if this is a billing issue
        if (result['billingIssue'] == true) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Firebase Authentication'),
              content: Text('To use phone authentication, please enable billing in your Firebase project. Contact the app administrator for assistance.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to send OTP. Please try again.';
      });
    }
  }
  
  // Navigate based on user role after successful login
  Future<void> _navigateAfterLogin() async {
    // Use the simplified direct navigation method
    try {
      final isProfileComplete = await _authService.isProfileComplete();
      
      // Get the appropriate screen widget based on role
      final navigationScreen = await _authService.getNavigationScreenForUser(
        isProfileComplete: isProfileComplete
      );
      
      // Navigate to the screen returned by our helper
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => navigationScreen),
        (route) => false,
      );
    } catch (e) {
      print('***** ERROR NAVIGATING AFTER LOGIN: $e *****');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error determining user type. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: ''),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo and Welcome Text
                Container(
                  margin: EdgeInsets.only(top: 10, bottom: 20),
                  child: Column(
                    children: [
                      Center(child: Image.asset("assets/images/logo.png", height: 100)),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3366CC),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to your account',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Input Fields Card
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 30),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone Number',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            hintText: "+92 300 0000000",
                            prefixIcon: Icon(LucideIcons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF3366CC), width: 1.5),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ll send a verification code to this number',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      
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
                    ],
                  ),
                ),
                
                // Send OTP Button
                Container(
                  margin: EdgeInsets.symmetric(vertical: 24),
                  child: InkWell(
                    onTap: _isLoading ? null : _sendOTP,
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: const Color(0xFF3366CC),
                            ),
                          )
                        : ProceedButton(
                            isEnabled: true,
                            text: 'Send OTP',
                          ),
                  ),
                ),
                
                // Sign Up Link
                Container(
                  margin: EdgeInsets.only(bottom: 40),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUp(type: "Patient")),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account?',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sign Up',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3366CC),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
