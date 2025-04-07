import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    type = widget.type;
  }

  bool privacyAccepted = false;

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
                      hinttext: "Name",
                      icon: Icons.person_3_outlined,
                      inputType: TextInputType.text,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: DataInputFeild(
                      hinttext: "+92 300 0000000",
                      icon: Icons.phone,
                      inputType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 51),
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
                  privacyAccepted
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
