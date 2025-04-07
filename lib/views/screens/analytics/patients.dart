import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  final List<Map<String, String>> patients = const [
    {
      "name": "Ali",
      "age": "29 Years",
      "location": "Bhalwal",
      "image": "assets/images/patient_1.png",
    },
    {
      "name": "Fehmida",
      "age": "30 Years",
      "location": "Rahim Yar Khan",
      "image": "assets/images/patient_2.png",
    },
    {
      "name": "Asma",
      "age": "24 Years",
      "location": "Lahore",
      "image": "assets/images/patient_3.png",
    },
    {
      "name": "Sher Bano",
      "age": "33 Years",
      "location": "Risalpur",
      "image": "assets/images/patient_4.png",
    },
    {
      "name": "Naheed",
      "age": "30 Years",
      "location": "Soon Valley, Sakesar",
      "image": "assets/images/patient_5.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "Patients"),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 10),
            _buildFilters(),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  return _buildPatientCard(
                    patients[index]["name"]!,
                    patients[index]["age"]!,
                    patients[index]["location"]!,
                    patients[index]["image"]!,
                  );
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
          hintText: "Search Patients",
          border: InputBorder.none,
          icon: Icon(Icons.search_outlined, color: Colors.grey, size: 30),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildFilterButton(Icons.filter_list, "Filters", Colors.white, false),
        _buildFilterButton(Icons.star, "4 +", Colors.white, true),
        _buildFilterButton(Icons.location_on, "Islamabad", Colors.white, true),
      ],
    );
  }

  Widget _buildFilterButton(
    IconData icon,
    String label,
    Color bgColor,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected || label == "Filters"
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color:
                    isSelected || label == "Filters"
                        ? Colors.grey.shade600
                        : Colors.grey.shade300,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(
    String name,
    String age,
    String location,
    String image,
  ) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  age,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
