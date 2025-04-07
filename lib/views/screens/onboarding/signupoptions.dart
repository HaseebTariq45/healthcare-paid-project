import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/common/signup.dart';
import 'package:healthcare/views/screens/patient/bottom_navigation_patient.dart';

class SignUpOptions extends StatelessWidget {
  const SignUpOptions ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(
        text: '',
        isBackButtonVisible: true,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          // mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 76),
              child: Logo(
                text: "HealthCare",
              ),
            ),
            const SizedBox(height: 76),
            Text(
              "Sign Up",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            NavButtons(
              destination: BottomNavigationBarPatientScreen(profileStatus: "incomplete"),
              text: "Patient",
            ),
            const SizedBox(height: 16),
            NavButtons(
              destination: SignUp(
                type: "Doctor",
              ),
              text: "Doctor",
            ),
            const SizedBox(height: 16),
            NavButtons(
              destination: SignUp(
                type: "Lady Health Worker",
              ),
              text: "Lady Health Worker",
            ),
          ],
        ),
      ),
    );
  }
}
