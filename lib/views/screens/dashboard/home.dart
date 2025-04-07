import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/appointment/all_appoinments.dart';
import 'package:healthcare/views/screens/appointment/appointment_detail.dart';
import 'package:healthcare/views/screens/complete_profile/profile1.dart';
import 'package:healthcare/views/screens/dashboard/analytics.dart';
import 'package:healthcare/views/screens/dashboard/menu.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeScreen extends StatefulWidget {
  final String profileStatus;
  const HomeScreen({super.key, this.profileStatus = "incomplete"});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String profileStatus;

  @override
  void initState() {
    super.initState();
    profileStatus = widget.profileStatus;
    // Show popup automatically if the profile is not complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (profileStatus != "complete") {
        showPopup(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromRGBO(64, 124, 226, 1),
                    Color.fromRGBO(84, 144, 246, 1),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(64, 124, 226, 0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(25, 70, 25, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      "Dr. Asmara",
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                              color: Colors.white,
                      ),
                    ),
                  ],
                ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                ),
              ],
            ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: AssetImage("assets/images/User.png"),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 25),
                  // Earnings info in header
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.paid_outlined,
                            color: Color.fromRGBO(64, 124, 226, 1),
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 15),
                  Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Earning",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                                fontSize: 14,
                        ),
                      ),
                      Text(
                              "Rs 400.00",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                                fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            LucideIcons.arrowRight,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 25),
                  
                  // Quick action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickActionButton(
                        icon: LucideIcons.calendarClock,
                        label: "Schedule",
                        color: Color.fromRGBO(64, 124, 226, 1),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppointmentsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionButton(
                        icon: LucideIcons.clipboardPlus,
                        label: "New Patient",
                        color: Color(0xFF4CAF50),
                        onTap: () {
                          // Navigate to patient screen, assuming it exists
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppointmentDetailsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionButton(
                        icon: Icons.bar_chart,
                        label: "Reports",
                        color: Color(0xFFF44336),
                        onTap: () {
                          // Navigate to analytics screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnalyticsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionButton(
                        icon: LucideIcons.messageCircle,
                        label: "Menu",
                        color: Color(0xFFFF9800),
                        onTap: () {
                          // Navigate to menu screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MenuScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 25),
                  
                  // Ratings Card with improved design
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                          color: Color.fromRGBO(158, 158, 158, 0.2),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.shade100,
                        width: 1,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(64, 124, 226, 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                LucideIcons.thumbsUp,
                                color: Color.fromRGBO(64, 124, 226, 1),
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                      Text(
                        "Overall Ratings",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                        SizedBox(height: 15),
                  Row(
                    children: [
                      Text(
                              "4.2",
                        style: GoogleFonts.poppins(
                                fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(64, 124, 226, 1),
                        ),
                      ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 18),
                                    Icon(Icons.star, color: Colors.amber, size: 18),
                                    Icon(Icons.star, color: Colors.amber, size: 18),
                                    Icon(Icons.star, color: Colors.amber, size: 18),
                                    Icon(Icons.star_half, color: Colors.amber, size: 18),
                                  ],
                                ),
                                SizedBox(height: 5),
                  Text(
                    "Based on 121 reviews",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                  ),
                ],
              ),
            ),
                  
                  SizedBox(height: 25),

            // Upcoming Appointments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Upcoming Appointments",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                      TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentsScreen(),
                      ),
                    );
                  },
                        icon: Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: Color.fromRGBO(64, 124, 226, 1),
                        ),
                        label: Text(
                    "See all",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Color.fromRGBO(64, 124, 226, 1),
                    ),
                  ),
                ),
              ],
            ),
                  SizedBox(height: 15),

            Column(
              children: List.generate(3, (index) {
                return Container(
                        margin: EdgeInsets.only(bottom: 15),
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                              color: Color.fromRGBO(158, 158, 158, 0.15),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                      ),
                    ],
                          border: Border.all(
                            color: Colors.grey.shade100,
                            width: 1,
                          ),
                  ),
                  child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: index % 3 == 0
                                    ? Color(0xFFE3F2FD)
                                    : index % 3 == 1
                                        ? Color(0xFFE8F5E9)
                                        : Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  "${10 + index}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: index % 3 == 0
                                        ? Color(0xFF2196F3)
                                        : index % 3 == 1
                                            ? Color(0xFF4CAF50)
                                            : Color(0xFFFFC107),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Appointment with Hania",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                                  SizedBox(height: 4),
                      Text(
                                    "Jan ${10 + index}, 2025 • 12:00 pm",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(64, 124, 226, 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "View",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromRGBO(64, 124, 226, 1),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
                  ),
                  SizedBox(height: 25),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

void showPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible:
        false, // Prevent closing the dialog when tapping outside
    builder: (BuildContext context) {
      return Stack(
        children: [
          // Blurred background effect
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5,
              sigmaY: 5,
            ), // Adjust blur intensity
            child: Container(
              color: const Color.fromARGB(
                30,
                0,
                0,
                0,
              ), // Darken background slightly
            ),
          ),
          AlertDialog(
            backgroundColor: const Color.fromRGBO(64, 124, 226, 1),
            title: Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 20),
              child: Center(
                child: Text(
                  "Please Complete Your Profile first",
                  style: GoogleFonts.poppins(fontSize: 20, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            actions: [
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CompleteProfileScreen(),
                    ),
                  );
                },
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      color: const Color.fromRGBO(217, 217, 217, 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    width: 100,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        "Proceed",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
