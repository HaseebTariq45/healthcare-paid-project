import 'package:flutter/material.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/set_location.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DoctorsScreen extends StatefulWidget {
  @override
  _DoctorsScreenState createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  String? selectedRating;
  String? selectedLocation;
  String? selectedSpeciality;

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
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => _showFilterPopup());
  }

  void _showFilterPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Set Filters"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDropdown("Select Rating", ["4+", "3+", "2+", "1+"], (value) {
                setState(() => selectedRating = value);
              }),
              _buildDropdown("Select Location", ["Islamabad", "Rawalpindi", "Lahore"], (value) {
                setState(() => selectedLocation = value);
              }),
              _buildDropdown("Select Speciality", ["Cardiologist", "Dentist", "Orthopaedic"], (value) {
                setState(() => selectedSpeciality = value);
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown(String hint, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(border: OutlineInputBorder()),
        hint: Text(hint),
        value: null,
        onChanged: onChanged,
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "Doctors"),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search doctor, appointments ..",
                prefixIcon: Icon(LucideIcons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _filterButton("Filters", LucideIcons.filter),
                _filterButton("4 +", LucideIcons.star),
                _filterButton("Islamabad", LucideIcons.mapPin),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DoctorDetailsScreen(),
                        ),
                      );
                    },
                    child: DoctorCard(
                      name: doctors[index]["name"]!,
                      specialty: doctors[index]["specialty"]!,
                      rating: doctors[index]["rating"]!,
                      fee: doctors[index]["fee"]!,
                      location: doctors[index]["location"]!,
                      image: doctors[index]["image"]!,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String text, IconData icon) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.blue,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 1,
      ),
      icon: Icon(icon, size: 18),
      label: Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
      onPressed: () {},
    );
  }
}

// Doctor Card Widget
class DoctorCard extends StatelessWidget {
  final String name, specialty, rating, fee, location, image;

  const DoctorCard({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.fee,
    required this.location,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),

            // Doctor Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(specialty, style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),

                  // Rating & Fee Row
                  Row(
                    children: [
                      _infoBadge(LucideIcons.star, rating),
                      const SizedBox(width: 8),
                      _infoBadge(LucideIcons.dollarSign, fee),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(location, style: TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for Badge Icons (Rating & Fee)
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
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
