import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/patient/appointment/available_doctors.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page1.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PatientHomeScreen extends StatefulWidget {
  final String profileStatus;
  const PatientHomeScreen({super.key, this.profileStatus = "incomplete"});

  @override
  _PatientHomeScreenState createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  late String profileStatus;

  @override
  void initState() {
    super.initState();
    profileStatus = widget.profileStatus;
    // Show popup automatically if the profile is not complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (profileStatus != "complete") {
        showPopup(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text("Welcome", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text("Amna", style: TextStyle(fontSize: 18, color: Colors.black54)),

              SizedBox(height: 15),

              // Search Bar
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(LucideIcons.search),
                  hintText: "Search doctor, appointments ..",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 15),

              // Book a Consultation Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DoctorsScreen()),
            );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text("Book a Consultation", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),

              SizedBox(height: 20),

              // Upcoming Appointments Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Upcoming Appointments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("See all", style: TextStyle(fontSize: 16, color: Colors.blue)),
                ],
              ),

              SizedBox(height: 10),

              // Appointments List
              Expanded(
                child: ListView.builder(
                  itemCount: 5, // Change dynamically
                  itemBuilder: (context, index) {
                    return AppointmentCard();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Appointment Card Widget
class AppointmentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Appointment with", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text("Dr. Rizwan", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Jan 10, 2025", style: TextStyle(fontSize: 14, color: Colors.grey)),
                Text("12:00 pm - 1:00 pm", style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible:
        false, // Prevent closing the dialog when tapping outside
    builder: (BuildContext context) {
      return Stack(
        children: [
          // Blurred background effect
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5,
              sigmaY: 5,
            ), // Adjust blur intensity
            child: Container(
              color: const Color.fromARGB(
                30,
                0,
                0,
                0,
              ), // Darken background slightly
            ),
          ),
          AlertDialog(
            backgroundColor: const Color.fromRGBO(64, 124, 226, 1),
            title: Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 20),
              child: Center(
                child: Text(
                  "Please Complete Your Profile first",
                  style: GoogleFonts.poppins(fontSize: 20, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            actions: [
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CompleteProfilePatient1Screen(),
                    ),
                  );
                },
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      color: const Color.fromRGBO(217, 217, 217, 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    width: 100,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        "Proceed",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

