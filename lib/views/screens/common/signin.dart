import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/components/signup.dart';
import 'package:healthcare/views/screens/common/otpentry.dart';
import 'package:healthcare/views/screens/common/signup.dart';

class SignIN extends StatefulWidget {
  const SignIN({super.key});

  @override
  State<SignIN> createState() => _SignINState();
}

class _SignINState extends State<SignIN> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _sendOTP() async {
    // Validate phone number
    String phoneNumber = _phoneController.text.trim();
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
      // Check if user exists
      bool userExists = await _authService.checkUserExists(phoneNumber);
      
      if (!userExists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No account found with this phone number';
        });
        return;
      }
      
      // Send OTP
      await _authService.sendOTP(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) {
          // Auto verification completed
          // This usually happens on Android devices
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
                text: "Welcome Back",
                phoneNumber: phoneNumber,
                isSignUp: false,
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
              child: Logo(text: 'Welcome to Healthcare'),
            ),
            Container(
              margin: const EdgeInsets.only(top: 40),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: DataInputFeild(
                  controller: _phoneController,
                  hinttext: "+92 300 0000000",
                  icon: Icons.phone,
                  inputType: TextInputType.phone,
                ),
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
            SizedBox(
              height: 20,
            ),
            InkWell(
              onTap: _isLoading ? null : _sendOTP,
              child: ProceedButton(
                isEnabled: !_isLoading,
                text: _isLoading ? 'Sending...' : 'Send OTP',
              ),
            ),
            SizedBox(height: 30),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUp(
                    type: "Patient",
                  )),
                );
              },
              child: Text(
                'Don\'t have an account? Sign Up',
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
