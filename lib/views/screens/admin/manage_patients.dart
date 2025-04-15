import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/admin_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

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
      final patients = await _adminService.getAllPatients();
      setState(() {
        _patients = patients;
        _filteredPatients = List.from(_patients);
        _isLoading = false;
      });
      
      // Apply initial sort
      _sortPatients();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load patients: ${e.toString()}';
        _isLoading = false;
      });
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
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Patient'),
        content: Text('Are you sure you want to delete $patientName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirmed) return;
    
    try {
      // Display loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );
      
      // Delete patient from Firestore
      await _firestore.collection('users').doc(patientId).delete();
      
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
          content: Text('Patient deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete patient: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Patients',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Status filter dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Status',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: _selectedStatusFilter,
                    items: _statusFilters.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
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
                SizedBox(width: 12),
                // Sort dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Sort By',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: _selectedSortOption,
                    items: _sortOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
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
          
          SizedBox(height: 8),
          
          // Patient list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 60, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.poppins(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
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
                                Icon(Icons.person_off, size: 60, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No patients found',
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPatients,
                            child: ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: _filteredPatients.length,
                              itemBuilder: (context, index) {
                                return _buildPatientCard(context, _filteredPatients[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Map<String, dynamic> patient) {
    final bool isActive = patient['status'] == 'Active';
    
    // Format date strings
    String lastLogin = 'Never logged in';
    if (patient['lastLogin'] != null) {
      final loginDate = (patient['lastLogin'] as Timestamp).toDate();
      lastLogin = DateFormat('MMM d, yyyy').format(loginDate);
    }
    
    String createdAt = 'Unknown';
    if (patient['createdAt'] != null) {
      final createDate = (patient['createdAt'] as Timestamp).toDate();
      createdAt = DateFormat('MMM d, yyyy').format(createDate);
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: patient['profileImageUrl'] != null
                      ? NetworkImage(patient['profileImageUrl'])
                      : null,
                  child: patient['profileImageUrl'] == null
                      ? Text(
                          patient['name'].toString().isNotEmpty
                              ? patient['name'].toString().substring(0, 1)
                              : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 16),
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
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Blocked',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isActive ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      _buildInfoRow(Icons.email, patient['email'] ?? 'No email'),
                      SizedBox(height: 4),
                      _buildInfoRow(Icons.phone, patient['phoneNumber'] ?? 'No phone'),
                      SizedBox(height: 4),
                      _buildInfoRow(
                        Icons.event_note,
                        'Appointments: ${patient['appointmentCount'] ?? 0}',
                      ),
                      SizedBox(height: 4),
                      _buildInfoRow(
                        Icons.person,
                        '${patient['gender'] ?? 'Unknown'}, ${patient['age'] ?? 'Unknown age'}',
                      ),
                      SizedBox(height: 4),
                      _buildInfoRow(
                        Icons.access_time,
                        'Joined: $createdAt',
                      ),
                      SizedBox(height: 4),
                      _buildInfoRow(
                        Icons.login,
                        'Last Login: $lastLogin',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  label: 'View',
                  icon: Icons.visibility,
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to detailed patient view
                    // TODO: Implement patient details screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('View patient details - Feature coming soon')),
                    );
                  },
                ),
                _buildActionButton(
                  label: 'Edit',
                  icon: Icons.edit,
                  color: Colors.orange,
                  onTap: () {
                    // Navigate to edit patient screen
                    // TODO: Implement edit patient screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Edit patient - Feature coming soon')),
                    );
                  },
                ),
                _buildActionButton(
                  label: isActive ? 'Block' : 'Unblock',
                  icon: isActive ? Icons.block : Icons.lock_open,
                  color: isActive ? Colors.red : Colors.green,
                  onTap: () {
                    _togglePatientStatus(patient['id'], isActive);
                  },
                ),
                _buildActionButton(
                  label: 'Delete',
                  icon: Icons.delete,
                  color: Colors.red.shade700,
                  onTap: () {
                    _deletePatient(patient['id'], patient['name']);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}