import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/components/signup.dart';
import 'package:healthcare/views/screens/common/OTPVerification.dart';
import 'package:healthcare/views/screens/common/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SignUp extends StatefulWidget {
  final String type;
  const SignUp({super.key, required this.type});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  late String type;
  bool privacyAccepted = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _professionalIdController = TextEditingController();
  
  // Auth service
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    type = widget.type;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _professionalIdController.dispose();
    super.dispose();
  }
  
  void _sendOTP() async {
    // Validate inputs
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your full name';
      });
      return;
    }
    
    String phoneNumber = _phoneController.text.trim();
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
    
    // Validate professional ID for doctors and LHWs
    if ((type == "Doctor" || type == "Lady Health Worker") && 
        _professionalIdController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your professional ID';
      });
      return;
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
          // This is rare in signup flow so we'll just let the user enter the OTP manually
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
          
          // Navigate to OTP screen
          final otpScreen = OTPVerificationScreen(
            text: "Sign Up as a $type",
            phoneNumber: phoneNumber,
            verificationId: verificationId,
            fullName: _nameController.text.trim(),
            professionalId: (type == "Doctor" || type == "Lady Health Worker") ? 
                _professionalIdController.text.trim() : null,
            userType: type,
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
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3366CC),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign up as a $type',
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
                        'Personal Information',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Full Name Field
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: _nameController,
                          onTapOutside: (event) => FocusScope.of(context).unfocus(),
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.blue.shade50.withOpacity(0.3),
                            hintText: "Full Name",
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
                              child: Icon(LucideIcons.user, color: const Color(0xFF3366CC), size: 24),
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
                      
                      // Phone Number Field
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
                      
                      // Professional ID Field (for doctors and LHWs)
                      if (type == "Doctor" || type == "Lady Health Worker")
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TextFormField(
                            controller: _professionalIdController,
                            onTapOutside: (event) => FocusScope.of(context).unfocus(),
                            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.blue.shade50.withOpacity(0.3),
                              hintText: "Professional ID",
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
                                child: Icon(LucideIcons.badgeCheck, color: const Color(0xFF3366CC), size: 24),
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
                    ],
                  ),
                ),
                
                // Privacy Policy
                PrivacyPolicy(
                  isselected: privacyAccepted,
                  onChanged: (newValue) {
                    setState(() {
                      privacyAccepted = newValue;
                    });
                  },
                ),
                
                // Send OTP Button
                Container(
                  margin: EdgeInsets.symmetric(vertical: 24),
                  child: InkWell(
                    onTap: !privacyAccepted || _isLoading ? null : _sendOTP,
                    child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF3366CC),
                          ),
                        )
                      : ProceedButton(
                          isEnabled: privacyAccepted,
                          text: 'Send OTP',
                        ),
                  ),
                ),
                
                // Sign In Link
                Container(
                  margin: EdgeInsets.only(bottom: 40),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignIN()),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sign In',
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
