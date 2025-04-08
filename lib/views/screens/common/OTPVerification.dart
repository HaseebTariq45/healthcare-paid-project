import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/components/signup.dart';
import 'package:healthcare/views/screens/dashboard/home.dart';
import 'package:healthcare/views/screens/bottom_navigation_bar.dart';
import 'package:healthcare/views/screens/patient/bottom_navigation_patient.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page1.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthcare/utils/navigation_helper.dart';

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

  Timer? _timer;
  int _start = 60;

  // Create a controller for each of the 6 OTP digits
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    text = widget.text;
    verificationId = widget.verificationId;
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

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    // Get OTP code from text fields
    final otp = _controllers.map((c) => c.text).join();
    
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
      final credential = await _authService.verifyOTP(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      // Check if this is a new user (from sign up) or existing user (login)
      if (widget.userType != null && widget.fullName != null) {
        // This is a new user signing up
        await _registerNewUser(credential.user!.uid);
      }
      
      // Navigate based on user role and profile completion
      await _navigateBasedOnUserRole();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Invalid OTP. Please try again.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error verifying OTP. Please try again.';
      });
    }
  }

  Future<void> _registerNewUser(String uid) async {
    if (widget.userType == null || widget.fullName == null) return;
    
    // Convert string user type to enum
    UserRole role;
    switch (widget.userType) {
      case 'Patient':
        role = UserRole.patient;
        break;
      case 'Doctor':
        role = UserRole.doctor;
        break;
      case 'Lady Health Worker':
        role = UserRole.ladyHealthWorker;
        break;
      default:
        role = UserRole.patient;
    }
    
    // Register user in Firestore
    await _authService.registerUser(
      uid: uid,
      fullName: widget.fullName!,
      phoneNumber: widget.phoneNumber,
      role: role,
    );
  }

  Future<void> _navigateBasedOnUserRole() async {
    final userRole = await _authService.getUserRole();
    final isProfileComplete = await _authService.isProfileComplete();
    
    setState(() {
      _isLoading = false;
    });
    
    switch (userRole) {
      case UserRole.patient:
        if (!isProfileComplete) {
          // Navigate to patient profile completion
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage1(userRole: UserRole.patient),
            ),
            (route) => false,
          );
        } else {
          // Navigate to patient dashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => BottomNavigationBarPatientScreen(
                key: BottomNavigationBarPatientScreen.navigatorKey,
                profileStatus: "complete"
              ),
            ),
            (route) => false,
          );
        }
        break;
        
      case UserRole.doctor:
      case UserRole.ladyHealthWorker:
        if (!isProfileComplete) {
          // Navigate to doctor/LHW profile completion
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage1(userRole: userRole),
            ),
            (route) => false,
          );
        } else {
          // Navigate to doctor/LHW dashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => BottomNavigationBarScreen(
                key: BottomNavigationBarScreen.navigatorKey,
                profileStatus: "complete"
              ),
            ),
            (route) => false,
          );
        }
        break;
        
      default:
        // Unknown user role - should not happen if registration was successful
        setState(() {
          _errorMessage = 'Unknown user type. Please try again.';
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                'Enter the OTP sent to ${widget.phoneNumber}',
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
                        
                        // Auto-submit when all digits are entered
                        if (index == 5 && value.isNotEmpty) {
                          _verifyOTP();
                        }
                      },
                    ),
                  );
                }),
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
                  onPressed: () {
                    debugPrint("Resend OTP pressed");
                    // Optionally clear OTP fields
                    setState(() {
                      for (final controller in _controllers) {
                        controller.clear();
                      }
                    });
                    // Restart the timer after resending OTP
                    startTimer();
                  },
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
                onTap: _isLoading ? null : _verifyOTP,
                child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFF3366CC),
                      ),
                    )
                  : ProceedButton(isEnabled: true, text: "Confirm OTP"),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 