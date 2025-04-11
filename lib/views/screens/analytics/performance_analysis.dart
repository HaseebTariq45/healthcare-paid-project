import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/utils/navigation_helper.dart';
import 'package:healthcare/views/screens/doctor/availability/doctor_availability_screen.dart';
import 'package:healthcare/views/screens/doctor/hospitals/manage_hospitals_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PerformanceAnalysis extends StatelessWidget {
  const PerformanceAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Performance Analysis",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance summary card
            _buildSummaryCard(),
            
            SizedBox(height: 24),
            
            // Quick Actions
            Text(
              "Manage Your Schedule",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: "Manage Hospitals",
                    subtitle: "Add or remove your hospitals",
                    icon: LucideIcons.building2,
                    backgroundColor: Color(0xFFE8EAF6),
                    iconColor: Color(0xFF3F51B5),
                    onTap: () {
                      // Use cached navigation for better performance
                      NavigationHelper.navigateToCachedScreen(
                        context, 
                        "ManageHospitalsScreen", 
                        () => ManageHospitalsScreen()
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    title: "Set Availability",
                    subtitle: "Update your schedule",
                    icon: LucideIcons.calendar,
                    backgroundColor: Color(0xFFE0F2F1),
                    iconColor: Color(0xFF009688),
                    onTap: () {
                      // Use cached navigation for better performance
                      NavigationHelper.navigateToCachedScreen(
                        context, 
                        "DoctorAvailabilityScreen", 
                        () => DoctorAvailabilityScreen()
                      );
                    },
                  ),
              ),
            ],
          ),
            
            SizedBox(height: 24),
            
            // Performance metrics section
              Text(
              "Performance Metrics",
                style: GoogleFonts.poppins(
                fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            SizedBox(height: 16),
            
            // Metrics cards
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildMetricCard("Appointments", "32", "This Month", Colors.blue.shade100, Colors.blue.shade700),
                _buildMetricCard("Revenue", "₹34,500", "This Month", Colors.green.shade100, Colors.green.shade700),
                _buildMetricCard("Rating", "4.8/5", "From 45 Reviews", Colors.amber.shade100, Colors.amber.shade700),
                _buildMetricCard("Patients", "28", "New This Month", Colors.purple.shade100, Colors.purple.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3949AB),
            Color(0xFF5C6BC0),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3949AB).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Performance Summary",
                  style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
                    color: Colors.white,
              ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem("98%", "On-time Rate"),
              _buildSummaryItem("4.8", "Avg. Rating"),
              _buildSummaryItem("95%", "Retention"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label) {
    return Column(
            children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
    );
  }
  
  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color backgroundColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
                  style: GoogleFonts.poppins(
              fontSize: 22,
                    fontWeight: FontWeight.bold,
              color: textColor,
              ),
          ),
          SizedBox(height: 4),
        Text(
            subtitle,
          style: GoogleFonts.poppins(
              fontSize: 12,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
