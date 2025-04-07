import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/analytics/financial_analysis.dart';
import 'package:healthcare/views/screens/analytics/patients.dart';
import 'package:healthcare/views/screens/analytics/performance_analysis.dart';
import 'package:healthcare/views/screens/analytics/reports.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarOnboarding(isBackButtonVisible: false, text: "Analytics"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildAnalyticsCard(
                icon: Icons.show_chart_rounded,
                title: "Performance Analysis",
                color: Color.fromRGBO(167, 199, 231, 1),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PerformanceAnalysis(),
                    ),
                  );
                },
              ),
              _buildAnalyticsCard(
                icon: Icons.bar_chart_rounded,
                title: "Financial Analytics",
                color: Color.fromRGBO(49, 93, 168, 0.744),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FinancialAnalyticsScreen(),
                    ),
                  );
                },
              ),
              _buildAnalyticsCard(
                icon: Icons.group_rounded,
                title: "Patients",
                color: Color.fromRGBO(162, 217, 160, 1),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PatientsScreen()),
                  );
                },
              ),
              _buildAnalyticsCard(
                icon: Icons.description_rounded,
                title: "Reports",
                color: Color.fromRGBO(189, 195, 199, 1),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReportsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required IconData icon,
    required String title,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        height: 140,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween, // Ensures spacing between text and arrow
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left side content (icon and text)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: Colors.black),
                SizedBox(height: 8), // Spacing between icon and text
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            // Right side (arrow icon)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.arrow_forward_ios, size: 28, color: Colors.black),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
