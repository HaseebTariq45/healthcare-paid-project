import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneBookingScreen extends StatelessWidget {
  const PhoneBookingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Book via Phone",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header image
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Color(0xFFEAF2FF),
                ),
                child: Stack(
                  children: [
                    // Background design elements
                    Positioned(
                      top: -20,
                      right: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3366CC).withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3366CC).withOpacity(0.1),
                        ),
                      ),
                    ),
                    // Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.headset_mic,
                            size: 60,
                            color: Color(0xFF3366CC),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Customer Service",
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3366CC),
                            ),
                          ),
                          Text(
                            "Book your appointment by phone",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Instructions
              Text(
                "How it works",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              
              // Step 1
              _buildInstructionStep(
                "1",
                "Call customer service",
                "Our representatives are available from 9am to 8pm, 7 days a week."
              ),
              
              // Step 2
              _buildInstructionStep(
                "2",
                "Provide your details",
                "Share your name, contact information, and any medical reports if available."
              ),
              
              // Step 3
              _buildInstructionStep(
                "3",
                "Specify preferences",
                "Let us know your preferred doctor, specialty, date and time."
              ),
              
              // Step 4
              _buildInstructionStep(
                "4",
                "Confirm appointment",
                "Give your confirmation to confirm your appointment."                
              ),
              
              SizedBox(height: 32),
              
              // Contact Numbers
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF3366CC).withOpacity(0.3)),
                  color: Color(0xFFEAF2FF),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Contact Numbers",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Helpline number
                    _buildPhoneCard(
                      context,
                      "Main Helpline",
                      "0300 1234567",
                      "For general booking inquiries",
                      Icons.headset_mic,
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Emergency booking number
                    _buildPhoneCard(
                      context,
                      "Priority Booking",
                      "0300 7654321",
                      "For urgent appointments",
                      Icons.local_hospital,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Working hours
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Color(0xFF3366CC),
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Working Hours",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildTimeRow("Monday - Friday", "9:00 AM - 8:00 PM"),
                    SizedBox(height: 8),
                    _buildTimeRow("Saturday", "10:00 AM - 6:00 PM"),
                    SizedBox(height: 8),
                    _buildTimeRow("Sunday", "10:00 AM - 4:00 PM"),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              
              // Additional note
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Color(0xFFFFF9C4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade800,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "For medical emergencies, please call emergency services at 1122 or go to the nearest hospital.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInstructionStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF3366CC),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPhoneCard(BuildContext context, String title, String number, String description, IconData icon) {
    return InkWell(
      onTap: () => _makePhoneCall(context, number),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF3366CC).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Color(0xFF3366CC),
                size: 22,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    number,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3366CC),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _makePhoneCall(context, number),
              icon: Icon(
                Icons.phone,
                color: Colors.white,
                size: 14,
              ),
              label: Text(
                "Call",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3366CC),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
                shadowColor: Color(0xFF3366CC).withOpacity(0.3),
                minimumSize: Size(70, 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeRow(String day, String hours) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          hours,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3366CC),
          ),
        ),
      ],
    );
  }
  
  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    // Show a dialog with the phone number
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Call this number",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Would you like to call:",
              style: GoogleFonts.poppins(),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.phone, 
                  color: Color(0xFF3366CC),
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  phoneNumber,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Color(0xFF3366CC),
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: phoneNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Phone number copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Launch phone dialer using a more reliable approach
              final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber.replaceAll(' ', ''));
              try {
                // First try with launchUrl
                bool launched = await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
                
                // If launchUrl returns false or throws an exception, try with a different approach
                if (!launched) {
                  final String telUrl = 'tel:${phoneNumber.replaceAll(' ', '')}';
                  await launchUrl(Uri.parse(telUrl));
                }
              } catch (e) {
                print('Error launching phone app: $e');
                
                // Try one more time with a simpler approach
                try {
                  final String telUrl = 'tel:${phoneNumber.replaceAll(' ', '')}';
                  await launchUrl(Uri.parse(telUrl), mode: LaunchMode.platformDefault);
                } catch (e) {
                  print('Failed to launch phone app again: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not launch phone dialer. Error: $e'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3366CC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Call",
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }
} 