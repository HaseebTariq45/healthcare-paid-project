import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> appointments = [
    {
      "title": "Consultation with Emily Watson",
      "date": "Dec 30, 2023",
      "time": "9:30 AM - 10:00 AM",
      "status": "completed",
      "patientImage": "assets/images/User.png",
      "amount": "Rs 1,200",
      "type": "Video Consultation"
    },
    {
      "title": "Check-up with James Wilson",
      "date": "Dec 28, 2023",
      "time": "2:00 PM - 2:30 PM",
      "status": "completed",
      "patientImage": "assets/images/User.png",
      "amount": "Rs 1,500",
      "type": "In-Person Visit"
    },
    {
      "title": "Follow-up with Sarah Adams",
      "date": "Dec 23, 2023",
      "time": "11:00 AM - 11:30 AM",
      "status": "cancelled",
      "patientImage": "assets/images/User.png",
      "amount": "Rs 800",
      "type": "Video Consultation"
    },
    {
      "title": "Consultation with Robert Lee",
      "date": "Dec 20, 2023",
      "time": "4:30 PM - 5:00 PM",
      "status": "completed",
      "patientImage": "assets/images/User.png",
      "amount": "Rs 1,200",
      "type": "Video Consultation"
    },
  ];

  final List<Map<String, dynamic>> upcomingAppointments = [
    {
      "title": "Consultation with Michael Brown",
      "date": "Jan 10, 2024",
      "time": "10:30 AM - 11:00 AM",
      "status": "upcoming",
      "patientImage": "assets/images/User.png",
      "amount": "Rs 1,200",
      "type": "Video Consultation"
    },
    {
      "title": "Check-up with Emma Smith",
      "date": "Jan 15, 2024",
      "time": "3:00 PM - 3:30 PM",
      "status": "upcoming",
      "patientImage": "assets/images/User.png",
      "amount": "Rs 1,500",
      "type": "In-Person Visit"
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {},
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsList(upcomingAppointments, true),
          _buildAppointmentsList(appointments, false),
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
              ],
            ),
          )
        : ListView.builder(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(20),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              return _buildAppointmentCard(appointments[index], index, isUpcoming);
            },
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
                        appointment["date"],
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        LucideIcons.clock,
                        "Time",
                        appointment["time"],
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
                        appointment["amount"],
                      ),
                    ),
                    isUpcoming
                        ? Row(
                            children: [
                              _buildActionButton(
                                LucideIcons.pencil,
                                Color(0xFF3366FF),
                                () {},
                              ),
                              SizedBox(width: 8),
                              _buildActionButton(
                                LucideIcons.x,
                                Colors.red,
                                () {},
                              ),
                            ],
                          )
                        : _buildActionButton(
                            LucideIcons.repeat,
                            Color(0xFF3366FF),
                            () {},
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
}
