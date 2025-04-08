import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/common/signin.dart';
import 'package:healthcare/views/screens/onboarding/signupoptions.dart';

class Onboarding3 extends StatelessWidget {
  const Onboarding3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarOnboarding(text: '', isBackButtonVisible: false),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 76),
              child: Logo(text: "HealthCare"),
            ),
            const SizedBox(height: 76),
            Column(
              children: [
                Text(
                  "Let's get started",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                NavButtons(destination: SignIN(), text: "Sign In"),
                const SizedBox(height: 16),
                NavButtons(destination: SignUpOptions(), text: "Sign Up"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
