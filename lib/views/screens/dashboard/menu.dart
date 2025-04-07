import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/menu/appointment_history.dart';
import 'package:healthcare/views/screens/menu/availability.dart';
import 'package:healthcare/views/screens/menu/faqs.dart';
import 'package:healthcare/views/screens/menu/payment_method.dart';
import 'package:healthcare/views/screens/menu/profile_update.dart';
import 'package:healthcare/views/screens/menu/withdrawal_history.dart';
import 'package:healthcare/views/screens/onboarding/onboarding_3.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final List<MenuItem> menuItems = [
    MenuItem("Edit Profile", LucideIcons.user, ProfileEditorScreen()),
    MenuItem("Update Availability", LucideIcons.calendar, SetAvailabilityScreen()),
    MenuItem("Appointments History", LucideIcons.history, AppointmentHistoryScreen()),
    MenuItem("Payment Methods", LucideIcons.creditCard, PaymentMethodsScreen()),
    MenuItem("FAQs", Icons.help_outline, FAQScreen()),
    MenuItem("Withdrawal History", LucideIcons.wallet, WithdrawalHistoryScreen()),
    MenuItem("Help Center", LucideIcons.headphones),
    MenuItem("Logout", LucideIcons.logOut),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Solid color header with profile info
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromRGBO(64, 124, 226, 1),
                    Color.fromRGBO(84, 144, 246, 1),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(64, 124, 226, 0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(20, 35, 20, 35),
              child: Column(
                children: [
                  // Profile image with border
                  Hero(
                    tag: 'profileImage',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundImage: AssetImage("assets/images/User.png"),
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    "Dr. Asmara",
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black12,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "General Practitioner",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Stats cards - enhanced with background
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatCard("Appointments", "25"),
                        Container(
                          height: 45,
                          width: 1.5,
                          margin: EdgeInsets.symmetric(horizontal: 24),
                          color: Colors.white.withOpacity(0.4),
                        ),
                        _buildStatCard("Earnings", "Rs 15,000"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.fromLTRB(22, 25, 22, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Settings & Options",
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(64, 124, 226, 0.12),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(64, 124, 226, 0.08),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      LucideIcons.settings,
                      color: Color.fromRGBO(64, 124, 226, 1),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu items list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 18),
                physics: BouncingScrollPhysics(),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    transform: Matrix4.translationValues(0, index * 5.0, 0)..translate(0, -index * 5.0),
                    child: _buildMenuItem(menuItems[index], index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black12,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        SizedBox(height: 6),
        Text(
          title, 
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(MenuItem item, int index) {
    final bool isLogout = item.title == "Logout";
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isLogout ? Color(0xFFFEE8E9) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isLogout ? Colors.red.withOpacity(0.08) : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isLogout ? Color(0xFFFFCDD2) : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: isLogout 
              ? Colors.red.withOpacity(0.1) 
              : Color(0xFF3366FF).withOpacity(0.05),
          highlightColor: isLogout 
              ? Colors.red.withOpacity(0.05) 
              : Color(0xFF3366FF).withOpacity(0.025),
          onTap: () {
            if (item.screen != null) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => item.screen!));
            }
            if (isLogout) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Onboarding3()),
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLogout 
                      ? Color(0xFFFFEBEE) 
                      : Color(0xFF3366FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: isLogout 
                          ? Colors.red.withOpacity(0.1) 
                          : Color(0xFF3366FF).withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  item.icon, 
                  color: isLogout 
                      ? Colors.redAccent 
                      : Color(0xFF3366FF),
                  size: 22,
                ),
              ),
              title: Text(
                item.title, 
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isLogout ? Colors.redAccent : Color(0xFF333333),
                ),
              ),
              trailing: Container(
                decoration: BoxDecoration(
                  color: isLogout 
                      ? Colors.redAccent.withOpacity(0.08) 
                      : Color(0xFF3366FF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(8),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: isLogout ? Colors.redAccent : Color(0xFF3366FF),
                ),
              ),
            ),
          ),
        ),
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
