import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/analytics/financial_analysis.dart';
import 'package:healthcare/views/screens/analytics/patients.dart';
import 'package:healthcare/views/screens/analytics/performance_analysis.dart';
import 'package:healthcare/views/screens/analytics/reports.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:healthcare/utils/navigation_helper.dart';

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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom app bar with gradient
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    spreadRadius: 1,
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    "Analytics Dashboard",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(64, 124, 226, 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.activity,
                      color: Color.fromRGBO(64, 124, 226, 1),
                    ),
                  ),
                ],
              ),
            ),
            
            // Summary stats row
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(64, 124, 226, 1),
                      Color.fromRGBO(84, 144, 246, 1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(64, 124, 226, 0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem("121", "Patients"),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildSummaryItem("86", "Appointments"),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildSummaryItem("\$4.5k", "Earnings"),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Analytics Categories",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            // Analytics cards
            Expanded(
        child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.05,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
            children: [
              _buildAnalyticsCard(
                      icon: LucideIcons.trendingUp,
                title: "Performance Analysis",
                      description: "Track your growth metrics",
                      bgColor: Color(0xFFE3F2FD),
                      iconColor: Color(0xFF2196F3),
                onPressed: () {
                  NavigationHelper.navigateWithBottomBar(context, PerformanceAnalysis());
                },
              ),
              _buildAnalyticsCard(
                      icon: LucideIcons.activity,
                title: "Financial Analytics",
                      description: "Revenue & expense reports",
                      bgColor: Color(0xFFE1F5FE),
                      iconColor: Color(0xFF03A9F4),
                onPressed: () {
                  NavigationHelper.navigateWithBottomBar(context, FinancialAnalyticsScreen());
                },
              ),
              _buildAnalyticsCard(
                      icon: LucideIcons.users,
                title: "Patients",
                      description: "Manage patient data",
                      bgColor: Color(0xFFE8F5E9),
                      iconColor: Color(0xFF4CAF50),
                onPressed: () {
                  NavigationHelper.navigateWithBottomBar(context, PatientsScreen());
                },
              ),
              _buildAnalyticsCard(
                      icon: LucideIcons.clipboardList,
                title: "Reports",
                      description: "View all reports",
                      bgColor: Color(0xFFFFF3E0),
                      iconColor: Color(0xFFFF9800),
                onPressed: () {
                  NavigationHelper.navigateWithBottomBar(context, ReportsScreen());
                },
              ),
            ],
          ),
        ),
      ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard({
    required IconData icon,
    required String title,
    required String description,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                size: 22,
                color: iconColor,
              ),
            ),
            Spacer(),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 3),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black54,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
