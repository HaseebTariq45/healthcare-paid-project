import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/screens/menu/appointment_history.dart';
import 'package:healthcare/views/screens/menu/faqs.dart';
import 'package:healthcare/views/screens/menu/payment_method.dart';
import 'package:healthcare/views/screens/menu/profile_update.dart';
import 'package:healthcare/views/screens/onboarding/onboarding_3.dart';
import 'package:healthcare/views/screens/onboarding/signupoptions.dart';
import 'package:healthcare/views/screens/patient/complete_profile/profile_page1.dart';
import 'package:healthcare/views/screens/patient/dashboard/patient_profile_details.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:healthcare/views/screens/dashboard/menu.dart';

class PatientMenuScreen extends StatefulWidget {
  final String name;
  final String role;
  final int profileCompletionPercentage;
  final UserType userType;
  
  const PatientMenuScreen({
    super.key,
    this.name = "Amna",
    this.role = "Patient",
    this.profileCompletionPercentage = 0,
    this.userType = UserType.patient,
  });

  @override
  State<PatientMenuScreen> createState() => _PatientMenuScreenState();
}

class _PatientMenuScreenState extends State<PatientMenuScreen> {
  late List<MenuItem> menuItems;
  late int profileCompletionPercentage;
  
  @override
  void initState() {
    super.initState();
    _initializeMenuItems();
    profileCompletionPercentage = widget.profileCompletionPercentage;
  }
  
  void _initializeMenuItems() {
    menuItems = [
      MenuItem("Edit Profile", LucideIcons.user, const ProfileEditorScreen()),
      // MenuItem("Medical Records", LucideIcons.fileText, null),
      MenuItem("Appointments History", LucideIcons.history, const AppointmentHistoryScreen()),
      MenuItem("Payment Methods", LucideIcons.creditCard, PaymentMethodsScreen(userType: widget.userType)),
      MenuItem("FAQs", LucideIcons.info, const FAQScreen()),
      MenuItem("Help Center", LucideIcons.headphones, null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(),
                
                // Always show profile completion card
                _buildProfileCompletionCard(),
                
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        
                        Text(
                          "Settings",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Menu items
                        ...menuItems.map((item) => _buildMenuItem(item)).toList(),
                        
                        // Logout button
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
              ],
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 18),
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
          const SizedBox(height: 15),
          
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
                    radius: 40,
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
                    const SizedBox(height: 12),
                    
                    // View detailed profile button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientDetailProfileScreen(
                              name: widget.name,
                              age: "28", // This would come from actual user data
                              bloodGroup: "B+", // This would come from actual user data
                              phoneNumber: "+92 300 1234567", // This would come from actual user data
                              // Sample data - in a real app, these would be passed from state
                              allergies: const ["Peanuts", "Penicillin", "Dust Mites"],
                              diseases: const ["Asthma", "Migraine", "High Blood Pressure"],
                              height: 165,
                              weight: 65,
                              // Document files would be passed from the user's profile data
                              // In a real app, these would be loaded from a storage service
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.user,
                              color: Color(0xFF3366CC),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "View Medical Profile",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3366CC),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (item.screen != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => item.screen!),
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

  // New widget for profile completion card
  Widget _buildProfileCompletionCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: profileCompletionPercentage < 100
              ? [Color(0xFFFFA726), Color(0xFFFF7043)]
              : [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (profileCompletionPercentage < 100
                    ? Color(0xFFFF7043)
                    : Color(0xFF4CAF50))
                .withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  profileCompletionPercentage < 100
                      ? LucideIcons.user
                      : LucideIcons.userCheck,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  profileCompletionPercentage < 100
                      ? "Complete Your Profile"
                      : "Profile Complete",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$profileCompletionPercentage%",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: profileCompletionPercentage < 100
                        ? Color(0xFFFF7043)
                        : Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: profileCompletionPercentage / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          if (profileCompletionPercentage < 100) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompleteProfilePatient1Screen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Complete Now",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFF7043),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          LucideIcons.arrowRight,
                          size: 14,
                          color: Color(0xFFFF7043),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class MenuItem {
  final String title;
  final IconData icon;
  final Widget? screen;

  MenuItem(this.title, this.icon, this.screen);
}
