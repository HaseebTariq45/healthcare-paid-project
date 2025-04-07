import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/card_payment.dart';
import 'package:healthcare/views/screens/patient/appointment/easypaisa_payment.dart';
import 'package:healthcare/views/screens/patient/appointment/jazzcash_payment.dart';

class PaymentMethodScreen extends StatefulWidget {
  @override
  _PaymentMethodScreenState createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String? selectedPaymentMethod = "JazzCash"; // Default selection

  void _proceedToNextScreen() {
    if (selectedPaymentMethod == "JazzCash") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JazzCashPaymentScreen(), // Navigate to JazzCash screen
        ),
      );
    } else if(selectedPaymentMethod == "EasyPaisa"){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EasypaisaPaymentScreen(), // Navigate to JazzCash screen
        ),
      );
      // Handle other payment methods (EasyPaisa, Debit Card)
      print("Navigate to other payment screens...");
    }
    else if(selectedPaymentMethod == "Debit Card"){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardPaymentScreen(), // Navigate to JazzCash screen
        ),
      );
      // Handle other payment methods (EasyPaisa, Debit Card)
      print("Navigate to other payment screens...");
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
            // Subtitle
            Center(child: Text("Select Payment Method", style: TextStyle(color: Colors.grey, fontSize: 16))),
            const SizedBox(height: 20),

            // Payment Options
            _buildPaymentOption("JazzCash"),
            _buildPaymentOption("EasyPasia"),
            _buildPaymentOption("Debit Card"),

            const SizedBox(height: 40),

           _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // Widget for Payment Options
  Widget _buildPaymentOption(String method) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: RadioListTile<String>(
        title: Text(method, style: TextStyle(fontSize: 16)),
        value: method,
        groupValue: selectedPaymentMethod,
        activeColor: Colors.black,
        onChanged: (value) {
          setState(() {
            selectedPaymentMethod = value;
          });
        },
      ),
    );
  }
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _proceedToNextScreen,
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

