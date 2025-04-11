import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/seed_data_service.dart';

class DeveloperToolsScreen extends StatefulWidget {
  const DeveloperToolsScreen({super.key});

  @override
  State<DeveloperToolsScreen> createState() => _DeveloperToolsScreenState();
}

class _DeveloperToolsScreenState extends State<DeveloperToolsScreen> {
  final SeedDataService _seedService = SeedDataService();
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Developer Tools',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning banner
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Developer Mode',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'These tools are for development and testing only. Do not use in production.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                Text(
                  'Firebase Tools',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Message display
                if (_message != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isError ? Colors.red.shade200 : Colors.green.shade200,
                      ),
                    ),
                    child: Text(
                      _message!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ),
                
                // Seed Hospitals button
                _buildActionCard(
                  title: 'Seed Hospitals',
                  description: 'Add sample hospitals to Firestore and connect them to the current doctor',
                  icon: Icons.business,
                  iconColor: Colors.blue,
                  backgroundColor: Colors.blue.shade50,
                  onTap: _seedHospitals,
                ),
                
                SizedBox(height: 12),
                
                // Add Availability button
                _buildActionCard(
                  title: 'Add Quick Availability',
                  description: 'Add sample availability for today and tomorrow at the first hospital',
                  icon: Icons.calendar_month,
                  iconColor: Colors.purple,
                  backgroundColor: Colors.purple.shade50,
                  onTap: _addQuickAvailability,
                ),
                
                SizedBox(height: 12),
                
                // Clear Hospital Data button
                _buildActionCard(
                  title: 'Clear Hospital Data',
                  description: 'Delete all hospitals and doctor assignments',
                  icon: Icons.delete_outline,
                  iconColor: Colors.red,
                  backgroundColor: Colors.red.shade50,
                  onTap: _cleanupHospitals,
                ),
                
                SizedBox(height: 24),
                
                Text(
                  'Application Info',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                
                SizedBox(height: 16),
                
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('App Version', '1.0.0 (Dev)'),
                      _buildInfoRow('Flutter Version', '3.16.0'),
                      _buildInfoRow('Firebase', 'Enabled'),
                      _buildInfoRow('Environment', 'Development'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            _isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Seed hospitals
  Future<void> _seedHospitals() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final result = await _seedService.seedHospitals();
      
      setState(() {
        _isLoading = false;
        _isError = !result['success'];
        _message = result['message'];
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _message = 'Error: ${e.toString()}';
      });
    }
  }

  // Add quick availability
  Future<void> _addQuickAvailability() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final result = await _seedService.addQuickAvailability();
      
      setState(() {
        _isLoading = false;
        _isError = !result['success'];
        _message = result['message'];
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _message = 'Error: ${e.toString()}';
      });
    }
  }

  // Clean up hospital data
  Future<void> _cleanupHospitals() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final result = await _seedService.cleanupHospitals();
      
      setState(() {
        _isLoading = false;
        _isError = !result['success'];
        _message = result['message'];
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _message = 'Error: ${e.toString()}';
      });
    }
  }
} 