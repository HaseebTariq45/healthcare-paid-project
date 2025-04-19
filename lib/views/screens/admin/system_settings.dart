import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:healthcare/views/screens/admin/admin_dashboard.dart';

class SystemSettings extends StatefulWidget {
  const SystemSettings({Key? key}) : super(key: key);

  @override
  State<SystemSettings> createState() => _SystemSettingsState();
}

class _SystemSettingsState extends State<SystemSettings> {
  // Mock settings
  bool _maintenanceMode = false;
  bool _enableNotifications = true;
  bool _enablePatientRegistration = true;
  bool _enableDoctorRegistration = true;
  String _selectedTheme = 'Light';
  double _appointmentFee = 5.0; // Default platform fee in %
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate back to admin dashboard and select the home tab
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboard(),
          ),
        );
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'System Settings',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // System Status
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _maintenanceMode ? Color(0xFFFF5722).withOpacity(0.1) : Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _maintenanceMode ? Icons.warning : Icons.check_circle,
                      color: _maintenanceMode ? Color(0xFFFF5722) : Color(0xFF4CAF50),
                      size: 28,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _maintenanceMode ? 'Maintenance Mode' : 'System Online',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _maintenanceMode ? Color(0xFFFF5722) : Color(0xFF4CAF50),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _maintenanceMode
                                ? 'The system is currently in maintenance mode. Only admins can access the platform.'
                                : 'The system is online and fully operational.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // General Settings
              Text(
                'General Settings',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              _buildSettingSwitch(
                'Maintenance Mode',
                'Put the system in maintenance mode',
                _maintenanceMode,
                (value) {
                  setState(() {
                    _maintenanceMode = value;
                  });
                  _showSettingUpdatedSnackBar('Maintenance mode');
                },
                icon: LucideIcons.wrench,
                color: Color(0xFFFF5722),
              ),
              _buildSettingSwitch(
                'Push Notifications',
                'Enable system-wide push notifications',
                _enableNotifications,
                (value) {
                  setState(() {
                    _enableNotifications = value;
                  });
                  _showSettingUpdatedSnackBar('Push notifications');
                },
                icon: LucideIcons.bell,
                color: Color(0xFF3366CC),
              ),
              _buildSettingSwitch(
                'Patient Registration',
                'Allow new patients to register',
                _enablePatientRegistration,
                (value) {
                  setState(() {
                    _enablePatientRegistration = value;
                  });
                  _showSettingUpdatedSnackBar('Patient registration');
                },
                icon: LucideIcons.userPlus,
                color: Color(0xFF4CAF50),
              ),
              _buildSettingSwitch(
                'Doctor Registration',
                'Allow new doctors to register',
                _enableDoctorRegistration,
                (value) {
                  setState(() {
                    _enableDoctorRegistration = value;
                  });
                  _showSettingUpdatedSnackBar('Doctor registration');
                },
                icon: LucideIcons.userPlus,
                color: Color(0xFF2196F3),
              ),
              
              SizedBox(height: 24),
              
              // Appearance Settings
              Text(
                'Appearance',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              _buildThemeSetting(),
              
              SizedBox(height: 24),
              
              // Payment Settings
              Text(
                'Payment Settings',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              _buildSliderSetting(),
              
              SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFC107).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.wallet,
                      color: Color(0xFFFFC107),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Configure Payment Methods',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Manage available payment gateways and options',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: Icon(LucideIcons.chevronRight),
                  onTap: () => _showPaymentMethodsBottomSheet(),
                ),
              ),
              
              SizedBox(height: 24),
              
              // System Backup
              Text(
                'System Maintenance',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(0xFF3366CC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.database,
                          color: Color(0xFF3366CC),
                          size: 24,
                        ),
                      ),
                      title: Text(
                        'Backup Database',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Create a full backup of the system database',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: Icon(LucideIcons.download),
                      onTap: () => _showBackupDialog(),
                    ),
                    Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF5722).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.trash2,
                          color: Color(0xFFFF5722),
                          size: 24,
                        ),
                      ),
                      title: Text(
                        'Clear System Cache',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Remove temporary files to improve performance',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: Icon(LucideIcons.trash),
                      onTap: () => _showClearCacheDialog(),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // Reset button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: Icon(LucideIcons.refreshCcw, color: Colors.red),
                  label: Text('Reset All Settings'),
                  onPressed: () => _showResetConfirmDialog(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSettingSwitch(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged, {
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Color(0xFF3366CC),
        ),
      ),
    );
  }
  
  Widget _buildThemeSetting() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFF9C27B0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.palette,
                    color: Color(0xFF9C27B0),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Theme',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Change the appearance of the app',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildThemeOption('Light', LucideIcons.sun),
                SizedBox(width: 16),
                _buildThemeOption('Dark', LucideIcons.moon),
                SizedBox(width: 16),
                _buildThemeOption('System', LucideIcons.smartphone),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeOption(String theme, IconData icon) {
    final isSelected = _selectedTheme == theme;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTheme = theme;
          });
          _showSettingUpdatedSnackBar('Theme');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF3366CC) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                size: 24,
              ),
              SizedBox(height: 8),
              Text(
                theme,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSliderSetting() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.percent,
                    color: Color(0xFF2196F3),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platform Fee',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Set the percentage fee for each appointment',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_appointmentFee.toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Slider(
              value: _appointmentFee,
              min: 0,
              max: 20,
              divisions: 40,
              activeColor: Color(0xFF2196F3),
              inactiveColor: Color(0xFF2196F3).withOpacity(0.2),
              label: '${_appointmentFee.toStringAsFixed(1)}%',
              onChanged: (value) {
                setState(() {
                  _appointmentFee = value;
                });
              },
              onChangeEnd: (value) {
                _showSettingUpdatedSnackBar('Platform fee');
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '20%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showSettingUpdatedSnackBar(String setting) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$setting updated successfully'),
        backgroundColor: Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  void _showPaymentMethodsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment Methods',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              Text(
                'Enabled Payment Gateways',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              
              SizedBox(height: 12),
              
              // Payment methods list
              _buildPaymentMethodItem('Credit/Debit Cards', true),
              _buildPaymentMethodItem('EasyPaisa', true),
              _buildPaymentMethodItem('JazzCash', true),
              _buildPaymentMethodItem('Bank Transfer', false),
              
              SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSettingUpdatedSnackBar('Payment methods');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3366CC),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPaymentMethodItem(String name, bool isEnabled) {
    return StatefulBuilder(
      builder: (context, setState) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          trailing: Switch(
            value: isEnabled,
            onChanged: (value) {
              setState(() {
                // This would update the local state in a real app
              });
            },
            activeColor: Color(0xFF3366CC),
          ),
        );
      }
    );
  }
  
  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Backup Database',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will create a complete backup of the system database. The process may take several minutes.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              // Simulate backup process
              Future.delayed(Duration(seconds: 3), () {
                Navigator.pop(context);
                _showSettingUpdatedSnackBar('Database backup completed');
              });
            },
            child: Text(
              'Backup',
              style: TextStyle(color: Color(0xFF3366CC)),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Cache',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will remove all temporary files from the system. Users may experience slower loading times initially as caches rebuild.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              // Simulate cache clearing process
              Future.delayed(Duration(seconds: 2), () {
                Navigator.pop(context);
                _showSettingUpdatedSnackBar('Cache cleared successfully');
              });
            },
            child: Text(
              'Clear Cache',
              style: TextStyle(color: Color(0xFFFF5722)),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset All Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will reset all system settings to their default values. This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset all settings
              setState(() {
                _maintenanceMode = false;
                _enableNotifications = true;
                _enablePatientRegistration = true;
                _enableDoctorRegistration = true;
                _selectedTheme = 'Light';
                _appointmentFee = 5.0;
              });
              _showSettingUpdatedSnackBar('Settings reset to defaults');
            },
            child: Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 