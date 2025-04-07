import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/reschedule_appointment.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PatientAppointmentDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "Appointment Details"),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor's Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset("assets/images/patient_1.png", width: 70, height: 70, fit: BoxFit.cover),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Dr. Rizwan",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Cardiologist", style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          _infoChip(LucideIcons.star, "4.7"),
                          SizedBox(width: 5),
                          _infoChip(LucideIcons.dollarSign, "Rs 1500"),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 14, color: Colors.grey),
                          SizedBox(width: 5),
                          Text("CMH Rawalpindi", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(height: 20),

            // About Section
            _sectionTitle("About"),
            Text(
              "Lorem ipsum dolor sit amet, consectetur adipi elit, sed do eiusmod tempor incididunt ut laore et dolore magna aliqua. Ut enim ad minim veniam... ",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Read more",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // Date & Time Section
            _sectionTitle("Date and Time"),
            Row(
              children: [
                _infoButton(LucideIcons.calendar, "10/01/2025"),
                SizedBox(width: 10),
                _infoButton(LucideIcons.clock, "2.00 PM"),
              ],
            ),
            SizedBox(height: 20),

            // Additional Notes
            _sectionTitle("Additional Notes"),
            Text(
              "Lorem ipsum dolor sit amet, consectetur adipi elit, sed do eiusmod tempor incididunt ut laore et dolore magna aliqua. Ut enim ad minim veniam... ",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Read more",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),

            // Join Meeting Button
            _buildSubmitButton("Join Meeting", () {print("Appointment booked!");}),

            SizedBox(height: 10),

            // Reschedule Button
            _buildSubmitButton("Reschedule", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => RescheduleAppointmentScreen()));
            }),
          ],
        ),
      ),
    );
  }

  // Section Title Widget
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  // Small Info Chips (Rating, Fee)
  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.blue),
          SizedBox(width: 5),
          Text(text, style: TextStyle(color: Colors.blue, fontSize: 12)),
        ],
      ),
    );
  }

  // Stylized Info Buttons (Date & Time)
  Widget _infoButton(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Color.fromRGBO(64, 124, 226, 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            SizedBox(width: 5),
            Text(text, style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
Widget _buildSubmitButton(String buttonText, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: onPressed, // Dynamically set action
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromRGBO(64, 124, 226, 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        buttonText, // Dynamically set text
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}


}
