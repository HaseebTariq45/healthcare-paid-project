import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/models/doctor_model.dart';

class ManageDoctors extends StatefulWidget {
  final int initialTab;
  
  const ManageDoctors({
    Key? key, 
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<ManageDoctors> createState() => _ManageDoctorsState();
}

class _ManageDoctorsState extends State<ManageDoctors> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: widget.initialTab,
      length: 3, 
      vsync: this
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Doctors',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFF3366CC),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Color(0xFF3366CC),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Blocked'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search doctors by name or specialty',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF3366CC), width: 1.5),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDoctorsList('pending'),
                _buildDoctorsList('approved'),
                _buildDoctorsList('blocked'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDoctorsList(String status) {
    // Mock data for demonstration
    List<Map<String, dynamic>> mockDoctors = _getMockDoctors(status);
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      mockDoctors = mockDoctors.where((doctor) {
        return doctor['name'].toLowerCase().contains(_searchQuery) ||
               doctor['specialty'].toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    if (mockDoctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 48,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No doctors found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: mockDoctors.length,
      itemBuilder: (context, index) {
        final doctor = mockDoctors[index];
        return _buildDoctorCard(doctor, status);
      },
    );
  }
  
  Widget _buildDoctorCard(Map<String, dynamic> doctor, String status) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF3366CC).withOpacity(0.1),
                  backgroundImage: doctor['imageUrl'] != null
                      ? NetworkImage(doctor['imageUrl'])
                      : null,
                  child: doctor['imageUrl'] == null
                      ? Text(
                          doctor['name'].substring(0, 1),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3366CC),
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        doctor['specialty'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 4),
                          Text(
                            doctor['location'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Doctor details section
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Experience', '${doctor['experience']} years'),
                  Divider(),
                  _buildDetailRow('Rating', '${doctor['rating']} ★ (${doctor['reviewCount']} reviews)'),
                  Divider(),
                  _buildDetailRow('Phone', doctor['phone']),
                  Divider(),
                  _buildDetailRow('Email', doctor['email']),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: _buildActionButtons(status),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildActionButtons(String status) {
    switch (status) {
      case 'pending':
        return [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.check_circle),
              label: Text('Approve'),
              onPressed: () => _showActionDialog('approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.cancel),
              label: Text('Reject'),
              onPressed: () => _showActionDialog('reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF5722),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ];
      
      case 'approved':
        return [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.edit),
              label: Text('Edit'),
              onPressed: () => _showDoctorEditDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF3366CC),
                side: BorderSide(color: Color(0xFF3366CC)),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.block),
              label: Text('Block'),
              onPressed: () => _showActionDialog('block'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF5722),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ];
      
      case 'blocked':
        return [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.lock_open),
              label: Text('Unblock'),
              onPressed: () => _showActionDialog('unblock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.delete),
              label: Text('Delete'),
              onPressed: () => _showActionDialog('delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ];
      
      default:
        return [];
    }
  }
  
  void _showActionDialog(String action) {
    String title = '';
    String content = '';
    Color confirmColor = Colors.red;
    
    switch (action) {
      case 'approve':
        title = 'Approve Doctor';
        content = 'Are you sure you want to approve this doctor? They will be able to accept appointments from patients.';
        confirmColor = Color(0xFF4CAF50);
        break;
      case 'reject':
        title = 'Reject Doctor';
        content = 'Are you sure you want to reject this doctor\'s application?';
        confirmColor = Color(0xFFFF5722);
        break;
      case 'block':
        title = 'Block Doctor';
        content = 'Are you sure you want to block this doctor? They will not be able to access the platform until unblocked.';
        confirmColor = Color(0xFFFF5722);
        break;
      case 'unblock':
        title = 'Unblock Doctor';
        content = 'Are you sure you want to unblock this doctor? They will regain access to the platform.';
        confirmColor = Color(0xFF4CAF50);
        break;
      case 'delete':
        title = 'Delete Doctor';
        content = 'Are you sure you want to permanently delete this doctor? This action cannot be undone.';
        confirmColor = Colors.red.shade700;
        break;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Doctor successfully ${action}ed'),
                  backgroundColor: confirmColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Text(
              action.substring(0, 1).toUpperCase() + action.substring(1),
              style: TextStyle(color: confirmColor),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDoctorEditDialog() {
    // Implement edit doctor dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Doctor Details'),
        content: Text('This feature is not implemented in this demo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Mock data for demonstration
  List<Map<String, dynamic>> _getMockDoctors(String status) {
    if (status == 'pending') {
      return [
        {
          'name': 'Dr. Fahad Ahmed',
          'specialty': 'Cardiologist',
          'location': 'Karachi, Pakistan',
          'experience': 8,
          'rating': 4.5,
          'reviewCount': 32,
          'phone': '+923001234567',
          'email': 'fahad.ahmed@example.com',
          'imageUrl': null,
        },
        {
          'name': 'Dr. Sara Khan',
          'specialty': 'Dermatologist',
          'location': 'Lahore, Pakistan',
          'experience': 5,
          'rating': 4.2,
          'reviewCount': 18,
          'phone': '+923111234567',
          'email': 'sara.khan@example.com',
          'imageUrl': null,
        },
      ];
    } else if (status == 'approved') {
      return [
        {
          'name': 'Dr. Ali Hassan',
          'specialty': 'Neurologist',
          'location': 'Islamabad, Pakistan',
          'experience': 12,
          'rating': 4.8,
          'reviewCount': 87,
          'phone': '+923041234567',
          'email': 'ali.hassan@example.com',
          'imageUrl': null,
        },
        {
          'name': 'Dr. Zainab Malik',
          'specialty': 'Gynecologist',
          'location': 'Karachi, Pakistan',
          'experience': 10,
          'rating': 4.7,
          'reviewCount': 64,
          'phone': '+923051234567',
          'email': 'zainab.malik@example.com',
          'imageUrl': null,
        },
        {
          'name': 'Dr. Bilal Khan',
          'specialty': 'Orthopedic Surgeon',
          'location': 'Lahore, Pakistan',
          'experience': 15,
          'rating': 4.9,
          'reviewCount': 112,
          'phone': '+923061234567',
          'email': 'bilal.khan@example.com',
          'imageUrl': null,
        },
      ];
    } else if (status == 'blocked') {
      return [
        {
          'name': 'Dr. Usman Ali',
          'specialty': 'General Physician',
          'location': 'Rawalpindi, Pakistan',
          'experience': 6,
          'rating': 3.5,
          'reviewCount': 24,
          'phone': '+923071234567',
          'email': 'usman.ali@example.com',
          'imageUrl': null,
        },
      ];
    }
    
    return [];
  }
}