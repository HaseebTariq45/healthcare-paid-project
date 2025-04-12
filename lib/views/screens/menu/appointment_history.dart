import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/dashboard/patient_profile_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare/views/screens/appointment/appointment_detail.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Appointment data structure for storing fetched appointments
  final List<Map<String, dynamic>> _appointments = [];
  
  // Pagination variables
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  DocumentSnapshot? _lastDocument;
  final int _appointmentsPerPage = 10;

  // Search query
  String _searchQuery = '';
  String _selectedFilter = 'All';
  
  // Auth and Firestore instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ScrollController for infinite scrolling
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    
    // Initialize scroll controller
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    
    _loadAppointments();
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Scroll listener to detect when user scrolls to bottom
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreAppointments();
    }
  }
  
  // Load more appointments when scrolling
  Future<void> _loadMoreAppointments() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    await _fetchAppointments(isInitialLoad: false);
  }
  
  // Load appointments from Firestore
  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _lastDocument = null;
      _hasMoreData = true;
      _appointments.clear();
    });
    
    await _fetchAppointments(isInitialLoad: true);
  }
  
  // Fetch appointments from Firestore with pagination
  Future<void> _fetchAppointments({required bool isInitialLoad}) async {
    try {
      // Get current user
      final String? userId = _auth.currentUser?.uid;
      
      if (userId == null) {
        setState(() {
          _errorMessage = 'No user logged in';
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }
      
      // Get user role to determine query
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final String userRole = userDoc.data()?['role'] ?? 'patient';
      
      // Create base query depending on user role
      Query query;
      
      if (userRole == 'doctor') {
        // For doctors, find appointments where they are the doctor
        query = _firestore
            .collection('appointments')
            .where('doctorId', isEqualTo: userId)
            .orderBy('createdAt', descending: true);
      } else {
        // For patients, find appointments where they are the patient
        query = _firestore
            .collection('appointments')
            .where('patientId', isEqualTo: userId)
            .orderBy('createdAt', descending: true);
      }
      
      // Apply pagination
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      
      // Limit results
      query = query.limit(_appointmentsPerPage);
      
      // Execute query
      final appointmentsSnapshot = await query.get();
      
      // Update pagination info
      _hasMoreData = appointmentsSnapshot.docs.length >= _appointmentsPerPage;
      
      if (appointmentsSnapshot.docs.isNotEmpty) {
        _lastDocument = appointmentsSnapshot.docs.last;
      }
      
      if (appointmentsSnapshot.docs.isEmpty && isInitialLoad) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }
      
      // Process appointments
      List<Map<String, dynamic>> loadedAppointments = [];
      
      for (var doc in appointmentsSnapshot.docs) {
        final appointmentData = doc.data() as Map<String, dynamic>;
        
        // Get patient details
        String patientName = "Unknown Patient";
        String patientImage = "";
        String patientAge = "";
        String patientLocation = "";
        
        if (appointmentData['patientId'] != null) {
          try {
            final patientDoc = await _firestore
                .collection('users')
                .doc(appointmentData['patientId'])
                .get();
                
            if (patientDoc.exists) {
              final patientData = patientDoc.data() as Map<String, dynamic>;
              patientName = patientData['fullName'] ?? patientData['name'] ?? "Unknown Patient";
              patientImage = patientData['profileImageUrl'] ?? "";
              patientAge = patientData['age'] != null ? "${patientData['age']} Years" : "";
              patientLocation = patientData['city'] ?? patientData['address'] ?? "";
            }
          } catch (e) {
            print('Error fetching patient data: $e');
          }
        }
        
        // Get doctor details
        String doctorName = "Unknown Doctor";
        String doctorSpecialty = "";
        
        if (appointmentData['doctorId'] != null) {
          try {
            final doctorDoc = await _firestore
                .collection('doctors')
                .doc(appointmentData['doctorId'])
                .get();
                
            if (doctorDoc.exists) {
              final doctorData = doctorDoc.data() as Map<String, dynamic>;
              doctorName = doctorData['fullName'] ?? doctorData['name'] ?? "Unknown Doctor";
              doctorSpecialty = doctorData['specialty'] ?? "";
            }
          } catch (e) {
            print('Error fetching doctor data: $e');
          }
        }
        
        // Format appointment date
        String formattedDate = "Unknown Date";
        String formattedTime = "Unknown Time";
        
        if (appointmentData['appointmentDate'] != null && appointmentData['appointmentDate'] is Timestamp) {
          final appointmentDateTime = (appointmentData['appointmentDate'] as Timestamp).toDate();
          formattedDate = "${appointmentDateTime.day} ${_getMonthName(appointmentDateTime.month)} ${appointmentDateTime.year}";
          
          // Format time in 12-hour format
          final hour = appointmentDateTime.hour > 12 ? appointmentDateTime.hour - 12 : appointmentDateTime.hour;
          final period = appointmentDateTime.hour >= 12 ? "PM" : "AM";
          formattedTime = "$hour:${appointmentDateTime.minute.toString().padLeft(2, '0')} $period";
        } else if (appointmentData['date'] != null) {
          // Handle string date format
          formattedDate = appointmentData['date'];
          formattedTime = appointmentData['time'] ?? "Unknown Time";
        }
        
        // Get hospital details
        String hospitalName = appointmentData['hospitalName'] ?? "Unknown Hospital";
        String hospitalLocation = "";
        
        // Format appointment data
        final appointment = {
          "id": doc.id,
          "patientId": appointmentData['patientId'],
          "doctorId": appointmentData['doctorId'],
          "patientName": patientName,
          "patientAge": patientAge,
          "patientLocation": patientLocation,
          "patientImage": patientImage,
          "doctorName": doctorName,
          "doctorSpecialty": doctorSpecialty,
          "condition": appointmentData['reason'] ?? "Consultation",
          "date": formattedDate,
          "time": formattedTime,
          "hospital": hospitalName,
          "reason": appointmentData['reason'] ?? "Consultation",
          "status": appointmentData['status'] ?? "Pending",
          "diagnosis": appointmentData['diagnosis'] ?? "",
          "prescription": appointmentData['prescription'] ?? "",
          "notes": appointmentData['notes'] ?? "",
          "nextVisit": appointmentData['nextVisit'] ?? "",
          "amount": appointmentData['fee'] ?? 0,
          "displayAmount": appointmentData['fee'] != null ? "Rs ${appointmentData['fee']}" : "N/A",
          "type": appointmentData['isPanelConsultation'] == true 
              ? "In-Person Visit" 
              : "Video Consultation",
          "createdAt": appointmentData['createdAt'],
        };
        
        loadedAppointments.add(appointment);
      }
      
      setState(() {
        // Append new data or replace existing data
        if (isInitialLoad) {
          _appointments.clear();
          _appointments.addAll(loadedAppointments);
        } else {
          _appointments.addAll(loadedAppointments);
        }
        
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load appointments: ${e.toString()}';
        _isLoading = false;
        _isLoadingMore = false;
      });
      print('Error loading appointments: $e');
    }
  }
  
  // Helper method to get month name
  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }
  
  // Filter appointments based on search query and selected filter
  List<Map<String, dynamic>> get filteredAppointments {
    List<Map<String, dynamic>> result = _appointments;
    
    // Apply search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((appointment) {
        final patientName = appointment['patientName'].toString().toLowerCase();
        final doctorName = appointment['doctorName'].toString().toLowerCase();
        final hospital = appointment['hospital'].toString().toLowerCase();
        final condition = appointment['condition'].toString().toLowerCase();
        final date = appointment['date'].toString().toLowerCase();
        final status = appointment['status'].toString().toLowerCase();
      
        final query = _searchQuery.toLowerCase();
      
        return patientName.contains(query) || 
               doctorName.contains(query) ||
               hospital.contains(query) ||
               condition.contains(query) ||
               date.contains(query) ||
               status.contains(query);
      }).toList();
    }
  
    // Apply filter
    if (_selectedFilter != 'All') {
      result = result.where((appointment) {
        if (_selectedFilter == 'Consultation') {
          return appointment['type'] == 'Video Consultation';
        } else if (_selectedFilter == 'In-Person') {
          return appointment['type'] == 'In-Person Visit';
        } else if (_selectedFilter == 'Completed') {
          return appointment['status'].toString().toLowerCase() == 'completed';
        } else if (_selectedFilter == 'Upcoming') {
          final status = appointment['status'].toString().toLowerCase();
          return status == 'pending' || status == 'confirmed';
        } else if (_selectedFilter == 'Cancelled') {
          return appointment['status'].toString().toLowerCase() == 'cancelled';
        }
        return true;
      }).toList();
    }
    
    return result;
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
          "Appointments",
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
      body: _isLoading && _appointments.isEmpty
        ? Center(
            child: CircularProgressIndicator(
                color: Color(0xFF3366FF),
            ),
          )
        : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : Column(
              children: [
                // Search and filter section
                _buildSearchAndFilterSection(),
                
                // Results count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Text(
                        "${filteredAppointments.length} appointment${filteredAppointments.length != 1 ? 's' : ''} found",
                        style: GoogleFonts.poppins(
                          color: Color(0xFF666666),
                          fontSize: 14,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFE6F0FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Filter: $_selectedFilter",
                          style: GoogleFonts.poppins(
                            color: Color(0xFF3366FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Appointments list
                Expanded(
                  child: _appointments.isEmpty
                    ? _buildEmptyState()
                    : filteredAppointments.isEmpty
                      ? _buildNoResultsView()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredAppointments.length + (_hasMoreData ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Show loading indicator at the end
                            if (index == filteredAppointments.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Color(0xFF3366FF),
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            // Display appointment card
                            return _buildAppointmentCard(filteredAppointments[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Search bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Color(0xFFEEEEEE)),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search appointments...",
                hintStyle: GoogleFonts.poppins(
                  color: Color(0xFF999999),
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: Color(0xFF999999)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          SizedBox(height: 12),
          
          // Filter buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterButton('All'),
                _buildFilterButton('Upcoming'),
                _buildFilterButton('Completed'),
                _buildFilterButton('Cancelled'),
                _buildFilterButton('Consultation'),
                _buildFilterButton('In-Person'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    final isSelected = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF3366FF) : Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Color(0xFF3366FF) : Color(0xFFEEEEEE),
          ),
        ),
        child: Text(
          filter,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Color(0xFF666666),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    // Determine status color
    Color statusColor = Colors.blue;
    if (appointment['status'].toString().toLowerCase() == 'completed') {
      statusColor = Colors.green;
    } else if (appointment['status'].toString().toLowerCase() == 'cancelled') {
      statusColor = Colors.red;
    } else if (appointment['status'].toString().toLowerCase() == 'pending') {
      statusColor = Colors.orange;
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(
              appointmentDetails: appointment,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: Color(0xFFE0E0E0)),
        ),
        child: Column(
          children: [
            // Appointment header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF5F9FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Patient/Doctor Image
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundImage: appointment['patientImage'] != null && appointment['patientImage'].isNotEmpty 
                          ? NetworkImage(appointment['patientImage']) as ImageProvider
                          : AssetImage("assets/images/User.png"),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  SizedBox(width: 16),
                  // Name and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment['patientName'] ?? "Unknown Patient",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          appointment['condition'] ?? "Consultation",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      appointment['status'] ?? "Pending",
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Appointment details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Date and time row
                  Row(
                    children: [
                      _buildDetailItem(
                        Icons.calendar_today,
                        "Date",
                        appointment['date'] ?? "Unknown",
                      ),
                      SizedBox(width: 16),
                      _buildDetailItem(
                        Icons.access_time,
                        "Time",
                        appointment['time'] ?? "Unknown",
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Hospital and doctor
                  Row(
                    children: [
                      _buildDetailItem(
                        Icons.local_hospital,
                        "Hospital",
                        appointment['hospital'] ?? "Unknown",
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Doctor or appointment type
                  Row(
                    children: [
                      _buildDetailItem(
                        Icons.person,
                        "Doctor",
                        appointment['doctorName'] ?? "Unknown",
                      ),
                      SizedBox(width: 16),
                      _buildDetailItem(
                        Icons.video_call,
                        "Type",
                        appointment['type'] ?? "Consultation",
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // View details button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentDetailsScreen(
                            appointmentDetails: appointment,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Color(0xFF3366FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          "View Details",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Color(0xFF3366FF),
              size: 18,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: Color(0xFFCCDDFF),
          ),
          SizedBox(height: 16),
          Text(
            "No Appointments Yet",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "You don't have any appointments yet. Book an appointment to get started.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Color(0xFFCCDDFF),
          ),
          SizedBox(height: 16),
          Text(
            "No Results Found",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "We couldn't find any appointments matching your search or filter.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
          ),
          SizedBox(height: 20),
          InkWell(
            onTap: () {
              setState(() {
                _searchQuery = '';
                _selectedFilter = 'All';
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                color: Color(0xFF3366FF),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                "Clear Filters",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade300,
          ),
          SizedBox(height: 16),
          Text(
            "Something Went Wrong",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadAppointments,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3366FF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Try Again"),
          ),
        ],
      ),
    );
  }
}
