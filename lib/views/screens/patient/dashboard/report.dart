import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReportsScreen extends StatelessWidget {
  final List<Map<String, String>> reports = [
    {"title": "Appointment with Dr Asmara", "date": "Dec 30, 2024"},
    {"title": "Appointment with Dr Fahad", "date": "Dec 30, 2024"},
    {"title": "Last Month Expenditure", "date": "Dec 30, 2024"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView( // Fix: Allows the entire screen to be scrollable
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoCard(
                    title: "Blood Group",
                    value: "B+",
                    icon: LucideIcons.droplet,
                    color: Colors.pink.shade100,
                  ),
                  _infoCard(
                    title: "Weight",
                    value: "103lbs",
                    icon: LucideIcons.dumbbell,
                    color: Colors.amber.shade100,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Latest Reports
              Text(
                "Latest Reports",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Report List
              ListView.builder(
                shrinkWrap: true, // Fix: Prevents ListView from taking all space
                physics: NeverScrollableScrollPhysics(), // Fix: Avoids nested scrolling issue
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _reportTile(report["title"]!, report["date"]!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for Info Cards
  Widget _infoCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      width: 40,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.black),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.black)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  // Widget for Report ListTile
  Widget _reportTile(String title, String date) {
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
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(LucideIcons.fileText, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(date, style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          Icon(LucideIcons.ellipsis, color: Colors.black54),
        ],
      ),
    );
  }
}
