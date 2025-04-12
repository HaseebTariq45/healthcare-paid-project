import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:healthcare/views/screens/patient/appointment/card_payment.dart';
import 'package:healthcare/views/screens/patient/appointment/easypaisa_payment.dart';
import 'package:healthcare/views/screens/patient/appointment/jazzcash_payment.dart';
import 'package:healthcare/views/screens/patient/appointment/saved_cards.dart';

class PatientPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> appointmentDetails;
  const PatientPaymentScreen({super.key, required this.appointmentDetails});

  @override
  _PatientPaymentScreenState createState() => _PatientPaymentScreenState();
}

class _PatientPaymentScreenState extends State<PatientPaymentScreen> {
  String? selectedPaymentMethod = "JazzCash"; // Default selection
  bool _isLoading = false;

  void _proceedToPayment() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });

      if (selectedPaymentMethod == "JazzCash") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JazzCashPaymentScreen(
              appointmentDetails: widget.appointmentDetails,
            ),
          ),
        );
      } else if (selectedPaymentMethod == "EasyPaisa") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EasypaisaPaymentScreen(
              appointmentDetails: widget.appointmentDetails,
            ),
          ),
        );
      } else if (selectedPaymentMethod == "Debit Card") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SavedCardsScreen(
              appointmentDetails: widget.appointmentDetails,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Method',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appointment Summary
                  _buildAppointmentSummary(),
                  SizedBox(height: 30),
                  
                  // Payment Methods Title
                  Text(
                    'Select Payment Method',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Payment Options
                  _buildPaymentOption(
                    "JazzCash",
                    "Pay using JazzCash wallet or mobile account",
                    LucideIcons.wallet,
                    Color(0xFFF44336),
                  ),
                  _buildPaymentOption(
                    "EasyPaisa",
                    "Pay using EasyPaisa wallet or mobile account",
                    LucideIcons.wallet,
                    Color(0xFF2196F3),
                  ),
                  _buildPaymentOption(
                    "Debit Card",
                    "Pay using your debit/credit card",
                    LucideIcons.creditCard,
                    Color(0xFF4CAF50),
                  ),

                  SizedBox(height: 30),
                  _buildSubmitButton(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3366CC)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFE6EFFF),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            LucideIcons.user,
            "Doctor",
            widget.appointmentDetails['doctor'] ?? 'Not selected',
          ),
          SizedBox(height: 12),
          _buildSummaryRow(
            LucideIcons.calendar,
            "Date",
            widget.appointmentDetails['date'] ?? 'Not selected',
          ),
          SizedBox(height: 12),
          _buildSummaryRow(
            LucideIcons.clock,
            "Time",
            widget.appointmentDetails['time'] ?? 'Not selected',
          ),
          SizedBox(height: 12),
          _buildSummaryRow(
            LucideIcons.mapPin,
            "Location",
            widget.appointmentDetails['hospitalName'] ?? widget.appointmentDetails['location'] ?? 'Not selected',
          ),
          SizedBox(height: 12),
          _buildSummaryRow(
            LucideIcons.creditCard,
            "Fee",
            widget.appointmentDetails['displayFee'] ?? 
            (widget.appointmentDetails['fee'] != null 
              ? widget.appointmentDetails['fee'].toString() 
              : 'Not selected'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF3366CC).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Color(0xFF3366CC),
            size: 16,
          ),
        ),
        SizedBox(width: 12),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String method, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedPaymentMethod = method;
          });
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selectedPaymentMethod == method
                ? color.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectedPaymentMethod == method
                  ? color
                  : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method,
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
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedPaymentMethod == method)
                Icon(
                  Icons.check_circle,
                  color: color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _proceedToPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF3366CC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          "Proceed to Payment",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
} 