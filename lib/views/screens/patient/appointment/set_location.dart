import 'package:flutter/material.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/book_appointment.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DoctorDetailsScreen extends StatefulWidget {
  @override
  _DoctorDetailsScreenState createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final List<Map<String, String>> doctors = [
    {
      "name": "Dr Rizwan",
      "specialty": "Cardiologist",
      "rating": "4.7",
      "fee": "Rs 1500",
      "location": "CMH Rawalpindi",
      "image": "assets/images/patient_1.png"
    },
    {
      "name": "Dr Fatima",
      "specialty": "Dentist",
      "rating": "4.7",
      "fee": "Rs 1500",
      "location": "PAF Hospital Unit-2",
      "image": "assets/images/patient_2.png"
    },
    {
      "name": "Dr Asmara",
      "specialty": "Orthopaedic",
      "rating": "4.7",
      "fee": "Rs 1500",
      "location": "KRL Hospital G9, Islamabad",
      "image": "assets/images/patient_3.png"
    },
    {
      "name": "Dr. Tariq Mehmood",
      "specialty": "Cardiologist",
      "rating": "4.7",
      "fee": "Rs 1500",
      "location": "Maaroof International Hospital",
      "image": "assets/images/patient_4.png"
    },
    {
      "name": "Dr. Fahad Akram",
      "specialty": "Eye Specialist",
      "rating": "4.7",
      "fee": "Rs 1500",
      "location": "LRBT Shahpur Saddar, Sargodha",
      "image": "assets/images/patient_5.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "Doctor"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    "assets/images/patient_1.png",
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dr. Rizwan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Cardiologist", style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        _infoBadge(LucideIcons.star, "4.7"),
                        SizedBox(width: 8),
                        _infoBadge(LucideIcons.dollarSign, "Rs 1500"),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin, color: Colors.grey, size: 16),
                        SizedBox(width: 4),
                        Text("CMH Rawalpindi", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Text("Where to book appointment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _locationTile(context, "Personal Clinic", "Kuddos Medical Center, X Sector Islamabad"),
            _locationTile(context, "CMH", "CMH Rawalpindi, Near Saddar Bazar, Rawalpindi"),
            _locationTile(context, "Online", "Virtual Consultation"),
          ],
        ),
      ),
    );
  }

  Widget _locationTile(BuildContext context, String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookAppointmentScreen(doctor: doctors[0])),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey)),
                ],
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 16),
          SizedBox(width: 4),
          Text(text, style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class BookingLocationScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  BookingLocationScreen({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.mapPin, size: 80, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
