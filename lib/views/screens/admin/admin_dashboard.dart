import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/admin/manage_doctors.dart';
import 'package:healthcare/views/screens/admin/manage_patients.dart';
import 'package:healthcare/views/screens/admin/system_settings.dart';
import 'package:healthcare/views/screens/admin/analytics_dashboard.dart';
import 'package:healthcare/views/screens/admin/appointment_management.dart';

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
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
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
              icon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Appointments',
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
  // Mock data for statistics
  String doctorCount = '42';
  String patientCount = '367';
  String appointmentCount = '89';
  bool _isLoading = false;
  List<Map<String, dynamic>> _recentActivities = [
    {
      'title': 'New Doctor Registration',
      'description': 'Dr. Ahsan Khan has registered as a Cardiologist.',
      'time': '10 minutes ago',
      'icon': Icons.check_circle,
      'color': Color(0xFF3366CC),
    },
    {
      'title': 'Patient Complaint',
      'description': 'Sara Ahmed reported an issue with appointment scheduling.',
      'time': '1 hour ago',
      'icon': Icons.warning,
      'color': Color(0xFFFF5722),
    },
    {
      'title': 'System Update',
      'description': 'Payment system was updated successfully.',
      'time': '2 hours ago',
      'icon': Icons.update,
      'color': Color(0xFF4CAF50),
    },
  ];

  @override
  void initState() {
    super.initState();
    // In a real app, we would fetch data here
    // _fetchDashboardData();
  }

  // Simulating a data refresh
  Future<void> _refreshDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));
    
    // In a real app, we would make API calls here
    // For now, just update with random data
    setState(() {
      doctorCount = (40 + (DateTime.now().second % 10)).toString();
      patientCount = (360 + (DateTime.now().second % 20)).toString();
      appointmentCount = (80 + (DateTime.now().second % 15)).toString();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshDashboardData,
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
                      _buildStatCard('Doctors', doctorCount, Icons.medical_services, Color(0xFF4CAF50)),
                      _buildStatCard('Patients', patientCount, Icons.people, Color(0xFFFFC107)),
                      _buildStatCard('Appointments', appointmentCount, Icons.bar_chart, Color(0xFFFF5722)),
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
                _buildActionCard(
                  'Manage Doctors',
                  Icons.medical_services,
                  Color(0xFFFF5722),
                  () {
                    final adminDashboardState = context.findAncestorStateOfType<_AdminDashboardState>();
                    if (adminDashboardState != null) {
                      adminDashboardState.setState(() {
                        adminDashboardState._selectedIndex = 3;
                      });
                    }
                  },
                ),
                _buildActionCard(
                  'Manage Patients',
                  Icons.people,
                  Color(0xFF9C27B0),
                  () {
                    final adminDashboardState = context.findAncestorStateOfType<_AdminDashboardState>();
                    if (adminDashboardState != null) {
                      adminDashboardState.setState(() {
                        adminDashboardState._selectedIndex = 4;
                      });
                    }
                  },
                ),
                _buildActionCard(
                  'System Settings',
                  Icons.settings,
                  Color(0xFFFF5722),
                  () {
                    final adminDashboardState = context.findAncestorStateOfType<_AdminDashboardState>();
                    if (adminDashboardState != null) {
                      adminDashboardState.setState(() {
                        adminDashboardState._selectedIndex = 5;
                      });
                    }
                  },
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Recent Activities
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activities',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _isLoading ? null : _refreshDashboardData,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),
            ..._recentActivities.map((activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildActivityCard(
                activity['title'],
                activity['description'],
                activity['time'],
                activity['icon'],
                activity['color'],
              ),
            )).toList(),
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
  
  Widget _buildActivityCard(String title, String description, String time, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
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
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 