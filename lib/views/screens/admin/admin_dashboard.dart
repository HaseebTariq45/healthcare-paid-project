import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/admin/manage_doctors.dart';
import 'package:healthcare/views/screens/admin/manage_patients.dart';
import 'package:healthcare/views/screens/admin/system_settings.dart';
import 'package:healthcare/views/screens/admin/analytics_dashboard.dart';
import 'package:healthcare/views/screens/admin/appointment_management.dart';
import 'package:healthcare/views/screens/admin/book_via_call_screen.dart';
import 'package:healthcare/services/admin_service.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/views/screens/onboarding/onboarding_3.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const AdminHome(),
    const AnalyticsDashboard(),
    const AppointmentManagement(),
    const ManageDoctors(),
    const ManagePatients(),
    const SystemSettings(),
    const BookViaCallScreen(),
  ];

  // Helper method to map bottom nav index to page index
  int _getPageIndex(int bottomNavIndex) {
    switch (bottomNavIndex) {
      case 0: return 0; // Home
      case 1: return 3; // Doctors (index 3 in pages)
      case 2: return 4; // Patients (index 4 in pages)
      case 3: return 5; // Settings (index 5 in pages)
      default: return 0;
    }
  }
  
  // Helper method to get the correct bottom nav index from page index
  int _getBottomNavIndex(int pageIndex) {
    switch (pageIndex) {
      case 0: return 0; // Home
      case 3: return 1; // Doctors -> bottom nav index 1
      case 4: return 2; // Patients -> bottom nav index 2
      case 5: return 3; // Settings -> bottom nav index 3
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    final bool isSmallScreen = screenWidth < 360;
    final double padding = screenWidth * 0.04;
    
    return WillPopScope(
      onWillPop: () async {
        // If we're already on the home screen, show exit confirmation
        if (_selectedIndex == 0) {
          return await _showExitConfirmationDialog(context);
        } else {
          // If we're on another screen, navigate back to home
          setState(() {
            _selectedIndex = 0;
          });
          return false; // Prevent default back button behavior
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Admin Dashboard',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: screenWidth * 0.05,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Color(0xFF3366CC)),
              tooltip: 'Logout',
              onPressed: () {
                _showLogoutConfirmationDialog(context);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: _pages[_selectedIndex],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _getBottomNavIndex(_selectedIndex),
            onTap: (index) {
              setState(() {
                _selectedIndex = _getPageIndex(index);
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF3366CC),
            unselectedItemColor: Colors.grey.shade600,
            selectedLabelStyle: GoogleFonts.poppins(
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w500,
            ),
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.medical_services),
                label: 'Doctors',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Patients',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    final AuthService _authService = AuthService();
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    final double padding = screenWidth * 0.05;
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout,
                  color: Color(0xFFFF5252),
                  size: screenWidth * 0.075,
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              Text(
                "Logout",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              Text(
                "Are you sure you want to logout from the admin dashboard?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        ),
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Close the confirmation dialog first
                        Navigator.of(dialogContext).pop();
                        
                        try {
                          // Perform logout directly without showing loading dialog
                          await _authService.signOut();
                        } catch (e) {
                          print('Error during signout: $e');
                          // Continue with navigation even if signout fails
                        } finally {
                          // Always navigate to onboarding screen, regardless of signout success/failure
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const Onboarding3(),
                              ),
                              (route) => false,
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5252),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        ),
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                        elevation: 0,
                      ),
                      child: Text(
                        "Logout",
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add exit confirmation dialog
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.exit_to_app,
                  color: Color(0xFF3366CC),
                  size: screenWidth * 0.075,
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              Text(
                "Exit App",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              Text(
                "Are you sure you want to exit the application?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        ),
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3366CC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        ),
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                        elevation: 0,
                      ),
                      child: Text(
                        "Exit",
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ?? false;
  }
}

class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  // Create a service instance
  final AdminService _adminService = AdminService();
  
  // State variables
  bool _isLoading = true;
  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // Fetch dashboard data
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get dashboard stats and recent activities in parallel
      final statsResult = await _adminService.getDashboardStats();
      final activitiesResult = await _adminService.getRecentActivities();
      
      if (mounted) {
        setState(() {
          _dashboardStats = statsResult;
          _recentActivities = activitiesResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) {
    setState(() {
      _isLoading = false;
    });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    final bool isSmallScreen = screenWidth < 360;
    final double padding = screenWidth * 0.04;
    
    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Welcome Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3366CC), Color(0xFF6699FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF3366CC).withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Welcome, Administrator',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.055,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (_isLoading)
                        SizedBox(
                          width: screenWidth * 0.05,
                          height: screenWidth * 0.05,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'You have full access to manage the healthcare platform.',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.035,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double itemWidth = (constraints.maxWidth - screenWidth * 0.04) / 3;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard(
                            'Doctors', 
                            _isLoading ? '-' : _dashboardStats['doctorCount']?.toString() ?? '0', 
                            Icons.medical_services, 
                            Color(0xFF4CAF50),
                            itemWidth,
                            screenWidth,
                            screenHeight
                          ),
                          _buildStatCard(
                            'Patients', 
                            _isLoading ? '-' : _dashboardStats['patientCount']?.toString() ?? '0', 
                            Icons.people, 
                            Color(0xFFFFC107),
                            itemWidth,
                            screenWidth,
                            screenHeight
                          ),
                          _buildStatCard(
                            'Appointments', 
                            _isLoading ? '-' : _dashboardStats['appointmentCount']?.toString() ?? '0', 
                            Icons.calendar_today, 
                            Color(0xFFFF5722),
                            itemWidth,
                            screenWidth,
                            screenHeight
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
            
            SizedBox(height: screenHeight * 0.03),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: padding,
              mainAxisSpacing: padding,
              childAspectRatio: isSmallScreen ? 1.3 : 1.5,
              children: [
                _buildActionCard(
                  'View Analytics',
                  Icons.analytics,
                  Color(0xFF3366CC),
                  () {
                    final adminDashboardState = context.findAncestorStateOfType<_AdminDashboardState>();
                    if (adminDashboardState != null) {
                      adminDashboardState.setState(() {
                        adminDashboardState._selectedIndex = 1;
                      });
                    }
                  },
                  screenWidth,
                  screenHeight
                ),
                _buildActionCard(
                  'Manage Appointments',
                  Icons.calendar_today,
                  Color(0xFF4CAF50),
                  () {
                    final adminDashboardState = context.findAncestorStateOfType<_AdminDashboardState>();
                    if (adminDashboardState != null) {
                      adminDashboardState.setState(() {
                        adminDashboardState._selectedIndex = 2;
                      });
                    }
                  },
                  screenWidth,
                  screenHeight
                ),
                _buildActionCard(
                  'Book via Call',
                  Icons.phone,
                  Color(0xFF9C27B0),
                  () {
                    final adminDashboardState = context.findAncestorStateOfType<_AdminDashboardState>();
                    if (adminDashboardState != null) {
                      adminDashboardState.setState(() {
                        adminDashboardState._selectedIndex = 6;
                      });
                    }
                  },
                  screenWidth,
                  screenHeight
                ),
              ],
            ),
            
            SizedBox(height: screenHeight * 0.03),
            
            // Revenue (full width)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.015),
                    child: Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: Color(0xFF4CAF50),
                          size: screenWidth * 0.06,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Text(
                            'Revenue',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _isLoading 
                          ? '-' 
                          : _dashboardStats['revenueFormatted'] ?? 'Rs 0.00',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Text(
                    'Total revenue from appointments',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: screenHeight * 0.03),
            
            // Recent Activities
            Text(
              'Recent Activities',
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3366CC),
                ),
              )
            else if (_recentActivities.isEmpty)
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey.shade400,
                        size: screenWidth * 0.1,
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'No recent activities found',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: _recentActivities.map((activity) => _buildActivityItem(
                    activity['title'] ?? 'Activity',
                    activity['description'] ?? 'Description',
                    activity['time'] ?? 'Recently',
                    activity['icon'] ?? Icons.info,
                    activity['color'] ?? Colors.grey,
                    screenWidth,
                    screenHeight
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(
    String title, 
    String value, 
    IconData icon, 
    Color color,
    double width,
    double screenWidth,
    double screenHeight
  ) {
    return Container(
      width: width,
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: screenWidth * 0.07,
          ),
          SizedBox(height: screenHeight * 0.005),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.03,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionCard(
    String title, 
    IconData icon, 
    Color color, 
    VoidCallback onTap,
    double screenWidth,
    double screenHeight
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: screenWidth * 0.07,
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusCounter(String label, int count, Color color, double screenWidth) {
    // This method is no longer used, but we'll keep it for backward compatibility
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.01),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.03,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusCounterRow(String label, int count, Color color, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.03,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: screenWidth * 0.01),
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActivityItem(
    String title, 
    String description, 
    String time, 
    IconData icon, 
    Color color,
    double screenWidth,
    double screenHeight
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.015),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: screenWidth * 0.035,
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.0325,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.003),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.0275,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: screenWidth * 0.01),
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.0225,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        Divider(height: screenHeight * 0.03),
      ],
    );
  }
} 