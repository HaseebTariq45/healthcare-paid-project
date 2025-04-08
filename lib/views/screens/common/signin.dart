import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/components/signup.dart';
import 'package:healthcare/views/screens/common/OTPVerification.dart';
import 'package:healthcare/views/screens/common/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SignIN extends StatefulWidget {
  const SignIN({super.key});

  @override
  _SignINState createState() => _SignINState();
}

class _SignINState extends State<SignIN> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  void _sendOTP() async {
    String phoneNumber = _phoneController.text.trim();
    
    // Validate phone number format
    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your phone number';
      });
      return;
    }
    
    // Add country code if not present
    if (!phoneNumber.startsWith('+')) {
      // Assuming Pakistan as default country code
      phoneNumber = '+92${phoneNumber.startsWith('0') ? phoneNumber.substring(1) : phoneNumber}';
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendOTP(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verification completed (on Android devices)
          _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.message ?? 'Verification failed. Please try again.';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
          });
          
          final otpScreen = OTPVerificationScreen(
            text: "Welcome Back",
            phoneNumber: phoneNumber,
            verificationId: verificationId,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => otpScreen,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
          setState(() {
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error sending OTP. Please try again.';
      });
    }
  }

  void _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      await _authService.verifyOTP(
        verificationId: '', // Not needed for auto-verification
        smsCode: '', // Not needed for auto-verification
      );
      
      // Navigate based on user role and profile completion
      _navigateBasedOnUserRole();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error signing in. Please try again.';
      });
    }
  }

  void _navigateBasedOnUserRole() async {
    // Check if user exists and get their role
    final userRole = await _authService.getUserRole();
    final isProfileComplete = await _authService.isProfileComplete();
    
    // Navigate to appropriate screen based on role and profile completion
    // This will be implemented in the next step
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
                        'Login to your account',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Phone Number Input Card
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
                        child: TextFormField(
                          controller: _phoneController,
                          onTapOutside: (event) => FocusScope.of(context).unfocus(),
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.blue.shade50.withOpacity(0.3),
                            hintText: "+92 300 0000000",
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.5,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100.withOpacity(0.5),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Icon(LucideIcons.phone, color: const Color(0xFF3366CC), size: 24),
                            ),
                            contentPadding: const EdgeInsets.all(0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.blue.shade200.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: const Color(0xFF3366CC), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red,
                            ),
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
