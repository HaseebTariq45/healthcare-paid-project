import 'package:flutter/material.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/appointment_booking_flow.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorDetailsScreen extends StatefulWidget {
  @override
  _DoctorDetailsScreenState createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late List<Map<String, dynamic>> doctors = [];
  
  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }
  
  // Fetch doctors from Firestore
  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final QuerySnapshot doctorsSnapshot = await _firestore.collection('doctors').limit(5).get();
      
      final List<Map<String, dynamic>> doctorsList = [];
      
      for (var doc in doctorsSnapshot.docs) {
        final doctorData = doc.data() as Map<String, dynamic>;
        final doctorId = doc.id;
        
        doctorsList.add({
          "id": doctorId,
          "name": doctorData['fullName'] ?? doctorData['name'] ?? "Dr. Unknown",
          "specialty": doctorData['specialty'] ?? "General Practitioner",
          "rating": doctorData['rating']?.toString() ?? "4.7",
          "fee": "Rs ${doctorData['fee']?.toString() ?? "1500"}",
          "location": doctorData['primaryLocation'] ?? "Local Hospital",
          "image": doctorData['profileImageUrl'] ?? "assets/images/patient_1.png"
        });
      }
      
      if (mounted) {
        setState(() {
          if (doctorsList.isEmpty) {
            // Fallback to default doctors if Firestore has no data
            doctors = _getDefaultDoctors();
          } else {
            doctors = doctorsList;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading doctors: $e';
          doctors = _getDefaultDoctors();
          _isLoading = false;
        });
      }
      debugPrint('Error fetching doctors: $e');
    }
  }
  
  List<Map<String, dynamic>> _getDefaultDoctors() {
    return [
      {
        "id": "default1",
        "name": "Dr. Rizwan Ahmed",
        "specialty": "Cardiologist",
        "rating": "4.7",
        "fee": "Rs 1500",
        "location": "CMH Rawalpindi",
        "image": "assets/images/patient_1.png"
      },
      {
        "id": "default2",
        "name": "Dr. Fatima Khan",
        "specialty": "Dentist",
        "rating": "4.9",
        "fee": "Rs 2000",
        "location": "PAF Hospital Unit-2",
        "image": "assets/images/patient_2.png"
      },
      {
        "id": "default3",
        "name": "Dr. Asmara Malik",
        "specialty": "Orthopaedic",
        "rating": "4.8",
        "fee": "Rs 1800",
        "location": "KRL Hospital G9, Islamabad",
        "image": "assets/images/patient_3.png"
      },
      {
        "id": "default4",
        "name": "Dr. Tariq Mehmood",
        "specialty": "Cardiologist",
        "rating": "4.6",
        "fee": "Rs 2500",
        "location": "Maaroof International Hospital",
        "image": "assets/images/patient_4.png"
      },
      {
        "id": "default5",
        "name": "Dr. Fahad Akram",
        "specialty": "Eye Specialist",
        "rating": "4.7",
        "fee": "Rs 1500",
        "location": "LRBT Shahpur Saddar, Sargodha",
        "image": "assets/images/patient_5.png"
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "Doctor"),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        doctors.isNotEmpty ? doctors[0]["image"]! : "assets/images/patient_1.png",
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctors.isNotEmpty ? doctors[0]["name"]! : "Loading...", 
                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(doctors.isNotEmpty ? doctors[0]["specialty"]! : "Specialist", 
                             style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            _infoBadge(LucideIcons.star, doctors.isNotEmpty ? doctors[0]["rating"]! : "4.5"),
                            SizedBox(width: 8),
                            _infoBadge(LucideIcons.dollarSign, doctors.isNotEmpty ? doctors[0]["fee"]! : "Rs 1500"),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(LucideIcons.mapPin, color: Colors.grey, size: 16),
                            SizedBox(width: 4),
                            Text(doctors.isNotEmpty ? doctors[0]["location"]! : "Hospital", 
                                 style: TextStyle(color: Colors.grey)),
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
        final selectedDoctor = {
          'id': doctors[0]['id'] ?? 'default1',
          'name': doctors[0]['name'],
          'specialty': doctors[0]['specialty'],
          'rating': doctors[0]['rating'],
          'fee': doctors[0]['fee'],
          'location': title == "Personal Clinic" ? subtitle : doctors[0]['location'],
          'image': doctors[0]['image'],
        };
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentBookingFlow(
              preSelectedDoctor: selectedDoctor,
            ),
          ),
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
