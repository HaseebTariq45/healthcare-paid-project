import 'package:flutter/material.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/onboarding/onboarding_2.dart';

class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

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
            OboardingImage(imagepath: "assets/images/lady-doctor.png"),
            const SizedBox(height: 20),
            OnboardingText(
              text: "Find a lot of specialist doctors in one place",
            ),
            OnboardingNavigation(pageno: 1, destination: Onboarding2()),
          ],
        ),
      ),
    );
  }
}
