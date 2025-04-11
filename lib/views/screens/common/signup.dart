import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/components/signup.dart';
import 'package:healthcare/views/screens/common/OTPVerification.dart';
import 'package:healthcare/views/screens/common/signin.dart';
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
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
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
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Check if this phone number already exists in our database
      final userCheck = await _authService.getUserByPhoneNumber(formattedPhoneNumber);
      
      if (userCheck.containsKey('error')) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error checking user account: ${userCheck['error']}';
        });
        return;
      }
      
      if (userCheck['exists'] == true) {
        // Phone number already exists
        setState(() {
          _isLoading = false;
        });
        
        // Get user role
        final userRole = userCheck['userRole'] as UserRole;
        String userRoleDisplay = 'account';
        switch (userRole) {
          case UserRole.doctor: userRoleDisplay = 'Doctor account'; break;
          case UserRole.patient: userRoleDisplay = 'Patient account'; break;
          case UserRole.ladyHealthWorker: userRoleDisplay = 'Lady Health Worker account'; break;
          case UserRole.admin: userRoleDisplay = 'Admin account'; break;
          default: userRoleDisplay = 'account'; break;
        }
        
        // Show a dialog to inform the user
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Account Already Exists'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This phone number is already registered as a $userRoleDisplay.'),
                SizedBox(height: 8),
                Text('Would you like to sign in instead?'),
              ],
            ),
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
      
      // Phone number doesn't exist, proceed with OTP sending
      final result = await _authService.sendOTP(
        phoneNumber: formattedPhoneNumber,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success']) {
        // Navigate to OTP verification screen with verification ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              text: "Sign Up as a $type",
              phoneNumber: formattedPhoneNumber,
              verificationId: result['verificationId'],
              fullName: _nameController.text.trim(),
              userType: type,
            ),
          ),
        );
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
                        'Sign up as a $type',
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
