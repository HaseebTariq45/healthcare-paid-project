import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/components/signup.dart';
import 'package:healthcare/views/screens/bottom_navigation_bar.dart';
import 'package:healthcare/views/screens/patient/bottom_navigation_patient.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page1.dart';
import 'package:healthcare/views/screens/doctor/complete_profile/doctor_profile_page1.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthcare/utils/navigation_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String text;
  final String phoneNumber;
  final String verificationId;
  final String? fullName;
  final String? userType;

  const OTPVerificationScreen({
    super.key,
    required this.text,
    required this.phoneNumber,
    required this.verificationId,
    this.fullName,
    this.userType,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  late String text;
  late String verificationId;
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isVerificationSuccessful = false;

  Timer? _timer;
  int _start = 60;

  // Create a controller for each of the 6 OTP digits
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    text = widget.text;
    verificationId = widget.verificationId;
    startTimer();
  }

  void startTimer() {
    setState(() {
      _start = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Resend OTP method
  Future<void> _resendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final result = await _authService.sendOTP(
        phoneNumber: widget.phoneNumber,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success']) {
        // Update verification ID
        verificationId = result['verificationId'];
        // Clear OTP fields
        for (final controller in _controllers) {
          controller.clear();
        }
        // Restart timer
        startTimer();
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to resend OTP. Please try again.';
      });
    }
  }

  Future<void> _verifyOTP() async {
    // Get OTP code from text fields
    final otp = _controllers.map((c) => c.text).join();
    
    // Validate OTP code
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Verify OTP with Firebase
      final result = await _authService.verifyOTP(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      if (result['success']) {
        // Set flag for successful verification
        _isVerificationSuccessful = true;
        
        // Success notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification successful!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Check if this is a new user (from sign up) or existing user (login)
        if (widget.userType != null && widget.fullName != null) {
          // This is a new user signing up
          final String uid = result['user'].uid;
              
          final registerResult = await _registerNewUser(uid);
          
          if (!registerResult['success']) {
            setState(() {
              _isLoading = false;
              _errorMessage = registerResult['message'];
            });
            return;
          }
        
          // Update last login timestamp
          await _authService.updateLastLogin(uid);
        }
        
        // Navigate based on user role and profile completion
        await _navigateBasedOnUserRole();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error verifying OTP. Please try again.';
      });
    }
  }

  Future<Map<String, dynamic>> _registerNewUser(String uid) async {
    if (widget.userType == null || widget.fullName == null) {
      print('***** REGISTER NEW USER - MISSING USER INFO *****');
      return {
        'success': false,
        'message': 'Missing user information'
      };
    }
    
    print('***** REGISTER NEW USER - TYPE FROM WIDGET: ${widget.userType} *****');
    
    // Convert string user type to enum
    UserRole role;
    switch (widget.userType) {
      case 'Patient':
        role = UserRole.patient;
        print('***** REGISTER NEW USER - MAPPED TO PATIENT ROLE *****');
        break;
      case 'Doctor':
        role = UserRole.doctor;
        print('***** REGISTER NEW USER - MAPPED TO DOCTOR ROLE *****');
        break;
      case 'Lady Health Worker':
        role = UserRole.ladyHealthWorker;
        print('***** REGISTER NEW USER - MAPPED TO LHW ROLE *****');
        break;
      default:
        role = UserRole.patient;
        print('***** REGISTER NEW USER - DEFAULTED TO PATIENT ROLE *****');
    }
    
    // Register user in Firestore
    return await _authService.registerUser(
      uid: uid,
      fullName: widget.fullName!,
      phoneNumber: widget.phoneNumber,
      role: role,
    );
  }

  Future<void> _navigateBasedOnUserRole() async {
    // Use the simplified direct navigation method
    final isProfileComplete = await _authService.isProfileComplete();
    
    try {
      // Get the appropriate screen widget based on role
      final navigationScreen = await _authService.getNavigationScreenForUser(
        isProfileComplete: isProfileComplete
      );
      
      setState(() {
        _isLoading = false;
      });
      
      // Navigate to the screen returned by our helper
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => navigationScreen),
        (route) => false,
      );
    } catch (e) {
      print('Error navigating based on user role: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error determining user type. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final minutes = _start ~/ 60;
    final seconds = _start % 60;
    final formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBarOnboarding(text: text, isBackButtonVisible: true),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  'Enter the OTP sent to ${widget.phoneNumber}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // OTP input fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: size.width * 0.12,
                      child: TextField(
                        onTapOutside: (event) => FocusScope.of(context).unfocus(),
                        controller: _controllers[index],
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          counterText: "",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            FocusScope.of(context).nextFocus();
                          }
                          
                          // Auto-submit when all digits are entered
                          if (index == 5 && value.isNotEmpty) {
                            _verifyOTP();
                          }
                        },
                      ),
                    );
                  }),
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
              
              const SizedBox(height: 24),
              _start > 0
                  ? Text(
                    "Resend OTP in $formattedTime",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  )
                  : TextButton(
                    onPressed: _isLoading ? null : _resendOTP,
                    child: Text(
                      "Resend OTP",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
              const SizedBox(height: 24),
              // Confirm OTP button
              Container(
                margin: const EdgeInsets.only(top: 40),
                child: InkWell(
                  onTap: _isLoading || _isVerificationSuccessful ? null : _verifyOTP,
                  child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFF3366CC),
                        ),
                      )
                    : ProceedButton(isEnabled: !_isVerificationSuccessful, text: "Confirm OTP"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 