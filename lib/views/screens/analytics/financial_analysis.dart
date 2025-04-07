import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/views/components/onboarding.dart';

class FinancialAnalyticsScreen extends StatelessWidget {
  const FinancialAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarOnboarding(
        isBackButtonVisible: true,
        text: "Financial Analytics",
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Finances",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildFinanceCard(context,
                icon: Icons.account_balance_wallet,
                text: "Payments being Cleared",
                amount: "Rs 12000",
              ),
              const SizedBox(height: 15),
              _buildFinanceCard(
                context,
                icon: Icons.arrow_downward,
                text: "Payments Withdrawn",
                amount: "Rs 50000",
              ),
              const SizedBox(height: 20),
              Image.asset("assets/images/earnings_graph.png", fit: BoxFit.cover),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceCard(BuildContext context, {
    required IconData icon,
    required String text,
    required String amount,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Color.fromRGBO(64, 124, 226, 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
