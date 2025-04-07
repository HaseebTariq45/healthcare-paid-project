import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/components/signup.dart';
import 'package:healthcare/views/screens/common/otpentry.dart';
import 'package:healthcare/views/screens/common/signup.dart';

class SignIN extends StatelessWidget {
  const SignIN({super.key});

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
                padding: const EdgeInsets.only(bottom: 20),
                child: DataInputFeild(
                  hinttext: "+92 300 0000000",
                  icon: Icons.phone,
                  inputType: TextInputType.phone,
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OTPScreen(text: "Welcome Back"),
                ),
              ),
              child: ProceedButton(
                isEnabled: true,
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
                child: TextButton(
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
              ),
          ],
        ),
      ),
    );
  }
}
