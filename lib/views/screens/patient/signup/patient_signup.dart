import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/components/signup.dart';
import 'package:healthcare/views/screens/bottom_navigation_bar.dart';
import 'package:healthcare/views/screens/common/OTPVerification.dart';
import 'package:healthcare/views/screens/common/signin.dart';
import 'package:healthcare/views/screens/patient/bottom_navigation_patient.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page1.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PatientSignUp extends StatefulWidget {
  const PatientSignUp({super.key});

  @override
  State<PatientSignUp> createState() => _PatientSignUpState();
}

class _PatientSignUpState extends State<PatientSignUp> {
  bool privacyAccepted = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  
  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  // Send OTP to the provided phone number
  Future<void> _sendOTP() async {
    // Validate inputs
    if (_nameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your full name';
      });
      return;
    }
    
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
    
    // Check for test numbers and bypass OTP for faster testing
    if (formattedPhoneNumber == "+923038775385" || formattedPhoneNumber == "+923128344065") {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Test Account Selection'),
          content: Text('This phone number is already registered in the test system. Would you like to directly sign in instead?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                
                // Redirect to sign in screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignIN()),
                );
              },
              child: Text('Go to Sign In'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        ),
      );
      return;
    }
        
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Actually send OTP using Firebase
      final result = await _authService.sendOTP(
        phoneNumber: formattedPhoneNumber,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success']) {
        // Check if this is test mode
        bool isTestMode = result['isTestMode'] == true;
        
        if (isTestMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Test mode: Use verification code 123456'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Navigate to OTP verification screen with real verification ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              text: "Sign Up as a Patient",
              phoneNumber: formattedPhoneNumber,
              verificationId: result['verificationId'],
              fullName: _nameController.text.trim(),
              userType: "Patient",
            ),
          ),
        );
      } else {
        // Check if this is a billing issue
        if (result['billingIssue'] == true) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Firebase Configuration Issue'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Firebase Phone Authentication requires billing to be enabled in the Firebase console.'),
                  SizedBox(height: 8),
                  Text('For testing, you can use:'),
                  Text('Phone: +923038775385 (Doctor)'),
                  Text('Phone: +923128344065 (Patient)'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    
                    // Auto-fill the doctor test number
                    _phoneController.text = '03038775385';
                  },
                  child: Text('Use Doctor'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    
                    // Auto-fill the patient test number
                    _phoneController.text = '03128344065';
                  },
                  child: Text('Use Patient'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
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
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 20),
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
                        'Sign up as a Patient',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
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
                        'Full Name',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: "Enter your full name",
                          prefixIcon: Icon(LucideIcons.user),
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
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 20),
                      
                      Text(
                        'Phone Number',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
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
                
                PrivacyPolicy(
                  isselected: privacyAccepted,
                  onChanged: (newValue) {
                    setState(() {
                      privacyAccepted = newValue;
                    });
                  },
                ),
                
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  child: InkWell(
                    onTap: privacyAccepted && !_isLoading
                        ? _sendOTP
                        : null,
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
                
                Container(
                  margin: const EdgeInsets.only(bottom: 40),
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

// OTP Verification Screen for Patient
class PatientOTPVerification extends StatefulWidget {
  final String phoneNumber;
  
  const PatientOTPVerification({super.key, required this.phoneNumber});

  @override
  State<PatientOTPVerification> createState() => _PatientOTPVerificationState();
}

class _PatientOTPVerificationState extends State<PatientOTPVerification> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
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
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 20),
                  child: Column(
                    children: [
                      Center(child: Image.asset("assets/images/logo.png", height: 100)),
                      const SizedBox(height: 16),
                      Text(
                        'Verify Your Number',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3366CC),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the 6-digit code sent to',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        widget.phoneNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (index) => SizedBox(
                        width: 50,
                        height: 65,
                        child: TextField(
                          controller: _otpControllers[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: const Color(0xFF3366CC), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              FocusScope.of(context).nextFocus();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Didn\'t receive the code?',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Resend',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3366CC),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  child: InkWell(
                    onTap: () {
                      // Navigate directly to profile completion screen
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CompleteProfilePatient1Screen(),
                        ),
                        (route) => false, // This clears the navigation stack
                      );
                    },
                    child: ProceedButton(
                      isEnabled: true,
                      text: 'Verify & Continue',
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