import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/seed_data_service.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeveloperToolsScreen extends StatefulWidget {
  const DeveloperToolsScreen({super.key});

  @override
  State<DeveloperToolsScreen> createState() => _DeveloperToolsScreenState();
}

class _DeveloperToolsScreenState extends State<DeveloperToolsScreen> {
  final SeedDataService _seedService = SeedDataService();
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  String _userInfo = 'No user info yet';
  String? _currentRole;
  String? _userId;
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userData = await _authService.getUserData();
        final userRole = await _authService.getUserRole();
        setState(() {
          _userId = currentUser.uid;
          _userInfo = 'Current User: ${userData?['fullName'] ?? 'Unknown'}\n'
              'Phone: ${userData?['phoneNumber'] ?? 'Unknown'}\n'
              'Role: ${userData?['role'] ?? 'Unknown'}\n'
              'Role from enum: $userRole';
          _currentRole = userData?['role'];
        });
      } else {
        setState(() {
          _userInfo = 'No user currently logged in';
        });
      }
    } catch (e) {
      setState(() {
        _userInfo = 'Error loading user info: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changeRole(String newRole) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_userId != null) {
        // Update the role in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .update({
          'role': newRole,
        });

        // Clear role cache
        await _authService.clearRoleCache();

        // Reload user info
        await _loadCurrentUserInfo();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role changed to $newRole successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error changing role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

                SizedBox(height: 24),
                
                // User Information Card
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current User Information',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          _userInfo,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildRoleButton('patient'),
                            _buildRoleButton('doctor'),
                            _buildRoleButton('ladyhealthworker'),
                          ],
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _authService.clearRoleCache();
                            await _loadCurrentUserInfo();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Role cache cleared!'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          icon: Icon(Icons.refresh),
                          label: Text('Clear Role Cache'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildRoleButton(String role) {
    final bool isCurrentRole = _currentRole == role;
    return ElevatedButton(
      onPressed: isCurrentRole ? null : () => _changeRole(role),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrentRole ? Colors.grey : Color(0xFF3366CC),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.green,
        disabledForegroundColor: Colors.white,
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