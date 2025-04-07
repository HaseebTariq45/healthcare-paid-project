import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentMethodsScreen extends StatelessWidget {
  final List<Map<String, String>> paymentMethods = [
    {
      "type": "Bank",
      "name": "Habib Bank Limited",
      "holder": "Asmara",
      "number": "1111 2222 3333 4444",
      "expiry": "12/27",
      "cvv": "333",
      "color": "0xFF71C282", // Green color
      "icon": "bank",
    },
    {
      "type": "Wallet",
      "name": "JazzCash",
      "holder": "Asmara",
      "number": "0300 - 1112223",
      "color": "0xFFC2554D", // Red color
      "icon": "wallet",
    },
  ];

  PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Payment Methods",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: paymentMethods.length,
                itemBuilder: (context, index) {
                  return _buildPaymentCard(paymentMethods[index]);
                },
              ),
            ),
            const SizedBox(height: 10),
            _buildAddPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, String> payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(int.parse(payment["color"]!)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                payment["icon"] == "bank"
                    ? Icons.credit_card
                    : Icons.account_balance_wallet,
                color: Colors.white,
                size: 28,
              ),
              if (payment["cvv"] != null)
                Text(
                  "CVV  ${payment["cvv"]}",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            payment["name"]!,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            payment["holder"]!,
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                payment["number"]!,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (payment["expiry"] != null)
                Text(
                  payment["expiry"]!,
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add, color: Color.fromRGBO(64, 124, 226, 1)),
        label: Text(
          "Add New Payment Method",
          style: GoogleFonts.poppins(color: Color.fromRGBO(64, 124, 226, 1)),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color.fromRGBO(64, 124, 226, 1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }
}
