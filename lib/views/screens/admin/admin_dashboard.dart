import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/admin/manage_doctors.dart';
import 'package:healthcare/views/screens/admin/manage_patients.dart';
import 'package:healthcare/views/screens/admin/system_settings.dart';
import 'package:healthcare/views/screens/admin/analytics_dashboard.dart';
import 'package:healthcare/views/screens/admin/appointment_management.dart';
import 'package:healthcare/services/admin_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Show confirmation dialog before logging out
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Log Out'),
                  content: Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: Text('Log Out'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
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
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
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
    );
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
    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Welcome Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3366CC), Color(0xFF6699FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
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
                      Text(
                        'Welcome, Administrator',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (_isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You have full access to manage the healthcare platform.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard(
                        'Doctors', 
                        _isLoading ? '-' : _dashboardStats['doctorCount']?.toString() ?? '0', 
                        Icons.medical_services, 
                        Color(0xFF4CAF50)
                      ),
                      _buildStatCard(
                        'Patients', 
                        _isLoading ? '-' : _dashboardStats['patientCount']?.toString() ?? '0', 
                        Icons.people, 
                        Color(0xFFFFC107)
                      ),
                      _buildStatCard(
                        'Appointments', 
                        _isLoading ? '-' : _dashboardStats['appointmentCount']?.toString() ?? '0', 
                        Icons.calendar_today, 
                        Color(0xFFFF5722)
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
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
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Revenue and Status
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                          padding: EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Revenue',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _isLoading 
                              ? '-' 
                              : _dashboardStats['revenueFormatted'] ?? 'Rs 0.00',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Total revenue from appointments',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                          padding: EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.event_note,
                                color: Color(0xFF3366CC),
                                size: 20,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Appointment Status',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            _buildStatusCounterRow('Confirmed', 
                              _isLoading ? 0 : _dashboardStats['confirmedAppointments'] ?? 0, 
                              Color(0xFF3366CC)
                            ),
                            SizedBox(height: 8),
                            _buildStatusCounterRow('Completed', 
                              _isLoading ? 0 : _dashboardStats['completedAppointments'] ?? 0, 
                              Color(0xFF4CAF50)
                            ),
                            SizedBox(height: 8),
                            _buildStatusCounterRow('Cancelled', 
                              _isLoading ? 0 : _dashboardStats['cancelledAppointments'] ?? 0, 
                              Color(0xFFFF5722)
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Recent Activities
                  Text(
                    'Recent Activities',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
            SizedBox(height: 16),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3366CC),
                ),
              )
            else if (_recentActivities.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No recent activities found',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
              )
            else
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
            )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          SizedBox(height: 4),
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
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
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
  
  Widget _buildStatusCounter(String label, int count, Color color) {
    // This method is no longer used, but we'll keep it for backward compatibility
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
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
  
  Widget _buildStatusCounterRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 4),
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActivityItem(String title, String description, String time, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 14,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 4),
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        Divider(height: 24),
      ],
    );
  }
} 