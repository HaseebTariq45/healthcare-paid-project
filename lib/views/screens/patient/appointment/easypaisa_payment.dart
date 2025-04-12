import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/successfull_appoinment.dart';
import 'package:healthcare/views/screens/patient/dashboard/finance.dart';
import 'package:healthcare/views/screens/menu/appointment_history.dart';
import 'package:healthcare/views/screens/patient/appointment/completed_appointments_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare/utils/patient_navigation_helper.dart';

class EasypaisaPaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? appointmentDetails;
  
  const EasypaisaPaymentScreen({
    super.key,
    this.appointmentDetails,
  });

  @override
  _EasypaisaPaymentScreenState createState() => _EasypaisaPaymentScreenState();
}

class _EasypaisaPaymentScreenState extends State<EasypaisaPaymentScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

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
              'paymentMethod': 'EasyPaisa',
              'paymentDate': FieldValue.serverTimestamp(),
              'bookingDate': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
              'notes': widget.appointmentDetails?['notes'],
              'isPanelConsultation': widget.appointmentDetails?['isPanelConsultation'] ?? false,
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
              'paymentMethod': 'EasyPaisa',
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
                        color: Color(0xFFEAF7E9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.check, 
                        color: Color(0xFF00822B),
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
                              color: Color(0xFF00822B),
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
                      backgroundColor: Color(0xFF00822B), // Easypaisa dark green (better contrast)
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
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "EasyPaisa Payment"),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  // EasyPaisa Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FFF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: double.infinity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.wallet,
                          color: const Color(0xFF4CAF50),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "EasyPaisa",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                "Pay via EasyPaisa Mobile Account",
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
                          "Consultation with $doctor",
                          LucideIcons.calendar,
                        ),
                        Divider(height: 20),
                        _buildSummaryRow(
                          "Amount",
                          fee,
                          LucideIcons.creditCard,
                          isAmount: true,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Phone Number Section
                  Text(
                    "Enter EasyPaisa Account",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "We'll send a payment request to this number",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 20),

            // Phone Number Input
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 3),
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
                          padding: EdgeInsets.all(12),
                          child: Text(
                            "+92",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        hintText: "3XX XXXXXXX",
                filled: true,
                        fillColor: Colors.white,
                border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: Color(0xFF4CAF50),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Security Message
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.shield,
                          color: Colors.green,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Your payment is secure. We do not store any payment details.",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Submit Button
                  _buildSubmitButton(),
                  
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Loading Overlay
          if (_isLoading)
            Container(
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
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Processing payment...",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAmount ? Color(0xFFE8F5E9) : Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isAmount ? Color(0xFF4CAF50) : Colors.grey.shade700,
              size: 18,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: isAmount ? FontWeight.w700 : FontWeight.w500,
                    color: isAmount ? Color(0xFF4CAF50) : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _confirmPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 15),
        ),
        child: _isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Confirm Payment",
          style: GoogleFonts.poppins(
            fontSize: 16,
                      fontWeight: FontWeight.w600,
          ),
                  ),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, size: 18),
                ],
        ),
      ),
    );
  }
}
