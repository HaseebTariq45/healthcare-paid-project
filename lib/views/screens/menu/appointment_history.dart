import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/dashboard/patient_profile_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _errorMessage = '';
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache key for appointments
  static const String _appointmentsCacheKey = 'doctor_appointments_cache';
  
  // Appointment data structure 
  final List<Map<String, dynamic>> _completedAppointments = [];

  // Search query
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }
  
  // Load appointments from Firestore with caching
  Future<void> _loadAppointments() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Load from cache first (for instant display)
      await _loadCachedAppointments();
      
      // Then fetch fresh data from Firestore
      if (mounted) {
        setState(() {
          _isRefreshing = true;
        });
      }
      
      await _fetchAppointmentsFromFirestore();
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load appointments: ${e.toString()}';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
      print('Error loading appointments: $e');
    }
  }
  
  // Load appointments from local cache
  Future<void> _loadCachedAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_appointmentsCacheKey);
      
      if (cachedData != null) {
        final List<dynamic> decodedData = json.decode(cachedData);
        final List<Map<String, dynamic>> appointments = 
            List<Map<String, dynamic>>.from(decodedData);
            
        if (mounted) {
      setState(() {
        _completedAppointments.clear();
            _completedAppointments.addAll(appointments);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading cached appointments: $e');
      // Continue silently - we'll try to load from Firestore
    }
  }
  
  // Fetch appointments from Firestore
  Future<void> _fetchAppointmentsFromFirestore() async {
    try {
      final String? doctorId = _auth.currentUser?.uid;
      
      if (doctorId == null) {
        throw Exception('User not authenticated');
      }
      
      // Query appointments collection for this doctor
      final QuerySnapshot appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('date', descending: true)
          .get();
      
      final List<Map<String, dynamic>> appointments = [];
      
      // Process each appointment document
      for (var doc in appointmentsSnapshot.docs) {
        try {
          Map<String, dynamic> appointment = doc.data() as Map<String, dynamic>;
          appointment['id'] = doc.id;
          
          // Fetch patient details
          if (appointment['patientId'] != null) {
            final patientDoc = await _firestore
                .collection('patients')
                .doc(appointment['patientId'].toString())
                .get();
            
            if (patientDoc.exists) {
              final patientData = patientDoc.data() as Map<String, dynamic>;
              
              // Merge patient data with appointment
              appointment['patientName'] = patientData['fullName'] ?? patientData['name'] ?? 'Patient';
              appointment['patientAge'] = patientData['age'] != null ? "${patientData['age']} Years" : "Unknown";
              appointment['patientLocation'] = patientData['location'] ?? patientData['address'] ?? 'Unknown';
              appointment['patientImage'] = patientData['profileImageUrl'] ?? 'assets/images/User.png';
            } else {
              // Fallback if patient doc doesn't exist
              appointment['patientName'] = 'Patient';
              appointment['patientAge'] = 'Unknown';
              appointment['patientLocation'] = 'Unknown';
              appointment['patientImage'] = 'assets/images/User.png';
            }
          }
          
          // Add default values if any field is missing
          appointment = {
            ...appointment,
            'date': appointment['date'] ?? DateTime.now().toString().split(' ')[0],
            'time': appointment['time'] ?? '00:00',
            'reason': appointment['reason'] ?? 'Consultation',
            'hospital': appointment['hospital'] ?? appointment['hospitalName'] ?? 'Hospital',
            'type': appointment['type'] ?? 'In-Person Visit',
            'status': appointment['status'] ?? 'Completed',
          };
          
          // Add fields without default values (will be checked before display)
          if (!appointment.containsKey('diagnosis')) {
            appointment['diagnosis'] = null;
          }
          
          if (!appointment.containsKey('prescription')) {
            appointment['prescription'] = null;
          }
          
          if (!appointment.containsKey('notes')) {
            appointment['notes'] = null;
          }
          
          // Add the appointment with patient details
          appointments.add(appointment);
        } catch (e) {
          print('Error processing appointment ${doc.id}: $e');
        }
      }
      
      // Save to cache
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_appointmentsCacheKey, json.encode(appointments));
      } catch (e) {
        print('Error saving appointments to cache: $e');
      }
      
      if (mounted) {
        setState(() {
          _completedAppointments.clear();
          _completedAppointments.addAll(appointments);
        _isLoading = false;
          _isRefreshing = false;
      });
      }
    } catch (e) {
      if (mounted) {
      setState(() {
          _errorMessage = 'Failed to fetch appointments: ${e.toString()}';
          _isRefreshing = false;
          if (_completedAppointments.isEmpty) {
        _isLoading = false;
          }
      });
      }
      print('Error fetching appointments from Firestore: $e');
    }
  }
  
  // Filter appointments based on search query and selected filter
  List<Map<String, dynamic>> get filteredAppointments {
    List<Map<String, dynamic>> result = _completedAppointments;
    
    // Apply search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((appointment) {
        final patientName = appointment['patientName']?.toString().toLowerCase() ?? '';
        final hospital = appointment['hospital']?.toString().toLowerCase() ?? '';
        final diagnosis = appointment['diagnosis']?.toString().toLowerCase() ?? '';
        final date = appointment['date']?.toString().toLowerCase() ?? '';
      
      final query = _searchQuery.toLowerCase();
      
        return patientName.contains(query) || 
               hospital.contains(query) ||
               diagnosis.contains(query) ||
             date.contains(query);
    }).toList();
  }
  
    // Apply filter
    if (_selectedFilter != 'All') {
      final now = DateTime.now();
      
      result = result.where((appointment) {
        // Get appointment date
        final String dateStr = appointment['date']?.toString() ?? '';
        final String timeStr = appointment['time']?.toString() ?? '';
        
        // Parse the appointment date
        DateTime? appointmentDateTime = _parseAppointmentDateTime(dateStr, timeStr);
        
        if (_selectedFilter == 'Upcoming') {
          // If we couldn't parse the date, check the status
          if (appointmentDateTime == null) {
            final status = appointment['status']?.toString().toLowerCase() ?? '';
            return status == 'upcoming' || status == 'scheduled' || status == 'confirmed' || status == 'pending';
          }
          
          // Check if appointment is in the future
          return appointmentDateTime.isAfter(now);
        } else if (_selectedFilter == 'Completed') {
          // If we couldn't parse the date, check the status
          if (appointmentDateTime == null) {
            final status = appointment['status']?.toString().toLowerCase() ?? '';
            return status == 'completed' || status == 'done' || status == 'cancelled';
          }
          
          // Check if appointment is in the past
          return appointmentDateTime.isBefore(now);
        }
        
        return true;
      }).toList();
    }
    
    return result;
  }
  
  // Helper to parse appointment date and time
  DateTime? _parseAppointmentDateTime(String dateStr, String timeStr) {
    if (dateStr.isEmpty) return null;
    
    try {
      DateTime? appointmentDate;
      
      // Try to parse date in different formats
      if (dateStr.contains('/')) {
        // Format: dd/MM/yyyy
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          appointmentDate = DateTime(
            int.parse(parts[2]),  // year
            int.parse(parts[1]),  // month
            int.parse(parts[0]),  // day
          );
        }
      } else if (dateStr.contains('-')) {
        // Format: yyyy-MM-dd
        appointmentDate = DateTime.parse(dateStr);
      } else {
        // Try to parse as text date (e.g., "15 Oct 2023")
        final months = {
          'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
          'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
        };
        
        final parts = dateStr.split(' ');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = months[parts[1].toLowerCase().substring(0, 3)] ?? 1;
          final year = int.parse(parts[2]);
          
          appointmentDate = DateTime(year, month, day);
        }
      }
      
      // Add time if available
      if (appointmentDate != null && timeStr.isNotEmpty) {
        // Clean up time string
        String cleanTime = timeStr.toUpperCase().trim();
        bool isPM = cleanTime.contains('PM');
        cleanTime = cleanTime.replaceAll('AM', '').replaceAll('PM', '').trim();
        
        final timeParts = cleanTime.split(':');
        if (timeParts.length >= 2) {
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          
          // Convert to 24-hour format
          if (isPM && hour < 12) {
            hour += 12;
          }
          if (!isPM && hour == 12) {
            hour = 0;
          }
          
          appointmentDate = DateTime(
            appointmentDate.year,
            appointmentDate.month,
            appointmentDate.day,
            hour,
            minute,
          );
        }
      }
      
      return appointmentDate;
    } catch (e) {
      print('Error parsing appointment date/time: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF333333), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Appointments History",
          style: GoogleFonts.poppins(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF3366FF), size: 22),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: _isLoading 
        ? Center(
            child: CircularProgressIndicator(
                color: Color(0xFF3366FF),
            ),
          )
        : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : Stack(
              children: [
                Column(
              children: [
                // Search and filter section
                _buildSearchAndFilterSection(),
                
                // Results count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        "${filteredAppointments.length} ${filteredAppointments.length == 1 ? 'result' : 'results'}",
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Text(
                            _selectedFilter != 'All' ? _selectedFilter : "Appointments history",
                        style: GoogleFonts.poppins(
                        fontSize: 14,
                              color: _selectedFilter == 'Upcoming' 
                                  ? Color(0xFF3366CC) 
                                  : _selectedFilter == 'Completed'
                                    ? Colors.green.shade700
                                    : Color(0xFF3366CC),
                          fontWeight: FontWeight.w500,
                    ),
                  ),
                    ],
                ),
                ),
                
                // Appointment list
                Expanded(
                  child: filteredAppointments.isEmpty
                    ? _buildEmptyView()
                    : _buildAppointmentsList(),
                    ),
                  ],
                ),
                
                // Loading indicator when refreshing
                if (_isRefreshing)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF3366CC),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Refreshing appointments...",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search by patient, condition, or location",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 18, color: Colors.grey.shade600),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              ),
            ),
          ),
          
          SizedBox(height: 15),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                SizedBox(width: 10),
                _buildFilterChip('Upcoming'),
                SizedBox(width: 10),
                _buildFilterChip('Completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF3366FF).withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF3366FF) : Colors.grey.shade300,
            ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Color(0xFF3366FF) : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
            Icons.assignment,
            size: 70,
            color: Colors.grey.shade300,
                  ),
          SizedBox(height: 20),
                  Text(
            "No appointments found",
                    style: GoogleFonts.poppins(
              fontSize: 18,
                      fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
                    ),
                  ),
          SizedBox(height: 10),
                  Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
              _searchQuery.isNotEmpty
                ? "No results matching \"$_searchQuery\""
                : "Your appointments will appear here",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                color: Colors.grey.shade500,
                      ),
                    ),
                  ),
          SizedBox(height: 30),
          if (_searchQuery.isNotEmpty)
                  ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'All';
                });
              },
              icon: Icon(Icons.refresh, size: 18),
                    label: Text(
                "Clear filters",
                style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3366FF),
                      foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
            Icons.error_outline,
            size: 70,
            color: Colors.amber,
                ),
          SizedBox(height: 20),
                Text(
            "Error Loading Appointments",
                  style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
                  ),
                ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                color: Colors.grey.shade600,
              ),
                    ),
                  ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _loadAppointments,
            icon: Icon(Icons.refresh, size: 18),
            label: Text(
              "Try Again",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3366FF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppointmentsList() {
    return ListView.builder(
              padding: EdgeInsets.all(20),
      itemCount: filteredAppointments.length,
              itemBuilder: (context, index) {
        final appointment = filteredAppointments[index];
        return _buildAppointmentCard(appointment, index);
              },
          );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Patient info header
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Color(0xFFF5F7FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      appointment['patientImage'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 15),
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
                      ),
                      SizedBox(height: 2),
                      Text(
                        "${appointment['patientAge']} • ${appointment['patientLocation']}",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status indicator
                    _buildStatusIndicator(appointment),
                    SizedBox(height: 5),
                    // Patient profile button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailProfileScreen(
                              name: appointment['patientName'] ?? 'Patient',
                              age: _extractAge(appointment['patientAge']),
                              bloodGroup: appointment['bloodGroup'] ?? "Not Available",
                              diseases: [appointment['diagnosis'] ?? 'Not specified'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Color(0xFF3366CC).withOpacity(0.1),
                      shape: BoxShape.circle,
                  ),
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF3366CC),
                      size: 16,
                    ),
                  ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Appointment details
          Padding(
            padding: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date, time and type row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                  children: [
                    _buildInfoTag(
                      Icons.calendar_today,
                      appointment['date'],
                      Colors.blue.shade700,
                    ),
                    SizedBox(width: 10),
                    _buildInfoTag(
                      Icons.access_time,
                      appointment['time'],
                      Colors.orange.shade700,
                    ),
                    SizedBox(width: 10),
                    _buildInfoTag(
                      appointment['type'] == 'Video Consultation' 
                          ? Icons.videocam
                          : Icons.medical_services,
                      appointment['type'],
                      appointment['type'] == 'Video Consultation'
                          ? Colors.purple.shade700
                          : Colors.green.shade700,
                    ),
                  ],
                  ),
                ),
                
                SizedBox(height: 15),
                
                // Facility and reason
                _buildDetailRow(
                  "Facility",
                  appointment['hospital'],
                  Icons.business,
                ),
                SizedBox(height: 10),
                _buildDetailRow(
                  "Reason",
                  appointment['reason'],
                  Icons.assignment,
                ),
                
                // Display any additional appointment details from Firestore
                ..._buildAdditionalDetails(appointment),
                
                // Only show diagnosis if available
                if (appointment.containsKey('diagnosis') && 
                    appointment['diagnosis'] != null && 
                    appointment['diagnosis'].toString().isNotEmpty &&
                    appointment['diagnosis'] != 'Not provided')
                  Column(
                    children: [
                SizedBox(height: 10),
                _buildDetailRow(
                  "Diagnosis",
                  appointment['diagnosis'],
                  Icons.medical_services,
                ),
                    ],
                  ),
                
                // Only show prescription if available
                if (appointment.containsKey('prescription') && 
                    appointment['prescription'] != null && 
                    appointment['prescription'].toString().isNotEmpty &&
                    appointment['prescription'] != 'Not provided')
                  Column(
                    children: [
                SizedBox(height: 10),
                _buildDetailRow(
                  "Prescription",
                  appointment['prescription'],
                  Icons.medication,
                      ),
                    ],
                ),
                
                SizedBox(height: 15),
                
                // Clinical notes - only show if available
                if (appointment.containsKey('notes') && 
                    appointment['notes'] != null && 
                    appointment['notes'].toString().isNotEmpty &&
                    appointment['notes'] != 'No clinical notes available')
                  Column(
                    children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      Text(
                        "Clinical Notes",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        appointment['notes'],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                          ),
                  ],
                ),
                      ),
                      SizedBox(height: 15),
                    ],
                ),
                
                SizedBox(height: 15),
                
                // Bottom row: Fee only
                Row(
                  children: [
                    Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          "Consultation Fee",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                        ),
                        Text(
                          _formatAmount(appointment),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3366CC),
                          ),
                        ),
                      ],
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

  Widget _buildInfoTag(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
          ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
        ),
          SizedBox(width: 5),
              Text(
            text,
                style: GoogleFonts.poppins(
              fontSize: 12,
                  fontWeight: FontWeight.w500,
              color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
        padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
            color: Color(0xFF3366CC).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
            size: 16,
            color: Color(0xFF3366CC),
          ),
      ),
        SizedBox(width: 10),
        Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
              ),
            ),
            Text(
                value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
              ),
            ),
            ],
              ),
            ),
          ],
    );
  }

  // Format the amount based on available data in the appointment
  String _formatAmount(Map<String, dynamic> appointment) {
    // Check for pre-formatted displayAmount
    if (appointment.containsKey('displayAmount') && appointment['displayAmount'] != null) {
      return appointment['displayAmount'].toString();
    }
    
    // Check for numeric amount
    if (appointment.containsKey('amount') && appointment['amount'] != null) {
      final amount = appointment['amount'];
      
      // Handle both numeric and string values
      try {
        final double numericAmount = amount is num 
            ? amount.toDouble() 
            : double.parse(amount.toString());
        
        return 'Rs ${numericAmount.toStringAsFixed(2)}';
      } catch (e) {
        print('Error formatting amount: $e');
      }
    }
    
    // Check for fee field
    if (appointment.containsKey('fee') && appointment['fee'] != null) {
      final fee = appointment['fee'];
      
      try {
        final double numericFee = fee is num 
            ? fee.toDouble() 
            : double.parse(fee.toString());
        
        return 'Rs ${numericFee.toStringAsFixed(2)}';
      } catch (e) {
        print('Error formatting fee: $e');
      }
    }
    
    // Fallback if no amount or fee is available
    return 'Rs 0.00';
  }

  String _extractAge(String age) {
    if (age.contains('Years')) {
      return age.split(' ')[0];
    } else if (age.contains('Age')) {
      return age.split(' ')[0];
    } else if (age.contains('years')) {
      return age.split(' ')[0];
    } else if (age.contains('age')) {
      return age.split(' ')[0];
    } else {
      return 'Unknown';
    }
  }

  List<Widget> _buildAdditionalDetails(Map<String, dynamic> appointment) {
    final List<Widget> widgets = [];
    
    // Common additional fields in medical appointments
    final Map<String, Map<String, dynamic>> additionalFields = {
      'symptoms': {
        'label': 'Symptoms',
        'icon': Icons.sick,
      },
      'treatmentPlan': {
        'label': 'Treatment Plan',
        'icon': Icons.healing,
      },
      'followUpInstructions': {
        'label': 'Follow-up Instructions',
        'icon': Icons.event_note,
      },
      'vitals': {
        'label': 'Vitals',
        'icon': Icons.favorite,
      },
      'labResults': {
        'label': 'Lab Results',
        'icon': Icons.science,
      },
      'allergies': {
        'label': 'Allergies',
        'icon': Icons.warning,
      },
      'medications': {
        'label': 'Medications',
        'icon': Icons.medication,
      },
      'condition': {
        'label': 'Condition',
        'icon': Icons.health_and_safety,
      },
    };
    
    // Check each field and add it if it exists in the appointment data
    additionalFields.forEach((key, value) {
      if (appointment.containsKey(key) && 
          appointment[key] != null && 
          appointment[key].toString().isNotEmpty) {
        widgets.add(
          Column(
            children: [
              SizedBox(height: 10),
              _buildDetailRow(
                value['label'],
                appointment[key].toString(),
                value['icon'],
              ),
            ],
          ),
        );
      }
    });
    
    // Check for any custom fields (prefixed with 'custom_')
    appointment.keys.where((key) => 
      key.startsWith('custom_') && 
      appointment[key] != null && 
      appointment[key].toString().isNotEmpty
    ).forEach((key) {
      final String label = key.replaceFirst('custom_', '').split('_').map(
        (word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
      ).join(' ');
      
      widgets.add(
        Column(
          children: [
            SizedBox(height: 10),
            _buildDetailRow(
              label,
              appointment[key].toString(),
              Icons.info_outline,
            ),
          ],
        ),
      );
    });
    
    return widgets;
  }

  Widget _buildStatusIndicator(Map<String, dynamic> appointment) {
    final String status = appointment['status']?.toString().toLowerCase() ?? '';
    final now = DateTime.now();
    final dateStr = appointment['date']?.toString() ?? '';
    final timeStr = appointment['time']?.toString() ?? '';
    DateTime? appointmentDateTime = _parseAppointmentDateTime(dateStr, timeStr);
    
    String displayStatus = "Unknown";
    Color statusColor = Colors.grey;
    
    // Determine status and color based on date comparison and status field
    if (appointmentDateTime != null) {
      if (appointmentDateTime.isAfter(now)) {
        displayStatus = "Upcoming";
        statusColor = Color(0xFF3366CC);
      } else {
        if (status == 'cancelled') {
          displayStatus = "Cancelled";
          statusColor = Colors.red.shade700;
        } else {
          displayStatus = "Completed";
          statusColor = Colors.green.shade700;
        }
      }
    } else {
      // Fallback to status text if date can't be parsed
      if (status == 'upcoming' || status == 'scheduled' || status == 'confirmed' || status == 'pending') {
        displayStatus = "Upcoming";
        statusColor = Color(0xFF3366CC);
      } else if (status == 'cancelled') {
        displayStatus = "Cancelled";
        statusColor = Colors.red.shade700;
      } else if (status == 'completed' || status == 'done') {
        displayStatus = "Completed";
        statusColor = Colors.green.shade700;
      }
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        displayStatus,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }
}
