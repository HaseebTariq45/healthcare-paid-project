import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/auth_service.dart';
// Import your custom onboarding AppBar, if needed
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/components/signup.dart';
import 'package:healthcare/views/screens/dashboard/home.dart';
import 'package:healthcare/views/screens/patient/dashboard/home.dart' as PatientHome;

class OTPScreen extends StatefulWidget {
  final String text;
  final String phoneNumber;
  final bool isSignUp;
  final String? userName;
  final String? userType;
  
  const OTPScreen({
    Key? key, 
    required this.text, 
    required this.phoneNumber,
    this.isSignUp = false,
    this.userName,
    this.userType,
  }) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  late String text;
  late String phoneNumber;
  late bool isSignUp;
  final AuthService _authService = AuthService();

  Timer? _timer;
  int _start = 60;
  bool _isVerifying = false;
  String? _errorMessage;

  // Create a controller for each of the 6 OTP digits
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    text = widget.text;
    phoneNumber = widget.phoneNumber;
    isSignUp = widget.isSignUp;
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

  Future<void> _resendOTP() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    
    try {
      await _authService.sendOTP(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) {
          setState(() {
            _isVerifying = false;
          });
        },
        verificationFailed: (exception) {
          setState(() {
            _isVerifying = false;
            _errorMessage = exception.message ?? 'Verification failed';
          });
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _isVerifying = false;
          });
          
          // Clear OTP fields
          for (final controller in _controllers) {
            controller.clear();
          }
          
          // Restart the timer
          startTimer();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          // Auto retrieval timeout
        },
      );
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Failed to resend OTP. Please try again.';
      });
      print('Error resending OTP: $e');
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _controllers.map((c) => c.text).join();
    
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }
    
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    
    try {
      final userCredential = await _authService.verifyOTP(otp);
      
      if (userCredential != null) {
        if (isSignUp && widget.userName != null && widget.userType != null) {
          // Register new user
          await _authService.registerUser(
            phoneNumber: phoneNumber,
            name: widget.userName!,
            type: widget.userType!,
          );
        }
        
        // Navigate to appropriate screen
        if (mounted) {
          // For demo purposes, navigate to doctor home if type is Doctor
          // otherwise navigate to patient home
          if (widget.userType == 'Doctor') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  profileStatus: "complete",
                ),
              ),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => PatientHome.PatientHomeScreen(),
              ),
              (route) => false,
            );
          }
        }
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Invalid OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Verification failed. Please try again.';
      });
      print('Error verifying OTP: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                'Enter the OTP sent to $phoneNumber',
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
                        // If all fields are filled, verify OTP automatically
                        if (index == 5 && value.isNotEmpty) {
                          bool allFilled = true;
                          for (var controller in _controllers) {
                            if (controller.text.isEmpty) {
                              allFilled = false;
                              break;
                            }
                          }
                          if (allFilled) {
                            _verifyOTP();
                          }
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
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
                  onPressed: _isVerifying ? null : _resendOTP,
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
                onTap: _isVerifying ? null : _verifyOTP,
                child: ProceedButton(
                  isEnabled: !_isVerifying,
                  text: _isVerifying ? "Verifying..." : "Confirm OTP",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
