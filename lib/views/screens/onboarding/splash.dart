import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/onboarding/onboarding_1.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(
      Duration(seconds: 2),
      () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Onboarding1()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(159, 179, 255, 1),
      body: Stack(
        children: [
          Positioned(
            top: 60,
            right: 20,
            child: Image.asset(
              "assets/images/capsules.png",
              opacity: const AlwaysStoppedAnimation(0.7),
            ),
          ),
          Positioned(
            top: 100,
            left: -10,
            child: Image.asset(
              "assets/images/tablets.png",
              scale: 0.8,
              opacity: const AlwaysStoppedAnimation(0.7),
            ),
          ),
          Positioned(
            bottom: 50,
            right: 0,
            child: Image.asset(
              "assets/images/bandage.png",
              scale: 0.9,
              opacity: const AlwaysStoppedAnimation(0.7),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            child: Image.asset(
              "assets/images/sethoscope.png",
              opacity: const AlwaysStoppedAnimation(0.6),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset("assets/images/logo.png"),
                const SizedBox(height: 20),
                Text(
                  "Healthcare",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
