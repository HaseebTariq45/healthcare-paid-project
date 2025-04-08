import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/menu/appointment_history.dart';
import 'package:healthcare/views/screens/menu/availability.dart';
import 'package:healthcare/views/screens/menu/faqs.dart';
import 'package:healthcare/views/screens/menu/payment_method.dart';
import 'package:healthcare/views/screens/menu/profile_update.dart';
import 'package:healthcare/views/screens/menu/withdrawal_history.dart';
import 'package:healthcare/views/screens/onboarding/onboarding_3.dart';
import 'package:healthcare/views/screens/onboarding/signupoptions.dart';
import 'package:healthcare/views/screens/patient/appointment/available_doctors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum UserType { doctor, patient }

class MenuScreen extends StatefulWidget {
  final UserType userType;
  final String name;
  final String role;
  
  const MenuScreen({
    super.key, 
    this.userType = UserType.doctor,
    this.name = "Dr. Asmara",
    this.role = "General Practitioner",
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late List<MenuItem> menuItems;
  
  @override
  void initState() {
    super.initState();
    _initializeMenuItems();
  }
  
  void _initializeMenuItems() {
    if (widget.userType == UserType.doctor) {
      menuItems = [
        MenuItem("Edit Profile", LucideIcons.user, const ProfileEditorScreen(), category: "Account"),
        MenuItem("Update Availability", LucideIcons.calendar, const SetAvailabilityScreen(), category: "Appointment"),
        MenuItem("Appointments History", LucideIcons.history, const AppointmentHistoryScreen(), category: "Appointment"),
        MenuItem("Payment Methods", LucideIcons.creditCard, const PaymentMethodsScreen(), category: "Payment"),
        MenuItem("Withdrawal History", LucideIcons.wallet, const WithdrawalHistoryScreen(), category: "Payment"),
        MenuItem("FAQs", LucideIcons.info, const FAQScreen(), category: "Support"),
        MenuItem("Help Center", LucideIcons.headphones, null, category: "Support"),
        MenuItem("Logout", LucideIcons.logOut, null, category: ""),
      ];
    } else {
      // Patient menu items
      menuItems = [
        MenuItem("Edit Profile", LucideIcons.user, const ProfileEditorScreen(), category: "Account"),
        MenuItem("Medical Records", LucideIcons.fileText, null, category: "Health"),
        MenuItem("Appointments History", LucideIcons.history, const AppointmentHistoryScreen(), category: "Appointment"),
        MenuItem("Payment Methods", LucideIcons.creditCard, const PaymentMethodsScreen(), category: "Payment"),
        MenuItem("FAQs", LucideIcons.info, const FAQScreen(), category: "Support"),
        MenuItem("Help Center", LucideIcons.headphones, null, category: "Support"),
        MenuItem("Logout", LucideIcons.logOut, null, category: ""),
      ];
    }
  }

  // Group the menu items by category
  Map<String, List<MenuItem>> get _groupedMenuItems {
    final Map<String, List<MenuItem>> result = {};
    
    for (var item in menuItems) {
      if (item.category.isEmpty) continue; // Skip the logout item for grouping
      
      if (!result.containsKey(item.category)) {
        result[item.category] = [];
      }
      
      result[item.category]!.add(item);
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildProfileHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      // Build each category section
                      ..._groupedMenuItems.entries.map((entry) => 
                        _buildCategorySection(entry.key, entry.value)
                      ).toList(),
                      
                      // Logout button at the bottom
                      _buildLogoutButton(),
                      
                      const SizedBox(height: 25),
                      
                      // App version info
                      Center(
                        child: Column(
                          children: [
                            Text(
                              "HealthCare App",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3366CC),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Version 1.0.0",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3366CC),
            Color(0xFF5E8EF7),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3366CC).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, widget.userType == UserType.patient ? 20 : 35),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.arrowLeft,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              Text(
                "My Profile",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Profile section
          Row(
            children: [
              // Profile image with border
              Hero(
                tag: 'profileImage',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: widget.userType == UserType.patient ? 40 : 55,
                    backgroundImage: const AssetImage("assets/images/User.png"),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      widget.role,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Only show stats for doctors
          if (widget.userType == UserType.doctor) ...[
            const SizedBox(height: 20),
            // Stats cards
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    "Appointments", 
                    "25",
                    LucideIcons.calendar,
                  ),
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildStatCard(
                    "Earnings", 
                    "Rs 15,000",
                    LucideIcons.wallet,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title, 
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12, top: 5),
          child: Text(
            category,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final int index = entry.key;
              final MenuItem item = entry.value;
              final bool isLast = index == items.length - 1;
              
              return Column(
                children: [
                  _buildMenuItem(item),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 65,
                      endIndent: 20,
                      color: Colors.grey.shade100,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (item.title == "Logout") {
            _showLogoutDialog();
          } else if (item.navigationScreen != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item.navigationScreen!),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: const Color(0xFF3366CC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Icon(
                LucideIcons.chevronRight,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.only(top: 5, bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFE5E5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showLogoutDialog(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.logOut,
                    color: Color(0xFFFF5252),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  "Logout",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFF5252),
                  ),
                ),
                const Spacer(),
                const Icon(
                  LucideIcons.chevronRight,
                  color: Color(0xFFFF9E9E),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.logOut,
                    color: Color(0xFFFF5252),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Log Out",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Are you sure you want to log out of your account?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade800,
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context, 
                            MaterialPageRoute(builder: (context) => SignUpOptions()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5252),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          "Log Out",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MenuItem {
  final String title;
  final IconData icon;
  final Widget? navigationScreen;
  final String category;

  MenuItem(this.title, this.icon, this.navigationScreen, {this.category = ""});
}
