import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/menu/appointment_history.dart';
import 'package:healthcare/views/screens/menu/faqs.dart';
import 'package:healthcare/views/screens/menu/payment_method.dart';
import 'package:healthcare/views/screens/menu/profile_update.dart';
import 'package:healthcare/views/screens/onboarding/onboarding_3.dart';


class PatientMenuScreen extends StatefulWidget {
  const PatientMenuScreen({super.key});

  @override
  State<PatientMenuScreen> createState() => _PatientMenuScreenState();
}

class _PatientMenuScreenState extends State<PatientMenuScreen> {
  final List<MenuItem> menuItems = [
    MenuItem("Update Profile", Icons.person_outline, ProfileEditorScreen()),
    MenuItem("Payment Methods", Icons.credit_card, PaymentMethodsScreen()),
    MenuItem("Appointments History", Icons.history, AppointmentHistoryScreen()),
    MenuItem("FAQs", Icons.help_outline, FAQScreen()),
    MenuItem("Help Center", Icons.support_agent),
    MenuItem("Logout", Icons.logout),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/images/User.png"), // Replace with actual profile image URL
            ),
            SizedBox(height: 10),
            Text(
              "Amna",
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatCard("Appointments", "25", Icons.local_hospital),
                SizedBox(width: 20),
                _buildStatCard("Earnings", "Rs 15000", Icons.attach_money),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return _buildMenuItem(menuItems[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 30),
        SizedBox(height: 5),
        Text(title, style: GoogleFonts.poppins(color: Colors.grey)),
        SizedBox(height: 3),
        Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
      ],
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(item.icon, color: Colors.blue),
        title: Text(item.title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          if (item.screen != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => item.screen!));
          }
          if (item.title == "Logout") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Onboarding3()),
            );
          }
        },
      ),
    );
  }
}

class MenuItem {
  final String title;
  final IconData icon;
  final Widget? screen;

  MenuItem(this.title, this.icon, [this.screen]);
}
