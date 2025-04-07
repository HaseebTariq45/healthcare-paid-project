import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Appointment data structure optimized for Firestore
  final List<Map<String, dynamic>> _appointments = [];
  final List<Map<String, dynamic>> _upcomingAppointments = [];

  // Search query
  String _searchQuery = '';
  
  // Sample appointment format - will be retrieved from Firestore
  /*
  {
    "id": "appointment123", // Document ID from Firestore
    "patientId": "patient456",
    "doctorId": "doctor789",
    "title": "Consultation with Emily Watson",
    "date": "2023-12-30",
    "timeSlot": {
      "start": "09:30:00",
      "end": "10:00:00",
    },
    "displayTime": "9:30 AM - 10:00 AM", // For UI display
    "displayDate": "Dec 30, 2023", // For UI display
    "timestamp": 1673452800000, // Unix timestamp for sorting
    "status": "completed", // completed, cancelled, upcoming
    "patientImage": "assets/images/User.png", // Will be replaced with Firebase Storage URL
    "patientName": "Emily Watson",
    "amount": 1200,
    "displayAmount": "Rs 1,200",
    "type": "Video Consultation", // In-Person Visit, Video Consultation
    "notes": "",
    "createdAt": 1673452800000,
    "updatedAt": 1673452800000,
  }
  */

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Load appointments from Firestore (mock implementation for now)
  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // This will be replaced with actual Firestore queries:
      /*
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      
      // Get upcoming appointments (where date is >= today)
      final upcomingQuery = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: DateTime.now().millisecondsSinceEpoch)
          .orderBy('timestamp', descending: false)
          .get();
          
      // Get past appointments (where date is < today)
      final pastQuery = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: userId)
          .where('timestamp', isLessThan: DateTime.now().millisecondsSinceEpoch)
          .orderBy('timestamp', descending: true)
          .get();
          
      final upcomingList = upcomingQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      final pastList = pastQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      setState(() {
        _upcomingAppointments = upcomingList;
        _appointments = pastList;
        _isLoading = false;
      });
      */
      
      // For demo purposes, use the sample data
      await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
      
      setState(() {
        _appointments.clear();
        _appointments.addAll([
          {
            "id": "appt1",
            "patientId": "patient1",
            "doctorId": "doctor1",
            "title": "Consultation with Emily Watson",
            "date": "2023-12-30",
            "timeSlot": {
              "start": "09:30:00",
              "end": "10:00:00",
            },
            "displayTime": "9:30 AM - 10:00 AM",
            "displayDate": "Dec 30, 2023",
            "timestamp": 1703913000000,
            "status": "completed",
            "patientImage": "assets/images/User.png",
            "patientName": "Emily Watson",
            "amount": 1200,
            "displayAmount": "Rs 1,200",
            "type": "Video Consultation",
            "notes": "",
            "createdAt": 1703913000000,
            "updatedAt": 1703913000000,
          },
          {
            "id": "appt2",
            "patientId": "patient2",
            "doctorId": "doctor1",
            "title": "Check-up with James Wilson",
            "date": "2023-12-28",
            "timeSlot": {
              "start": "14:00:00",
              "end": "14:30:00",
            },
            "displayTime": "2:00 PM - 2:30 PM",
            "displayDate": "Dec 28, 2023",
            "timestamp": 1703754000000,
            "status": "completed",
            "patientImage": "assets/images/User.png",
            "patientName": "James Wilson",
            "amount": 1500,
            "displayAmount": "Rs 1,500",
            "type": "In-Person Visit",
            "notes": "",
            "createdAt": 1703754000000,
            "updatedAt": 1703754000000,
          },
          {
            "id": "appt3",
            "patientId": "patient3",
            "doctorId": "doctor1",
            "title": "Follow-up with Sarah Adams",
            "date": "2023-12-23",
            "timeSlot": {
              "start": "11:00:00",
              "end": "11:30:00",
            },
            "displayTime": "11:00 AM - 11:30 AM",
            "displayDate": "Dec 23, 2023",
            "timestamp": 1703322000000,
            "status": "cancelled",
            "patientImage": "assets/images/User.png",
            "patientName": "Sarah Adams",
            "amount": 800,
            "displayAmount": "Rs 800",
            "type": "Video Consultation",
            "notes": "Patient had to reschedule",
            "createdAt": 1703322000000,
            "updatedAt": 1703322000000,
          },
          {
            "id": "appt4",
            "patientId": "patient4",
            "doctorId": "doctor1",
            "title": "Consultation with Robert Lee",
            "date": "2023-12-20",
            "timeSlot": {
              "start": "16:30:00",
              "end": "17:00:00",
            },
            "displayTime": "4:30 PM - 5:00 PM",
            "displayDate": "Dec 20, 2023",
            "timestamp": 1703077800000,
            "status": "completed",
            "patientImage": "assets/images/User.png",
            "patientName": "Robert Lee",
            "amount": 1200,
            "displayAmount": "Rs 1,200",
            "type": "Video Consultation",
            "notes": "",
            "createdAt": 1703077800000,
            "updatedAt": 1703077800000,
          },
        ]);
        
        _upcomingAppointments.clear();
        _upcomingAppointments.addAll([
          {
            "id": "appt5",
            "patientId": "patient5",
            "doctorId": "doctor1",
            "title": "Consultation with Michael Brown",
            "date": "2024-01-10",
            "timeSlot": {
              "start": "10:30:00",
              "end": "11:00:00",
            },
            "displayTime": "10:30 AM - 11:00 AM",
            "displayDate": "Jan 10, 2024",
            "timestamp": 1704867000000,
            "status": "upcoming",
            "patientImage": "assets/images/User.png",
            "patientName": "Michael Brown",
            "amount": 1200,
            "displayAmount": "Rs 1,200",
            "type": "Video Consultation",
            "notes": "",
            "createdAt": 1704867000000,
            "updatedAt": 1704867000000,
          },
          {
            "id": "appt6",
            "patientId": "patient6",
            "doctorId": "doctor1",
            "title": "Check-up with Emma Smith",
            "date": "2024-01-15",
            "timeSlot": {
              "start": "15:00:00",
              "end": "15:30:00",
            },
            "displayTime": "3:00 PM - 3:30 PM",
            "displayDate": "Jan 15, 2024",
            "timestamp": 1705316400000,
            "status": "upcoming",
            "patientImage": "assets/images/User.png",
            "patientName": "Emma Smith",
            "amount": 1500,
            "displayAmount": "Rs 1,500",
            "type": "In-Person Visit",
            "notes": "",
            "createdAt": 1705316400000,
            "updatedAt": 1705316400000,
          },
        ]);
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load appointments: ${e.toString()}';
        _isLoading = false;
      });
      print('Error loading appointments: $e');
    }
  }
  
  // Filter appointments based on search query
  List<Map<String, dynamic>> _getFilteredAppointments(List<Map<String, dynamic>> appointments) {
    if (_searchQuery.isEmpty) return appointments;
    
    return appointments.where((appointment) {
      final title = appointment['title'].toString().toLowerCase();
      final patientName = appointment['patientName'].toString().toLowerCase();
      final type = appointment['type'].toString().toLowerCase();
      final date = appointment['displayDate'].toString().toLowerCase();
      
      final query = _searchQuery.toLowerCase();
      
      return title.contains(query) || 
             patientName.contains(query) ||
             type.contains(query) ||
             date.contains(query);
    }).toList();
  }
  
  // Cancel an appointment
  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Cancel Appointment', 
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)
          ),
          content: Text(
            'Are you sure you want to cancel this appointment?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'No',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Yes',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
      
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });
      
      // This will be replaced with actual Firestore code:
      /*
      await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({
          'status': 'cancelled',
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      */
      
      // For demo purposes, update the local data
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
      
      setState(() {
        // Find and update the appointment in the list
        final index = _upcomingAppointments.indexWhere((a) => a['id'] == appointmentId);
        if (index != -1) {
          final appointment = {..._upcomingAppointments[index]};
          appointment['status'] = 'cancelled';
          appointment['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
          
          // Remove from upcoming and add to past
          _upcomingAppointments.removeAt(index);
          _appointments.insert(0, appointment);
        }
        
        _isLoading = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment cancelled successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      
      print('Error cancelling appointment: $e');
    }
  }
  
  // Setup real-time appointment updates (using Firestore snapshots)
  void _setupAppointmentListener() {
    // This will be replaced with actual Firestore listener:
    /*
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    
    // Listen for upcoming appointments
    FirebaseFirestore.instance
      .collection('appointments')
      .where('doctorId', isEqualTo: userId)
      .where('timestamp', isGreaterThanOrEqualTo: DateTime.now().millisecondsSinceEpoch)
      .orderBy('timestamp', descending: false)
      .snapshots()
      .listen((snapshot) {
        final upcomingList = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
        
        setState(() {
          _upcomingAppointments = upcomingList;
        });
      });
      
    // Listen for past appointments
    FirebaseFirestore.instance
      .collection('appointments')
      .where('doctorId', isEqualTo: userId)
      .where('timestamp', isLessThan: DateTime.now().millisecondsSinceEpoch)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .listen((snapshot) {
        final pastList = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
        
        setState(() {
          _appointments = pastList;
        });
      });
    */
  }

  @override
  Widget build(BuildContext context) {
    final filteredUpcomingAppointments = _getFilteredAppointments(_upcomingAppointments);
    final filteredPastAppointments = _getFilteredAppointments(_appointments);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Color(0xFF333333), size: 24),
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
            icon: Icon(LucideIcons.search, color: Color(0xFF3366FF), size: 22),
            onPressed: () {
              showSearch(
                context: context,
                delegate: AppointmentSearchDelegate(
                  upcoming: _upcomingAppointments,
                  past: _appointments,
                  onSearch: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.refreshCw, color: Color(0xFF3366FF), size: 22),
            onPressed: _loadAppointments,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Color(0xFFF5F7FF),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Color(0xFF3366FF),
              indicator: BoxDecoration(
                color: Color(0xFF3366FF),
                borderRadius: BorderRadius.circular(30),
              ),
              tabs: [
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Upcoming",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Past",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading 
        ? Center(
            child: CircularProgressIndicator(
              color: Color(0xFF3366FF),
            ),
          )
        : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 50,
                    color: Colors.amber,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Error Loading Appointments",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadAppointments,
                    icon: Icon(LucideIcons.refreshCw),
                    label: Text(
                      "Try Again",
                      style: GoogleFonts.poppins(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3366FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList(filteredUpcomingAppointments, true),
                _buildAppointmentsList(filteredPastAppointments, false),
              ],
      ),
    );
  }

  Widget _buildAppointmentsList(List<Map<String, dynamic>> appointments, bool isUpcoming) {
    return appointments.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isUpcoming ? LucideIcons.calendar : LucideIcons.history,
                  size: 50,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: 16),
                Text(
                  isUpcoming
                      ? "No upcoming appointments"
                      : "No appointment history",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    'No results for "$_searchQuery"',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: Icon(LucideIcons.x),
                    label: Text('Clear Search'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF3366FF),
                    ),
                  ),
                ],
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadAppointments,
            color: Color(0xFF3366FF),
            child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: EdgeInsets.all(20),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                return _buildAppointmentCard(appointments[index], index, isUpcoming);
              },
            ),
          );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, int index, bool isUpcoming) {
    final Color statusColor = appointment["status"] == "completed"
        ? Color(0xFF4CAF50)
        : appointment["status"] == "cancelled"
            ? Color(0xFFF44336)
            : Color(0xFF3366FF);

    final String statusText = appointment["status"] == "completed"
        ? "Completed"
        : appointment["status"] == "cancelled"
            ? "Cancelled"
            : "Upcoming";

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appointment header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF3366FF).withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage(appointment["patientImage"]),
                ),
                SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                        appointment["title"],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        appointment["type"],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          
          // Appointment details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Date and time row
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        LucideIcons.calendar,
                        "Date",
                        appointment["displayDate"],
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        LucideIcons.clock,
                        "Time",
                        appointment["displayTime"],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Amount and action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        LucideIcons.wallet,
                        "Amount",
                        appointment["displayAmount"],
                      ),
                    ),
                    isUpcoming && appointment["status"] == "upcoming"
                        ? Row(
                            children: [
                              _buildActionButton(
                                LucideIcons.pencil,
                                Color(0xFF3366FF),
                                () => _editAppointment(appointment["id"]),
                              ),
                              SizedBox(width: 8),
                              _buildActionButton(
                                LucideIcons.x,
                                Colors.red,
                                () => _cancelAppointment(appointment["id"]),
                              ),
                            ],
                          )
                        : _buildActionButton(
                            LucideIcons.repeat,
                            Color(0xFF3366FF),
                            () => _rescheduleAppointment(appointment),
                          ),
                  ],
                ),
                
                // Notes section for cancelled appointments
                if (appointment["status"] == "cancelled" && 
                    appointment["notes"] != null && 
                    appointment["notes"].toString().isNotEmpty) ...[
                  SizedBox(height: 12),
                  Divider(color: Colors.grey.shade200),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.clipboardList,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Note: ${appointment["notes"]}",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color(0xFF3366FF).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Color(0xFF3366FF),
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Color(0xFF666666),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Icon(
          icon,
          size: 20,
          color: color,
        ),
      ),
    );
  }
  
  void _editAppointment(String appointmentId) {
    // This will be implemented to navigate to appointment edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit appointment feature coming soon'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  void _rescheduleAppointment(Map<String, dynamic> appointment) {
    // This will be implemented to reschedule the appointment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reschedule appointment feature coming soon'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// Search delegate for appointments
class AppointmentSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> upcoming;
  final List<Map<String, dynamic>> past;
  final Function(String) onSearch;
  
  AppointmentSearchDelegate({
    required this.upcoming,
    required this.past,
    required this.onSearch,
  });
  
  @override
  String get searchFieldLabel => 'Search appointments';
  
  @override
  TextStyle get searchFieldStyle => GoogleFonts.poppins(
    fontSize: 16,
    color: Color(0xFF333333),
  );
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch('');
        },
      ),
    ];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }
  
  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    return Container(); // We handle the results in the main screen
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.search,
              size: 50,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              'Search for appointments',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching by patient name, type, or date',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    final suggestions = _getSuggestions();
    
    if (suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.searchX,
              size: 50,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: suggestions.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final appointment = suggestions[index];
        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          leading: CircleAvatar(
            backgroundImage: AssetImage(appointment['patientImage']),
          ),
          title: Text(
            appointment['title'],
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${appointment['displayDate']} • ${appointment['type']}',
            style: GoogleFonts.poppins(
              fontSize: 13,
            ),
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(appointment['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(appointment['status']),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _getStatusColor(appointment['status']),
              ),
            ),
          ),
          onTap: () {
            onSearch(query);
            close(context, query);
          },
        );
      },
    );
  }
  
  List<Map<String, dynamic>> _getSuggestions() {
    if (query.isEmpty) return [];
    
    final q = query.toLowerCase();
    List<Map<String, dynamic>> result = [];
    
    // Search in upcoming appointments
    for (var appointment in upcoming) {
      if (_matchesQuery(appointment, q)) {
        result.add(appointment);
      }
    }
    
    // Search in past appointments
    for (var appointment in past) {
      if (_matchesQuery(appointment, q)) {
        result.add(appointment);
      }
    }
    
    return result;
  }
  
  bool _matchesQuery(Map<String, dynamic> appointment, String query) {
    final title = appointment['title'].toString().toLowerCase();
    final patientName = appointment['patientName'].toString().toLowerCase();
    final type = appointment['type'].toString().toLowerCase();
    final date = appointment['displayDate'].toString().toLowerCase();
    
    return title.contains(query) || 
           patientName.contains(query) ||
           type.contains(query) ||
           date.contains(query);
  }
  
  Color _getStatusColor(String status) {
    return status == "completed"
        ? Color(0xFF4CAF50)
        : status == "cancelled"
            ? Color(0xFFF44336)
            : Color(0xFF3366FF);
  }
  
  String _getStatusText(String status) {
    return status == "completed"
        ? "Completed"
        : status == "cancelled"
            ? "Cancelled"
            : "Upcoming";
  }
}
