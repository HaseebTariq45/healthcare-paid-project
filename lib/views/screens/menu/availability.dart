import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/menu/availability/add_availability.dart';
import 'package:healthcare/views/screens/menu/availability/remove_availability.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SetAvailabilityScreen extends StatefulWidget {
  const SetAvailabilityScreen({super.key});

  @override
  State<SetAvailabilityScreen> createState() => _SetAvailabilityScreenState();
}

class _SetAvailabilityScreenState extends State<SetAvailabilityScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(
        padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome section
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.0, 0.6, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(0.0, 0.6, curve: Curves.easeOut),
                            ),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromRGBO(64, 124, 226, 0.1),
                                  Color.fromRGBO(84, 144, 246, 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Color.fromRGBO(64, 124, 226, 0.3),
                                width: 1,
                              ),
                            ),
          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                                Text(
                                  "Manage Your Schedule",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Set your available time slots for patient appointments and manage your schedule efficiently.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 30),
                      
                      // Option cards
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.2, 0.8, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(0.2, 0.8, curve: Curves.easeOut),
                            ),
                          ),
                          child: _buildOptionCard(
                            title: "Add New Availability",
                            subtitle: "Set available time slots for appointments",
                            icon: LucideIcons.calendarPlus,
                            color: Color.fromRGBO(64, 124, 226, 1),
                            onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddAvailabilityScreen()),
                    );
                            },
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.3, 0.9, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(0.3, 0.9, curve: Curves.easeOut),
                            ),
                          ),
                          child: _buildOptionCard(
                            title: "Update Existing Availability",
                            subtitle: "Modify or remove already scheduled slots",
                            icon: LucideIcons.calendarClock,
                            color: Color.fromRGBO(64, 124, 226, 1),
                            onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RemoveAvailability()),
                    );
                            },
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 30),
                      
                      // Weekly summary section
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.4, 1.0, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(0.4, 1.0, curve: Curves.easeOut),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Your Availability Summary",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildWeeklySummary(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
      padding: EdgeInsets.fromLTRB(20, 10, 20, 25),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(LucideIcons.arrowLeft, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 8),
                Text(
                  "Set Availability",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    // Mock data for availability
    final availabilityMap = {
      'Mon': 3,
      'Wed': 5,
      'Thu': 2,
      'Fri': 4,
    };
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              final hasAvailability = availabilityMap.containsKey(day);
              final slots = availabilityMap[day] ?? 0;
              
              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hasAvailability
                          ? Color.fromRGBO(64, 124, 226, 1)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        day,
                        style: GoogleFonts.poppins(
                          color: hasAvailability ? Colors.white : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  if (hasAvailability)
                    Text(
                      '$slots slot${slots > 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF666666),
                        fontSize: 10,
                      ),
                    )
                  else
                    Text(
                      'None',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Icon(
                LucideIcons.info,
                size: 16,
                color: Colors.grey.shade500,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "The summary shows your available time slots for the current week.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
