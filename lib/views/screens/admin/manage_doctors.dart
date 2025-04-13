import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageDoctors extends StatefulWidget {
  const ManageDoctors({super.key});

  @override
  State<ManageDoctors> createState() => _ManageDoctorsState();
}

class _ManageDoctorsState extends State<ManageDoctors> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _doctors = [];
  final AdminService _adminService = AdminService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDoctors();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final doctors = await _adminService.getAllDoctors();
      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading doctors: $e');
      setState(() {
        _isLoading = false;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load doctors: $e')),
      );
    }
  }
  
  // Filter doctors based on status and search query
  List<Map<String, dynamic>> _getFilteredDoctors(String status) {
    // First filter by status
    final filteredByStatus = _doctors.where((doctor) {
      if (status == 'pending') {
        return doctor['verified'] == false; 
      } else if (status == 'approved') {
        return doctor['verified'] == true && doctor['status'] == 'Active';
      } else if (status == 'blocked') {
        return doctor['status'] == 'Inactive';
      }
      return false;
    }).toList();
    
    // Then filter by search query if it exists
    if (_searchQuery.isEmpty) {
      return filteredByStatus;
    }
    
    final lowerCaseQuery = _searchQuery.toLowerCase();
    return filteredByStatus.where((doctor) {
      final name = (doctor['name'] ?? '').toLowerCase();
      final specialty = (doctor['specialty'] ?? '').toLowerCase();
      final email = (doctor['email'] ?? '').toLowerCase();
      final phone = (doctor['phoneNumber'] ?? '').toLowerCase();
      
      return name.contains(lowerCaseQuery) || 
             specialty.contains(lowerCaseQuery) ||
             email.contains(lowerCaseQuery) ||
             phone.contains(lowerCaseQuery);
    }).toList();
  }
  
  // Action handlers
  void _showActionDialog(String action, Map<String, dynamic> doctor) {
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
              _performAction(action, doctor);
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
  
  Future<void> _performAction(String action, Map<String, dynamic> doctor) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      String message = '';
      
      switch (action) {
        case 'approve':
          // Use AdminService to update verification status
          final result = await _adminService.updateDoctorVerification(doctor['id'], true);
          if (result['success']) {
            message = 'Doctor successfully approved';
          } else {
            throw Exception(result['message']);
          }
          break;
        case 'reject':
        case 'delete':
          // Use AdminService to delete doctor
          final result = await _adminService.deleteDoctor(doctor['id']);
          if (result['success']) {
            message = 'Doctor successfully ${action}ed';
          } else {
            throw Exception(result['message']);
          }
          break;
        case 'block':
          // Use AdminService to update active status
          final result = await _adminService.updateDoctorActiveStatus(doctor['id'], false);
          if (result['success']) {
            message = 'Doctor successfully blocked';
          } else {
            throw Exception(result['message']);
          }
          break;
        case 'unblock':
          // Use AdminService to update active status
          final result = await _adminService.updateDoctorActiveStatus(doctor['id'], true);
          if (result['success']) {
            message = 'Doctor successfully unblocked';
          } else {
            throw Exception(result['message']);
          }
          break;
      }
      
      // Refresh doctor list
      await _loadDoctors();
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: action == 'reject' || action == 'block' || action == 'delete' 
              ? Colors.red 
              : Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showDoctorEditDialog(Map<String, dynamic> doctor) {
    final TextEditingController nameController = TextEditingController(text: doctor['name']);
    final TextEditingController specialtyController = TextEditingController(text: doctor['specialty']);
    final TextEditingController phoneController = TextEditingController(text: doctor['phoneNumber']);
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Doctor Details'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter doctor\'s name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: specialtyController,
                    decoration: InputDecoration(
                      labelText: 'Specialty',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter specialty';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    isSubmitting = true;
                  });
                  
                  try {
                    final result = await _adminService.updateDoctorDetails(
                      doctor['id'],
                      {
                        'fullName': nameController.text.trim(),
                        'specialty': specialtyController.text.trim(),
                        'phoneNumber': phoneController.text.trim(),
                      },
                    );
                    
                    if (result['success']) {
                      // Close dialog and refresh data
                      Navigator.pop(context);
                      await _loadDoctors();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Doctor details updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      setState(() {
                        isSubmitting = false;
                      });
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${result['message']}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    setState(() {
                      isSubmitting = false;
                    });
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: isSubmitting 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Doctors'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Blocked'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search doctors...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
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
    final doctors = _getFilteredDoctors(status);
    
    if (doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No doctors found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Try a different search query',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        return _buildDoctorCard(doctors[index], status);
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
            // Doctor info header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile image
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: doctor['profileImageUrl'] != null 
                      ? NetworkImage(doctor['profileImageUrl']) 
                      : null,
                  child: doctor['profileImageUrl'] == null
                      ? Icon(Icons.person, size: 40, color: Colors.grey.shade500)
                      : null,
                ),
                
                SizedBox(width: 16),
                
                // Doctor info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'] ?? 'Unknown Doctor',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      SizedBox(height: 4),
                      
                      Text(
                        doctor['specialty'] ?? 'General Physician',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Hospital affiliations
                      if (doctor['hospitals'] != null && doctor['hospitals'].isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: (doctor['hospitals'] as List).map<Widget>((hospital) => 
                            Chip(
                              label: Text(
                                hospital,
                                style: TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.grey.shade100,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )
                          ).toList(),
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
                  _buildDetailRow('Experience', doctor['experience'] != null ? '${doctor['experience']} years' : 'N/A'),
                  Divider(),
                  _buildDetailRow('Rating', doctor['rating'] != null ? '${doctor['rating']} ★' : 'No ratings yet'),
                  Divider(),
                  _buildDetailRow('Phone', doctor['phoneNumber'] ?? 'N/A'),
                  Divider(),
                  _buildDetailRow('Email', doctor['email'] ?? 'N/A'),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: _buildActionButtons(status, doctor),
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
  
  List<Widget> _buildActionButtons(String status, Map<String, dynamic> doctor) {
    switch (status) {
      case 'pending':
        return [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.check_circle),
              label: Text('Approve'),
              onPressed: () => _showActionDialog('approve', doctor),
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
              onPressed: () => _showActionDialog('reject', doctor),
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
              onPressed: () => _showDoctorEditDialog(doctor),
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
              onPressed: () => _showActionDialog('block', doctor),
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
              onPressed: () => _showActionDialog('unblock', doctor),
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
              onPressed: () => _showActionDialog('delete', doctor),
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
}