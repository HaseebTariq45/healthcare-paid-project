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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/views/screens/admin/admin_dashboard.dart';

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

  // Main OTP controller for single input
  final TextEditingController _otpController = TextEditingController();
  
  // Track which input is focused
  int _focusedIndex = -1;
  // FocusNode for the hidden input
  final FocusNode _otpFocusNode = FocusNode();
  // Add debounce timer for smooth updates
  Timer? _debounceTimer;
  // Track which boxes have been animated as verified
  List<bool> _verifiedBoxes = List.generate(6, (_) => false);

  @override
  void initState() {
    super.initState();
    text = widget.text;
    verificationId = widget.verificationId;
    startTimer();
    
    // Listen to changes in the OTP controller
    _otpController.addListener(_onOtpChanged);
    
    // Auto-focus the OTP input field
    Future.delayed(Duration(milliseconds: 100), () {
      _otpFocusNode.requestFocus();
    });
  }
  
  void _onOtpChanged() {
    // Cancel any previous debounce timer
    _debounceTimer?.cancel();
    
    // Create a new timer for smoother UI updates
    _debounceTimer = Timer(Duration(milliseconds: 10), () {
      if (!mounted) return;
      
    final String otp = _otpController.text;
    
      // Update individual controllers only if needed
    for (int i = 0; i < 6; i++) {
        final String newValue = i < otp.length ? otp[i] : '';
        if (_controllers[i].text != newValue) {
          _controllers[i].text = newValue;
        }
    }
    
    // Set focused index
      setState(() {
    _focusedIndex = otp.length < 6 ? otp.length : 5;
      });
    
    // Auto-verify when all 6 digits are entered
    if (otp.length == 6 && !_isLoading && !_isVerificationSuccessful) {
      _verifyOTP();
    }
    });
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
    _debounceTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    _otpFocusNode.dispose();
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
        // Clear main controller too
        _otpController.clear();
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
      // First, ensure any previous sessions are cleared properly
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Check if the verification ID indicates an admin login attempt
      final bool isAdminAuthentication = verificationId.startsWith('admin-verification-id-');
      
      if (!isAdminAuthentication) {
        // For non-admin login attempts, ensure all admin sessions are cleared
        print('***** NON-ADMIN AUTHENTICATION ATTEMPT - CLEARING ADMIN SESSIONS *****');
        await prefs.remove('admin_session');
        await prefs.remove('admin_user_id');
        await prefs.remove('admin_phone');
      }
      
      // Verify OTP with Firebase
      final result = await _authService.verifyOTP(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      if (result['success']) {
        // Set flag for successful verification
        setState(() {
          _isVerificationSuccessful = true;
          _isLoading = false; // Stop loading first so animation is visible
        });
        
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
        
        // Run the animation first, then proceed with registration/navigation
        await _animateVerificationSuccess();
        
        // Special handling for admin users
        if (result['isAdmin'] == true) {
          print('***** ADMIN LOGIN CONFIRMED - NAVIGATING TO ADMIN DASHBOARD *****');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboard()),
            (route) => false,
          );
          return;
        } else {
          // For non-admin login, ensure no admin session persists
          print('***** NON-ADMIN LOGIN CONFIRMED - ENSURING NO ADMIN SESSION *****');
          await prefs.remove('admin_session');
          await prefs.remove('admin_user_id');
          await prefs.remove('admin_phone');
        }
        
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
    print('***** STARTING USER ROLE NAVIGATION *****');
    
    // Get FirebaseAuth current user
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final String? firebaseUid = firebaseUser?.uid;
    
    print('***** FIREBASE AUTH USER: $firebaseUid *****');
    
    // Check for admin session
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? adminSessionId = prefs.getString('admin_session');
    
    print('***** ADMIN SESSION ID: $adminSessionId *****');
    
    // Check for mismatch between Firebase user and admin session
    if (firebaseUid != null && adminSessionId != null && firebaseUid != adminSessionId) {
      print('***** MISMATCH DETECTED - FIREBASE USER AND ADMIN SESSION DON\'T MATCH *****');
      print('***** CLEARING ADMIN SESSION DATA *****');
      await prefs.remove('admin_session');
      await prefs.remove('admin_user_id');
      await prefs.remove('admin_phone');
    }
    
    // Force role refresh from Firestore
    await _authService.clearRoleCache();
    
    // Get current user role after clearing cache
    final userRole = await _authService.getUserRole();
    print('***** USER ROLE AFTER CACHE CLEAR: $userRole *****');
    
    // If user is admin, navigate directly to admin dashboard
    if (userRole == UserRole.admin) {
      print('***** USER IS ADMIN - NAVIGATING DIRECTLY TO ADMIN DASHBOARD *****');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AdminDashboard()),
        (route) => false,
      );
      return;
    }
    
    // For non-admin users, continue with standard navigation
    try {
      final isProfileComplete = await _authService.isProfileComplete();
      
      // Get the appropriate screen widget based on role
      final navigationScreen = await _authService.getNavigationScreenForUser(
        isProfileComplete: isProfileComplete
      );
      
      // Log what screen we're navigating to
      print('***** NAVIGATING TO: ${navigationScreen.runtimeType} *****');
      
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

  // Add this new method for the verification animation
  Future<void> _animateVerificationSuccess() async {
    print("Starting verification animation");
    // Use a Completer to make this method awaitable
    Completer<void> completer = Completer<void>();
    
    // Animation delay between boxes (100ms for more visibility)
    const animationDelay = 100;
    
    for (int i = 0; i < 6; i++) {
      await Future.delayed(Duration(milliseconds: animationDelay));
      if (mounted) {
        setState(() {
          print("Animating box $i");
          _verifiedBoxes[i] = true;
        });
      }
    }
    
    // Add a final delay to let the user see the completed animation
    await Future.delayed(Duration(milliseconds: 500));
    completer.complete();
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final bool isSmallScreen = screenWidth < 360;
    final basePadding = screenWidth * 0.04;

    final minutes = _start ~/ 60;
    final seconds = _start % 60;
    final formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF223A6A)),
        title: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
            color: Color(0xFF223A6A),
          ),
        ),
        centerTitle: true,
      ),
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
          physics: ClampingScrollPhysics(),
          child: SafeArea(
          child: Column(
            children: [
                // Icon header
                Container(
                  margin: EdgeInsets.only(
                    top: screenHeight * 0.04, 
                    bottom: screenHeight * 0.025
                  ),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.06),
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
                        size: screenWidth * 0.11,
                        color: Color(0xFF3366CC),
                      ),
                    ),
                  ),
                ),
                
                // Content area with white card effect
                Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth * 0.07),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Verification Code',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF223A6A),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey[700],
                          ),
                          children: [
                            TextSpan(text: 'Enter the 6-digit code sent to '),
                            TextSpan(
                              text: widget.phoneNumber,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3366CC),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.045),
                      
                      // Hidden OTP input for actual typing
                      SizedBox(
                        height: 0,
                        child: Opacity(
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
                      ),
                      
                      // Visual OTP boxes (display only)
                      GestureDetector(
                        onTap: () {
                          // Focus the hidden input when boxes are tapped
                          _otpFocusNode.requestFocus();
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double boxWidth = (constraints.maxWidth - (screenWidth * 0.03) * 5) / 6;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (index) {
                                bool isFilled = _controllers[index].text.isNotEmpty;
                                bool isFocused = _focusedIndex == index;
                                
                                return SizedBox(
                                  width: boxWidth,
                                  child: AspectRatio(
                                    aspectRatio: 1.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _verifiedBoxes[index] 
                                            ? Color(0xFFE7F5EE) 
                                            : (isFilled 
                                            ? Color(0xFFE1EDFF) 
                                                : Colors.grey[50]),
                                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                        border: Border.all(
                                          width: 1.5,
                                          color: _verifiedBoxes[index]
                                              ? Color(0xFF2E9066)
                                              : (isFilled 
                                              ? Color(0xFF3366CC) 
                                                  : (isFocused ? Color(0xFF3366CC).withOpacity(0.3) : Colors.grey.withOpacity(0.2))),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: isFilled 
                                          ? FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                _controllers[index].text,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: screenWidth * 0.055,
                                                  color: _verifiedBoxes[index] 
                                                      ? Color(0xFF2E9066)
                                                      : Color(0xFF223A6A),
                                                ),
                                              ),
                                            ) 
                                         : null,
                                      ),
                                    ),
                                  );
                                }),
                            );
                          },
                        ),
                      ),
              
                      SizedBox(height: screenHeight * 0.03),
                      
                      // Error message
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        height: _errorMessage != null ? screenHeight * 0.075 : 0,
                        curve: Curves.easeInOut,
                        child: _errorMessage != null
                          ? Container(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.0125, 
                                horizontal: screenWidth * 0.04
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(screenWidth * 0.015),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: screenWidth * 0.04,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.025),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth * 0.0325,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox.shrink(),
                      ),
                      
                      SizedBox(height: screenHeight * 0.045),
                      
                      // Timer and resend button
                      _start > 0
                        ? Text(
                            "Resend OTP in $formattedTime",
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3366CC),
                            ),
                          )
                        : TextButton(
                            onPressed: _isLoading ? null : _resendOTP,
                            style: TextButton.styleFrom(
                              foregroundColor: Color(0xFF3366CC),
                            ),
                            child: Text(
                              "Resend OTP",
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      
                      SizedBox(height: screenHeight * 0.045),
                      
                      // Confirm OTP button
                      Container(
                        width: double.infinity,
                        height: screenHeight * 0.07,
                        child: _isLoading
                          ? ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF3366CC),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Color(0xFF3366CC).withOpacity(0.7),
                                disabledForegroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: screenWidth * 0.05,
                                    height: screenWidth * 0.05,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Text(
                                    "Verifying...",
                                    style: GoogleFonts.poppins(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _isVerificationSuccessful ? null : _verifyOTP,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF3366CC),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Color(0xFF3366CC).withOpacity(0.7),
                                disabledForegroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                ),
                              ),
                              child: Text(
                                _isVerificationSuccessful 
                                  ? "Verified!"
                                  : "Verify & Proceed",
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
                
                // Security message
                Container(
                  margin: EdgeInsets.only(
                    top: screenHeight * 0.025, 
                    bottom: screenHeight * 0.025
                  ),
                  child: Text(
                    "Your verification is secure and encrypted",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.03,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
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