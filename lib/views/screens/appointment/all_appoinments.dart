import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/appointment/appointment_detail.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _searchQuery = '';
  int _selectedTabIndex = 0;
  
  final List<String> _tabs = ["Upcoming", "Past", "Cancelled"];
  
  final List<Appointment> _appointments = [
    Appointment(
      patientName: "Hania Singh",
      date: "Jan 10, 2025",
      time: "12:00 pm - 1:00 pm",
      patientImage: "assets/images/User.png",
      type: "Video Consultation",
      status: "upcoming"
    ),
    Appointment(
      patientName: "Anjali Kapoor",
      date: "Jan 11, 2025",
      time: "12:00 pm - 1:00 pm",
      patientImage: "assets/images/User.png",
      type: "In-Person Visit",
      status: "upcoming"
    ),
    Appointment(
      patientName: "Sameer Malhotra",
      date: "Jan 13, 2025",
      time: "12:00 pm - 1:00 pm",
      patientImage: "assets/images/User.png",
      type: "Video Consultation",
      status: "upcoming"
    ),
    Appointment(
      patientName: "Rohit Sharma",
      date: "Jan 4, 2025",
      time: "10:00 am - 11:00 am",
      patientImage: "assets/images/User.png",
      type: "Video Consultation",
      status: "completed"
    ),
    Appointment(
      patientName: "Preeti Jain",
      date: "Jan 2, 2025",
      time: "2:30 pm - 3:00 pm",
      patientImage: "assets/images/User.png",
      type: "In-Person Visit",
      status: "completed"
    ),
    Appointment(
      patientName: "Mohammed Khan",
      date: "Dec 28, 2024",
      time: "11:30 am - 12:00 pm",
      patientImage: "assets/images/User.png",
      type: "Video Consultation",
      status: "cancelled",
      cancellationReason: "Patient requested reschedule"
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  List<Appointment> get _filteredAppointments {
    // First filter by tab/status
    final List<Appointment> statusFiltered = _appointments.where((appointment) {
      if (_selectedTabIndex == 0) return appointment.status == "upcoming";
      if (_selectedTabIndex == 1) return appointment.status == "completed";
      if (_selectedTabIndex == 2) return appointment.status == "cancelled";
      return true;
    }).toList();
    
    // Then filter by search query if there is one
    if (_searchQuery.isEmpty) return statusFiltered;
    
    return statusFiltered.where((appointment) {
      final nameMatch = appointment.patientName.toLowerCase().contains(_searchQuery.toLowerCase());
      final dateMatch = appointment.date.toLowerCase().contains(_searchQuery.toLowerCase());
      final typeMatch = appointment.type.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatch || dateMatch || typeMatch;
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
                  child: _filteredAppointments.isEmpty
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
                                    0.1 + (index * 0.1),
                                    0.6 + (index * 0.1),
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
                                      0.1 + (index * 0.1),
                                      0.6 + (index * 0.1),
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
              "Appointments",
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
                icon: Icon(LucideIcons.calendarPlus, color: Colors.white),
                onPressed: () {
                  // Handle add appointment
                },
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
                    : LucideIcons.info,
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

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment, int index) {
    final bool isUpcoming = appointment.status == "upcoming";
    final bool isCancelled = appointment.status == "cancelled";
    
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
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
      color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card header with patient info
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
        child: Row(
          children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage(appointment.patientImage),
                ),
                SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                        appointment.patientName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        appointment.type,
                    style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
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
          
          // Card body with appointment details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Date and time
                Row(
                  children: [
                    _buildDetailItem(LucideIcons.calendar, "Date", appointment.date),
                    SizedBox(width: 16),
                    _buildDetailItem(LucideIcons.clock, "Time", appointment.time),
                  ],
                ),
                
                // If cancelled, show reason
                if (isCancelled && appointment.cancellationReason != null) ...[
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
                            appointment.cancellationReason!,
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
                              "Join Session",
                              LucideIcons.video,
                              Color.fromRGBO(64, 124, 226, 1),
                              () {
                                // Handle join session
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              "Details",
                              LucideIcons.clipboardList,
                              Color.fromRGBO(64, 124, 226, 1),
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AppointmentDetailsScreen(),
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
                      builder: (context) => AppointmentDetailsScreen(),
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
  
  Widget _buildDetailItem(IconData icon, String label, String value) {
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
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
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
        elevation: 0,
      ),
      icon: Icon(icon, size: 18),
      label: Text(
          label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class Appointment {
  final String patientName;
  final String date;
  final String time;
  final String patientImage;
  final String type;
  final String status; // upcoming, completed, cancelled
  final String? cancellationReason;

  Appointment({
    required this.patientName,
    required this.date,
    required this.time,
    required this.patientImage,
    required this.type,
    required this.status,
    this.cancellationReason,
  });
}
