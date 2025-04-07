import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/appointment/all_appoinments.dart';
import 'package:healthcare/views/screens/complete_profile/profile1.dart';

class HomeScreen extends StatefulWidget {
  final String profileStatus;
  const HomeScreen({super.key, this.profileStatus = "incomplete"});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    // double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(25, 80, 25, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "Dr. Asmara",
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 25,
                  backgroundImage: AssetImage("assets/images/User.png"),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Earnings Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color.fromRGBO(64, 124, 226, 1),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(158, 158, 158, 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.paid_outlined, color: Colors.white, size: 50),
                  // Image(image: AssetImage("assets/images/earnings.png")),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Total Earning",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "\$400.00",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Ratings Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(158, 158, 158, 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.thumb_up, color: Color.fromRGBO(64, 124, 226, 1)),
                      SizedBox(width: 8),
                      Text(
                        "Overall Ratings",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "4.2/5",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(64, 124, 226, 1),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.star, color: Colors.yellow, size: 24),
                      Icon(Icons.star, color: Colors.yellow, size: 24),
                      Icon(Icons.star, color: Colors.yellow, size: 24),
                      Icon(Icons.star_half, color: Colors.yellow, size: 24),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Based on 121 reviews",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Upcoming Appointments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Upcoming Appointments",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentsScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "See all",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Color.fromRGBO(64, 124, 226, 1),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            Column(
              children: List.generate(3, (index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 10),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(158, 158, 158, 0.3),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Appointment with Hania",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "Jan 10, 2025\n12:00 pm - 1:00 pm",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Color.fromRGBO(34, 31, 31, 0.8),
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
                      builder: (context) => const CompleteProfileScreen(),
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
