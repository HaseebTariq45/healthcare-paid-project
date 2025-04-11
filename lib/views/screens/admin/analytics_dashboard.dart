import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({Key? key}) : super(key: key);

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final List<String> _timeFilters = ['Last 7 days', 'Last 30 days', 'Last 3 months', 'Last year'];
  String _selectedTimeFilter = 'Last 30 days';
  
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
      body: SingleChildScrollView(
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
                        });
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
                    '247',
                    '+12% vs last period',
                    Icons.calendar_today,
                    Color(0xFF3366CC),
                    true,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    'Total Revenue',
                    'Rs 458,200',
                    '+8% vs last period',
                    Icons.attach_money,
                    Color(0xFF4CAF50),
                    true,
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
                    '54',
                    '+5% vs last period',
                    Icons.person_add,
                    Color(0xFFFFC107),
                    true,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    'New Doctors',
                    '12',
                    '-3% vs last period',
                    Icons.medical_services,
                    Color(0xFFFF5722),
                    false,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Appointment Trends Chart
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
                  SizedBox(
                    height: 250,
                    child: LineChart(
                      _appointmentLineChartData(),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Revenue Chart
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
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      _revenueBarChartData(),
                    ),
                  ),
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
                  SizedBox(
                    height: 300,
                    child: PieChart(
                      _specialtyPieChartData(),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Legend
                  _buildSpecialtyLegend(),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Doctor-Patient Growth
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
                    'User Growth Trends',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Doctor and patient growth over time',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    height: 250,
                    child: LineChart(
                      _userGrowthLineChartData(),
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
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? Color(0xFF4CAF50) : Color(0xFFFF5722),
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                trend,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isPositive ? Color(0xFF4CAF50) : Color(0xFFFF5722),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSpecialtyLegend() {
    final Map<String, Color> specialties = {
      'Cardiology': Color(0xFF3366CC),
      'Dermatology': Color(0xFFFF5722),
      'Orthopedics': Color(0xFF4CAF50),
      'Gynecology': Color(0xFFFFC107),
      'Neurology': Color(0xFF9C27B0),
      'Others': Color(0xFF607D8B),
    };
    
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: specialties.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: entry.value,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(
              entry.key,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
  
  // Chart data
  LineChartData _appointmentLineChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              String text = '';
              switch (value.toInt()) {
                case 0:
                  text = 'Mon';
                  break;
                case 2:
                  text = 'Wed';
                  break;
                case 4:
                  text = 'Fri';
                  break;
                case 6:
                  text = 'Sun';
                  break;
                default:
                  text = '';
              }
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value % 10 == 0) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${value.toInt()}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
            reservedSize: 28,
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            FlSpot(0, 15),
            FlSpot(1, 18),
            FlSpot(2, 24),
            FlSpot(3, 26),
            FlSpot(4, 22),
            FlSpot(5, 30),
            FlSpot(6, 28),
          ],
          isCurved: true,
          color: Color(0xFF3366CC),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Color(0xFF3366CC),
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Color(0xFF3366CC).withOpacity(0.2),
          ),
        ),
      ],
    );
  }
  
  BarChartData _revenueBarChartData() {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 100000,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.white,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              'Rs ${rod.toY.toInt()}',
              GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              String text = '';
              switch (value.toInt()) {
                case 0:
                  text = 'Jan';
                  break;
                case 1:
                  text = 'Feb';
                  break;
                case 2:
                  text = 'Mar';
                  break;
                case 3:
                  text = 'Apr';
                  break;
                case 4:
                  text = 'May';
                  break;
                case 5:
                  text = 'Jun';
                  break;
                default:
                  text = '';
              }
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              );
            },
            reservedSize: 16,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              String text = '';
              if (value == 0) {
                text = '0';
              } else if (value == 50000) {
                text = '50K';
              } else if (value == 100000) {
                text = '100K';
              }
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              );
            },
            reservedSize: 40,
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      gridData: FlGridData(
        show: true,
        checkToShowHorizontalLine: (value) => value % 25000 == 0,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.shade200,
          strokeWidth: 1,
        ),
        drawVerticalLine: false,
      ),
      borderData: FlBorderData(show: false),
      barGroups: [
        _generateBarGroup(0, 45000),
        _generateBarGroup(1, 58000),
        _generateBarGroup(2, 53000),
        _generateBarGroup(3, 72000),
        _generateBarGroup(4, 80000),
        _generateBarGroup(5, 95000),
      ],
    );
  }
  
  BarChartGroupData _generateBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Color(0xFF4CAF50),
          width: 22,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }
  
  PieChartData _specialtyPieChartData() {
    return PieChartData(
      sections: [
        PieChartSectionData(
          value: 35,
          title: '35%',
          color: Color(0xFF3366CC),
          radius: 100,
          titleStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        PieChartSectionData(
          value: 20,
          title: '20%',
          color: Color(0xFFFF5722),
          radius: 100,
          titleStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        PieChartSectionData(
          value: 15,
          title: '15%',
          color: Color(0xFF4CAF50),
          radius: 100,
          titleStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        PieChartSectionData(
          value: 15,
          title: '15%',
          color: Color(0xFFFFC107),
          radius: 100,
          titleStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        PieChartSectionData(
          value: 10,
          title: '10%',
          color: Color(0xFF9C27B0),
          radius: 100,
          titleStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        PieChartSectionData(
          value: 5,
          title: '5%',
          color: Color(0xFF607D8B),
          radius: 100,
          titleStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
      sectionsSpace: 2,
      centerSpaceRadius: 0,
    );
  }
  
  LineChartData _userGrowthLineChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              String text = '';
              switch (value.toInt()) {
                case 0:
                  text = 'Jan';
                  break;
                case 1:
                  text = 'Feb';
                  break;
                case 2:
                  text = 'Mar';
                  break;
                case 3:
                  text = 'Apr';
                  break;
                case 4:
                  text = 'May';
                  break;
                case 5:
                  text = 'Jun';
                  break;
                default:
                  text = '';
              }
              return Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value % 20 == 0) {
                return Text(
                  '${value.toInt()}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                );
              }
              return const SizedBox();
            },
            reservedSize: 28,
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      lineBarsData: [
        // Patients line
        LineChartBarData(
          spots: [
            FlSpot(0, 38),
            FlSpot(1, 45),
            FlSpot(2, 52),
            FlSpot(3, 60),
            FlSpot(4, 68),
            FlSpot(5, 80),
          ],
          isCurved: true,
          color: Color(0xFF4CAF50),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Color(0xFF4CAF50),
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
        // Doctors line
        LineChartBarData(
          spots: [
            FlSpot(0, 12),
            FlSpot(1, 14),
            FlSpot(2, 16),
            FlSpot(3, 18),
            FlSpot(4, 20),
            FlSpot(5, 24),
          ],
          isCurved: true,
          color: Color(0xFF3366CC),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Color(0xFF3366CC),
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.white,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final String type = barSpot.barIndex == 0 ? 'Patients' : 'Doctors';
              return LineTooltipItem(
                '$type: ${barSpot.y.toInt()}',
                GoogleFonts.poppins(
                  color: barSpot.barIndex == 0 ? Color(0xFF4CAF50) : Color(0xFF3366CC),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
} 