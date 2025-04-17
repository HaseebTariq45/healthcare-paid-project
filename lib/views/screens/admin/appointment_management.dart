import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:healthcare/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentManagement extends StatefulWidget {
  const AppointmentManagement({Key? key}) : super(key: key);

  @override
  State<AppointmentManagement> createState() => _AppointmentManagementState();
}

class _AppointmentManagementState extends State<AppointmentManagement> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Filter values
  String _selectedStatusFilter = 'All';
  String _selectedDoctorFilter = 'All Doctors';
  DateTimeRange? _selectedDateRange;
  
  // Service and data
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  StreamSubscription? _appointmentSubscription;
  
  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _setupAppointmentListener();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _appointmentSubscription?.cancel();
    super.dispose();
  }
  
  // Set up real-time appointment updates
  void _setupAppointmentListener() {
    try {
      final stream = FirebaseFirestore.instance
          .collection('appointments')
          .orderBy('appointmentDate', descending: true)
          .limit(100)
          .snapshots();
          
      _appointmentSubscription = stream.listen(
        (snapshot) {
          if (!mounted) return;
          
          // Only refresh if we're not already loading
          if (!_isLoading) {
            _loadAppointments();
          }
        },
        onError: (error) {
          debugPrint('Error in appointment listener: $error');
        },
      );
    } catch (e) {
      debugPrint('Error setting up appointment listener: $e');
    }
  }
  
  // Load appointments from AdminService
  Future<void> _loadAppointments() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      debugPrint('📅 Starting to load appointments from Firestore...');
      final appointments = await _adminService.getAllAppointments();
      debugPrint('📅 Successfully loaded ${appointments.length} appointments');
      
      if (appointments.isNotEmpty) {
        debugPrint('Sample appointment: ${appointments.first}');
      }
      
      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading appointments: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load appointments: ${e.toString()}';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }
  
  // Refresh appointments
  Future<void> _refreshAppointments() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      // Clear cache to force fresh data
      _adminService.clearAllCaches();
      await _loadAppointments();
    } catch (e) {
      debugPrint('Error refreshing appointments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing appointments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
  
  // Filtered appointments based on search and filters
  List<Map<String, dynamic>> get filteredAppointments {
    return _appointments.where((appointment) {
      // Apply status filter
      if (_selectedStatusFilter != 'All' && 
          appointment['status'] != _selectedStatusFilter) {
        return false;
      }
      
      // Apply doctor filter
      if (_selectedDoctorFilter != 'All Doctors' && 
          appointment['doctorName'] != _selectedDoctorFilter) {
        return false;
      }
      
      // Apply date range filter
      if (_selectedDateRange != null) {
        final appointmentDate = appointment['actualDate'] as DateTime;
        if (appointmentDate.isBefore(_selectedDateRange!.start) || 
            appointmentDate.isAfter(_selectedDateRange!.end.add(Duration(days: 1)))) {
          return false;
        }
      }
      
      // Apply search query
      if (_searchQuery.isNotEmpty) {
        final String patientName = appointment['patientName'].toLowerCase();
        final String doctorName = appointment['doctorName'].toLowerCase();
        final String id = appointment['id'].toLowerCase();
        final String hospital = appointment['hospital'].toLowerCase();
        
        final query = _searchQuery.toLowerCase();
        
        return patientName.contains(query) || 
               doctorName.contains(query) || 
               id.contains(query) || 
               hospital.contains(query);
      }
      
      return true;
    }).toList();
  }
  
  // Get a list of all doctors for filtering
  List<String> get _doctorsList {
    final Set<String> doctors = {'All Doctors'};
    for (final appointment in _appointments) {
      doctors.add(appointment['doctorName']);
    }
    return doctors.toList();
  }
  
  // Update appointment status
  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _adminService.updateAppointmentStatus(appointmentId, status);
      
      if (result['success']) {
        // Refresh appointments list
        await _loadAppointments();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment status updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
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
        _isLoading = false;
      });
      
      // Show error message
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appointment Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isRefreshing)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3366CC)),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshAppointments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Redesigned Search and filters section
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // More compact search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search appointments...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13),
                    prefixIcon: Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF3366CC)),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                
                SizedBox(height: 8),
                
                // Compact filter controls row
                Row(
                  children: [
                    // Compact title & reset
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, size: 16, color: Color(0xFF3366CC)),
                          SizedBox(width: 4),
                          Text(
                            'Filters:',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _selectedStatusFilter = 'All';
                                _selectedDoctorFilter = 'All Doctors';
                                _selectedDateRange = null;
                              });
                            },
                            child: Text(
                              'Reset',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF3366CC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Compact filters in a row
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Status filter - compact
                            _buildCompactFilterDropdown(
                              label: 'Status',
                              value: _selectedStatusFilter,
                              items: ['All', 'Pending', 'Confirmed', 'Completed', 'Cancelled'],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedStatusFilter = value;
                                  });
                                }
                              },
                            ),
                            
                            SizedBox(width: 8),
                            
                            // Doctor filter - compact
                            _buildCompactFilterDropdown(
                              label: 'Doctor',
                              value: _selectedDoctorFilter,
                              items: _doctorsList,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedDoctorFilter = value;
                                  });
                                }
                              },
                            ),
                            
                            SizedBox(width: 8),
                            
                            // Date range filter - compact
                            _buildCompactDateRangeFilter(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Divider
          Divider(height: 1),
          
          // Appointments list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : filteredAppointments.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: filteredAppointments.length,
                            itemBuilder: (context, index) {
                              final appointment = filteredAppointments[index];
                              return _buildAppointmentCard(appointment);
                            },
                          ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load appointments',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage ?? 'An unknown error occurred',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
            onPressed: _loadAppointments,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3366CC),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No appointments found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Reset Filters'),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _selectedStatusFilter = 'All';
                _selectedDoctorFilter = 'All Doctors';
                _selectedDateRange = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3366CC),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(width: 2),
          DropdownButton<String>(
            value: value,
            icon: Icon(Icons.arrow_drop_down, size: 16),
            iconSize: 16,
            underline: SizedBox(),
            isDense: true,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            onChanged: onChanged,
            items: items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactDateRangeFilter() {
    final String displayText = _selectedDateRange != null
        ? '${DateFormat('MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('MM/dd').format(_selectedDateRange!.end)}'
        : 'Date Range';
    
    return InkWell(
      onTap: () async {
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2022),
          lastDate: DateTime.now().add(Duration(days: 365)),
          initialDateRange: _selectedDateRange ?? DateTimeRange(
            start: DateTime.now().subtract(Duration(days: 30)),
            end: DateTime.now(),
          ),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFF3366CC),
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (picked != null) {
          setState(() {
            _selectedDateRange = picked;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range,
              size: 14,
              color: Color(0xFF3366CC),
            ),
            SizedBox(width: 4),
            Text(
              displayText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (_selectedDateRange != null) ...[
              SizedBox(width: 4),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedDateRange = null;
                  });
                },
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    Color statusColor;
    switch (appointment['status']) {
      case 'Confirmed':
        statusColor = Color(0xFF4CAF50);
        break;
      case 'Pending':
        statusColor = Color(0xFFFFC107);
        break;
      case 'Completed':
        statusColor = Color(0xFF3366CC);
        break;
      case 'Cancelled':
        statusColor = Color(0xFFFF5722);
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header with status badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${appointment['id']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    appointment['status'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Appointment details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor and patient info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        appointment['doctorName'].substring(0, 1),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3366CC),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment['doctorName'],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            appointment['specialty'] ?? 'Doctor',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                
                // Patient info (separated from doctor info to avoid overflow)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.green.shade100,
                      child: Text(
                        appointment['patientName'].substring(0, 1),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment['patientName'],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Patient',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Appointment date and time
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Date',
                        value: appointment['date'],
                      ),
                      SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.access_time,
                        label: 'Time',
                        value: appointment['time'],
                      ),
                      SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: appointment['hospital'],
                      ),
                      if (appointment['type'] != null) ...[
                        SizedBox(height: 8),
                        _buildDetailRow(
                          icon: appointment['type'] == 'Video Consultation'
                              ? Icons.videocam
                              : Icons.person,
                          label: 'Type',
                          value: appointment['type'],
                        ),
                      ],
                      SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.medical_services,
                        label: 'Reason',
                        value: appointment['reason'],
                      ),
                      if (appointment['displayAmount'] != null) ...[
                        SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.payments,
                          label: 'Fee',
                          value: appointment['displayAmount'],
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    if (appointment['status'] == 'Pending') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.check_circle),
                          label: Text('Confirm'),
                          onPressed: () => _showConfirmationDialog(
                            appointment['id'],
                            'Are you sure you want to confirm this appointment?',
                            'confirmed',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF4CAF50),
                            side: BorderSide(color: Color(0xFF4CAF50)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    
                    if (appointment['status'] != 'Cancelled' &&
                        appointment['status'] != 'Completed') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.cancel),
                          label: Text('Cancel'),
                          onPressed: () => _showConfirmationDialog(
                            appointment['id'],
                            'Are you sure you want to cancel this appointment?',
                            'cancelled',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFFFF5722),
                            side: BorderSide(color: Color(0xFFFF5722)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    
                    if (appointment['status'] == 'Confirmed') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.done_all),
                          label: Text('Complete'),
                          onPressed: () => _showConfirmationDialog(
                            appointment['id'],
                            'Are you sure you want to mark this appointment as completed?',
                            'completed',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF3366CC),
                            side: BorderSide(color: Color(0xFF3366CC)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.visibility),
                        label: Text('Details'),
                        onPressed: () => _showAppointmentDetails(appointment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3366CC),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        SizedBox(width: 8),
        Text(
          '$label:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
  
  void _showConfirmationDialog(String appointmentId, String message, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Action'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateAppointmentStatus(appointmentId, status);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'cancelled' ? Color(0xFFFF5722) : Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
  
  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          constraints: BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Appointment Details',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 24,
                    tooltip: 'Close',
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildDetailItem('Appointment ID', appointment['id']),
              Divider(),
              _buildDetailItem('Patient', appointment['patientName']),
              _buildDetailItem('Doctor', appointment['doctorName']),
              _buildDetailItem('Specialty', appointment['specialty'] ?? 'Not specified'),
              Divider(),
              _buildDetailItem('Date', appointment['date']),
              _buildDetailItem('Time', appointment['time']),
              _buildDetailItem('Hospital', appointment['hospital']),
              _buildDetailItem('Type', appointment['type'] ?? 'In-person'),
              Divider(),
              _buildDetailItem('Reason', appointment['reason']),
              _buildDetailItem('Fee', appointment['displayAmount'] ?? 'Not specified'),
              _buildDetailItem('Status', appointment['status']),
              _buildDetailItem('Payment Status', appointment['paymentStatus'] ?? 'Not specified'),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3366CC),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
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
} 