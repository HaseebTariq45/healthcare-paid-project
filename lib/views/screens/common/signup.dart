import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/components/signup.dart';
import 'package:healthcare/views/screens/common/otpentry.dart';
import 'package:healthcare/views/screens/common/signin.dart';

class SignUp extends StatefulWidget {
  final String type;
  const SignUp({super.key, required this.type});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  late String type;
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    type = widget.type;
  }

  bool privacyAccepted = false;

  Future<void> _sendOTP() async {
    // Validate inputs
    String name = _nameController.text.trim();
    String phoneNumber = _phoneController.text.trim();
    
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return;
    }
    
    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your phone number';
      });
      return;
    }
    
    // Format phone number if needed
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+$phoneNumber';
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Check if user already exists
      bool userExists = await _authService.checkUserExists(phoneNumber);
      
      if (userExists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An account with this phone number already exists';
        });
        return;
      }
      
      // Send OTP
      await _authService.sendOTP(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) {
          // Auto verification completed
          setState(() {
            _isLoading = false;
          });
        },
        verificationFailed: (exception) {
          // Handle verification failure
          setState(() {
            _isLoading = false;
            _errorMessage = exception.message ?? 'Verification failed';
          });
        },
        codeSent: (verificationId, resendToken) {
          // Navigate to OTP screen
          setState(() {
            _isLoading = false;
          });
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(
                text: "Sign Up as a $type",
                phoneNumber: phoneNumber,
                isSignUp: true,
                userName: name,
                userType: type,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          // Auto retrieval timeout
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
      print('Error sending OTP: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: ''),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        reverse: true,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Logo(text: 'Welcome to Healthcare as a $type'),
            ),
            Container(
              margin: const EdgeInsets.only(top: 50),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: DataInputFeild(
                      controller: _nameController,
                      hinttext: "Name",
                      icon: Icons.person_3_outlined,
                      inputType: TextInputType.text,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: DataInputFeild(
                      controller: _phoneController,
                      hinttext: "+92 300 0000000",
                      icon: Icons.phone,
                      inputType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            SizedBox(height: 40),
            PrivacyPolicy(
              isselected: privacyAccepted,
              onChanged: (newValue) {
                setState(() {
                  privacyAccepted = newValue;
                });
              },
            ),
            SizedBox(height: 20),
            InkWell(
              onTap:
                  privacyAccepted && !_isLoading
                      ? _sendOTP
                      : null,
              child: ProceedButton(
                isEnabled: privacyAccepted && !_isLoading,
                text: _isLoading ? 'Sending...' : 'Send OTP',
              ),
            ),
            SizedBox(height: 30),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignIN()),
                );
              },
              child: Text(
                'Already have an account? Sign In',
                style: GoogleFonts.poppins(
                  decoration: TextDecoration.underline,
                  color: Color.fromRGBO(0, 0, 0, 0.6),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
