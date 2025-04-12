import 'package:flutter/material.dart';
import 'dart:ui';  // Add this import for ImageFilter
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/successfull_appoinment.dart';
import 'package:healthcare/views/screens/menu/appointment_history.dart';
import 'package:healthcare/views/screens/patient/appointment/completed_appointments_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare/views/screens/patient/dashboard/finance.dart';
import 'package:healthcare/utils/patient_navigation_helper.dart';
import 'package:healthcare/views/screens/appointment/all_appoinments.dart';

class JazzCashPaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? appointmentDetails;
  
  const JazzCashPaymentScreen({
    super.key,
    this.appointmentDetails,
  });

  @override
  _JazzCashPaymentScreenState createState() => _JazzCashPaymentScreenState();
}

class _JazzCashPaymentScreenState extends State<JazzCashPaymentScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _confirmPayment() {
    String phoneNumber = _phoneController.text;
    if (phoneNumber.isNotEmpty && phoneNumber.length >= 10) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      Future.delayed(Duration(seconds: 2), () async {
        // Get the current user ID
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userId = user.uid;
          
          try {
            // Get the fee amount directly as it's already a number
            int amountValue = widget.appointmentDetails?['fee'] ?? 0;
            
            // 1. Save the appointment to Firestore
            final appointmentRef = await FirebaseFirestore.instance.collection('appointments').add({
              'patientId': userId,
              'doctorId': widget.appointmentDetails?['doctorId'],
              'doctorName': widget.appointmentDetails?['doctorName'],
              'date': widget.appointmentDetails?['date'],
              'time': widget.appointmentDetails?['time'],
              'location': widget.appointmentDetails?['location'],
              'hospitalName': widget.appointmentDetails?['hospitalName'] ?? 'Unknown Hospital',
              'hospitalId': widget.appointmentDetails?['hospitalId'],
              'fee': amountValue,
              'displayFee': widget.appointmentDetails?['displayFee'],
              'status': 'confirmed',
              'paymentStatus': 'completed',
              'paymentMethod': 'JazzCash',
              'paymentDate': FieldValue.serverTimestamp(),
              'bookingDate': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
              'notes': widget.appointmentDetails?['notes'],
              'isPanelConsultation': widget.appointmentDetails?['isPanelConsultation'] ?? false,
              // Store transaction reference to prevent duplicate entries
              'hasFinancialTransaction': true,
            });
            
            // 2. Save the transaction to Firestore
            await FirebaseFirestore.instance.collection('transactions').add({
              'userId': userId,
              'patientId': userId,
              'doctorId': widget.appointmentDetails?['doctorId'],
              'appointmentId': appointmentRef.id,
              'title': 'Appointment Payment',
              'description': 'Consultation with ${widget.appointmentDetails?['doctorName']}',
              'amount': amountValue,
              'date': Timestamp.now(),
              'type': 'payment',
              'status': 'completed',
              'paymentMethod': 'JazzCash',
              'doctorName': widget.appointmentDetails?['doctorName'],
              'hospitalName': widget.appointmentDetails?['hospitalName'],
              'createdAt': Timestamp.now(),
              'updatedAt': Timestamp.now(),
            });
            
            // 3. Update the appointment slot status to booked
            final String? slotId = widget.appointmentDetails?['slotId'];
            if (slotId != null) {
              await FirebaseFirestore.instance.collection('appointment_slots').doc(slotId).update({
                'isBooked': true,
                'tempHoldUntil': null,
                'tempHoldBy': null,
                'bookedAt': FieldValue.serverTimestamp(),
                'bookedBy': userId,
                'appointmentId': appointmentRef.id,
              });
              print('Appointment slot updated successfully');
            } else {
              print('No slotId found in appointment details');
            }
            
            print('Appointment and transaction saved successfully');
            
            // Show success dialog
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Dialog(
                insetPadding: EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 10,
                shadowColor: Colors.black38,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE00000),
                            Color(0xFFFF4D4D),
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Icon(
                              LucideIcons.checkCheck,
                        color: Color(0xFFE00000),
                              size: 44,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Payment Successful!",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                    Text(
                            "Your appointment has been confirmed",
                      style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                    ),
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                      Container(
                            padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                              color: Color(0xFFFFF5F5),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                        ),
                        child: Row(
                          children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE00000).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                              LucideIcons.creditCard,
                                    size: 24,
                              color: Color(0xFFE00000),
                            ),
                                ),
                                SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Amount Paid",
                                    style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                        "Rs. ${widget.appointmentDetails?['fee'] ?? '0'}",
                                    style: GoogleFonts.poppins(
                                          fontSize: 18,
                                      fontWeight: FontWeight.w600,
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
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      PatientNavigationHelper.navigateToHome(context);
                      Future.delayed(Duration(milliseconds: 100), () {
                                      PatientNavigationHelper.navigateToTab(context, 2); // Navigate to Finances tab
                      });
                    },
                    style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFE00000),
                      foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                                    shadowColor: Color(0xFFE00000).withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: Icon(LucideIcons.wallet, size: 18),
                                  label: Text(
                                    "View Payment",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context); // Close the dialog
                                    // Navigate directly to appointments screen
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AppointmentsScreen(),
                                      ),
                                      (route) => route.isFirst, // Keep only the first route
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Color(0xFF2754C3),
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(color: Color(0xFF2754C3).withOpacity(0.5), width: 1.5),
                                    ),
                                  ),
                                  icon: Icon(LucideIcons.calendarCheck, size: 18),
                                  label: Text(
                                    "View Booking",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
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
          } catch (e) {
            print('Error saving appointment and transaction: $e');
            
            // Show error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      SizedBox(width: 10),
                      Text("Payment failed: ${e.toString()}"),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              
        setState(() {
          _isLoading = false;
        });
            }
          }
        } else {
          // User not signed in
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 10),
                    Text("You must be signed in to book an appointment"),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            
            setState(() {
              _isLoading = false;
            });
          }
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Text("Please enter a valid phone number"),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the appropriate fee from appointment details
    String fee = widget.appointmentDetails != null 
        ? (widget.appointmentDetails!.containsKey('displayFee') 
          ? widget.appointmentDetails!['displayFee'] 
          : (widget.appointmentDetails!.containsKey('fee')
              ? (widget.appointmentDetails!['fee'] is int 
                  ? "Rs. ${widget.appointmentDetails!['fee']}" 
                  : widget.appointmentDetails!['fee'])
              : 'Rs. 2,000'))
        : 'Rs. 2,000';
    
    String doctor = widget.appointmentDetails != null && widget.appointmentDetails!.containsKey('doctor') 
        ? widget.appointmentDetails!['doctor'] 
        : 'Doctor';

    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "JazzCash Payment"),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
                child: Padding(
              padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  // JazzCash Logo & Info
                  _buildHeaderImage(),
                  
                  SizedBox(height: 30),
                  
                  // Payment Information
                      Container(
                    padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                            ),
                          ],
                        ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                          "Payment Summary",
                                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 15),
                        _buildSummaryRow(
                          "Appointment",
                          "Consultation with ${widget.appointmentDetails?['doctorName'] ?? 'Doctor'}",
                          LucideIcons.calendar,
                        ),
                        Divider(height: 20),
                        _buildSummaryRow(
                          "Amount",
                          widget.appointmentDetails != null 
                              ? (widget.appointmentDetails!.containsKey('displayFee') 
                                ? widget.appointmentDetails!['displayFee'] 
                                : "Rs. ${widget.appointmentDetails!['fee']}")
                              : 'Rs. 2,000',
                          LucideIcons.creditCard,
                          isAmount: true,
                            ),
                          ],
                        ),
                      ),
                      
                  SizedBox(height: 30),
                      
                      Text(
                    "JazzCash Details",
                        style: GoogleFonts.poppins(
                      fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  SizedBox(height: 20),
                  
                  // Phone number field with validation pattern
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Phone Number",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                          ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
              decoration: InputDecoration(
                          hintText: "03XX-XXXXXXX",
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            LucideIcons.smartphone,
                            color: Color(0xFFE00000),
                            size: 20,
                          ),
                          prefixText: _phoneController.text.isNotEmpty && !_phoneController.text.startsWith('03') ? '03' : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color(0xFFE00000),
                              width: 1.5,
                            ),
                          ),
                          errorText: _phoneController.text.isNotEmpty && !RegExp(r'^03\d{2}[0-9]{7}$').hasMatch(_phoneController.text) 
                              ? 'Enter a valid 11-digit JazzCash number' 
                              : null,
                          errorStyle: GoogleFonts.poppins(
                            color: Colors.red.shade600,
                            fontSize: 12,
                          ),
                          helperText: "Enter your 11-digit JazzCash number",
                          helperStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Payment Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE00000),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        shadowColor: Color(0xFFE00000).withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "Processing...",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              "Pay Now",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                            ),
                ),
              ),
            ),

                  SizedBox(height: 20),
                      
                  // Secure Payment Note
                      Container(
                    padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                        width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                        Icon(
                          LucideIcons.shieldCheck,
                          color: Color(0xFFE00000),
                          size: 22,
                        ),
                        SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Secure Payment",
                                    style: GoogleFonts.poppins(
                                  fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                "Your payment information is secure. We don't store your JazzCash details.",
                                    style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
          ],
                        ),
                      ),
                    ],
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
              color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE00000)),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Processing Payment",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Please wait while we process your payment...",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/jazzcash_logo.png',
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 60,
                width: 120,
                decoration: BoxDecoration(
                  color: Color(0xFFE00000),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  "JazzCash",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          Text(
            "Fast and secure mobile payments",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, IconData icon, {bool isAmount = false}) {
    return Row(
      children: [
        Icon(
          icon,
          color: isAmount ? Color(0xFFBA0000) : Colors.grey[600],
          size: 20,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isAmount ? Color(0xFFBA0000) : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
