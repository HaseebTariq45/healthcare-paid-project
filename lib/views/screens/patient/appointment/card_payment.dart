import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';
import 'package:healthcare/views/screens/patient/appointment/successfull_appoinment.dart';

class CardPaymentScreen extends StatefulWidget {
  @override
  _CardPaymentScreenState createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {

  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(isBackButtonVisible: true, text: "Book Appointment"),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Debit Card",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            ),
            SizedBox(height: 20),

            _buildTextField(_cardNameController, "Name of Card", Icons.person),
            _buildTextField(_cardNumberController, "0000 0000 0000 0000", Icons.credit_card, keyboardType: TextInputType.number),

            Row(
              children: [
                Expanded(child: _buildTextField(_expiryDateController, "12/22", Icons.calendar_today, keyboardType: TextInputType.datetime)),
                SizedBox(width: 10),
                Expanded(child: _buildTextField(_cvvController, "123", Icons.lock, keyboardType: TextInputType.number, obscureText: true)),
              ],
            ),

            _buildTextField(_addressController, "Address", Icons.location_on),
            _buildTextField(_provinceController, "Province", Icons.image),
            _buildTextField(_zipCodeController, "ZIP Code", Icons.location_city, keyboardType: TextInputType.number),

            SizedBox(height: 30),

            // Proceed Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon,
      {TextInputType keyboardType = TextInputType.text, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
           Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientAppointmentDetailsScreen(), // Navigate to JazzCash screen
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromRGBO(64, 124, 226, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          "Proceed",
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
