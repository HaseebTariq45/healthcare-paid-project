import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/successfull_appoinment.dart';

class JazzCashPaymentScreen extends StatefulWidget {
  @override
  _JazzCashPaymentScreenState createState() => _JazzCashPaymentScreenState();
}

class _JazzCashPaymentScreenState extends State<JazzCashPaymentScreen> {
  final TextEditingController _phoneController = TextEditingController();

  void _confirmPayment() {
    String phoneNumber = _phoneController.text;
    if (phoneNumber.isNotEmpty && phoneNumber.length >= 10) {
      print("Proceeding with payment via JazzCash: $phoneNumber");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientAppointmentDetailsScreen(), // Navigate to JazzCash screen
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid phone number")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "Book Appointment"),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text("JazzCash", style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            const SizedBox(height: 20),

            // Phone Number Input
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.account_balance_wallet_rounded, color: Colors.grey),
                hintText: "+92 000 0000000",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 40),

            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _confirmPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromRGBO(64, 124, 226, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          "Book Appointment",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
