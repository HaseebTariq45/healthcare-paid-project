import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthcare/views/screens/patient/dashboard/home.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final String appointmentId;
  final double amount;
  final String doctorName;
  final String? hospitalName;
  final String paymentMethod;

  const PaymentConfirmationScreen({
    super.key,
    required this.appointmentId,
    required this.amount,
    required this.doctorName,
    this.hospitalName,
    required this.paymentMethod,
  });

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  bool _isProcessing = false;
  bool _isSuccess = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _processPayment();
  }

  // Process the payment and update Firestore
  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get the doctor ID from the appointment
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();
          
      if (!appointmentDoc.exists) {
        throw Exception('Appointment not found');
      }
      
      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      final doctorId = appointmentData['doctorId'];
      
      if (doctorId == null) {
        throw Exception('Doctor information missing from appointment');
      }

      // Update appointment with payment information
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'paymentStatus': 'completed',
        'paymentDate': FieldValue.serverTimestamp(),
        'paymentMethod': widget.paymentMethod,
        'fee': widget.amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create a transaction record for the patient
      await FirebaseFirestore.instance.collection('transactions').add({
        'patientId': userId,
        'doctorId': doctorId,
        'appointmentId': widget.appointmentId,
        'title': 'Appointment Payment',
        'description': 'Payment for appointment with ${widget.doctorName}',
        'amount': widget.amount,
        'date': FieldValue.serverTimestamp(),
        'type': 'payment',
        'status': 'completed',
        'paymentMethod': widget.paymentMethod,
        'doctorName': widget.doctorName,
        'hospitalName': widget.hospitalName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Record the earning for the doctor
      await FirebaseFirestore.instance.collection('doctor_earnings').add({
        'doctorId': doctorId,
        'patientId': userId,
        'appointmentId': widget.appointmentId,
        'title': 'Consultation Fee',
        'description': 'Payment received for appointment',
        'amount': widget.amount,
        'date': FieldValue.serverTimestamp(),
        'status': 'completed',
        'patientName': appointmentData['patientName'] ?? 'Patient',
        'paymentMethod': widget.paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update doctor's total earnings in their profile (optional)
      final doctorRef = FirebaseFirestore.instance.collection('doctors').doc(doctorId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doctorDoc = await transaction.get(doctorRef);
        
        if (doctorDoc.exists) {
          final currentEarnings = doctorDoc.data()?['totalEarnings'] ?? 0;
          final newEarnings = currentEarnings + widget.amount;
          
          transaction.update(doctorRef, {
            'totalEarnings': newEarnings,
            'lastPaymentDate': FieldValue.serverTimestamp(),
          });
        }
      });

      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });
    } catch (e) {
      print('Payment error: $e');
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _errorMessage = 'Payment failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          'Payment Confirmation',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isProcessing) ...[
                  CircularProgressIndicator(
                    color: Color(0xFF3366CC),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Processing Payment...',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Please wait while we process your payment.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ] else if (_isSuccess) ...[
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.checkCheck,
                      color: Colors.green,
                      size: 64,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Payment Successful!',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Your appointment with ${widget.doctorName} has been confirmed.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Amount Paid', 'Rs. ${widget.amount}'),
                        Divider(height: 24),
                        _buildInfoRow('Payment Method', widget.paymentMethod),
                        Divider(height: 24),
                        _buildInfoRow('Status', 'Completed'),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => PatientHomeScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3366CC),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Return Home',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.alertCircle,
                      color: Colors.red,
                      size: 64,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Payment Failed',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3366CC),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
} 