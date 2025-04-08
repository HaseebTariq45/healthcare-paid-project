import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/transaction_model.dart';

class FinancesScreen extends StatelessWidget {
  final List<TransactionItem> transactions = [
    TransactionItem(
      "Appointment with Maheen",
      "Rs 1,800",
      "12 June, 2023",
      TransactionType.income,
    ),
    TransactionItem(
      "Appointment with Dr Akbar",
      "Rs 5,500",
      "10 June, 2023",
      TransactionType.expense,
    ),
    TransactionItem(
      "Appointment with Ajmal",
      "Rs 2,990",
      "8 June, 2023",
      TransactionType.income,
    ),
    TransactionItem(
      "Service Charges",
      "Rs 300",
      "5 June, 2023",
      TransactionType.income,
    ),
    TransactionItem(
      "Equipment Purchase",
      "Rs 8,500",
      "2 June, 2023",
      TransactionType.expense,
    ),
  ];

  FinancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom app bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    spreadRadius: 1,
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    "Financial Overview",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(64, 124, 226, 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.wallet,
                      color: Color.fromRGBO(64, 124, 226, 1),
                    ),
                  ),
                ],
              ),
            ),
            
            // Main financial summary
            Container(
              margin: EdgeInsets.fromLTRB(20, 20, 20, 10),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromRGBO(64, 124, 226, 1),
                    Color.fromRGBO(84, 144, 246, 1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(64, 124, 226, 0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.wallet,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Total Balance",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Rs 32,500",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBalanceItem(
                        "Income",
                        "Rs 40,300",
                        LucideIcons.arrowDown,
                        Colors.greenAccent,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildBalanceItem(
                        "Expenses",
                        "Rs 7,800",
                        LucideIcons.arrowUp,
                        Colors.redAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Financial stats
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "This Month",
                      "Rs 15,000",
                      Color(0xFFE8F5E9),
                      LucideIcons.calendar,
                      Color(0xFF4CAF50),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      "Pending",
                      "Rs 1,200",
                      Color(0xFFFFF3E0),
                      LucideIcons.hourglass,
                      Color(0xFFFF9800),
                    ),
                  ),
                ],
              ),
            ),
            
            // Recent transactions heading
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Transactions",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "See All",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color.fromRGBO(64, 124, 226, 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Transactions list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
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

  Widget _buildBalanceItem(String title, String amount, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 16,
          ),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 2),
            Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String amount,
    Color bgColor,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          SizedBox(height: 12),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionItem transaction) {
    final isIncome = transaction.type == TransactionType.income;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Transaction icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isIncome 
                  ? Color(0xFFE8F5E9) 
                  : Color(0xFFFBE9E7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? LucideIcons.arrowDown : LucideIcons.arrowUp,
              color: isIncome ? Color(0xFF4CAF50) : Color(0xFFF44336),
              size: 22,
            ),
          ),
          SizedBox(width: 15),
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  transaction.date,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            transaction.amount,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isIncome ? Color(0xFF4CAF50) : Color(0xFFF44336),
            ),
          ),
        ],
      ),
    );
  }
}

enum TransactionType { income, expense }

class TransactionItem {
  final String title;
  final String amount;
  final String date;
  final TransactionType type;

  TransactionItem(this.title, this.amount, this.date, this.type);
}
