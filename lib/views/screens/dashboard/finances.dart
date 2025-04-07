import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FinancesScreen extends StatelessWidget {
  final List<TransactionItem> transactions = [
    TransactionItem(
      "Appointment with Maheen",
      "Rs 1800",
      Colors.green,
      Icons.check,
    ),
    TransactionItem(
      "Appointment with Dr Akbar",
      "Rs 5500",
      Colors.red,
      Icons.close,
    ),
    TransactionItem(
      "Appointment with Ajmal",
      "Rs 2990",
      Colors.green,
      Icons.check,
    ),
    TransactionItem("Service Charges", "Rs 300", Colors.green, Icons.check),
  ];

  FinancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Finances",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard(
                  "Earnings this Month",
                  "Rs 15000",
                  Colors.green,
                  Icons.account_balance_wallet,
                ),
                _buildStatCard(
                  "Payment Pending",
                  "Rs 1200",
                  Colors.orange,
                  Icons.swap_horiz,
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              "Recent Transactions",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  return _buildTransactionCard(transactions[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 160,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black, size: 28),
          SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 5),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionItem transaction) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: transaction.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(transaction.icon, color: Colors.white),
        ),
        title: Text(
          transaction.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(transaction.amount),
        trailing: Icon(Icons.more_vert),
      ),
    );
  }
}

class TransactionItem {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  TransactionItem(this.title, this.amount, this.color, this.icon);
}
