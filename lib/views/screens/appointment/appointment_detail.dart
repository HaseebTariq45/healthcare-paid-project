import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String? appointmentId;
  
  const AppointmentDetailsScreen({
    super.key,
    this.appointmentId,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _appointmentData = {};
  String _patientName = "Patient";
  String _appointmentDate = "Upcoming";
  String _appointmentTime = "";
  String _patientInfo = "No additional information available.";
  String _additionalNotes = "No notes available.";

  @override
  void initState() {
    super.initState();
    if (widget.appointmentId != null) {
      _fetchAppointmentData();
    } else {
      // No appointment ID provided, show mock data
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAppointmentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Fetch appointment data
      final appointmentDoc = await firestore
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();
      
      if (!appointmentDoc.exists || appointmentDoc.data() == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final data = appointmentDoc.data()!;
      _appointmentData = data;
      
      // Format date and time
      if (data.containsKey('date') && data['date'] is Timestamp) {
        final DateTime appointmentDate = (data['date'] as Timestamp).toDate();
        _appointmentDate = DateFormat('MM/dd/yyyy').format(appointmentDate);
        _appointmentTime = DateFormat('h:mm a').format(appointmentDate);
      }
      
      // Get patient information
      if (data.containsKey('patientId')) {
        final patientDoc = await firestore
            .collection('users')
            .doc(data['patientId'])
            .get();
        
        if (patientDoc.exists && patientDoc.data() != null) {
          final patientData = patientDoc.data()!;
          _patientName = patientData['fullName'] ?? "Patient";
          
          // Build patient info from available fields
          List<String> patientInfos = [];
          
          if (patientData.containsKey('phoneNumber')) {
            patientInfos.add("Phone: ${patientData['phoneNumber']}");
          }
          
          if (patientData.containsKey('email')) {
            patientInfos.add("Email: ${patientData['email']}");
          }
          
          if (patientData.containsKey('address')) {
            patientInfos.add("Address: ${patientData['address']}");
          }
          
          if (patientInfos.isNotEmpty) {
            _patientInfo = patientInfos.join("\n");
          }
        }
      }
      
      // Get notes if available
      if (data.containsKey('notes') && data['notes'] != null && data['notes'].toString().isNotEmpty) {
        _additionalNotes = data['notes'];
      }
      
    } catch (e) {
      print('Error fetching appointment data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(
        isBackButtonVisible: true,
        text: "Appointments",
      ),
      // appBar: AppBar(
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back, color: Colors.black),
      //     onPressed: () {
      //       Navigator.pop(context);
      //     },
      //   ),
      //   title: Text(
      //     "Appointments",
      //     style: GoogleFonts.poppins(
      //       color: Colors.black,
      //       fontWeight: FontWeight.bold,
      //     ),
      //   ),
      //   centerTitle: true,
      //   backgroundColor: Colors.white,
      //   elevation: 0,
      // ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(64, 124, 226, 1),
              ),
            )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                )
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Appointment with $_patientName",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(0, 0, 0, 7.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildInfoButton(Icons.calendar_today, _appointmentDate),
                        const SizedBox(width: 12),
                        _buildInfoButton(Icons.access_time, _appointmentTime),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "About Patient",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _patientInfo,
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
                    const SizedBox(height: 30),
                    Text(
                      "Additional Notes",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _additionalNotes,
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
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          "Copy Invite",
                          Color.fromRGBO(64, 124, 226, 1),
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invitation link copied!'),
                                backgroundColor: Color.fromRGBO(64, 124, 226, 1),
                              ),
                            );
                          },
                        ),
                        _buildActionButton(
                          "Reschedule", 
                          Colors.red,
                          () {
                            // Reschedule appointment
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Reschedule functionality not implemented yet'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Join session
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Video call session not implemented yet'),
                              backgroundColor: Color.fromRGBO(64, 124, 226, 1),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(64, 124, 226, 1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Join Session",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoButton(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color.fromRGBO(64, 124, 226, 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 140,
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
      ),
    );
  }
}
