import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page1.dart';

class DevMenuScreen extends StatelessWidget {
  const DevMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Development Menu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Profile Screens',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileButton(
              context,
              'Patient Profile',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage1(userRole: UserRole.patient),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildProfileButton(
              context,
              'Doctor Profile',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage1(userRole: UserRole.doctor),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildProfileButton(
              context,
              'Lady Health Worker Profile',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage1(userRole: UserRole.ladyHealthWorker),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context, String title, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
} 