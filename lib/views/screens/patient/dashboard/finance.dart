import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare/services/finance_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PatientFinancesScreen extends StatefulWidget {
  const PatientFinancesScreen({super.key});

  @override
  State<PatientFinancesScreen> createState() => _PatientFinancesScreenState();
}

class _PatientFinancesScreenState extends State<PatientFinancesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  TransactionType? _selectedType;
  
  // Financial summary data
  Map<String, num> _financialSummary = {
    'totalPaid': 0,
    'pendingPayments': 0,
    'refunds': 0,
  };
  
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _userId;
  List<FinancialTransaction> _transactions = [];
  List<FinancialTransaction> _filteredTransactions = [];
  static const String _financeCacheKey = 'patient_finance_data';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Initialize data
    _getUserId();
  }

  void _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      _loadData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = _tabController.index;
        
        // Update selected type based on tab
        switch (_selectedTabIndex) {
          case 0: // All
            _selectedType = null;
            _filterTransactions(null);
            break;
          case 1: // Payments
            _selectedType = TransactionType.payment;
            _filterTransactions(TransactionType.payment);
            break;
          case 2: // Refunds
            _selectedType = TransactionType.refund;
            _filterTransactions(TransactionType.refund);
            break;
        }
      });
    }
  }

  void _filterTransactions(TransactionType? type) {
    if (type == null) {
      _filteredTransactions = _transactions;
    } else {
      _filteredTransactions = _transactions.where((tx) => tx.type == type).toList();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Try to load data from cache first
    await _loadCachedData();
    
    // Then fetch fresh data from Firebase
    await _loadFinancialData();
  }

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString(_financeCacheKey);
      
      if (cachedData != null) {
        Map<String, dynamic> data = json.decode(cachedData);
        
        setState(() {
          _financialSummary = Map<String, num>.from(data['summary'] ?? {});
          
          // Convert cached transactions back to FinancialTransaction objects
          List<dynamic> txList = data['transactions'] ?? [];
          _transactions = txList.map((tx) => FinancialTransaction.fromJson(tx)).toList();
          
          _filterTransactions(_selectedType);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cached data: $e');
    }
  }

  // Load financial data from Firebase
  Future<void> _loadFinancialData() async {
    if (_userId == null) {
      debugPrint('Error: No user ID available');
      return;
    }

    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final repository = FinanceRepository();
      
      // Get transactions and summary from repository
      final transactions = await repository.getUserTransactions();
      final summary = await repository.getFinancialSummary();
      
      // Prepare data for caching
      Map<String, dynamic> cacheData = {
        'summary': summary,
        'transactions': transactions.map((tx) => tx.toJson()).toList(),
      };

      // Save to cache
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_financeCacheKey, json.encode(cacheData));
      } catch (e) {
        debugPrint('Error saving to cache: $e');
      }

      setState(() {
        _transactions = transactions;
        _filterTransactions(_selectedType); // Apply current filter
        _financialSummary = summary;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading financial data: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  // This method is replaced by the repository
  Future<void> _loadPatientPayments(FirebaseFirestore firestore, List<FinancialTransaction> fetchedTransactions) async {
    // Implementation moved to FinanceRepository
    return;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () async {
                  if (await _showExitConfirmationDialog(context)) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/patient/bottom_navigation', (route) => false);
                  }
                },
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Text(
                'Finance',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  _buildFinancialSummary(),
                  _buildTabBar(),
                  Expanded(
                    child: _buildTransactionsList(),
                  ),
                ],
              ),
              // Refresh indicator at bottom
              if (_isRefreshing)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF0167FF),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Refreshing...",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment History',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Track all your medical payments',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _loadData,
            icon: Icon(LucideIcons.refreshCcw),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0167FF), Color(0xFF0157FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0167FF).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Amount Paid',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${_financialSummary['totalPaid']}',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem(
                      title: 'Pending',
                      amount: _financialSummary['pendingPayments'],
                      icon: LucideIcons.clock,
                      iconColor: Colors.orangeAccent,
                    ),
                    _buildSummaryItem(
                      title: 'Refunds',
                      amount: _financialSummary['refunds'],
                      icon: LucideIcons.arrowUp,
                      iconColor: Colors.greenAccent,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required num? amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            Text(
              'Rs. ${amount ?? 0}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Color(0xFF0167FF),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black87,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Payments'),
          Tab(text: 'Refunds'),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.receipt,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedType == null
                  ? 'Your payment history will appear here'
                  : 'No ${_selectedType == TransactionType.payment ? 'payment' : 'refund'} transactions found',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTransactions.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(FinancialTransaction transaction) {
    final isPayment = transaction.type == TransactionType.payment;
    final isCompleted = transaction.status == TransactionStatus.completed;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPayment ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.creditCard,
                  color: isPayment ? Colors.blue : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPayment ? '-' : '+'} Rs. ${transaction.amount}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isPayment ? Colors.red : Colors.green,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted 
                        ? Colors.green.withOpacity(0.1) 
                        : transaction.status == TransactionStatus.pending
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction.status.toString().split('.').last,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isCompleted 
                          ? Colors.green 
                          : transaction.status == TransactionStatus.pending
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (transaction.doctorName != null || transaction.hospitalName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 46),
              child: Text(
                [
                  if (transaction.doctorName != null) 'Dr. ${transaction.doctorName}',
                  if (transaction.hospitalName != null) transaction.hospitalName,
                ].where((item) => item != null).join(' • '),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Add exit confirmation dialog
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Exit Finance Screen',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to exit?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Yes, Exit',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }
}

