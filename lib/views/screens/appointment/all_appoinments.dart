import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/appointment/appointment_detail.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _searchQuery = '';
  bool _isShowingUpcoming = true; // Default to showing upcoming appointments
  bool _isLoading = true;
  bool _isRefreshing = false;
  static const String _appointmentsCacheKey = 'all_appointments_cache';
  
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _completedAppointments = [];
  List<Map<String, dynamic>> _filteredAppointments = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    // Load data from cache first, then fetch from Firebase
    _loadData();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    try {
      // First try to load data from cache
      await _loadCachedData();
      
      // Then fetch fresh data from Firebase
      if (mounted) {
        _fetchAppointments();
      }
    } catch (e) {
      print('Error in _loadData: $e');
    }
  }

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString(_appointmentsCacheKey);
      
      if (cachedData != null) {
        final List<dynamic> decoded = json.decode(cachedData);
        final List<Map<String, dynamic>> appointments = 
            List<Map<String, dynamic>>.from(decoded);
        
        _processAppointments(appointments);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }
  
  // Fetch appointment data from Firebase
  Future<void> _fetchAppointments() async {
    if (!mounted) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId == null) {
        setState(() {
          _isRefreshing = false;
          _isLoading = false;
        });
        return;
      }
      
      print('Fetching appointments for user: $userId');
      
      // Query appointments collection
      final QuerySnapshot appointmentsSnapshot = await firestore
          .collection('appointments')
          .where('patientId', isEqualTo: userId)
          .get();
      
      print('Found ${appointmentsSnapshot.docs.length} appointments in database');
      
      List<Map<String, dynamic>> appointments = [];
      
      for (var doc in appointmentsSnapshot.docs) {
        try {
          Map<String, dynamic> appointment = doc.data() as Map<String, dynamic>;
          appointment['id'] = doc.id;
          
          // Fetch doctor details for this appointment
          if (appointment['doctorId'] != null) {
            final doctorDoc = await firestore
                .collection('doctors')
                .doc(appointment['doctorId'].toString())
                .get();
            
            if (doctorDoc.exists) {
              final doctorData = doctorDoc.data() as Map<String, dynamic>;
              // Merge doctor data into appointment
              appointment['doctorName'] = doctorData['fullName'] ?? doctorData['name'] ?? 'Doctor';
              appointment['specialty'] = doctorData['specialty'] ?? 'Specialist';
              appointment['doctorImage'] = doctorData['profileImageUrl'];
            }
          }

          // Ensure all required fields exist
          appointment = {
            ...appointment,
            'date': appointment['date'] ?? DateTime.now().toString().split(' ')[0],
            'time': appointment['time'] ?? '00:00',
            'status': appointment['status']?.toString().toLowerCase() ?? 'upcoming',
            'doctorName': appointment['doctorName'] ?? 'Doctor',
            'specialty': appointment['specialty'] ?? 'Specialist',
            'hospitalName': appointment['hospitalName'] ?? 'Hospital',
            'type': appointment['type'] ?? 'Consultation',
            'doctorImage': appointment['doctorImage'] ?? 'assets/images/doctor1.png',
          };

          print('Processing appointment: ${appointment['id']} for ${appointment['doctorName']} on ${appointment['date']} at ${appointment['time']}');
          appointments.add(appointment);
        } catch (e) {
          print('Error processing individual appointment: $e');
        }
      }

      // Save to cache
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_appointmentsCacheKey, json.encode(appointments));
        } catch (e) {
        print('Error saving to cache: $e');
      }

      if (!mounted) return;

      print('Successfully processed ${appointments.length} appointments');
      _processAppointments(appointments);
      
    } catch (e) {
      print('Error fetching appointments: $e');
      if (mounted) {
      setState(() {
          _isRefreshing = false;
        _isLoading = false;
      });
      }
    }
  }
  
  void _processAppointments(List<Map<String, dynamic>> appointments) {
    if (!mounted) return;
    
    // Clear existing lists
    _upcomingAppointments.clear();
    _completedAppointments.clear();
    
    // Get current date and time
    final DateTime now = DateTime.now();
    
    // Process each appointment
    for (var appointment in appointments) {
      try {
        // Get appointment date and time
        final String dateStr = appointment['date']?.toString() ?? '';
        final String timeStr = appointment['time']?.toString() ?? '';
        
        DateTime? appointmentDateTime;
        
        // Try to parse date and time
        try {
          if (dateStr.contains('/')) {
            // Parse dd/MM/yyyy format
            final parts = dateStr.split('/');
            if (parts.length == 3) {
              appointmentDateTime = DateTime(
                int.parse(parts[2]),  // year
                int.parse(parts[1]),  // month
                int.parse(parts[0]),  // day
              );
            }
          } else {
            // Try parsing ISO format
            appointmentDateTime = DateTime.parse(dateStr);
          }

          // Add time if available
          if (appointmentDateTime != null && timeStr.isNotEmpty) {
            // Clean up time string and handle AM/PM
            String cleanTime = timeStr.toUpperCase().trim();
            bool isPM = cleanTime.contains('PM');
            cleanTime = cleanTime.replaceAll('AM', '').replaceAll('PM', '').trim();
            
            final timeParts = cleanTime.split(':');
            if (timeParts.length >= 2) {
              int hour = int.parse(timeParts[0]);
              int minute = int.parse(timeParts[1]);
        
        // Convert to 24-hour format if PM
        if (isPM && hour < 12) {
          hour += 12;
              }
              // Handle 12 AM case
              if (!isPM && hour == 12) {
          hour = 0;
        }
        
              appointmentDateTime = DateTime(
                appointmentDateTime.year,
                appointmentDateTime.month,
                appointmentDateTime.day,
                hour,
                minute,
              );
            }
      }
    } catch (e) {
          print('Error parsing date/time for appointment: $e');
          print('Date string: $dateStr');
          print('Time string: $timeStr');
        }

        // Determine appointment status based on date/time
        if (appointmentDateTime != null) {
          print('Comparing appointment date: ${appointmentDateTime} with now: ${now}');
          if (appointmentDateTime.isAfter(now)) {
            print('Adding to upcoming: ${appointment['id']}');
            _upcomingAppointments.add(appointment);
          } else {
            print('Adding to completed: ${appointment['id']}');
            _completedAppointments.add(appointment);
          }
        } else {
          // Fallback to status if date parsing fails
          final String status = appointment['status']?.toString().toLowerCase() ?? '';
          if (status == 'upcoming' || status == 'pending' || status == 'confirmed') {
            _upcomingAppointments.add(appointment);
          } else {
            _completedAppointments.add(appointment);
          }
        }
      } catch (e) {
        print('Error processing appointment ${appointment['id']}: $e');
      }
    }
    
    print('Processed ${appointments.length} appointments:');
    print('Upcoming: ${_upcomingAppointments.length}');
    print('Completed: ${_completedAppointments.length}');
    
    setState(() {
      _appointments = appointments;
      _filterAppointments();
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  Future<void> _onRefresh() async {
    await _fetchAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _showExitConfirmationDialog(context)) {
          print('***** BACK BUTTON PRESSED - NAVIGATING TO PATIENT BOTTOM NAVIGATION *****');
          Navigator.of(context).pushNamedAndRemoveUntil('/patient/bottom_navigation', (route) => false);
        }
        return false;
      },
      child: Scaffold(
      backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (await _showExitConfirmationDialog(context)) {
                print('***** BACK BUTTON PRESSED - NAVIGATING TO PATIENT BOTTOM NAVIGATION *****');
                Navigator.of(context).pushNamedAndRemoveUntil('/patient/bottom_navigation', (route) => false);
              }
            },
          ),
          title: Text(
            "My Appointments",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
        children: [
            Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildSearchBar(),
                ),
                
                // Toggle buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F7FF),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isShowingUpcoming = true;
                                _filterAppointments();
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _isShowingUpcoming
                                    ? Color(0xFF3366CC)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                "Upcoming",
                                style: GoogleFonts.poppins(
                                  color: _isShowingUpcoming
                                      ? Colors.white
                                      : Color(0xFF3366CC),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  ),
                                ),
                              ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isShowingUpcoming = false;
                                _filterAppointments();
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !_isShowingUpcoming
                                    ? Color(0xFF3366CC)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                "Completed",
                                style: GoogleFonts.poppins(
                                  color: !_isShowingUpcoming
                                      ? Colors.white
                                      : Color(0xFF3366CC),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ),
                ),
              ],
            ),
          ),
                ),
                
                // Appointment list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: _buildAppointmentList(
                      _filteredAppointments,
                      _isShowingUpcoming ? "upcoming" : "completed"
                    ),
                  ),
                ),
              ],
            ),
            
            // Loading indicator at bottom
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
      ),
    );
  }

  Widget _buildAppointmentList(List<Map<String, dynamic>> appointments, String status) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3366CC)),
        ),
      );
    }
    
    if (appointments.isEmpty) {
      return _buildNoAppointmentsFound(status);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                0.1 + (index * 0.1 > 0.5 ? 0.5 : index * 0.1),
                0.6 + (index * 0.1 > 0.5 ? 0.5 : index * 0.1),
                curve: Curves.easeOut,
              ),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, 0.2),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  0.1 + (index * 0.1 > 0.5 ? 0.5 : index * 0.1),
                  0.6 + (index * 0.1 > 0.5 ? 0.5 : index * 0.1),
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: _buildAppointmentCard(
              context,
              appointments[index],
              index,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterAppointments();
          });
        },
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: "Search appointments",
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            color: Color.fromRGBO(64, 124, 226, 1),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _filterAppointments();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildNoAppointmentsFound(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.calendar,
            size: 60,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 20),
          Text(
            "No appointments found",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            _searchQuery.isNotEmpty
                ? "Try a different search term"
                : "You don't have any appointments yet",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Map<String, dynamic> appointment, int index) {
    final String statusText = appointment['status']?.toString().toLowerCase() ?? 'upcoming';
    final bool isUpcoming = _isShowingUpcoming; // Use the current tab state instead of status
    final bool isCancelled = statusText == 'cancelled';
    final bool isCompleted = !isUpcoming && !isCancelled;
    
    final Color statusColor = isCancelled
        ? Color(0xFFF44336)
        : isUpcoming
            ? Color.fromRGBO(64, 124, 226, 1)
            : Color(0xFF4CAF50);
            
    final String displayStatus = isCancelled
        ? "Cancelled"
        : isUpcoming
            ? "Upcoming"
            : "Completed";
    
    final String doctorName = appointment['doctorName']?.toString() ?? 'Doctor';
    final String specialty = appointment['specialty']?.toString() ?? 'Specialist';
    final String date = appointment['date']?.toString() ?? 'No date';
    final String time = appointment['time']?.toString() ?? 'No time';
    final String hospitalName = appointment['hospitalName']?.toString() ?? 'Hospital';
    final String appointmentType = appointment['type']?.toString() ?? 'Consultation';
    
    // Check if appointment has been reviewed
    final bool hasReview = appointment['isRated'] == true;
    
    // Only show review options for appointments in the completed tab
    final bool canReview = !_isShowingUpcoming && !isCancelled && !hasReview;
    
    return Container(
      margin: EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey.shade200,
                    child: Icon(
                      LucideIcons.user,
                      color: Colors.grey,
                      size: 22,
                    ),
                    foregroundImage: _getDoctorImageSafely(appointment),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        specialty,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    displayStatus,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildAppointmentDetail(
                      LucideIcons.calendar,
                      "Date",
                      date,
                    ),
                    SizedBox(width: 15),
                    _buildAppointmentDetail(
                      LucideIcons.clock,
                      "Time",
                      time,
                    ),
                  ],
                ),
                SizedBox(height: 18),
                Row(
                  children: [
                    _buildAppointmentDetail(
                      LucideIcons.building2,
                      "Hospital",
                      hospitalName,
                    ),
                    SizedBox(width: 15),
                    _buildAppointmentDetail(
                      LucideIcons.tag,
                      "Appointment Type",
                      appointmentType,
                    ),
                  ],
                ),
                
                // If cancelled, show reason
                if (isCancelled && appointment['cancellationReason'] != null) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.info,
                          color: Colors.red.shade400,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appointment['cancellationReason']?.toString() ?? 'Cancelled by user',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: 16),
                
                // Action buttons row
                Row(
                        children: [
                          Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AppointmentDetailsScreen(
                                      appointmentDetails: appointment,
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          shadowColor: statusColor.withOpacity(0.3),
                        ),
                        icon: Icon(LucideIcons.clipboardList, size: 18),
                        label: Text(
                              "View Details",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    
                    // Add Review button for completed appointments that haven't been reviewed
                    if (canReview) ...[
                            SizedBox(width: 12),
                            Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showRatingDialog(context, appointment),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFFB300),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            shadowColor: Color(0xFFFFB300).withOpacity(0.3),
                          ),
                          icon: Icon(LucideIcons.star, size: 18),
                          label: Text(
                            "Add Review",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    // Show rating if review exists
                    if (!_isShowingUpcoming && hasReview) ...[
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFFFB300).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                LucideIcons.star,
                              size: 16,
                              color: Color(0xFFFFB300),
                            ),
                            SizedBox(width: 4),
                            Text(
                              "${appointment['userRating']?.toString() ?? '0'}/5",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFFB300),
                              ),
                            ),
                          ],
                              ),
                            ),
                          ],
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppointmentDetail(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color.fromRGBO(64, 124, 226, 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Color.fromRGBO(64, 124, 226, 1),
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
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        shadowColor: color.withOpacity(0.3),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, Map<String, dynamic> appointment) {
    double _rating = appointment['userRating']?.toDouble() ?? 0;
    TextEditingController _feedbackController = TextEditingController();
    _feedbackController.text = appointment['userFeedback'] ?? '';
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFF8E1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.star,
                        size: 35,
                        color: Color(0xFFFFB300),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Rate Your Experience",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "How was your appointment with Dr. ${appointment['doctorName'].split(' ').last}?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: index < _rating ? Color(0xFFFFB300) : Colors.grey,
                            size: 36,
                          ),
                          onPressed: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      child: TextField(
                        controller: _feedbackController,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Share your feedback (optional)",
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting 
                                ? null 
                                : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFF666666),
                              side: BorderSide(color: Color(0xFFE0E0E0)),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting || _rating == 0
                                ? null
                                : () async {
                                    setState(() {
                                      _isSubmitting = true;
                                    });
                                    
                                    await _submitRating(
                                      appointment['id'],
                                      appointment['doctorName'],
                                      _rating,
                                      _feedbackController.text,
                                    );
                                    
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF1E74FD),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: Color(0xFFBDBDBD),
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "Submit",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Future<void> _submitRating(
    String appointmentId, 
    String doctorName,
    double rating, 
    String feedback
  ) async {
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      final userId = auth.currentUser?.uid;
      
      if (userId == null) return;
      
      // Get appointment document
      final appointmentDoc = await firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      
      if (!appointmentDoc.exists) {
        print('Appointment document not found');
        return;
      }
      
      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      final doctorId = appointmentData['doctorId'];
      
      if (doctorId == null) {
        print('Doctor ID not found in appointment');
        return;
      }
      
      // Create review document in doctor_reviews collection
      await firestore.collection('doctor_reviews').add({
        'appointmentId': appointmentId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'feedback': feedback,
        'patientId': userId,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update appointment with rating status
      await firestore.collection('appointments').doc(appointmentId).update({
        'userRating': rating,
        'userFeedback': feedback,
        'isRated': true,
        'ratingTimestamp': FieldValue.serverTimestamp(),
      });
      
      // Update local state
      if (mounted) {
        setState(() {
          for (var appointment in _appointments) {
            if (appointment['id'] == appointmentId) {
              appointment['userRating'] = rating;
              appointment['userFeedback'] = feedback;
              appointment['isRated'] = true;
              break;
            }
          }
          _filterAppointments();
        });
      }
      
      print('Review submitted successfully');
    } catch (e) {
      print('Error submitting review: $e');
      throw e;
    }
  }

  void _filterAppointments() {
    if (!mounted) return;
    
    setState(() {
      final List<Map<String, dynamic>> sourceList = 
          _isShowingUpcoming ? _upcomingAppointments : _completedAppointments;
      
      if (_searchQuery.isEmpty) {
        _filteredAppointments = List.from(sourceList);
        return;
      }
      
      // Apply search filter
      _filteredAppointments = sourceList.where((appointment) {
        final searchLower = _searchQuery.toLowerCase();
        final nameMatch = appointment['doctorName']?.toString().toLowerCase().contains(searchLower) ?? false;
        final dateMatch = appointment['date']?.toString().toLowerCase().contains(searchLower) ?? false;
        final typeMatch = appointment['type']?.toString().toLowerCase().contains(searchLower) ?? false;
        final hospitalMatch = appointment['hospitalName']?.toString().toLowerCase().contains(searchLower) ?? false;
        return nameMatch || dateMatch || typeMatch || hospitalMatch;
      }).toList();
    });
  }

  // Helper method to handle doctor image safely
  ImageProvider? _getDoctorImageSafely(Map<String, dynamic> appointment) {
    try {
      final String? imageUrl = appointment['doctorImage']?.toString();
      if (imageUrl == null || imageUrl.isEmpty) {
        return null;
      }
      
      if (imageUrl.startsWith('assets/')) {
        return AssetImage(imageUrl);
      } else {
        return NetworkImage(imageUrl);
      }
    } catch (e) {
      print('Error loading doctor image: $e');
      return null;
    }
  }

  // Add exit confirmation dialog
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Exit Appointments Screen',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to exit?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Yes, Exit',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }
}
