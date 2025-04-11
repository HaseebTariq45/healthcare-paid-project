import 'package:flutter/material.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/onboarding/onboarding_3.dart';

class Onboarding2 extends StatelessWidget {
  const Onboarding2 ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBarOnboarding(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NavSkipText(),
            const SizedBox(height: 20),
            OboardingImage(
              imagepath: "assets/images/male-doctor.png"
            ),
            const SizedBox(
              height: 20
            ),
            OnboardingText(
              text: "Get advice only from a doctor you believe in.",
            ),
            OnboardingNavigation(
              pageno: 2,
              destination: Onboarding3(),
            ),
          ],
        ),
      ),
    );
  }
}