import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/reschedule_appointment.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientAppointmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? appointmentDetails;
  
  const PatientAppointmentDetailsScreen({
    Key? key,
    this.appointmentDetails,
  }) : super(key: key);

  @override
  _PatientAppointmentDetailsScreenState createState() => _PatientAppointmentDetailsScreenState();
}

class _PatientAppointmentDetailsScreenState extends State<PatientAppointmentDetailsScreen> {
  Map<String, dynamic> appointmentData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointmentData();
  }

  Future<void> _loadAppointmentData() async {
    if (widget.appointmentDetails != null) {
      setState(() {
        appointmentData = widget.appointmentDetails!;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch the most recent appointment for this user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final appointmentsSnapshot = await FirebaseFirestore.instance
            .collection('appointments')
            .where('patientId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (appointmentsSnapshot.docs.isNotEmpty) {
          final data = appointmentsSnapshot.docs.first.data();
          setState(() {
            appointmentData = data;
            _isLoading = false;
          });
        } else {
          // Use default data if no appointment is found
          setState(() {
            appointmentData = {
              'doctorName': 'Dr. Rizwan',
              'specialty': 'Cardiologist',
              'rating': '4.7',
              'fee': 'Rs 1500',
              'location': 'CMH Rawalpindi',
              'date': '10/01/2025',
              'time': '2.00 PM',
            };
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading appointment data: $e');
      setState(() {
        // Use default data if there's an error
        appointmentData = {
          'doctorName': 'Dr. Rizwan',
          'specialty': 'Cardiologist',
          'rating': '4.7',
          'fee': 'Rs 1500',
          'location': 'CMH Rawalpindi',
          'date': '10/01/2025',
          'time': '2.00 PM',
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBarOnboarding(isBackButtonVisible: true, text: "Appointment Details"),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Extract the doctor name and other details
    final doctorName = appointmentData['doctorName'] ?? appointmentData['doctor'] ?? 'Dr. Rizwan';
    final specialty = appointmentData['specialty'] ?? 'Specialist';
    final rating = appointmentData['rating'] ?? '4.7';
    final fee = appointmentData['fee'] ?? 'Rs 1500';
    final location = appointmentData['location'] ?? 'Hospital';
    final date = appointmentData['date'] ?? '01/01/2025';
    final time = appointmentData['time'] ?? '12:00 PM';
    
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
                      Text(doctorName,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(specialty, 
                          style: TextStyle(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          _infoChip(LucideIcons.star, rating),
                          SizedBox(width: 5),
                          _infoChip(LucideIcons.dollarSign, fee.toString()),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 14, color: Colors.grey),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(location, 
                                style: TextStyle(color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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
                _infoButton(LucideIcons.calendar, date),
                SizedBox(width: 10),
                _infoButton(LucideIcons.clock, time),
              ],
            ),
            SizedBox(height: 20),

            // Additional Notes
            _sectionTitle("Additional Notes"),
            Text(
              appointmentData['notes'] ?? "No additional notes for this appointment.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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
            _buildSubmitButton("Join Meeting", () {print("Joining meeting...");}),

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
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.blue),
          SizedBox(width: 3),
          Text(text, 
              style: TextStyle(color: Colors.blue, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            SizedBox(width: 5),
            Text(text, 
                style: TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
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
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromRGBO(64, 124, 226, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          buttonText,
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
