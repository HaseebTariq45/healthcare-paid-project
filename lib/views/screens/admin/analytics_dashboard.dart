import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcare/services/admin_service.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({Key? key}) : super(key: key);

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final List<String> _timeFilters = ['Last 7 days', 'Last 30 days', 'Last 3 months', 'Last year'];
  String _selectedTimeFilter = 'Last 30 days';
  
  // Service and state
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _analyticsData = {};
  
  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }
  
  Future<void> _loadAnalyticsData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      debugPrint('Loading analytics data for period: $_selectedTimeFilter');
      final data = await _adminService.getGrowthMetrics(_selectedTimeFilter);
      
      // Check if the data contains an error flag
      if (data['error'] == true) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load analytics data: ${data['errorMessage']}';
            _isLoading = false;
          });
        }
        return;
      }
      
      if (mounted) {
        setState(() {
          _analyticsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error in _loadAnalyticsData: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load analytics data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalyticsData,
        child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAnalyticsData,
                      child: Text('Try Again'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time filter
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Time Period:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedTimeFilter,
                    icon: Icon(Icons.keyboard_arrow_down),
                    underline: SizedBox(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedTimeFilter = newValue;
                                  _isLoading = true;
                        });
                                _loadAnalyticsData();
                      }
                    },
                    items: _timeFilters
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // KPI Cards
            Text(
              'Key Performance Indicators',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    'Total Appointments',
                            '${_analyticsData['currentPeriodAppointments'] ?? 0}',
                            '${_analyticsData['appointmentGrowth']?.toStringAsFixed(1) ?? 0}% vs last period',
                    Icons.calendar_today,
                    Color(0xFF3366CC),
                            _analyticsData['appointmentGrowth'] != null ? _analyticsData['appointmentGrowth'] >= 0 : true,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    'Total Revenue',
                            'Rs ${NumberFormat('#,###').format(_analyticsData['currentPeriodRevenue'] ?? 0)}',
                            '${_analyticsData['revenueGrowth']?.toStringAsFixed(1) ?? 0}% vs last period',
                    Icons.attach_money,
                    Color(0xFF4CAF50),
                            _analyticsData['revenueGrowth'] != null ? _analyticsData['revenueGrowth'] >= 0 : true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    'New Patients',
                            '${_analyticsData['currentPeriodPatients'] ?? 0}',
                            '${_analyticsData['patientGrowth']?.toStringAsFixed(1) ?? 0}% vs last period',
                    Icons.person_add,
                    Color(0xFFFFC107),
                            _analyticsData['patientGrowth'] != null ? _analyticsData['patientGrowth'] >= 0 : true,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    'New Doctors',
                            '${_analyticsData['currentPeriodDoctors'] ?? 0}',
                            '${_analyticsData['doctorGrowth']?.toStringAsFixed(1) ?? 0}% vs last period',
                    Icons.medical_services,
                    Color(0xFFFF5722),
                            _analyticsData['doctorGrowth'] != null ? _analyticsData['doctorGrowth'] >= 0 : true,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
                    // Appointment Trends
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment Trends',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Number of appointments over time',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 24),
                          _buildAppointmentsList(),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
                    // Revenue Tracking
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Tracking',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Platform revenue in Pakistani Rupees',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 24),
                          _buildRevenueList(),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Popular Specialties
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popular Specialties',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Most booked medical specialties',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 24),
                          _buildSpecialtyList(),
                        ],
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
  
  Widget _buildKpiCard(String title, String value, String trend, IconData icon, Color color, bool isPositive) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? Color(0xFF4CAF50) : Color(0xFFFF5722),
                size: 12,
              ),
              SizedBox(width: 2),
              Flexible(
                child: Text(
                  trend,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isPositive ? Color(0xFF4CAF50) : Color(0xFFFF5722),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppointmentsList() {
    Map<String, dynamic> appointmentsByDay = 
        (_analyticsData['appointmentsByDay'] as Map<String, dynamic>?) ?? {};
    
    if (appointmentsByDay.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No appointment data available for the selected period',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    // Sort the dates
    List<String> sortedDates = appointmentsByDay.keys.toList()..sort();
    
    return Column(
      children: [
        for (String date in sortedDates)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                child: Text(
                    _formatDate(date),
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${appointmentsByDay[date]}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3366CC),
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRevenueList() {
    Map<String, dynamic> revenueByDay = 
        (_analyticsData['revenueByDay'] as Map<String, dynamic>?) ?? {};
    
    if (revenueByDay.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No revenue data available for the selected period',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    // Sort the dates
    List<String> sortedDates = revenueByDay.keys.toList()..sort();
    
    return Column(
      children: [
        for (String date in sortedDates)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                child: Text(
                    _formatDate(date),
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                child: Text(
                    'Rs ${NumberFormat('#,###').format(revenueByDay[date])}',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildSpecialtyList() {
    Map<String, dynamic> specialtyDistribution = 
        (_analyticsData['specialtyDistribution'] as Map<String, dynamic>?) ?? {};
    
    if (specialtyDistribution.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No specialty data available for the selected period',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    // Sort the specialties by count (descending)
    List<MapEntry<String, dynamic>> sortedSpecialties = 
        specialtyDistribution.entries.toList()
        ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    
    // Calculate total for percentages
    int totalAppointments = sortedSpecialties
        .fold(0, (sum, entry) => sum + (entry.value as num).toInt());
    
    return Column(
      children: [
        for (MapEntry<String, dynamic> specialty in sortedSpecialties)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        specialty.key,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${specialty.value} (${totalAppointments > 0 ? ((specialty.value / totalAppointments) * 100).toStringAsFixed(1) : 0}%)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
          ),
        ),
      ],
                ),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: totalAppointments > 0 ? (specialty.value / totalAppointments) : 0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getColorForSpecialty(sortedSpecialties.indexOf(specialty)),
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
          ),
        ),
      ],
    );
  }
  
  Color _getColorForSpecialty(int index) {
    final List<Color> colors = [
      Color(0xFF3366CC), // Blue
      Color(0xFF4CAF50), // Green
      Color(0xFFFFC107), // Yellow
      Color(0xFFFF5722), // Orange
      Color(0xFF9C27B0), // Purple
      Color(0xFF607D8B), // Blue Grey
      Color(0xFF795548), // Brown
    ];
    
    return colors[index % colors.length];
  }
  
  String _formatDate(String dateStr) {
    // Format from "YYYY-MM-DD" to "Mon DD, YYYY"
    final dateParts = dateStr.split('-');
    if (dateParts.length >= 3) {
      final year = dateParts[0];
      final month = int.tryParse(dateParts[1]) ?? 1;
      final day = int.tryParse(dateParts[2]) ?? 1;
      
      final monthNames = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      return '${monthNames[month]} $day, $year';
    }
    
    return dateStr;
  }
} 