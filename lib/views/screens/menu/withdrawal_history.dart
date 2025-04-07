import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WithdrawalHistoryScreen extends StatelessWidget {
  final List<Map<String, String>> transactions = [
    {"amount": "Rs 15000", "bank": "ABC Bank Limited", "date": "Dec 30, 2024"},
    {"amount": "Rs 15000", "bank": "ABC Bank Limited", "date": "Dec 30, 2024"},
  ];

  WithdrawalHistoryScreen({super.key});

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
          "Withdrawal History",
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
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return _buildTransactionCard(transactions[index]);
          },
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, String> transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(29, 158, 158, 158),
            blurRadius: 5,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.currency_rupee,
              color: Colors.blue,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Withdrawn ${transaction["amount"]}",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction["bank"]!,
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction["date"]!,
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
