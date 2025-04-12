import 'package:flutter/material.dart';
import 'dart:ui';  // Add this import for ImageFilter
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
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFFFEEDED),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.check, 
                        color: Color(0xFFE00000),
                        size: 40,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Payment Successful",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
                content: Container(
                  constraints: BoxConstraints(minWidth: 300),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your payment has been processed successfully.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(0xFF555555),
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.creditCard,
                              size: 20,
                              color: Color(0xFFE00000),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Amount Paid",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Color(0xFF777777),
                                    ),
                                  ),
                                  Text(
                                    "${widget.appointmentDetails?['displayFee'] ?? 'Rs. 2,000'}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF222222),
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
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Close"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      // Navigate to Finances tab (index 2) in the bottom nav
                      PatientNavigationHelper.navigateToHome(context);
                      Future.delayed(Duration(milliseconds: 100), () {
                        PatientNavigationHelper.navigateToTab(context, 2);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE00000), // JazzCash red color
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    child: Text("View Payment History"),
                  ),
                ],
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
      body: Stack(
        children: [
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                      // JazzCash Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        width: double.infinity,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.wallet,
                              color: const Color(0xFFC2554D),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "JazzCash",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "Pay via JazzCash Mobile Account",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Enhanced Payment Information
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Amount to Pay",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  fee,
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFBA0000),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Divider(),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFEF8E8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    LucideIcons.stethoscope,
                                    color: Color(0xFFBA0000),
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Consultation",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        "Dr. $doctor",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Enhanced Phone Number Section
                      Text(
                        "Enter JazzCash Account",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "We'll send a payment request to this number",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Enhanced Phone Number Input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                          ),
              decoration: InputDecoration(
                            prefixIcon: Container(
                              padding: EdgeInsets.all(16),
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Color(0xFFFEF8E8),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                              child: Text(
                                "+92",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFBA0000),
                                ),
                              ),
                            ),
                            hintText: "3XX XXXXXXX",
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey[400],
                            ),
                filled: true,
                            fillColor: Colors.white,
                border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Color(0xFFBA0000),
                                width: 2,
                              ),
                            ),
                ),
              ),
            ),

                      SizedBox(height: 32),
                      
                      // Enhanced Security Message
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.shield,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Secure Payment",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Your payment details are protected",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
          ],
        ),
      ),
                      
                      SizedBox(height: 32),

                      // Enhanced Submit Button
                      Container(
      width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFBA0000).withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
      child: ElevatedButton(
                          onPressed: _isLoading ? null : _confirmPayment,
        style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFBA0000),
                            foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.wallet),
                                    SizedBox(width: 12),
                                    Text(
                                      "Confirm Payment",
          style: GoogleFonts.poppins(
            fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Enhanced Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFFEF8E8),
                            shape: BoxShape.circle,
                          ),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBA0000)),
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "Processing Payment",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Please wait while we process your payment",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
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
}
