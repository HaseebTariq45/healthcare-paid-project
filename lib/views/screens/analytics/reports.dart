import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/utils/navigation_helper.dart';
import 'package:healthcare/views/screens/doctor/availability/doctor_availability_screen.dart';
import 'package:healthcare/views/screens/doctor/hospitals/manage_hospitals_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _selectedTab = 0;
  
  final List<Map<String, String>> reports = const [
    {"title": "Appointment with Dr Asmara", "date": "Dec 30, 2024", "type": "appointment"},
    {"title": "Appointment with Dr Fahad", "date": "Dec 30, 2024", "type": "appointment"},
    {"title": "Last Month Expenditure", "date": "Dec 30, 2024", "type": "finance"},
    {"title": "Patient Growth Analysis", "date": "Dec 20, 2024", "type": "statistics"},
    {"title": "Performance Report", "date": "Dec 15, 2024", "type": "statistics"},
    {"title": "Revenue Analysis Q4", "date": "Dec 10, 2024", "type": "finance"},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Map<String, String>> get filteredReports {
    if (_selectedTab == 0) {
      return reports;
    } else if (_selectedTab == 1) {
      return reports.where((report) => report["type"] == "appointment").toList();
    } else if (_selectedTab == 2) {
      return reports.where((report) => report["type"] == "finance").toList();
    } else {
      return reports.where((report) => report["type"] == "statistics").toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Reports",
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
            Text(
              "Quick Actions",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            
            // Quick actions cards
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    title: "Manage Hospitals",
                    icon: LucideIcons.building2,
                    color: Color(0xFF3F51B5),
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
                  child: _buildQuickActionCard(
                    title: "Update Availability",
                    icon: LucideIcons.calendar,
                    color: Color(0xFF009688),
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
            
            // More implementation here...
          ],
        ),
      ),
    );
  }

  Widget _buildNoReportsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No reports found",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try a different category",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: filteredReports.length,
      itemBuilder: (context, index) {
        final delay = index * 0.1;
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _controller,
            curve: Interval(0.3 + delay, 0.8 + delay > 0.95 ? 0.95 : 0.8 + delay, curve: Curves.easeOut),
          )),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _controller,
              curve: Interval(0.3 + delay, 0.8 + delay > 0.95 ? 0.95 : 0.8 + delay, curve: Curves.easeOut),
            )),
            child: _buildReportCard(
              filteredReports[index]["title"]!,
              filteredReports[index]["date"]!,
              filteredReports[index]["type"]!,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabItem("All", 0),
            _buildTabItem("Appointments", 1),
            _buildTabItem("Finance", 2),
            _buildTabItem("Statistics", 3),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = _selectedTab == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.shade200.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String date, String type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case "appointment":
        icon = Icons.calendar_today_rounded;
        color = Colors.blue;
        break;
      case "finance":
        icon = Icons.attach_money_rounded;
        color = Colors.green;
        break;
      case "statistics":
        icon = Icons.bar_chart_rounded;
        color = Colors.purple;
        break;
      default:
        icon = Icons.description_outlined;
        color = Colors.blue;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // View report details
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.download_rounded,
                        color: Colors.blue.shade400,
                        size: 22,
                      ),
                      onPressed: () {
                        // Download report
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade500,
                      ),
                      onPressed: () {
                        // Show options
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
