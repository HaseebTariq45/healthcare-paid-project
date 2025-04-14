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

class _SignINState extends State<SignIN> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.1, 0.8, curve: Curves.easeOut),
      ),
    );
    
    // Start animation after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
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
      
      // Check if this is an admin phone number
      final isAdmin = await _authService.isAdminPhoneNumber(formattedPhoneNumber);
      if (isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin verification required'),
            backgroundColor: Colors.blue,
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
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEEF5FF),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative elements
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0x20477CDB),
                        Color(0x05477CDB),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0x154F80E1),
                        Color(0x054F80E1),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Medical icons
              Positioned(
                top: size.height * 0.18,
                left: size.width * 0.1,
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset('assets/images/capsules.png', width: 32),
                ),
              ),
              Positioned(
                top: size.height * 0.25,
                right: size.width * 0.15,
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset('assets/images/tablets.png', width: 32),
                ),
              ),
              Positioned(
                bottom: size.height * 0.1,
                right: size.width * 0.2,
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset('assets/images/bandage.png', width: 32),
                ),
              ),
              
              // Main content
              SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.topLeft,
                          child: _buildBackButton(),
                        ),
                        
                        // Logo and header
                        SizedBox(height: 30),
                        _buildHeader(),
                        SizedBox(height: 40),
                        
                        // Sign in form
                        _buildSignInForm(),
                        SizedBox(height: 40),
                        
                        // Sign in button
                        _buildSignInButton(),
                        SizedBox(height: 24),
                        
                        // Sign up link
                        _buildSignUpLink(),
                        SizedBox(height: 30),
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
  
  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: Color(0xFF3366CC),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 110,
          height: 110,
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x20477CDB),
                blurRadius: 25,
                spreadRadius: 3,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Image.asset(
            "assets/images/logo.png",
          ),
        ),
        SizedBox(height: 30),
        
        // Title and subtitle
        Text(
          "Welcome Back",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF223A6A),
          ),
        ),
        SizedBox(height: 12),
        Text(
          "Sign in to continue to your account",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSignInForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phone label
          Row(
            children: [
              Icon(
                LucideIcons.phone,
                size: 20,
                color: Color(0xFF3366CC),
              ),
              SizedBox(width: 10),
              Text(
                "Phone Number",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF223A6A),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Phone input
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFFE1EDFF),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _phoneController,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Color(0xFF223A6A),
              ),
              decoration: InputDecoration(
                hintText: "Enter your phone number",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "+92",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3366CC),
                    ),
                  ),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.phone,
            ),
          ),
          SizedBox(height: 12),
          
          // Helper text
          Row(
            children: [
              Icon(
                LucideIcons.info,
                size: 14,
                color: Colors.grey.shade600,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "We'll send a verification code to this number",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          
          // Error message if any
          if (_errorMessage != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
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
          ],
        ],
      ),
    );
  }
  
  Widget _buildSignInButton() {
    return InkWell(
      onTap: _isLoading ? null : _sendOTP,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3366CC), Color(0xFF4F80E1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF3366CC).withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isLoading 
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Send OTP",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
  
  Widget _buildSignUpLink() {
    return GestureDetector(
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
            "Don't have an account? ",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            "Sign Up",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3366CC),
            ),
          ),
        ],
      ),
    );
  }
}
