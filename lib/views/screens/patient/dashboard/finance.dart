import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PatientFinancesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> transactions = [
    {"title": "Appointment with Dr Asmara", "amount": "Rs 1800"},
    {"title": "Appointment with Dr Akbar", "amount": "Rs 5500"},
    {"title": "Appointment with Dr Fahad", "amount": "Rs 2990"},
    {"title": "Service Charges", "amount": "Rs 300"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spent Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.wallet, size: 24, color: Colors.black),
                        const SizedBox(height: 8),
                        Text("Spent", style: TextStyle(fontSize: 16, color: Colors.black)),
                      ],
                    ),
                    Text(
                      "Rs 15000",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Recent Transactions Title
              Text(
                "Recent Transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Transactions List
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _transactionTile(transaction["title"]!, transaction["amount"]!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Transaction Tile Widget
  Widget _transactionTile(String title, String amount) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Green Icon Box
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(LucideIcons.chevronRight, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 12),

          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(amount, style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),

          // More Options Icon
          Icon(LucideIcons.ellipsis, color: Colors.black54),
        ],
      ),
    );
  }
}
