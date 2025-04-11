import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare/services/financial_repository.dart';
import 'package:healthcare/models/transaction_model.dart';
import 'package:healthcare/utils/navigation_helper.dart';
import 'package:fl_chart/fl_chart.dart';

class FinancialAnalyticsScreen extends StatefulWidget {
  const FinancialAnalyticsScreen({super.key});

  @override
  State<FinancialAnalyticsScreen> createState() => _FinancialAnalyticsScreenState();
}

class _FinancialAnalyticsScreenState extends State<FinancialAnalyticsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Financial repository
  final FinancialRepository _financialRepository = FinancialRepository();
  
  // Financial data
  bool _isLoading = true;
  Map<String, num> _financialSummary = {
    'income': 0,
    'expense': 0,
    'balance': 0,
    'pending': 0,
  };
  
  List<Map<String, dynamic>> _monthlyData = [];
  List<FinancialTransaction> _recentTransactions = [];
  
  // Analysis results
  double _averageMonthlyIncome = 0;
  double _growthRate = 0;
  int _mostProfitableMonth = 0;
  String _mostProfitableCategory = 'Unknown';
  double _projectedAnnualIncome = 0;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
    
    _loadFinancialData();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  // Load all financial data
  Future<void> _loadFinancialData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get financial summary for the last 12 months
      final now = DateTime.now();
      final lastYear = DateTime(now.year - 1, now.month, now.day);
      
      // Load financial summary
      final summary = await _financialRepository.getFinancialSummary(
        startDate: lastYear,
      );
      
      // Load monthly data
      final monthlyData = await _financialRepository.getMonthlyFinancialSummary(
        year: now.year,
      );
      
      // Load recent transactions
      final transactionsStream = _financialRepository.getTransactions(limit: 10);
      final recentTransactions = await transactionsStream.first;
      
      // Load pending amount
      final pendingTransactions = await _financialRepository.getPendingTransactions().first;
      final pendingAmount = pendingTransactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
      
      // Calculate financial insights
      _analyzeFinancialData(monthlyData, summary, pendingAmount);
      
      if (mounted) {
        setState(() {
          _financialSummary = {
            'income': summary['income'] ?? 0,
            'expense': summary['expense'] ?? 0,
            'balance': summary['balance'] ?? 0,
            'pending': pendingAmount,
          };
          _monthlyData = monthlyData;
          _recentTransactions = recentTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading financial data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Analyze financial data to extract insights
  void _analyzeFinancialData(
    List<Map<String, dynamic>> monthlyData,
    Map<String, num> summary,
    double pendingAmount
  ) {
    if (monthlyData.isEmpty) return;
    
    // Calculate average monthly income
    double totalIncome = 0;
    int nonZeroMonths = 0;
    
    for (var month in monthlyData) {
      final income = month['income'] as num;
      if (income > 0) {
        totalIncome += income.toDouble();
        nonZeroMonths++;
      }
    }
    
    _averageMonthlyIncome = nonZeroMonths > 0 ? totalIncome / nonZeroMonths : 0;
    
    // Find most profitable month
    int mostProfitableMonth = 1;
    double highestIncome = 0;
    
    for (var month in monthlyData) {
      final income = month['income'] as num;
      if (income > highestIncome) {
        highestIncome = income.toDouble();
        mostProfitableMonth = month['month'] as int;
      }
    }
    
    _mostProfitableMonth = mostProfitableMonth;
    
    // Calculate growth rate (comparing first and last 3 months with data)
    double firstQuarterIncome = 0;
    double lastQuarterIncome = 0;
    int firstCount = 0;
    int lastCount = 0;
    
    // Get months with data
    final activeMonths = monthlyData
        .where((month) => (month['income'] as num) > 0)
        .toList()
      ..sort((a, b) => (a['month'] as int).compareTo(b['month'] as int));
    
    if (activeMonths.length >= 2) {
      // Take first third and last third
      final firstThird = activeMonths.sublist(0, (activeMonths.length / 3).ceil());
      final lastThird = activeMonths.sublist(activeMonths.length - (activeMonths.length / 3).ceil());
      
      for (var month in firstThird) {
        firstQuarterIncome += (month['income'] as num).toDouble();
        firstCount++;
      }
      
      for (var month in lastThird) {
        lastQuarterIncome += (month['income'] as num).toDouble();
        lastCount++;
      }
      
      if (firstCount > 0 && lastCount > 0 && firstQuarterIncome > 0) {
        // Calculate average quarterly growth
        final avgFirstQuarter = firstQuarterIncome / firstCount;
        final avgLastQuarter = lastQuarterIncome / lastCount;
        _growthRate = ((avgLastQuarter - avgFirstQuarter) / avgFirstQuarter) * 100;
      }
    }
    
    // Project annual income based on current monthly average and growth trend
    if (_averageMonthlyIncome > 0) {
      // Simple projection: average monthly income * 12 * (1 + growth rate)
      final growthFactor = 1 + (_growthRate / 100);
      _projectedAnnualIncome = _averageMonthlyIncome * 12 * (growthFactor > 0 ? growthFactor : 1);
    }
    
    // Determine most profitable category (in a real app, you'd have transaction categories)
    _mostProfitableCategory = "Consultations";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Financial Analytics",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadFinancialData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Financial Summary"),
                    const SizedBox(height: 20),
                    _buildFinanceCards(),
                    const SizedBox(height: 25),
                    _buildInsightsCard(),
                    const SizedBox(height: 25),
                    _buildSectionHeader("Earnings Breakdown"),
                    const SizedBox(height: 20),
                    _buildEarningsChart(),
                    const SizedBox(height: 25),
                    _buildSectionHeader("Growth Analysis"),
                    const SizedBox(height: 20),
                    _buildGrowthAnalysisCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      )),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFinanceCards() {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs ',
      decimalDigits: 0,
    );
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
      )),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFinanceCard(
                  context,
                  icon: Icons.account_balance_wallet,
                  text: "Total Balance",
                  amount: currencyFormat.format(_financialSummary['balance']),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildFinanceCard(
                  context,
                  icon: Icons.arrow_downward,
                  text: "Total Income",
                  amount: currencyFormat.format(_financialSummary['income']),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildFinanceCard(
                  context,
                  icon: Icons.trending_up,
                  text: "Avg. Monthly",
                  amount: currencyFormat.format(_averageMonthlyIncome),
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildFinanceCard(
                  context,
                  icon: Icons.credit_card,
                  text: "Pending",
                  amount: currencyFormat.format(_financialSummary['pending']),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(
    BuildContext context, {
    required IconData icon,
    required String text,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsightsCard() {
    final monthFormat = DateFormat('MMMM');
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs ',
      decimalDigits: 0,
    );
    
    final mostProfitableMonthName = monthFormat.format(
      DateTime(DateTime.now().year, _mostProfitableMonth)
    );
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      )),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3949AB),
              Color(0xFF5C6BC0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Financial Insights",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 15),
            _buildInsightRow(
              "Growth Rate",
              "${_growthRate.toStringAsFixed(1)}%",
              _growthRate >= 0 ? Icons.trending_up : Icons.trending_down,
              _growthRate >= 0 ? Colors.green.shade300 : Colors.red.shade300,
            ),
            Divider(color: Colors.white24, height: 20),
            _buildInsightRow(
              "Most Profitable Month",
              mostProfitableMonthName,
              Icons.calendar_today,
              Colors.amber.shade300,
            ),
            Divider(color: Colors.white24, height: 20),
            _buildInsightRow(
              "Projected Annual Income",
              currencyFormat.format(_projectedAnnualIncome),
              Icons.analytics,
              Colors.teal.shade300,
            ),
            Divider(color: Colors.white24, height: 20),
            _buildInsightRow(
              "Primary Revenue Source",
              _mostProfitableCategory,
              Icons.pie_chart,
              Colors.purple.shade300,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInsightRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsChart() {
    // Filter only months with data
    final monthsWithData = _monthlyData
        .asMap()
        .entries
        .where((entry) => (entry.value['income'] as num) > 0)
        .toList();
    
    if (monthsWithData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "No earnings data available for the current year",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    // Create bar chart data
    List<BarChartGroupData> barGroups = [];
    
    for (var entry in monthsWithData) {
      final monthIndex = entry.value['month'] as int;
      final income = (entry.value['income'] as num).toDouble();
      final expense = (entry.value['expense'] as num).toDouble();
      
      barGroups.add(
        BarChartGroupData(
          x: monthIndex,
          barRods: [
            BarChartRodData(
              toY: income,
              color: Colors.green.shade400,
              width: 15,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: expense,
              color: Colors.red.shade400,
              width: 15,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
        )),
        child: Container(
          height: 300,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Monthly Income vs Expenses",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildLegendItem(Colors.green.shade400, "Income"),
                  const SizedBox(width: 20),
                  _buildLegendItem(Colors.red.shade400, "Expenses"),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: barGroups,
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            final formatter = NumberFormat.compact();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                formatter.format(value),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                monthNames[value.toInt()],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      horizontalInterval: 5000,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                      drawVerticalLine: false,
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
  
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
  
  Widget _buildGrowthAnalysisCard() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      )),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Revenue Growth Analysis",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildGrowthAnalysisRow(
              "Growth Trend",
              _growthRate >= 10 ? "Strong Positive" :
              _growthRate >= 5 ? "Positive" :
              _growthRate >= 0 ? "Stable" :
              _growthRate >= -5 ? "Slight Decline" : "Decline",
              _getGrowthStatusColor(_growthRate),
            ),
            const SizedBox(height: 15),
            _buildGrowthAnalysisRow(
              "Performance vs Target",
              _averageMonthlyIncome >= 50000 ? "Exceeding" :
              _averageMonthlyIncome >= 30000 ? "Meeting" : "Below",
              _averageMonthlyIncome >= 30000 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 15),
            _buildGrowthAnalysisRow(
              "Year-End Projection",
              _projectedAnnualIncome >= 600000 ? "Excellent" :
              _projectedAnnualIncome >= 400000 ? "Good" :
              _projectedAnnualIncome >= 200000 ? "Fair" : "Needs Improvement",
              _getProjectionStatusColor(_projectedAnnualIncome),
            ),
            const SizedBox(height: 20),
            _buildRecommendationSection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGrowthAnalysisRow(String label, String status, Color statusColor) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecommendationSection() {
    String recommendation;
    IconData icon;
    
    if (_growthRate >= 10) {
      recommendation = "Consider expanding services to capitalize on strong growth";
      icon = Icons.trending_up;
    } else if (_growthRate >= 0) {
      recommendation = "Maintain current strategy while exploring new opportunities";
      icon = Icons.thumbs_up_down;
    } else {
      recommendation = "Review pricing strategy and focus on increasing patient volume";
      icon = Icons.trending_down;
    }
    
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade100,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb,
            color: Colors.amber.shade700,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Recommendation",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  recommendation,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getGrowthStatusColor(double growthRate) {
    if (growthRate >= 10) return Colors.green.shade700;
    if (growthRate >= 5) return Colors.green;
    if (growthRate >= 0) return Colors.blue;
    if (growthRate >= -5) return Colors.orange;
    return Colors.red;
  }
  
  Color _getProjectionStatusColor(double projectedIncome) {
    if (projectedIncome >= 600000) return Colors.green.shade700;
    if (projectedIncome >= 400000) return Colors.green;
    if (projectedIncome >= 200000) return Colors.orange;
    return Colors.red;
  }
}
