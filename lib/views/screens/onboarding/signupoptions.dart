import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/common/signup.dart';
import 'package:healthcare/views/screens/patient/signup/patient_signup.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SignUpOptions extends StatelessWidget {
  const SignUpOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarOnboarding(text: '', isBackButtonVisible: true),
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
                        'Choose your account type',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildUserTypeCard(
                  context,
                  "Patient",
                  "Book appointments with doctors",
                  LucideIcons.user,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientSignUp(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildUserTypeCard(
                  context,
                  "Doctor",
                  "Provide medical services",
                  LucideIcons.stethoscope,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignUp(type: "Doctor"),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildUserTypeCard(
                  context,
                  "Lady Health Worker",
                  "Provide community health services",
                  LucideIcons.heart,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignUp(type: "Lady Health Worker"),
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

  Widget _buildUserTypeCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
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
          border: Border.all(
            color: const Color(0xFF3366CC).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3366CC),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: Color(0xFF3366CC),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
