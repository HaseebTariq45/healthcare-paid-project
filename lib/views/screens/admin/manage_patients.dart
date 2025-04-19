import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/admin_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:healthcare/views/screens/admin/admin_dashboard.dart';

class ManagePatients extends StatefulWidget {
  const ManagePatients({Key? key}) : super(key: key);

  @override
  State<ManagePatients> createState() => _ManagePatientsState();
}

class _ManagePatientsState extends State<ManagePatients> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  final List<String> _statusFilters = ['All', 'Active', 'Blocked'];
  String _selectedStatusFilter = 'All';
  
  // Admin service instance
  final AdminService _adminService = AdminService();
  
  // Firebase instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // State variables
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Sort options
  final List<String> _sortOptions = ['Name (A-Z)', 'Name (Z-A)', 'Newest First', 'Oldest First'];
  String _selectedSortOption = 'Name (A-Z)';
  
  @override
  void initState() {
    super.initState();
    _loadPatients();
    
    _searchController.addListener(() {
      _filterPatients();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Load all patients
  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('patients')
          .get();
      
      List<Map<String, dynamic>> patients = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Count appointments for this patient
        final appointmentCount = await _firestore
            .collection('appointments')
            .where('patientId', isEqualTo: data['id'] ?? doc.id)
            .count()
            .get();
        
        patients.add({
          'id': data['id'] ?? doc.id,
          'name': data['fullName'] ?? 'Unknown',
          'email': data['email'] ?? 'No email',
          'phoneNumber': data['phoneNumber'] ?? 'No phone',
          'age': data['age'] ?? 'Unknown',
          'gender': data['gender'] ?? 'Unknown',
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
          'appointmentCount': appointmentCount.count,
          'status': data['profileComplete'] == true ? 'Active' : 'Inactive',
          'profileImageUrl': data['profileImageUrl'],
        });
      }
      
      if (mounted) {
        setState(() {
          _patients = patients;
          _filteredPatients = List.from(_patients);
          _isLoading = false;
        });
        
        // Apply initial sort
        _sortPatients();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load patients: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  
  // Filter patients based on search query and status filter
  void _filterPatients() {
    if (!mounted) return;
    
    setState(() {
      _filteredPatients = _patients.where((patient) {
        // Apply search filter
        final matchesSearch = _searchQuery.isEmpty || 
            patient['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            patient['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            patient['phoneNumber'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
        
        // Apply status filter
        final matchesStatus = _selectedStatusFilter == 'All' || 
            patient['status'] == (_selectedStatusFilter == 'Blocked' ? 'Inactive' : 'Active');
        
        return matchesSearch && matchesStatus;
      }).toList();
      
      // Re-apply sort
      _sortPatients();
    });
  }
  
  // Sort patients based on selected sort option
  void _sortPatients() {
    if (!mounted) return;
    
    setState(() {
      switch (_selectedSortOption) {
        case 'Name (A-Z)':
          _filteredPatients.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
          break;
        case 'Name (Z-A)':
          _filteredPatients.sort((a, b) => b['name'].toString().compareTo(a['name'].toString()));
          break;
        case 'Newest First':
          _filteredPatients.sort((a, b) {
            final aDate = a['createdAt'] != null 
                ? (a['createdAt'] as Timestamp).toDate() 
                : DateTime(2000);
            final bDate = b['createdAt'] != null 
                ? (b['createdAt'] as Timestamp).toDate() 
                : DateTime(2000);
            return bDate.compareTo(aDate);
          });
          break;
        case 'Oldest First':
          _filteredPatients.sort((a, b) {
            final aDate = a['createdAt'] != null 
                ? (a['createdAt'] as Timestamp).toDate() 
                : DateTime(2000);
            final bDate = b['createdAt'] != null 
                ? (b['createdAt'] as Timestamp).toDate() 
                : DateTime(2000);
            return aDate.compareTo(bDate);
          });
          break;
      }
    });
  }
  
  // Toggle patient active status
  Future<void> _togglePatientStatus(String patientId, bool isCurrentlyActive) async {
    try {
      // Display loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );
      
      // Update status in Firestore
      await _firestore.collection('users').doc(patientId).update({
        'active': !isCurrentlyActive,
      });
      
      // Refresh patient list
      await _loadPatients();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCurrentlyActive 
            ? 'Patient blocked successfully' 
            : 'Patient unblocked successfully'
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update patient status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Delete patient
  Future<void> _deletePatient(String patientId, String patientName) async {
    // Show enhanced confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Delete Patient'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this patient?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Patient: $patientName',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone. All data associated with this patient will be permanently deleted.',
              style: GoogleFonts.poppins(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 2,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ) ?? false;
    
    if (!confirmed) return;
    
    try {
      // Display loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF3366CC)),
                SizedBox(height: 12),
                Text(
                  'Deleting patient...',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
          ),
        ),
      );
      
      // Delete patient from Firestore using the patients collection
      await _firestore.collection('patients').doc(patientId).delete();
      
      // Also delete any appointments related to this patient
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in appointmentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // Refresh patient list
      await _loadPatients();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Patient deleted successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Failed to delete patient: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    final double padding = screenWidth * 0.04;
    final bool isSmallScreen = screenWidth < 360;
    
    return WillPopScope(
      onWillPop: () async {
        // Navigate back to admin dashboard and select the home tab
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboard(),
          ),
        );
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Patients',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: screenWidth * 0.05,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPatients,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: EdgeInsets.all(padding),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search patients...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterPatients();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterPatients();
                  });
                },
              ),
            ),
            
            // Filter and sort options
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Row(
                children: [
                  // Status filter dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Status',
                        contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                      ),
                      value: _selectedStatusFilter,
                      items: _statusFilters.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(
                            status, 
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.04,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStatusFilter = value;
                            _filterPatients();
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  // Sort dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Sort By',
                        contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                      ),
                      value: _selectedSortOption,
                      items: _sortOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(
                            option,
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.04,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedSortOption = value;
                            _sortPatients();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: screenHeight * 0.01),
            
            // Patient list
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: screenWidth * 0.15, color: Colors.red),
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(fontSize: screenWidth * 0.04),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              ElevatedButton(
                                onPressed: _loadPatients,
                                child: Text('Try Again'),
                              ),
                            ],
                          ),
                        )
                      : _filteredPatients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_off, size: screenWidth * 0.15, color: Colors.grey),
                                  SizedBox(height: screenHeight * 0.02),
                                  Text(
                                    'No patients found',
                                    style: GoogleFonts.poppins(fontSize: screenWidth * 0.04),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadPatients,
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding * 0.5),
                                itemCount: _filteredPatients.length,
                                itemBuilder: (context, index) {
                                  final patient = _filteredPatients[index];
                                  final isActive = patient['status'] == 'Active';
                                  final createdAt = patient['createdAt'] != null 
                                      ? DateFormat('MMM d, yyyy').format((patient['createdAt'] as Timestamp).toDate())
                                      : 'Unknown';
                                  final lastLogin = patient['updatedAt'] != null 
                                      ? DateFormat('MMM d, yyyy').format((patient['updatedAt'] as Timestamp).toDate())
                                      : 'Unknown';
                                  
                                  return Container(
                                    margin: EdgeInsets.only(bottom: screenHeight * 0.015),
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
                                          padding: EdgeInsets.all(padding),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Patient avatar
                                              CircleAvatar(
                                                radius: screenWidth * 0.08,
                                                backgroundColor: Colors.blue.shade100,
                                                backgroundImage: patient['profileImageUrl'] != null
                                                    ? NetworkImage(patient['profileImageUrl'])
                                                    : null,
                                                child: patient['profileImageUrl'] == null
                                                    ? Text(
                                                        patient['name'].toString().substring(0, 1),
                                                        style: TextStyle(
                                                          fontSize: screenWidth * 0.07,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF3366CC),
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                              SizedBox(width: screenWidth * 0.04),
                                              // Patient info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            patient['name'] ?? 'Unknown',
                                                            style: GoogleFonts.poppins(
                                                              fontSize: isSmallScreen ? screenWidth * 0.045 : screenWidth * 0.05,
                                                              fontWeight: FontWeight.w600,
                                                              color: Color(0xFF333333),
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: EdgeInsets.symmetric(
                                                            horizontal: screenWidth * 0.025, 
                                                            vertical: screenHeight * 0.005
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(screenWidth * 0.05),
                                                            border: Border.all(
                                                              color: isActive ? Colors.green.shade300 : Colors.red.shade300,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            isActive ? 'Active' : 'Inactive',
                                                            style: GoogleFonts.poppins(
                                                              fontSize: screenWidth * 0.03,
                                                              fontWeight: FontWeight.w500,
                                                              color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: screenHeight * 0.015),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              _buildInfoRow(
                                                                Icons.email, 
                                                                patient['email'] ?? 'No email',
                                                                screenWidth
                                                              ),
                                                              SizedBox(height: screenHeight * 0.008),
                                                              _buildInfoRow(
                                                                Icons.phone, 
                                                                patient['phoneNumber'] ?? 'No phone',
                                                                screenWidth
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              _buildInfoRow(
                                                                Icons.event_note,
                                                                'Appointments: ${patient['appointmentCount'] ?? 0}',
                                                                screenWidth
                                                              ),
                                                              SizedBox(height: screenHeight * 0.008),
                                                              _buildInfoRow(
                                                                Icons.person,
                                                                '${patient['gender'] ?? 'Unknown'}, ${patient['age'] ?? 'Unknown age'}',
                                                                screenWidth
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: screenHeight * 0.008),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: _buildInfoRow(
                                                            Icons.access_time,
                                                            'Joined: $createdAt',
                                                            screenWidth
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: _buildInfoRow(
                                                            Icons.login,
                                                            'Last Activity: $lastLogin',
                                                            screenWidth
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Action buttons - Divider and Delete button section
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(screenWidth * 0.04),
                                              bottomRight: Radius.circular(screenWidth * 0.04),
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: screenHeight * 0.015, 
                                            horizontal: padding
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              _buildDeleteButton(
                                                patientId: patient['id'], 
                                                patientName: patient['name'],
                                                screenWidth: screenWidth,
                                                screenHeight: screenHeight
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text, double screenWidth) {
    final double iconSize = screenWidth * 0.04;
    final double fontSize = screenWidth * 0.035;
    
    return Row(
      children: [
        Icon(
          icon,
          size: iconSize,
          color: Colors.grey.shade600,
        ),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDeleteButton({
    required String patientId,
    required String patientName,
    required double screenWidth,
    required double screenHeight,
  }) {
    final double fontSize = screenWidth * 0.035;
    final double iconSize = screenWidth * 0.045;
    
    return GestureDetector(
      onTap: () => _deletePatient(patientId, patientName),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04, 
          vertical: screenHeight * 0.01
        ),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              color: Colors.red.shade700,
              size: iconSize,
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}