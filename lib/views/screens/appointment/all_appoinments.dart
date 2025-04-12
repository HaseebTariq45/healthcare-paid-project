import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/appointment/appointment_detail.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _searchQuery = '';
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  
  final List<String> _tabs = ["Upcoming", "Past", "Cancelled"];
  
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _filteredAppointments = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    // Fetch data from Firebase
    _fetchAppointments();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Fetch appointment data from Firebase
  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      final userId = auth.currentUser?.uid;
      
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      print('Fetching appointments for user ID: $userId');
      
      // Get all appointments for the current user
      final appointmentsSnapshot = await firestore
          .collection('appointments')
          .where('patientId', isEqualTo: userId)
          .get();
      
      print('Found ${appointmentsSnapshot.docs.length} appointments');
      
      List<Map<String, dynamic>> fetchedAppointments = [];
      
      for (var appointmentDoc in appointmentsSnapshot.docs) {
        try {
          final appointmentData = appointmentDoc.data();
          print('Processing appointment: ${appointmentDoc.id}');
          
          // Fetch doctor details
          if (appointmentData['doctorId'] != null) {
            final doctorDoc = await firestore
                .collection('doctors')
                .doc(appointmentData['doctorId'])
                .get();
            
            if (doctorDoc.exists) {
              final doctorData = doctorDoc.data() as Map<String, dynamic>;
              print('Found doctor data: ${doctorData['fullName'] ?? doctorData['name']}');
              
              // Format the appointment date
              DateTime appointmentDate;
              if (appointmentData['appointmentDate'] != null) {
                appointmentDate = (appointmentData['appointmentDate'] as Timestamp).toDate();
              } else if (appointmentData['date'] != null && appointmentData['date'] is Timestamp) {
                appointmentDate = (appointmentData['date'] as Timestamp).toDate();
              } else {
                appointmentDate = DateTime.now();
              }
              
              String formattedDate = "${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}";
              String formattedTime = appointmentData['time'] ?? 
                                    "${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')}";
              
              // Determine appointment status
              String status = appointmentData['status'] ?? 'pending';
              if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'confirmed') {
                status = 'upcoming';
              } else if (status.toLowerCase() == 'completed') {
                status = 'completed';
              } else if (status.toLowerCase() == 'cancelled') {
                status = 'cancelled';
              }
              
              fetchedAppointments.add({
                'id': appointmentDoc.id,
                'date': formattedDate,
                'time': formattedTime,
                'status': status,
                'doctorName': doctorData['fullName'] ?? doctorData['name'] ?? "Unknown Doctor",
                'specialty': doctorData['specialty'] ?? "General",
                'hospitalName': appointmentData['hospitalName'] ?? doctorData['hospitalName'] ?? "Unknown Hospital",
                'reason': appointmentData['reason'] ?? appointmentData['notes'] ?? 'Consultation',
                'doctorImage': doctorData['profileImageUrl'] ?? 'assets/images/User.png',
                'fee': appointmentData['fee']?.toString() ?? '0',
                'paymentStatus': appointmentData['paymentStatus'] ?? 'pending',
                'paymentMethod': appointmentData['paymentMethod'] ?? 'Not specified',
                'isPanelConsultation': appointmentData['isPanelConsultation'] ?? false,
                'cancellationReason': appointmentData['cancellationReason'],
                'type': appointmentData['isPanelConsultation'] ? 'In-Person Visit' : 'Regular Consultation',
              });
              print('Successfully added appointment to list');
            } else {
              print('Doctor document not found for ID: ${appointmentData['doctorId']}');
            }
          }
        } catch (e) {
          print('Error processing appointment: $e');
        }
      }
      
      setState(() {
        _appointments = fetchedAppointments;
        _filterAppointments();
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error fetching appointment data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _filterAppointments() {
    // First filter by tab/status
    final List<Map<String, dynamic>> statusFiltered = _appointments.where((appointment) {
      if (_selectedTabIndex == 0) return appointment['status'] == "upcoming";
      if (_selectedTabIndex == 1) return appointment['status'] == "completed";
      if (_selectedTabIndex == 2) return appointment['status'] == "cancelled";
      return true;
    }).toList();
    
    // Then filter by search query if there is one
    if (_searchQuery.isEmpty) {
      _filteredAppointments = statusFiltered;
      return;
    }
    
    _filteredAppointments = statusFiltered.where((appointment) {
      final nameMatch = appointment['doctorName'].toLowerCase().contains(_searchQuery.toLowerCase());
      final dateMatch = appointment['date'].toLowerCase().contains(_searchQuery.toLowerCase());
      final typeMatch = appointment['type'].toLowerCase().contains(_searchQuery.toLowerCase());
      final hospitalMatch = appointment['hospitalName'].toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatch || dateMatch || typeMatch || hospitalMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildSearchBar(),
                ),
                SizedBox(height: 16),
                _buildTabs(),
                SizedBox(height: 10),
                Expanded(
                  child: _isLoading 
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Color.fromRGBO(64, 124, 226, 1),
                        ),
                      )
                    : _filteredAppointments.isEmpty
                      ? _buildNoAppointmentsFound()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredAppointments.length,
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
                                  _filteredAppointments[index],
                                  index,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(64, 124, 226, 1),
            Color.fromRGBO(84, 144, 246, 1),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(64, 124, 226, 0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 25),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            SizedBox(width: 8),
            Text(
              "My Appointments",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(LucideIcons.refreshCcw, color: Colors.white),
                onPressed: _fetchAppointments,
                tooltip: 'Refresh',
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildTabs() {
    return Container(
      height: 44,
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: List.generate(
          _tabs.length,
          (index) => Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                  _filterAppointments();
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTabIndex == index
                      ? Color.fromRGBO(64, 124, 226, 1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  _tabs[index],
                  style: GoogleFonts.poppins(
                    color: _selectedTabIndex == index
                        ? Colors.white
                        : Color.fromRGBO(64, 124, 226, 1),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoAppointmentsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedTabIndex == 0
                ? LucideIcons.calendar
                : _selectedTabIndex == 1
                    ? LucideIcons.clipboardCheck
                    : Icons.cancel_outlined,
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
                : _selectedTabIndex == 0
                    ? "You have no upcoming appointments"
                    : _selectedTabIndex == 1
                        ? "You have no past appointments"
                        : "You have no cancelled appointments",
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
    final bool isUpcoming = appointment['status'] == "upcoming";
    final bool isCancelled = appointment['status'] == "cancelled";
    
    // Define status color based on appointment status
    final Color statusColor = isCancelled
        ? Color(0xFFF44336) // Red for cancelled
        : isUpcoming
            ? Color.fromRGBO(64, 124, 226, 1) // Blue for upcoming
            : Color(0xFF4CAF50); // Green for completed
            
    final String statusText = isCancelled
        ? "Cancelled"
        : isUpcoming
            ? "Upcoming"
            : "Completed";
    
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
                    backgroundImage: appointment['doctorImage'].startsWith('assets/')
                        ? AssetImage(appointment['doctorImage'])
                        : NetworkImage(appointment['doctorImage']) as ImageProvider,
                  ),
                ),
                SizedBox(width: 15),
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
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        appointment['specialty'],
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
                    statusText,
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
                      appointment['date'],
                    ),
                    SizedBox(width: 15),
                    _buildAppointmentDetail(
                      LucideIcons.clock,
                      "Time",
                      appointment['time'],
                    ),
                  ],
                ),
                SizedBox(height: 18),
                Row(
                  children: [
                    _buildAppointmentDetail(
                      LucideIcons.building2,
                      "Hospital",
                      appointment['hospitalName'],
                    ),
                    SizedBox(width: 15),
                    _buildAppointmentDetail(
                      LucideIcons.tag,
                      "Appointment Type",
                      appointment['type'],
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
                            appointment['cancellationReason'],
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
                
                // Action buttons
                isUpcoming
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              "View Details",
                              LucideIcons.clipboardList,
                              Color.fromRGBO(64, 124, 226, 1),
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AppointmentDetailsScreen(
                                      appointmentDetails: appointment,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              "View Details",
                              LucideIcons.clipboardList,
                              statusColor,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AppointmentDetailsScreen(
                                      appointmentDetails: appointment,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (!isCancelled) ...[
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                "Schedule Again",
                                LucideIcons.repeat,
                                Color(0xFF4CAF50),
                                () {
                                  // Handle reschedule
                                },
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
}
