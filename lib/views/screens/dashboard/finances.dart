import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:healthcare/models/transaction_model.dart';
import 'package:healthcare/utils/navigation_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare/services/auth_service.dart';
import 'package:healthcare/services/financial_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/views/screens/bottom_navigation_bar.dart';

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({Key? key}) : super(key: key);

  @override
  _FinancesScreenState createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  // Loading states
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  
  // Financial data
  List<TransactionItem> _transactions = [];
  double _totalBalance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _currentMonthIncome = 0.0;
  double _pendingAmount = 0.0;
  
  // Pagination
  int _currentPage = 1;
  bool _hasMoreData = true;
  DocumentSnapshot? _lastTransactionDoc;
  bool _hasMoreTransactions = true;
  bool _isLoadingMoreTransactions = false;
  final int _transactionsPerPage = 10;
  
  // Controllers
  final ScrollController _scrollController = ScrollController();
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  late final FinancialRepository _financialRepository;
  
  // Cache key
  static const String _financesCacheKey = 'doctor_finances_data';

  @override
  void initState() {
    super.initState();
    _financialRepository = FinancialRepository();
    _scrollController.addListener(_scrollListener);
    _loadFinancialData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll listener to detect when user scrolls to bottom
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMoreTransactions &&
        _hasMoreTransactions) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMoreTransactions || !_hasMoreTransactions) return;
    
    setState(() {
      _isLoadingMoreTransactions = true;
    });
    
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoadingMoreTransactions = false;
        });
        return;
      }
      
      // Load more transactions
      await _loadTransactions(currentUser.uid, isFirstLoad: false);
      
      // Recalculate financial summaries
      _calculateFinancialSummaries();
    } catch (e) {
      print('Error loading more transactions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreTransactions = false;
        });
      }
    }
  }

  Future<void> _loadFinancialData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    // First load cached data
    bool hasCachedData = await _loadCachedData();
    
    // Only clear and refresh if no cached data or cache is old
    if (!hasCachedData) {
      if (mounted) {
        setState(() {
          // Reset pagination data on fresh load
          _lastTransactionDoc = null;
          _hasMoreTransactions = true;
          _transactions.clear();
        });
      }
      // Then start background refresh
      _refreshData();
    } else {
      // If we have cached data, do a background refresh after a delay
      Future.delayed(Duration(seconds: 30), () {
        if (mounted) {
          _refreshData();
        }
      });
    }
  }

  // Load cached data first
  Future<bool> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_financesCacheKey);
      
      if (cachedData != null) {
        final Map<String, dynamic> data = json.decode(cachedData);
        
        // Check if cache is not too old (24 hours)
        final lastUpdated = DateTime.parse(data['lastUpdated'] ?? DateTime.now().toIso8601String());
        final now = DateTime.now();
        final difference = now.difference(lastUpdated);
        
        if (difference.inHours < 24) {
          if (mounted) {
            setState(() {
              _totalBalance = (data['totalBalance'] as num?)?.toDouble() ?? 0.0;
              _totalIncome = (data['totalIncome'] as num?)?.toDouble() ?? 0.0;
              _totalExpenses = (data['totalExpenses'] as num?)?.toDouble() ?? 0.0;
              _currentMonthIncome = (data['currentMonthIncome'] as num?)?.toDouble() ?? 0.0;
              _pendingAmount = (data['pendingAmount'] as num?)?.toDouble() ?? 0.0;
              
              // Load cached transactions
              if (data.containsKey('transactions')) {
                _transactions = (data['transactions'] as List)
                    .map((item) => TransactionItem(
                          item['title'],
                          (item['amount'] as num).toDouble(),
                          item['date'],
                          _convertTransactionType(item['type']),
                        ))
                    .toList();
              }
              
              _isLoading = false;
            });
          }
          return true;
        }
      }
    } catch (e) {
      print('Error loading cached finances data: $e');
    }
    return false;
  }

  // Refresh data in background
  Future<void> _refreshData() async {
    if (!mounted) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Store current transactions in case we need to revert
      final previousTransactions = List<TransactionItem>.from(_transactions);
      
      // Load transactions
      bool success = await _loadTransactionsFromRepository();
      
      // If repository load fails, use fallback
      if (!success) {
        await _loadTransactions(currentUser.uid, isFirstLoad: true);
      }
      
      // Calculate financial summaries
      _calculateFinancialSummaries();
      
      // Save to cache only if we successfully loaded new data
      if (_transactions.isNotEmpty) {
        await _saveToCache();
      } else {
        // Revert to previous transactions if new load failed
        setState(() {
          _transactions = previousTransactions;
        });
      }
      
    } catch (e) {
      print('Error refreshing financial data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isLoading = false;
        });
      }
    }
  }

  // Save current data to cache
  Future<void> _saveToCache() async {
    try {
      final Map<String, dynamic> cacheData = {
        'totalBalance': _totalBalance,
        'totalIncome': _totalIncome,
        'totalExpenses': _totalExpenses,
        'currentMonthIncome': _currentMonthIncome,
        'pendingAmount': _pendingAmount,
        'lastUpdated': DateTime.now().toIso8601String(),
        'transactions': _transactions.map((item) => {
          'title': item.title,
          'amount': item.amount,
          'date': item.date,
          'type': item.type == TransactionType.income ? 'income' : 'expense',
        }).toList(),
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_financesCacheKey, json.encode(cacheData));
      print('Saved ${_transactions.length} transactions to cache');
    } catch (e) {
      print('Error saving finances to cache: $e');
    }
  }

  void _calculateTotals() {
    _totalIncome = _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    _totalExpenses = _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    _totalBalance = _totalIncome - _totalExpenses;
  }

  List<TransactionItem> _generateMockTransactions() {
    final random = DateTime.now();
    return List.generate(10, (i) {
      final isIncome = i % 3 == 0;
      return TransactionItem(
        isIncome ? 'Payment Received' : 'Purchase',
        (i + 1) * 100.0,
        DateFormat('dd MMM, yyyy').format(random.subtract(Duration(days: i))),
        isIncome ? TransactionType.income : TransactionType.expense,
      );
    });
  }

  // Attempt to load transactions using the FinancialRepository
  Future<bool> _loadTransactionsFromRepository() async {
    try {
      // Clear existing transactions if first load
      if (_lastTransactionDoc == null) {
        _transactions.clear();
      }
      
      // Get transactions stream from the repository
      final transactionsStream = _financialRepository.getTransactions(limit: _transactionsPerPage);
      
      // Convert stream to list
      final transactionsList = await transactionsStream.first;
      
      // If no transactions, return false to use fallback
      if (transactionsList.isEmpty) {
        return false;
      }
      
      // Convert FinancialTransaction to TransactionItem
      for (var transaction in transactionsList) {
        _transactions.add(TransactionItem(
          transaction.title,
          transaction.amount,
          DateFormat('dd MMM, yyyy').format(transaction.date),
          _convertTransactionType(transaction.type),
        ));
      }
      
      return true;
    } catch (e) {
      print('Error loading from repository: $e');
      return false;
    }
  }
  
  // Helper method to convert between TransactionType enums
  TransactionType _convertTransactionType(dynamic modelType) {
    if (modelType == null) return TransactionType.income;
    
    // Check if it's a string first
    if (modelType is String) {
      return modelType == 'expense' ? TransactionType.expense : TransactionType.income;
    }
    
    // Handle the case where it's the model's TransactionType enum
    try {
      final typeValue = modelType.toString().split('.').last;
      return typeValue == 'expense' ? TransactionType.expense : TransactionType.income;
    } catch (e) {
      return TransactionType.income;
    }
  }
  
  // Load transactions from Firestore
  Future<void> _loadTransactions(String userId, {required bool isFirstLoad}) async {
    try {
      // Clear existing transactions if first load
      if (isFirstLoad) {
        _transactions.clear();
        _lastTransactionDoc = null;
      }
      
      // Create base query
      Query query = _firestore
          .collection('transactions')
          .where('doctorId', isEqualTo: userId)
          .where('type', isEqualTo: 'payment')
          .where('status', isEqualTo: 'completed')
          .orderBy('date', descending: true);
      
      // Apply pagination
      if (_lastTransactionDoc != null) {
        query = query.startAfterDocument(_lastTransactionDoc!);
      }
      
      // Limit results
      query = query.limit(_transactionsPerPage);
      
      // Execute query
      final transactionsSnapshot = await query.get();
      
      // Update pagination info
      _hasMoreTransactions = transactionsSnapshot.docs.length >= _transactionsPerPage;
      
      if (transactionsSnapshot.docs.isNotEmpty) {
        _lastTransactionDoc = transactionsSnapshot.docs.last;
      }
      
      // If no transactions found on first load, try loading from appointments
      if (transactionsSnapshot.docs.isEmpty && isFirstLoad) {
        await _loadTransactionsFromAppointments(userId, isFirstLoad: true);
      } else {
        // Process transactions
        for (var doc in transactionsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Get patient name for better description
          String patientName = "Patient";
          if (data['patientId'] != null) {
            try {
              final patientDoc = await _firestore
                  .collection('users')
                  .doc(data['patientId'])
                  .get();
              
              if (patientDoc.exists && patientDoc.data() != null) {
                patientName = patientDoc.data()!['fullName'] ?? "Patient";
              }
            } catch (e) {
              print('Error fetching patient name: $e');
            }
          }

          String title = data['title'] ?? 'Payment Received';
          String description = data['description'] ?? 'Payment from $patientName';
          double amount = data['amount'] is num ? (data['amount'] as num).toDouble() : 0.0;
          DateTime date = data['date'] is Timestamp 
              ? (data['date'] as Timestamp).toDate() 
              : DateTime.now();
          
          // For doctors, all payments received are considered income
          _transactions.add(TransactionItem(
            description,
            amount,
            DateFormat('dd MMM, yyyy').format(date),
            TransactionType.income,
          ));
        }
      }
    } catch (e) {
      print('Error loading transactions: $e');
      // If there was an error on first load, try appointments as fallback
      if (isFirstLoad) {
        await _loadTransactionsFromAppointments(userId, isFirstLoad: true);
      }
    }
  }
  
  // Load transactions from appointments as an alternative source
  Future<void> _loadTransactionsFromAppointments(String userId, {required bool isFirstLoad}) async {
    try {
      // Clear existing transactions if this is first load
      if (isFirstLoad) {
        _transactions.clear();
        _lastTransactionDoc = null;
      }
      
      // Create base query
      Query query = _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: userId)
          .where('status', isEqualTo: 'confirmed')
          .where('paymentStatus', isEqualTo: 'completed')
          .orderBy('paymentDate', descending: true);
      
      // Apply pagination
      if (_lastTransactionDoc != null) {
        query = query.startAfterDocument(_lastTransactionDoc!);
      }
      
      // Limit results
      query = query.limit(_transactionsPerPage);
      
      // Execute query
      final appointmentsSnapshot = await query.get();
      
      // Update pagination info
      _hasMoreTransactions = appointmentsSnapshot.docs.length >= _transactionsPerPage;
      
      if (appointmentsSnapshot.docs.isNotEmpty) {
        _lastTransactionDoc = appointmentsSnapshot.docs.last;
      }
      
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get patient name
        String patientName = "Patient";
        if (data.containsKey('patientId')) {
          try {
            final patientDoc = await _firestore
                .collection('users')
                .doc(data['patientId'])
                .get();
            
            if (patientDoc.exists && patientDoc.data() != null) {
              final patientData = patientDoc.data()! as Map<String, dynamic>;
              patientName = patientData['fullName'] ?? "Patient";
            }
          } catch (e) {
            print('Error fetching patient: $e');
          }
        }
        
        // Prepare transaction data
        String title = "Payment from $patientName";
        double amount = data['fee'] is num ? (data['fee'] as num).toDouble() : 0.0;
        DateTime date = data['paymentDate'] is Timestamp 
            ? (data['paymentDate'] as Timestamp).toDate() 
            : (data['date'] is Timestamp ? (data['date'] as Timestamp).toDate() : DateTime.now());
        
        // For doctors, all appointment payments are income
        _transactions.add(TransactionItem(
          title,
          amount,
          DateFormat('dd MMM, yyyy').format(date),
          TransactionType.income,
        ));
      }
    } catch (e) {
      print('Error loading transactions from appointments: $e');
    }
  }
  
  // Calculate financial summaries based on loaded transactions
  void _calculateFinancialSummaries() {
    _totalIncome = 0.0;
    _totalExpenses = 0.0;
    _currentMonthIncome = 0.0;
    _pendingAmount = 0.0;
    
    // Get current month and year
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    for (var transaction in _transactions) {
      // Calculate totals based on transaction type
      if (transaction.type == TransactionType.income) {
        _totalIncome += transaction.amount;
        
        // Check if transaction is from current month
        final transactionDate = DateFormat('dd MMM, yyyy').parse(transaction.date);
        if (transactionDate.month == currentMonth && transactionDate.year == currentYear) {
          _currentMonthIncome += transaction.amount;
        }
      } else {
        _totalExpenses += transaction.amount;
      }
    }
    
    // Calculate total balance
    _totalBalance = _totalIncome - _totalExpenses;
    
    // Set pending amount (10% of total income as an example)
    // In a real app, you would query pending transactions
    _pendingAmount = _totalIncome * 0.1;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to the bottom navigation bar with home tab selected
        // Since this is in the doctor flow, use the BottomNavigationBarScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavigationBarScreen(
              profileStatus: "complete",
              initialIndex: 0, // Home tab index
            ),
          ),
        );
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
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
                    child: _isLoading
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20.0),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Column(
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
                                "Rs ${_totalBalance.toStringAsFixed(0)}",
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
                                    "Rs ${_totalIncome.toStringAsFixed(0)}",
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
                                    "Rs ${_totalExpenses.toStringAsFixed(0)}",
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
                            "Rs ${_currentMonthIncome.toStringAsFixed(0)}",
                            Color(0xFFE8F5E9),
                            LucideIcons.calendar,
                            Color(0xFF4CAF50),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: _buildStatCard(
                            "Pending",
                            "Rs ${_pendingAmount.toStringAsFixed(0)}",
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
                          onPressed: _refreshData,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isRefreshing)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromRGBO(64, 124, 226, 1),
                                      ),
                                    ),
                                  ),
                                ),
                              Text(
                                _isRefreshing ? "Refreshing..." : "Refresh",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromRGBO(64, 124, 226, 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Transactions list
                  Expanded(
                    child: _transactions.isEmpty && !_isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.database,
                                  size: 50,
                                  color: Colors.grey.shade300,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No transactions found",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _transactions.length + (_hasMoreTransactions ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _transactions.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  child: Center(
                                    child: SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Color.fromRGBO(64, 124, 226, 1),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return _buildTransactionCard(_transactions[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
            
            // Bottom refresh indicator
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
                              Color.fromRGBO(64, 124, 226, 1),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Refreshing finances...",
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
    );
  }

  Widget _buildBalanceItem(String title, String amount, IconData icon, Color iconColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
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
              SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color bgColor, IconData icon, Color iconColor) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
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
            "Rs ${transaction.amount.toStringAsFixed(0)}",
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
  final double amount;
  final String date;
  final TransactionType type;

  TransactionItem(this.title, this.amount, this.date, this.type);
}
