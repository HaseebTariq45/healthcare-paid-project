import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/appointment/appointment_booking_flow.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DoctorsScreen extends StatefulWidget {
  final String? specialty;
  const DoctorsScreen({super.key, this.specialty});

  @override
  _DoctorsScreenState createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  // Sample doctors data - Replace with actual API call
  final List<Map<String, dynamic>> _doctors = [
    {
      'name': 'Dr. Sarah Ahmed',
      'specialty': 'Cardiologist',
      'image': 'assets/images/User.png',
      'rating': 4.9,
      'experience': '15 years',
      'qualification': 'MBBS, FCPS',
      'languages': ['English', 'Urdu'],
      'fee': 'Rs. 2000',
    },
    {
      'name': 'Dr. John Miller',
      'specialty': 'Neurologist',
      'image': 'assets/images/User.png',
      'rating': 4.8,
      'experience': '12 years',
      'qualification': 'MBBS, MRCP',
      'languages': ['English'],
      'fee': 'Rs. 2500',
    },
    {
      'name': 'Dr. Amina Khan',
      'specialty': 'Dermatologist',
      'image': 'assets/images/User.png',
      'rating': 4.7,
      'experience': '8 years',
      'qualification': 'MBBS, FCPS',
      'languages': ['English', 'Urdu'],
      'fee': 'Rs. 1800',
    },
  ];

  List<Map<String, dynamic>> get _filteredDoctors {
    if (widget.specialty == null) return _doctors;
    return _doctors.where((doctor) => 
      doctor['specialty'].toLowerCase().contains(widget.specialty!.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.specialty ?? 'Available Doctors',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredDoctors.length,
        itemBuilder: (context, index) {
          final doctor = _filteredDoctors[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage(doctor['image']),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              doctor['specialty'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  doctor['rating'].toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(
                        LucideIcons.briefcase,
                        '${doctor['experience']} exp',
                      ),
                      SizedBox(width: 8),
                      _buildInfoChip(
                        LucideIcons.graduationCap,
                        doctor['qualification'],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(
                        LucideIcons.globe,
                        doctor['languages'].join(', '),
                      ),
                      SizedBox(width: 8),
                      _buildInfoChip(
                        LucideIcons.dollarSign,
                        doctor['fee'],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentBookingFlow(
                            preSelectedDoctor: doctor,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3366CC),
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Book Appointment',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF3366CC).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFF3366CC).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Color(0xFF3366CC),
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
} 