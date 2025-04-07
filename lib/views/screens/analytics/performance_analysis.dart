import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';

class PerformanceAnalysis extends StatelessWidget {
  const PerformanceAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(
        isBackButtonVisible: true,
        text: "Performance Analysis",
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Appointments",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Image.asset('assets/images/appointments_graph.png'),
              const SizedBox(height: 20),
              Image.asset('assets/images/cancelled_appointments.png'),
              const SizedBox(height: 30),
              _buildRatingsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingsCard(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.82,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Color.fromRGBO(64, 124, 226, 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                "Ratings",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            "4.7",
            style: GoogleFonts.poppins(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
