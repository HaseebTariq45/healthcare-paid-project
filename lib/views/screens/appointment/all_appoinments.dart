import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/appointment/appointment_detail.dart';

class AppointmentsScreen extends StatelessWidget {
  final List<Appointment> appointments = [
    Appointment("Hania", "Jan 10, 2025", "12:00 pm - 1:00 pm"),
    Appointment("Hania", "Jan 11, 2025", "12:00 pm - 1:00 pm"),
    Appointment("Hania", "Jan 13, 2025", "12:00 pm - 1:00 pm"),
    Appointment("Hania", "Jun 15, 2025", "10:00 pm - 11:00 pm"),
  ];

  AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarOnboarding(
        isBackButtonVisible: true,
        text: "Appointments",
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  return _buildAppointmentCard(context, appointments[index]);
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
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search patient reports",
          border: InputBorder.none,
          icon: Icon(Icons.search_outlined, color: Colors.grey, size: 30),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Appointment with ${appointment.patientName}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    appointment.date,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    appointment.time,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _buildActionButton("Join Session", Color.fromRGBO(64, 124, 226, 1), () {
                  debugPrint("Joining session for ${appointment.patientName}");
                }),
                SizedBox(height: 8),
                _buildActionButton("Details", Color.fromRGBO(64, 124, 226, 1), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentDetailsScreen(),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color color, [
    VoidCallback? onPressed,
  ]) {
    return SizedBox(
      width: 130, // Set a fixed width
      height: 40, // Set a fixed height (optional for uniformity)
      child: ElevatedButton(
        onPressed: onPressed ?? () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
          textAlign: TextAlign.center,  
        ),
      ),
    );
  }
}

class Appointment {
  final String patientName;
  final String date;
  final String time;

  Appointment(this.patientName, this.date, this.time);
}
