import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/components/signup.dart';
import 'package:healthcare/views/screens/common/otpentry.dart';
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

  @override
  void initState() {
    super.initState();
    type = widget.type;
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
                        child: DataInputFeild(
                          hinttext: "+92 300 0000000",
                          icon: LucideIcons.phone,
                          inputType: TextInputType.phone,
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
                    onTap: privacyAccepted
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OTPScreen(text: "Sign Up as a $type"),
                              ),
                            );
                          }
                        : null,
                    child: ProceedButton(
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
