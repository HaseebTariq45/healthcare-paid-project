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

class _OTPVerificationScreenState extends State<OTPVerificationScreen> with SingleTickerProviderStateMixin {
  late String text;
  late String verificationId;
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isVerificationSuccessful = false;
  late AnimationController _animationController;

  Timer? _timer;
  int _start = 60;

  // Create a controller for each of the 6 OTP digits
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  
  // Main OTP controller for single input
  final TextEditingController _otpController = TextEditingController();
  
  // Track which input is focused
  int _focusedIndex = -1;
  // FocusNode for the hidden input
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    text = widget.text;
    verificationId = widget.verificationId;
    startTimer();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Listen to changes in the OTP controller
    _otpController.addListener(_onOtpChanged);
  }
  
  void _onOtpChanged() {
    final String otp = _otpController.text;
    
    // Update individual controllers
    for (int i = 0; i < 6; i++) {
      if (i < otp.length) {
        _controllers[i].text = otp[i];
      } else {
        _controllers[i].text = '';
      }
    }
    
    // Set focused index
    _focusedIndex = otp.length < 6 ? otp.length : 5;
    
    // Auto-verify when all 6 digits are entered
    if (otp.length == 6 && !_isLoading && !_isVerificationSuccessful) {
      _verifyOTP();
    }
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
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    _otpFocusNode.dispose();
    _animationController.dispose();
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
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent successfully!'),
            backgroundColor: Color(0xFF3366CC),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
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
    // Get OTP code from main controller
    final otp = _otpController.text;
    
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE1EDFF),
              Colors.white,
              Colors.white,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: [
                // Top animation
                Container(
                  height: 150,
                  margin: EdgeInsets.only(bottom: 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background decorative elements
                      Positioned(
                        top: 30,
                        right: 20,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Color(0x104F80E1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 30,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0x103366CC),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      
                      // OTP icon
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x304F80E1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.sms_outlined,
                          size: 40,
                          color: Color(0xFF3366CC),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content area with white card effect
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Verification Code',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF223A6A),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Enter the OTP sent to ${widget.phoneNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),
                      
                      // Hidden OTP input for actual typing
                      Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            counterText: "",
                          ),
                        ),
                      ),
                      
                      // Visual OTP boxes (display only)
                      GestureDetector(
                        onTap: () {
                          // Focus the hidden input when boxes are tapped
                          _otpFocusNode.requestFocus();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: size.width * 0.12,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _focusedIndex == index 
                                      ? Color(0xFFE1EDFF) 
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    width: 1.5,
                                    color: _controllers[index].text.isNotEmpty 
                                        ? Color(0xFF3366CC).withOpacity(0.3) 
                                        : Colors.transparent,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _controllers[index].text,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: Color(0xFF223A6A),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      if (_errorMessage != null)
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Expanded(
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
                      
                      SizedBox(height: 30),
                      
                      // Timer and resend button
                      _start > 0
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 18,
                                  color: Color(0xFF3366CC),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Resend OTP in $formattedTime",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            )
                          : TextButton(
                              onPressed: _isLoading ? null : _resendOTP,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    size: 16,
                                    color: Color(0xFF3366CC),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Resend OTP",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF3366CC),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      
                      SizedBox(height: 30),
                      
                      // Confirm OTP button
                      Container(
                        width: double.infinity,
                        child: _isLoading
                          ? ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Color(0xFF3366CC),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Color(0xFF3366CC).withOpacity(0.6),
                                disabledForegroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          : InkWell(
                              onTap: _isVerificationSuccessful ? null : _verifyOTP,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isVerificationSuccessful 
                                      ? [Color(0xFF3366CC).withOpacity(0.6), Color(0xFF4F80E1).withOpacity(0.6)]
                                      : [Color(0xFF3366CC), Color(0xFF4F80E1)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF3366CC).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    "Verify & Proceed",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
                
                // Illustration at bottom
                Container(
                  margin: EdgeInsets.only(top: 30),
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        color: Color(0xFF3366CC).withOpacity(0.7),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Your verification is secure and encrypted",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 